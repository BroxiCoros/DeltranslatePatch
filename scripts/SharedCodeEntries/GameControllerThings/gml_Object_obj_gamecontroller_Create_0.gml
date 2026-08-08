if (instance_number(obj_gamecontroller) > 1)
{
    instance_destroy();
    exit;
}

// En los capítulos el ejecutable vive en `chapterN_windows/`, por eso
// `../lang/` apunta a la carpeta de idiomas compartida del juego.
global.lang_folder = working_directory + "../lang/"

global.lang = "en"
global.orig_en = false

global.is_console = scr_is_switch_os() || os_type == os_ps4 || os_type == os_ps5;
scr_file_exists_init(global.lang_folder, undefined);
var launch_data = scr_init_launch_parameters();
global.launcher = launch_data.is_launcher;
is_connecting_controller = 3;
gamepad_active = 0;
gamepad_id = 0;
gamepad_shoulderlb_reassign = 0;
gamepad_type = "";
_load_enabled = false;

if (!variable_global_exists("gamepad_type"))
    global.gamepad_type = "N/A";

enable_loading = function()
{
    _load_enabled = true;
};

init_global_vars();

// ---------------------------------------------------------------
// Configuración persistida (true_config.ini)
// ---------------------------------------------------------------
// `saved_lang` es lo único añadido aquí: el idioma que el jugador
// eligió la última vez, para el escaneo multi-idioma de más abajo.
// `special_mode` y `translated_songs` NO se leen aquí (a diferencia del
// upstream): se recuerdan por idioma, así que hace falta saber cuál está
// activo. Ver más abajo.
//
// En consola NO se puede tocar el ini todavía: `ossafe_ini_open` no lee del
// disco sino de `global.savedata`, que se rellena de forma asíncrona y en
// este momento aún no existe. Todo lo persistido se difiere al Step, que
// espera a `ld_load_state == 2` y entonces reaplica idioma y ajustes.
global.translator_mode = 0;
speed_mode = 0;
global.special_mode = 0;
global.translated_songs = 1;
var saved_lang = "";
if (!global.is_console)
{
    ossafe_ini_open("true_config.ini");
    saved_lang = ini_read_string("LANG", "LANG_DT", "");
    ossafe_ini_close();
}
else
{
    ld_load_state = 0;
}

global.lang_sprites = ds_map_create();
global.lang_sounds = ds_map_create();
global.lang_fonts = ds_map_create();
global.lang_settings = {};

// En consola, al volver al menú del capítulo el juego hace `game_restart()`,
// que reejecuta este Create SIN volver a montar el romfs. Cualquier
// `directory_exists`/`file_find_*` sobre una ruta del pack en ese momento no
// devuelve `false`: aborta el proceso con `2002-6006` en `nn::fs::OpenDirectory`
// (pantalla negra). Los globales SÍ sobreviven al reinicio, así que reusamos el
// escaneo del arranque en vez de repetirlo. Es la misma guarda que el upstream
// tiene en `scr_file_exists_init` para `global.file_map`; sin ella, este
// `scan_languages` era el único punto del fork que volvía a entrar al romfs.
// En escritorio se reescanea como siempre.
lang_scan_valid = global.is_console
    && variable_global_exists("languages_list")
    && array_length(global.languages_list) > 0
    && variable_global_exists("all_lang_settings");

if (!lang_scan_valid)
{
    global.languages_list = [];
    global.all_lang_settings = {};
    global.is_single_lang_mode = false;
}

// ---------------------------------------------------------------
// Escaneo de idiomas disponibles en `lang/`
// ---------------------------------------------------------------
// - Primero iteramos subcarpetas y leemos `lang/<code>/settings.json` de
//   cada pack válido. Si encontramos al menos uno, gana el modo
//   multi-idioma y se IGNORA cualquier `lang/settings.json` suelto en la raíz.
// - Solo si no hay ninguna subcarpeta válida caemos al pack heredado de un
//   solo idioma (`lang/settings.json` en la raíz).
scan_languages = function() {
    global.languages_list = []
    global.all_lang_settings = {}
    global.is_single_lang_mode = false

    var s = undefined
    var code = ""

    if (directory_exists(global.lang_folder)) {
        var entry = file_find_first(global.lang_folder + "*", fa_directory)
        while (entry != "") {
            if (entry != "." && entry != ".." && directory_exists(global.lang_folder + entry)) {
                var setting_path = global.lang_folder + entry + "/settings.json"
                if (scr_file_exists(setting_path)) {
                    s = scr_load_json(setting_path)
                    code = get_struct_field(s, "lang_code", entry)
                    array_push(global.languages_list, code)
                    variable_struct_set(global.all_lang_settings, code, s)
                }
            }
            entry = file_find_next()
        }
        file_find_close()
    }

    // Fallback al pack suelto de la raíz solo si el barrido de subcarpetas
    // no encontró ningún idioma válido.
    if (array_length(global.languages_list) == 0 && scr_file_exists(global.lang_folder + "settings.json")) {
        global.is_single_lang_mode = true
        s = scr_load_json(global.lang_folder + "settings.json")
        code = get_struct_field(s, "lang_code", "en")
        array_push(global.languages_list, code)
        variable_struct_set(global.all_lang_settings, code, s)
    }

    // ---------------------------------------------------------------
    // Idiomas NATIVOS del juego (inglés y japonés)
    // ---------------------------------------------------------------
    // Se ofrecen siempre, sin carpeta en `lang/`: sus strings, sprites,
    // sonidos y fuentes ya están dentro del data.win, y el juego trae el
    // código que los carga (`scr_84_init_localization`, que el mod nunca
    // reemplaza). `is_native_lang()` es lo que hace que el resto del mod se
    // aparte y deje trabajar a ese código.
    //
    // Si un pack declara el mismo `lang_code`, el pack gana: quien instala
    // un pack "en" quiere el suyo, no el inglés de fábrica.
    //
    // Se añaden TAMBIÉN en modo pack-suelto (`is_single_lang_mode`). Al
    // principio esto iba detrás de un `if (!global.is_single_lang_mode)`,
    // asumiendo que en ese modo no hay selector; es falso: el modo suelto solo
    // significa que el pack está en la raíz de `lang/` en vez de en una
    // subcarpeta, y el menú de idioma sigue existiendo. Con el guard, en una
    // instalación de pack suelto los idiomas nativos no aparecían nunca.
    if (true) {
        var native_codes = ["en", "ja"]
        var native_names = ["English", "日本語"]

        for (var i = 0; i < array_length(native_codes); i++) {
            if (!variable_struct_exists(global.all_lang_settings, native_codes[i])) {
                var ns = {}
                variable_struct_set(ns, "name", native_names[i])
                variable_struct_set(ns, "lang_code", native_codes[i])
                variable_struct_set(ns, "native", true)
                array_push(global.languages_list, native_codes[i])
                variable_struct_set(global.all_lang_settings, native_codes[i], ns)
            }
        }
    }
}

if (!lang_scan_valid)
    scan_languages();

// ---------------------------------------------------------------
// Elegir el idioma inicial
// ---------------------------------------------------------------
// Prioridad:
//   1) El que el jugador eligió la última vez (persistido en INI).
//   2) El idioma del sistema operativo, si hay un pack que lo sirva.
//   3) El primero encontrado al escanear (orden del file system).
//   4) "en" como fallback si no hay pack alguno.
//
// El paso 2 sustituye al `es_mx` fijo que había aquí antes. Con un único
// pack instalado da igual (el paso 3 elige ese mismo), pero con varios
// (en/ja junto a es_mx) cada jugador arranca en el suyo en vez de en el que
// el file system devolviera primero, que salía al azar entre máquinas.
//
// Nada de esto pisa la elección del jugador: en cuanto cambia de idioma una
// vez se guarda en `LANG_DT` y el paso 1 gana siempre.
//
// OJO con la forma del código: `os_get_language()` devuelve SOLO el idioma
// en ISO 639 de dos letras ("es", "en", "ja"), nunca la región, así que no
// puede coincidir tal cual con un `lang_code` tipo "es_mx". Por eso el paso
// 2 prueba primero el código entero (sirve para packs que se llamen "en" o
// "ja") y después compara solo la base del idioma de cada pack. Si el
// sistema no expone el dato devuelve "" y el paso se salta entero.
// No usamos `os_get_region()` para desempatar entre variantes del mismo
// idioma (es_mx vs es_es) porque esa función NO está en la tabla de
// funciones del data.win de DELTARUNE: habría que inyectarla y no está
// probado que el runner la resuelva. Con varias variantes gana la primera
// que devuelva el escaneo.

// "es_mx" -> "es", "pt-BR" -> "pt", "en" -> "en"
lang_base_code = function(code) {
    var c = string_lower(code)
    var sep = string_pos("_", c)
    if (sep == 0)
        sep = string_pos("-", c)
    if (sep > 0)
        c = string_copy(c, 1, sep - 1)
    return c
}

// Idioma que pide el sistema, normalizado a dos letras.
// En Switch `os_get_language` no es de fiar (el juego base tampoco la usa
// ahí, ver `scr_84_init_localization`): se pregunta a
// `switch_language_get_desired_language`, que devuelve códigos con región
// ("en-US", "es-419") y por eso también pasa por `lang_base_code`.
detect_os_lang = function() {
    var raw = ""
    if (scr_is_switch_os())
        raw = switch_language_get_desired_language()
    else
        raw = os_get_language()

    if (!is_string(raw) || raw == "")
        return ""

    return lang_base_code(raw)
}

var os_lang = detect_os_lang()
var picked = ""

if (saved_lang != "" && variable_struct_exists(global.all_lang_settings, saved_lang))
    picked = saved_lang

if (picked == "" && os_lang != "" && variable_struct_exists(global.all_lang_settings, os_lang))
    picked = os_lang

if (picked == "" && os_lang != "") {
    for (var i = 0; i < array_length(global.languages_list); i++) {
        if (lang_base_code(global.languages_list[i]) == os_lang) {
            picked = global.languages_list[i]
            break
        }
    }
}

if (picked == "" && array_length(global.languages_list) > 0)
    picked = global.languages_list[0]

if (picked == "")
    picked = "en"

global.lang = picked

// Cargar el settings.json del idioma activo. Si el pack no declara
// `lang_code` explícitamente, conservamos el `global.lang` que ya
// eligió el escaneo (normalmente el nombre de la subcarpeta).
//
// Los idiomas nativos no tienen carpeta ni settings.json: su struct lo
// fabricó `scan_languages()`, así que se toma de ahí (si no, el nombre del
// menú se perdería y saldría "English" para el japonés).
if (is_native_lang()) {
    global.lang_settings = variable_struct_get(global.all_lang_settings, global.lang)
} else if (scr_file_exists(get_lang_folder_path() + "settings.json")) {
    var settings = scr_load_json(get_lang_folder_path() + "settings.json")
    var lang_code = variable_struct_get(settings, "lang_code")
    if (is_undefined(lang_code))
        lang_code = global.lang
    global.lang = lang_code
    global.lang_settings = settings
    variable_struct_set(global.all_lang_settings, lang_code, settings)
} else {
    global.lang_settings = json_parse("{\"name\": \"English\"}")
}

// Modo especial y voces dobladas: se recuerdan POR IDIOMA
// (`special_mode_<lang>` / `translated_songs_<lang>`), así que solo se
// pueden leer aquí, ya fijado `global.lang`. Las claves globales del
// upstream (`special_mode` / `translated_songs`) se usan como fallback
// para migrar la preferencia que el jugador ya tuviera; a partir de ahí
// solo se escriben las claves por idioma.
// Ojo con los defaults: el modo especial arranca apagado (0) y las voces
// dobladas encendidas (1), igual que en el upstream.
//
// En consola se salta: el ini todavía no está disponible (ver arriba) y de
// esto se encarga `scr_console_read_lang_config` desde el Step.
if (!global.is_console)
{
    ossafe_ini_open("true_config.ini");
    global.special_mode = ini_read_real("LANG", "special_mode_" + global.lang, ini_read_real("LANG", "special_mode", 0));
    global.translated_songs = ini_read_real("LANG", "translated_songs_" + global.lang, ini_read_real("LANG", "translated_songs", 1));
    ossafe_ini_close();
}

// ----- Modo traductor (dev) -----
// Se conserva el soporte completo del upstream: mapas de strings usadas,
// diffs y registro de traducciones nuevas para el flujo de traducción.
//
// Va en una función y no inline (a diferencia del upstream) porque el modo
// se puede encender DESPUÉS del arranque: la U de obj_gamecontroller_Step_0
// relee `translator_mode` de `global.lang_settings`, que
// `scr_switch_game_language` ya pudo haber cambiado por el de otro pack. Si
// el idioma de arranque no traía el modo y el nuevo sí, el flag se encendía
// sin que estos mapas existieran y el primer `ds_map_set` de
// `scr_get_lang_string` reventaba. Ahora quien enciende el modo reserva
// también su estado.
//
// Es método de la instancia (no un gml_GlobalScript_) a propósito:
// `new_translations_filename` es variable de instancia y `add_new_translation`
// la lee de aquí. Un script global llamado desde `scr_switch_game_language`
// (donde `self` es obj_lang_settings) la crearía en la instancia equivocada.
init_translator_data = function()
{
    if (variable_global_exists("lang_to_orig"))
        exit;

    global.used_strings = ds_map_create();
    global.changed_strings = ds_map_create();
    global.lang_to_orig = ds_map_create();
    global.orig_to_lang = ds_map_create();
    global.used_room_strings = ds_map_create();

    new_translations_filename = "new_translations_ch" + string(global.chapter) + ".json";

    if (scr_file_exists(new_translations_filename)) {
        global.new_translations = scr_84_load_map_json(new_translations_filename);
    }
    else {
        global.new_translations = ds_map_create();
    }
};

if (get_lang_setting("translator_mode", 0))
    init_translator_data();

add_new_translation = function(arg0, arg1)
{
    ds_map_set(global.orig_to_lang, ds_map_find_value(global.lang_to_orig, arg0), arg1);
    ds_map_set(global.lang_to_orig, arg1, ds_map_find_value(global.lang_to_orig, arg0));
    var size = ds_map_size(global.used_room_strings);
    var key = ds_map_find_first(global.used_room_strings);

    for (var i = 0; i < size; i++)
    {
        if (ds_map_find_value(global.used_room_strings, key) == arg0)
        {
            ds_map_set(global.changed_strings, arg0, arg1);
            ds_map_set(global.new_translations, key, arg1);
            ds_map_set(global.lang_map, key, arg1);

            var new_translations_file = file_text_open_write(new_translations_filename);
            file_text_write_string(new_translations_file, json_encode(global.new_translations));
            file_text_close(new_translations_file);

            break;
        }

        key = ds_map_find_next(global.used_room_strings, key);
    }
};

// Globales para el sistema de cambio de idioma en caliente con
// sprites diferidos. Inicializadas aquí (no en otro lado) para que
// estén listas antes del primer scr_init_localization, y para que
// los chequeos defensivos en scr_84_get_sprite no fallen.
global.outdated_sprites = [];
global.lang_sprites_pending = false;
// Mismo mecanismo diferido para sonidos: los streams del idioma viejo
// se preservan en `outdated_sounds` y se borran tras cambiar de sala
// (con guard de audio_is_playing). `lang_sounds_loader` lo registra
// cada capitulo con su propio bloque de carga de sonidos.
global.outdated_sounds = [];
global.lang_sounds_pending = false;
last_room_for_lang = room;

file_find_close();
scr_init_localization();
update_on_room_end = false;

if (scr_file_exists(working_directory + "lang/lang_en.json")) {
    orig_filename = working_directory + "lang/lang_en.json"
    global.orig_map = scr_84_load_map_json(orig_filename)
}
