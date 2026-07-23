dtv = 502

if (instance_number(obj_gamecontroller) > 1)
{
    instance_destroy();
    exit;
}

if (os_type == os_android)
    global.savepath = init_external_dir();
else
    global.savepath = game_save_id;

is_connecting_controller = 3;
gamepad_active = 0;
gamepad_id = 0;
gamepad_shoulderlb_reassign = 0;
gamepad_type = "";

global.is_console = scr_is_switch_os() || os_type == os_ps4 || os_type == os_ps5;

global.lang_folder = working_directory + "lang/"
if (os_type == os_android) {
    global.lang_folder = global.savepath + "lang/"
}
// En Android, el pack de idiomas vive comprimido como `lang.zip`.
// Ojo: chequear con `directory_exists(global.lang_folder)` en vez de
// `get_lang_folder_path()` porque esta última ahora depende de
// `global.lang`, que aún no está inicializado.
if (os_type == os_android && !directory_exists(global.lang_folder)) {
    zip_unzip(global.savepath + "lang.zip", global.savepath);
}

if (!variable_global_exists("gamepad_type"))
    global.gamepad_type = "N/A";

if (variable_global_exists("lang_map"))
    return;

// ---------------------------------------------------------------
// Configuración persistida (true_config.ini)
// ---------------------------------------------------------------
// `saved_lang` es lo único añadido aquí: el idioma que el jugador
// eligió la última vez, para el escaneo multi-idioma de más abajo.
// `special_mode` y `translated_songs` NO se leen aquí (a diferencia del
// upstream): se recuerdan por idioma, así que hace falta saber cuál está
// activo. Ver más abajo.
ossafe_ini_open("true_config.ini")
var saved_lang = ini_read_string("LANG", "LANG_DT", "")
ossafe_ini_close()

global.lang_sprites = ds_map_create()
global.lang_sounds = ds_map_create()
global.font_map = ds_map_create()
global.langs_names = []
global.lang_settings = {}
global.languages_list = []
global.all_lang_settings = {}
global.is_single_lang_mode = false
global.lang = "en"
lang_changes_call = -1
lang_changes = {}
cur_translation_version = [0, 0, 0]
last_translation_version = [0, 0, 0]
translation_version_changes_files = []
translation_version_changes_datas = []
datas_loading = {}
translation_version_description = ""
translation_external_update = false

is_valid_version = function(str) {
    if (is_undefined(str))
        str = "";

    var major_pos = string_pos_ext(".", str, 1)
    var minor_pos = string_pos_ext(".", str, major_pos + 1)

    return major_pos != 0 && minor_pos != 0
}

string_to_version = function(str) {
    if (is_undefined(str))
        str = "0.0.0";

    try {
        var ver = [0, 0, 0]

        var major_pos = string_pos_ext(".", str, 1)
        var minor_pos = string_pos_ext(".", str, major_pos + 1)

        ver[0] = real(string_copy(str,             1,                      major_pos));
        ver[1] = real(string_copy(str, major_pos + 1,          minor_pos - major_pos));
        ver[2] = real(string_copy(str, minor_pos + 1, string_length(str) - minor_pos));
    } catch (err) {
        return [-1, -1, -1]
    }

    return ver
}

version_to_string = function(ver) {
    if (is_undefined(ver))
        ver = [0, 0, 0];

    return string(ver[0]) + "." + string(ver[1]) + "." + string(ver[2]);
}

is_version_greater = function(ver1, ver2) {
    if (is_undefined(ver1))
        ver1 = [0, 0, 0];
    if (is_undefined(ver2))
        ver2 = [0, 0, 0];

    return ver1[0] > ver2[0] ||
    (ver1[0] == ver2[0] && ver1[1] > ver2[1]) ||
    (ver1[0] == ver2[0] && ver1[1] == ver2[1] && ver1[2] > ver2[2])
}

// ---------------------------------------------------------------
// Escaneo de idiomas disponibles en `lang/`
// ---------------------------------------------------------------
// - Primero iteramos subcarpetas buscando `lang/<code>/settings.json` de
//   cada paquete válido. Si hay al menos uno, gana el modo multi-idioma y
//   se IGNORA cualquier `lang/settings.json` suelto en la raíz.
// - Solo si no hay ninguna subcarpeta válida caemos al pack heredado de un
//   único idioma suelto en la raíz.
//
// Tras correr, `global.all_lang_settings` queda mapeado por lang_code
// y `global.languages_list` contiene todos los códigos encontrados.

scan_languages = function() {
    global.languages_list = []
    global.all_lang_settings = {}
    global.is_single_lang_mode = false

    var s = undefined
    var code = ""

    if (directory_exists(global.lang_folder)) {
        // Modo multi-idioma: iteramos subcarpetas buscando cada settings.json.
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

    // Fallback al pack heredado: un único idioma suelto en la raíz, solo si
    // el barrido de subcarpetas no encontró ningún idioma válido.
    if (array_length(global.languages_list) == 0 && file_exists(global.lang_folder + "settings.json")) {
        global.is_single_lang_mode = true
        s = scr_load_json(global.lang_folder + "settings.json")
        code = get_struct_field(s, "lang_code", "en")
        array_push(global.languages_list, code)
        variable_struct_set(global.all_lang_settings, code, s)
    }
}

scan_languages()

// ---------------------------------------------------------------
// Elegir el idioma inicial
// ---------------------------------------------------------------
// Prioridad:
//   1) El que estaba guardado en config.ini, si sigue siendo válido.
//   2) El primero que encontramos al escanear (el orden es el del FS).
//   3) "en" como último recurso (sin pack).
if (saved_lang != "" && variable_struct_exists(global.all_lang_settings, saved_lang)) {
    global.lang = saved_lang
} else if (array_length(global.languages_list) > 0) {
    global.lang = global.languages_list[0]
} else {
    global.lang = "en"
}

update_lang_version = function() {
    var version = string_to_version("0.0.0")
    var changes_file = get_lang_folder_path() + "changes.json"
    if (file_exists(changes_file)) {
        var changes = scr_load_json(changes_file)
        var versions = variable_struct_get_names(changes)

        for (var i = 0; i < array_length(versions); i++) {
            var ver = string_to_version(versions[i])

            if (is_version_greater(ver, version)) {
                version = ver;
            }
        }
    }

    cur_translation_version = version;
    last_translation_version = version;
}

update_language = function() {
    if (file_exists(get_lang_folder_path() + "settings.json")) {
        var settings = scr_load_json(get_lang_folder_path() + "settings.json")

        var lang_code = variable_struct_get(settings, "lang_code")
        // Si el `settings.json` del pack no declara `lang_code`, usamos
        // el `global.lang` que ya eligió `scan_languages` (que a su vez
        // usa el nombre de la subcarpeta como fallback). Antes esto
        // hardcodeaba "en", lo que reseteaba el idioma a inglés en
        // packs sin lang_code.
        if (is_undefined(lang_code))
            lang_code = global.lang

        global.lang = lang_code
        global.lang_settings = settings

        // Mantenemos la caché `all_lang_settings` sincronizada por si
        // el settings en disco cambió desde el último escaneo (p.ej.
        // tras una actualización automática del pack).
        variable_struct_set(global.all_lang_settings, lang_code, settings)

        update_lang_version()
    } else {
        global.lang_settings = json_parse("{\"name\": \"English\"}");
    }
}

update_language()

// Modo especial y voces dobladas: se recuerdan POR IDIOMA
// (`special_mode_<lang>` / `translated_songs_<lang>`), así que solo se
// pueden leer aquí, ya fijado `global.lang`. Las claves globales del
// upstream (`special_mode` / `translated_songs`) se usan como fallback
// para migrar la preferencia que el jugador ya tuviera; a partir de ahí
// solo se escriben las claves por idioma.
// Ojo con los defaults: el modo especial arranca apagado (0) y las voces
// dobladas encendidas (1), igual que en el upstream.
ossafe_ini_open("true_config.ini")
global.special_mode = ini_read_real("LANG", "special_mode_" + global.lang, ini_read_real("LANG", "special_mode", 0))
global.translated_songs = ini_read_real("LANG", "translated_songs_" + global.lang, ini_read_real("LANG", "translated_songs", 1))
ossafe_ini_close()

// `files_url` (no `var`) es intencional: es una variable de instancia
// que `load_datas` consulta más abajo como fallback de `datas_url`.
files_url = get_lang_setting("files_url", "")

scr_init_localization()

_alpha = 0;
loading_new_translation_files = false

if (os_type != os_windows) {
    exit;
}

if (files_url != "") {
    lang_changes_call = http_get(files_url + "changes.json")
}

desc_folded = true;
panel_visible = true;

files_in_upload = {}
datas_in_upload = {}
loaded_files = []
loaded_datas = []
loading_error = ""

load_files = function() {
    files_in_upload = {}
    loaded_files = []
    loading_error = ""

    var files = translation_version_changes_files;
    for (var i = 0; i < array_length(files); i++) {
        var file = string_replace_all(files[i], "..", "")
        variable_struct_set(files_in_upload, file, http_get_file(get_lang_setting("files_url", "") + files[i], "\\\\?\\" + program_directory + "tmp/" + file));
    }
    if (!variable_struct_exists(files_in_upload, "settings.json")) {
        variable_struct_set(files_in_upload, "settings.json", http_get_file(get_lang_setting("files_url", "") + "settings.json", "\\\\?\\" + program_directory + "tmp/settings.json"));
    }
    if (!variable_struct_exists(files_in_upload, "changes.json")) {
        variable_struct_set(files_in_upload, "changes.json", http_get_file(get_lang_setting("files_url", "") + "changes.json", "\\\\?\\" + program_directory + "tmp/changes.json"));
    }
}

load_datas = function() {
    datas_in_upload = {}
    loaded_datas = []
    loading_error = ""

    var datas = translation_version_changes_datas;
    var datas_url = get_lang_setting("datas_url", files_url)
    if (is_array(datas_url)) {
        datas_url = string_copy(datas_url[0], 1, string_last_pos("/", datas_url[0]))
    }
    for (var i = 0; i < array_length(datas); i++) {
        var file = datas_url + "data_ch" + string(datas[i]) + ".win"
        var path = ""
        if (datas[i] > 0) {
            path = "chapter" + string(datas[i])
        }
        variable_struct_set(datas_in_upload, datas[i], http_get_file(file, "\\\\?\\" + program_directory + "tmp/" + path + "/data.win"));
    }
}

copy_files_from_tmp = function() {
    // Destino: si el pack es de un solo idioma (estructura heredada),
    // los archivos van a `lang/`. Si es multi-idioma, van a la
    // subcarpeta del idioma activo (`lang/<lang_code>/`).
    var dest_lang_dir = global.is_single_lang_mode ? "lang/" : ("lang/" + global.lang + "/")

    for (var i = 0; i < array_length(loaded_files); i++) {
        var src = "\\\\?\\" + program_directory + "tmp/" + loaded_files[i]
        var dst = "\\\\?\\" + program_directory + dest_lang_dir + loaded_files[i]

        // file_copy NO crea subdirectorios. Si el archivo es por ejemplo
        // `chapter1/strings.json`, hay que asegurarse de que el directorio
        // padre existe en el destino. Esto es importante si el pack añade
        // archivos en subcarpetas nuevas en versiones futuras.
        var dst_dir = filename_dir(dst)
        if (!directory_exists(dst_dir))
            directory_create(dst_dir)

        file_copy(src, dst)
    }

    for (var i = 0; i < array_length(loaded_datas); i++) {
        var path_from = "data.win"
        var path_to = "data.win"
        if (loaded_datas[i] > 0) {
            path_from = "chapter" + string(loaded_datas[i]) + "/data.win"
            path_to = "chapter" + string(loaded_datas[i]) + "_windows/data.win"
        }
        file_copy(
            "\\\\?\\" + program_directory + "tmp/" + path_from,
            "\\\\?\\" + program_directory + path_to,
        )

    }

    update_language()

    loading_new_translation_files = false
    scr_init_localization()

    directory_destroy("\\\\?\\" + program_directory + "tmp")
}

clear_tmp = function() {
    directory_destroy("\\\\?\\" + program_directory + "tmp")
}
