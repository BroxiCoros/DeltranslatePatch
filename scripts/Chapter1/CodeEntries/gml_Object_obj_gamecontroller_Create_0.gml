if (instance_number(obj_gamecontroller) > 1)
{
    instance_destroy();
    exit;
}

// En los capítulos el ejecutable vive en `chapterN_windows/`, por eso
// `../lang/` apunta a la carpeta de idiomas compartida del juego.
global.lang_folder = working_directory + "../lang/"

global.orig_en = false

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

global.is_console = scr_is_switch_os() || os_type == os_ps4 || os_type == os_ps5;
var launch_data = scr_init_launch_parameters();
global.launcher = launch_data.is_launcher;

// ---------------------------------------------------------------
// Configuración persistida (true_config.ini)
// ---------------------------------------------------------------
// `special_mode_index` lo carga `scr_load_special_modes` más abajo,
// una vez que ya sabemos el idioma activo (porque el índice es por
// idioma). Solo leemos aquí lo que no depende del pack.
ossafe_ini_open("true_config.ini")
global.translator_mode = 0
speed_mode = 0
global.translated_songs = ini_read_real("LANG", "translated_songs", 1)
var saved_lang = ini_read_string("LANG", "LANG_DT", "")
ossafe_ini_close()

// Inicializar globales de modos especiales para que cualquier función
// que las consulte antes de `scr_load_special_modes()` no truene.
global.special_mode_index = 0
global.special_mode = false
global.active_sp_prefix = ""
global.special_modes = []

global.lang_sprites = ds_map_create()
global.lang_sounds = ds_map_create()
global.lang_fonts = ds_map_create()
global.lang_settings = {}

global.used_strings = ds_map_create()
global.changed_strings = ds_map_create()
global.lang_to_orig = ds_map_create()
global.orig_to_lang = ds_map_create()

global.languages_list = []
global.all_lang_settings = {}
global.is_single_lang_mode = false
global.lang = "en"

// ---------------------------------------------------------------
// Escaneo de idiomas disponibles en `lang/`
// ---------------------------------------------------------------
// Misma lógica que el Menu:
// - Si `lang/settings.json` existe directamente, es un pack heredado
//   de un solo idioma: respetamos esa estructura.
// - Si no, iteramos subcarpetas y leemos `lang/<code>/settings.json`
//   de cada pack válido.

scan_languages = function() {
    global.languages_list = []
    global.all_lang_settings = {}
    global.is_single_lang_mode = false

    var s = undefined
    var code = ""

    if (file_exists(global.lang_folder + "settings.json")) {
        global.is_single_lang_mode = true
        s = scr_load_json(global.lang_folder + "settings.json")
        code = get_struct_field(s, "lang_code", "en")
        array_push(global.languages_list, code)
        variable_struct_set(global.all_lang_settings, code, s)
    } else if (directory_exists(global.lang_folder)) {
        var entry = file_find_first(global.lang_folder + "*", fa_directory)
        while (entry != "") {
            if (entry != "." && entry != ".." && directory_exists(global.lang_folder + entry)) {
                var setting_path = global.lang_folder + entry + "/settings.json"
                if (file_exists(setting_path)) {
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
}

scan_languages()

// ---------------------------------------------------------------
// Elegir el idioma inicial
// ---------------------------------------------------------------
// Prioridad:
//   1) El que el jugador eligió la última vez (persistido en INI).
//   2) El primero encontrado al escanear (orden del file system).
//   3) "en" como fallback si no hay pack alguno.
if (saved_lang != "" && variable_struct_exists(global.all_lang_settings, saved_lang)) {
    global.lang = saved_lang
} else if (array_length(global.languages_list) > 0) {
    global.lang = global.languages_list[0]
} else {
    global.lang = "en"
}

// Cargar el settings.json del idioma activo. Si el pack no declara
// `lang_code` explícitamente, conservamos el `global.lang` que ya
// eligió el escaneo (normalmente el nombre de la subcarpeta).
if (file_exists(get_lang_folder_path() + "settings.json")) {
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

// Los modos especiales vienen del pack de idioma activo, así que solo
// podemos leerlos DESPUÉS de fijar `global.lang` y `global.lang_settings`.
scr_load_special_modes()

// Globales para el sistema de cambio de idioma en caliente con
// sprites diferidos. Inicializadas aquí (no en otro lado) para que
// estén listas antes del primer scr_init_localization, y para que
// los chequeos defensivos en scr_84_get_sprite no fallen.
global.outdated_sprites = []
global.lang_sprites_pending = false
last_room_for_lang = room

file_find_close()
scr_init_localization()

update_on_room_end = false

// Mapa "original" (inglés) que alimenta el modo traductor (`orig_en`).
// Se mantiene tal cual estaba en el mod original: el path es relativo
// al `working_directory` del capítulo (no a `../lang/`), coincidiendo
// con el fallback que ya usa `scr_lang_load` internamente.
if (file_exists(working_directory + "lang/lang_en.json")) {
    orig_filename = working_directory + "lang/lang_en.json"
    global.orig_map = scr_84_load_map_json(orig_filename)
}
