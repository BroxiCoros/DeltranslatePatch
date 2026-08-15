// Cambia el idioma activo DENTRO de un capítulo, sin reiniciar la sala.
//
// No se puede reusar `change_language` en los capítulos porque esa
// función ya existe y hace otra cosa completamente distinta: alterna
// `global.orig_en` (el "modo traductor" que compara el texto con el
// original en inglés). Por eso aquí se define una función nueva.
//
// El trabajo de verdad lo hace `scr_init_localization`. En el caso normal ese
// trabajo es ninguno: el idioma ya esta en la cache (`scr_lang_cache`), porque
// o se precargo al arrancar el capitulo o ya se paso por el antes, y entrar en
// el es reasignar cuatro ds_map. Es lo mismo que hace el juego con sus idiomas
// nativos, y por eso ahora cuesta lo mismo: nada.
//
// Solo cuando el idioma NO esta cacheado hay que leer del disco de verdad (un
// pack instalado despues del arranque del capitulo). En consola ese camino
// ademas ABORTA el proceso -ver `scr_lang_preload_others`-, y por eso alli la
// precarga no es opcional: si un idioma llega hasta aqui sin cachear, mal. Para
// ese caso siguen los dos flags de pendiente que se marcan abajo: los loops de
// sprites y sonidos de `init` se saltan y la carga se difiere al primer
// `scr_84_get_sprite` / `scr_84_get_sound` o al cambio de sala (detector en el
// Step de `obj_gamecontroller`), en vez de congelar el frame del cambio.
//
// Sí toca el modo traductor: es una propiedad del pack (`translator_mode` en
// su settings.json), no del jugador, así que viaja con el idioma. Ver el
// bloque del final.

function scr_switch_game_language(argument0) //gml_Script_scr_switch_game_language
{
    var target_lang = argument0
    if (target_lang == global.lang) {
        exit;
    }

    global.lang = target_lang
    // Eleccion explicita del jugador; ver `is_native_lang`.
    global.lang_choice = target_lang

    // Usar la caché si el Create del gamecontroller ya escaneó todos
    // los idiomas; si no (por seguridad), leer del disco. Los idiomas
    // nativos no tienen carpeta ni settings.json: su struct siempre sale de
    // la caché, que es donde lo dejó `scan_languages()`.
    if (variable_global_exists("all_lang_settings") && variable_struct_exists(global.all_lang_settings, target_lang))
    {
        global.lang_settings = variable_struct_get(global.all_lang_settings, target_lang)
    }
    else
    {
        var settings_path = get_lang_folder_path() + "settings.json"
        if (scr_file_exists(settings_path))
            global.lang_settings = scr_load_json(settings_path)
    }

    // El modo especial y las voces dobladas se recuerdan por idioma:
    // releer los del idioma nuevo. Sin fallback a las claves globales: un
    // idioma que nunca se tocó arranca con su default de fábrica (modo
    // especial apagado, voces dobladas encendidas), y así ninguno de los
    // dos flags viaja a packs que no ofrecen ese interruptor.
    // Va antes de `scr_init_localization` porque de él dependen las
    // variantes `sp_`/`spm_` que se resolverán con el idioma nuevo.
    ossafe_ini_open("true_config.ini")
    global.special_mode = ini_read_real("LANG", "special_mode_" + global.lang, 0)
    global.translated_songs = ini_read_real("LANG", "translated_songs_" + global.lang, 1)
    ossafe_ini_close()

    // ----- Marcar la recarga como pendiente -----
    // Los assets del idioma que dejamos NO se tocan aqui: `scr_init_localization`
    // los guarda enteros en la cache (`scr_lang_cache_save`) un momento despues,
    // y por eso volver a este idioma sale gratis. Antes se trasladaban a
    // `outdated_sprites` / `outdated_sounds` para borrarlos al cambiar de sala;
    // ese mecanismo ya no existe, y con el se fue el riesgo de dejar un
    // `sprite_index` apuntando a un sprite borrado o de cortar una voz a mitad.
    //
    // Los flags siguen porque el diferido sigue haciendo falta cuando el idioma
    // nuevo NO esta cacheado: en consola no se precarga, y un pack instalado
    // despues del arranque tampoco estara. Si esta cacheado,
    // `scr_init_localization` los apaga acto seguido y no llega a diferirse nada.
    global.lang_sprites_pending = true
    global.lang_sounds_pending = true

    // ----- Recarga inmediata de fuentes y strings -----
    // Reutilizamos `scr_init_localization`. Los sprites y los sonidos NO
    // se recargan aqui: sus loops en `init` estan guardados por los flags
    // `lang_sprites_pending` / `lang_sounds_pending`, asi que se difieren
    // y los cargan `scr_load_lang_sprites_only` / el `lang_sounds_loader`
    // del capitulo despues.
    scr_init_localization()

    // ----- Modo traductor: caso simétrico al de la U -----
    // Si el pack nuevo no lo declara, se apaga. `orig_en` se resetea con él
    // porque `scr_84_get_sound` y `scr_84_get_sprite` lo consultan SIN
    // gatearlo por `translator_mode`: dejarlo encendido daría texto traducido
    // pero sprites y sonidos en inglés. El sentido contrario (encenderlo) no
    // se hace aquí a propósito: el modo traductor lo activa el usuario con la
    // U, no un cambio de idioma.
    if (!get_lang_setting("translator_mode", 0))
    {
        global.translator_mode = 0
        global.orig_en = false
    }

    // Persistir la elección para próximas sesiones y para que el menú
    // principal arranque en el mismo idioma.
    ossafe_ini_open("true_config.ini")
    ini_write_string("LANG", "LANG_DT", global.lang)
    ossafe_ini_close()
    ossafe_savedata_save()
}
