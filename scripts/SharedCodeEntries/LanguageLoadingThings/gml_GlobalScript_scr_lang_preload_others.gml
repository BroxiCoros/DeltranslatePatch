// Precarga a la cache los packs instalados que NO son el idioma activo.
//
// Es la segunda mitad de hacer que cambiar de idioma sea instantaneo. La cache
// por si sola ya deja gratis la vuelta a un idioma por el que ya pasaste, pero
// la PRIMERA vez que entras en uno sigue costando lo que cuesta leerlo del
// disco. Esto lo adelanta al arranque del capitulo, que es justo donde debe
// estar: hay pantalla de carga y ahi un segundo mas no se nota, mientras que en
// mitad de la partida un tiron si.
//
// Es exactamente lo que hace que los idiomas nativos parezcan instantaneos: no
// es que carguen rapido, es que ya estaban cargados desde que arranco el
// ejecutable.
//
// Se llama SOLO en el boot (desde `scr_init_localization`, cuando detecta que
// `lang_loaded` estaba vacio). En un cambio en caliente no tiene nada que
// hacer.
//
// CORRE TAMBIEN EN CONSOLA, y ahi no es una optimizacion: es lo unico que hace
// que un segundo pack funcione.
//
// Estuvo detras de un `if (global.is_console)` por RAM. Dos razones para
// quitarlo:
//
//   1. En Switch, `buffer_load` deja de resolver contra el romfs en cuanto la
//      savedata esta montada -lo avisa el upstream en `scr_buffer_load`: las
//      funciones que cargan sprites, fuentes y audio se cambiaron para usar la
//      ruta ROM primero, `buffer_load` no-, y un `nn::fs::OpenFile` que falla
//      NO devuelve error alli: ABORTA el proceso (2002-6006, pantalla negra).
//      Esta funcion se llama desde `scr_init_localization` en el boot, o sea
//      desde el Create de `obj_gamecontroller`, que es la unica ventana en que
//      la savedata todavia no esta montada. Cargar aqui los demas packs es
//      cargarlos en el unico momento seguro; despues, cambiar de idioma es un
//      acierto de cache que no toca ni un fichero. Sin esto, el pack con el que
//      arranca el capitulo funcionaba y cualquier otro mataba el juego.
//   2. El ahorro de RAM era menor de lo que parecia: la cache deja los dos
//      packs residentes en cuanto el jugador cambia de idioma una vez, asi que
//      la guarda no bajaba el pico, solo lo aplazaba. Solo ahorraba memoria a
//      quien nunca cambiase de idioma.
//
// Y de paso el codigo de consola deja de divergir del de PC en este camino.

function scr_lang_preload_others()
{
    if (!variable_global_exists("languages_list") || !variable_global_exists("all_lang_settings"))
        exit;

    // Si todavia no hay nada cargado no hay estado que preservar; algo se ha
    // llamado fuera de orden.
    if (!variable_global_exists("chemg_sprite_map") || !ds_exists(global.chemg_sprite_map, ds_type_map))
        exit;

    // Estado del idioma activo, para devolverlo EXACTAMENTE como estaba. No se
    // usa la cache para esto: el activo puede ser un idioma nativo, y esos no
    // se cachean nunca (ver `scr_lang_cache_save`).
    var keep_lang = global.lang
    var keep_settings = global.lang_settings
    var keep_chapter = global.chapter_lang_settings
    var keep_sprite_map = global.chemg_sprite_map
    var keep_sound_map = global.chemg_sound_map
    var keep_font_map = global.font_map
    var keep_lang_map = global.lang_map
    var keep_missing = variable_global_exists("lang_missing_map") ? global.lang_missing_map : -1
    var keep_sprites = global.loaded_sprites
    var keep_sounds = global.loaded_sounds
    var keep_fonts = global.loaded_fonts

    var keep_spr_pending = variable_global_exists("lang_sprites_pending") ? global.lang_sprites_pending : false
    var keep_snd_pending = variable_global_exists("lang_sounds_pending") ? global.lang_sounds_pending : false

    // Aqui la carga tiene que ser completa: diferir no tiene sentido cuando el
    // objetivo es precisamente dejarlo todo listo.
    global.lang_sprites_pending = false
    global.lang_sounds_pending = false

    for (var i = 0; i < array_length(global.languages_list); i++)
    {
        var code = global.languages_list[i]

        if (code == keep_lang)
            continue
        // Los nativos no necesitan precarga: sus assets ya estan en el data.win.
        if (is_native_lang(code))
            continue
        if (scr_lang_cache_has(code))
            continue
        if (!variable_struct_exists(global.all_lang_settings, code))
            continue

        // `get_lang_folder_path`, `get_lang_setting` y `get_chapter_lang_setting`
        // resuelven contra el idioma activo, asi que hay que activarlo de
        // verdad mientras se carga. Se restaura al salir del bucle.
        global.lang = code
        global.lang_settings = variable_struct_get(global.all_lang_settings, code)

        scr_lang_load_assets()
        scr_lang_cache_save(code)
    }

    global.lang = keep_lang
    global.lang_settings = keep_settings
    global.chapter_lang_settings = keep_chapter
    global.chemg_sprite_map = keep_sprite_map
    global.chemg_sound_map = keep_sound_map
    global.font_map = keep_font_map
    global.lang_map = keep_lang_map
    if (keep_missing != -1)
        global.lang_missing_map = keep_missing
    global.loaded_sprites = keep_sprites
    global.loaded_sounds = keep_sounds
    global.loaded_fonts = keep_fonts
    global.lang_sprites_pending = keep_spr_pending
    global.lang_sounds_pending = keep_snd_pending

    // Las fuentes-sprite (`global.tvlandfont` en el Cap.3, las de dano en el
    // Cap.5) son globales sueltos, no van dentro de la cache, asi que la
    // precarga las dejo apuntando al ultimo idioma que cargo. Rehacerlas
    // contra el idioma activo, ya restaurado, las devuelve a su sitio. El
    // loader borra la anterior antes de crear la nueva, asi que tampoco queda
    // colgando la que creo la precarga.
    if (variable_global_exists("lang_fonts_loader"))
        global.lang_fonts_loader()
}
