instance_deactivate_all(true)
instance_activate_object(obj_input)
instance_activate_object(obj_gamecontroller)

// Defensiva: si las globales de modos no fueron inicializadas por
// obj_gamecontroller_Create_0 (por ejemplo, si este patch quedó sin
// las modificaciones previas a obj_gamecontroller), las construimos
// aquí mismo para que el menú no crashee. En caso normal este bloque
// no hace nada porque ya están listas.
if (!variable_global_exists("special_modes")) {
    if (variable_global_exists("lang_settings") && variable_global_exists("lang"))
        scr_load_special_modes()
    else
        global.special_modes = []
}
if (!variable_global_exists("special_mode_index"))
    global.special_mode_index = 0
if (!variable_global_exists("active_sp_prefix"))
    global.active_sp_prefix = ""
if (!variable_global_exists("special_mode"))
    global.special_mode = false
if (!variable_global_exists("languages_list"))
    global.languages_list = []

option = 0

scale = 2
xx_options = 25 * scale
xxoff_heart = 15 * scale
yy_options = 50 * scale
yyoff_options = 25 * scale
xx_mid = 160 * scale

yy_return = (205 + 12) * scale

update_strings = function() {
    config_text = stringsetloc("LANGUAGE CONFIG", "obj_lang_settings_1_0")
    return_text = stringsetloc("Return", "obj_lang_settings_2_0")
    yes_text = stringsetloc("Yes", "obj_lang_settings_3_0")
    no_text = stringsetloc("No", "obj_lang_settings_4_0")
    lang_choice_text = stringsetloc("Language", "obj_lang_settings_5_0") + ": "
    spec_mode_text = stringsetloc("Special Mode", "obj_lang_settings_6_0") + ": "
    tr_songs_text = stringsetloc("Translated Songs", "obj_lang_settings_7_0") + ": "
    // Fallback genérico (solo se usa cuando un pack en formato heredado
    // `special_mode: true` no provee descripciones). Las strings _8 y _9
    // están deprecadas: en el formato nuevo, cada modo lleva su propia
    // `description` en settings.json.
    spec_mode_desc_fallback_off = stringsetloc("", "obj_lang_settings_8_0")
    spec_mode_desc_fallback_on  = stringsetloc("", "obj_lang_settings_9_0")
    version_text = stringsetloc("Current version - {0}; Latest available - {1}", "obj_lang_settings_10_0")

    options = ["language"]

    spec_mode_switch = false
    translated_songs_switch = false

    // La opción "Special Mode" se muestra cuando hay al menos un modo real
    // además del default. En el nuevo formato eso significa array_length > 1
    // (default + N modos). En el formato heredado `special_mode: true` el
    // sintetizador deja exactamente 2 entradas (default + "sp"), así que
    // también se cumple.
    if (array_length(global.special_modes) > 1) {
        array_push(options, "special_mode")
        spec_mode_switch = true
    }

    if (get_lang_setting("enable_translated_songs_switch")) {
        array_push(options, "enable_translated_songs_switch")
        translated_songs_switch = true
    }

    options_count = array_length(options)
}

// Devuelve el texto a mostrar al lado de "Special Mode: ".
// Lee el `name` del struct correspondiente al índice activo. Si está vacío
// (pack en formato heredado) cae al "Yes"/"No" localizado del menú.
get_sp_mode_name = function() {
    if (array_length(global.special_modes) == 0)
        return no_text
    var m = global.special_modes[global.special_mode_index]
    var nm = get_struct_field(m, "name", "")
    if (nm == "")
        return (global.special_mode_index == 0) ? no_text : yes_text
    return nm
}

// Devuelve la descripción del modo activo. Cae a las strings localizadas
// genéricas solo cuando el pack está en formato heredado.
get_sp_mode_desc = function() {
    if (array_length(global.special_modes) == 0)
        return spec_mode_desc_fallback_off
    var m = global.special_modes[global.special_mode_index]
    var d = get_struct_field(m, "description", "")
    if (d != "")
        return d
    return (global.special_mode_index == 0) ? spec_mode_desc_fallback_off : spec_mode_desc_fallback_on
}

// ¿Cuántos idiomas hay? Decide si la opción "Language" cicla con ←/→
// (más de uno) o solo abre el link (uno solo, compat).
get_lang_count = function() {
    return array_length(global.languages_list)
}

update_strings()
