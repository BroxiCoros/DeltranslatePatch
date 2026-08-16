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
// Un idioma sin cachear no deberia llegar aqui nunca: la precarga los deja
// todos listos en el arranque del capitulo. Si aun asi pasara, se carga del
// disco entero y de golpe -antes habia un mecanismo de carga diferida para
// suavizar ese frame, retirado por inalcanzable-. En consola ese camino ademas
// ABORTA el proceso, ver `scr_lang_preload_others`.
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

    // ----- El cambio de verdad -----
    // Los assets del idioma que dejamos NO se tocan: `scr_init_localization`
    // los guarda enteros en la cache (`scr_lang_cache_save`), y por eso volver
    // a este idioma sale gratis. Antes se trasladaban a `outdated_sprites` /
    // `outdated_sounds` para borrarlos al cambiar de sala; ese mecanismo ya no
    // existe, y con el se fue el riesgo de dejar un `sprite_index` apuntando a
    // un sprite borrado o de cortar una voz a mitad.
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

    // El título de la ventana está traducido, pero solo se pone al arrancar el
    // capítulo (`obj_initializer2_Create_0` y el final de `PROCESS_LOGO_Draw_0`),
    // así que sin esto se queda en el idioma anterior. La guarda es por el Cap.1:
    // antes del logo `scr_windowcaption` usa su argumento tal cual, y "" dejaría
    // la barra en blanco.
    if (global.chapter != 1 || global.tempflag[10] == 1)
        scr_windowcaption("")

    // Persistir la elección para próximas sesiones y para que el menú
    // principal arranque en el mismo idioma.
    ossafe_ini_open("true_config.ini")
    ini_write_string("LANG", "LANG_DT", global.lang)
    ossafe_ini_close()
    ossafe_savedata_save()
}
