// Defensiva: si las globales de modos no fueron inicializadas por
// obj_gamecontroller_Create_0 (por ejemplo, si este patch quedó sin
// las modificaciones previas a obj_gamecontroller), las construimos
// aquí mismo para que el menú no crashee.
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

scale = 1
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
    tr_songs_text = stringsetloc("Translated Voices", "obj_lang_settings_7_0") + ": "
    spec_mode_desc_fallback_off = stringsetloc("", "obj_lang_settings_8_0")
    spec_mode_desc_fallback_on  = stringsetloc("", "obj_lang_settings_9_0")

    options = ["language"]

    spec_mode_switch = false
    translated_songs_switch = false

    // Mostrar la opción solo si hay al menos un modo real además del default.
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

// Texto del valor actual al lado de "Special Mode: ".
get_sp_mode_name = function() {
    if (array_length(global.special_modes) == 0)
        return no_text
    var m = global.special_modes[global.special_mode_index]
    var nm = get_struct_field(m, "name", "")
    if (nm == "")
        return (global.special_mode_index == 0) ? no_text : yes_text
    return nm
}

// Descripción del modo activo.
get_sp_mode_desc = function() {
    if (array_length(global.special_modes) == 0)
        return spec_mode_desc_fallback_off
    var m = global.special_modes[global.special_mode_index]
    var d = get_struct_field(m, "description", "")
    if (d != "")
        return d
    return (global.special_mode_index == 0) ? spec_mode_desc_fallback_off : spec_mode_desc_fallback_on
}

// ¿Cuántos idiomas hay?
get_lang_count = function() {
    return array_length(global.languages_list)
}


SUBTYPE = 0
CH = string(global.chapter)
if ossafe_file_exists("filech" + CH + "_3")
    SUBTYPE = 1
if ossafe_file_exists("filech" + CH + "_4")
    SUBTYPE = 1
if ossafe_file_exists("filech" + CH + "_5")
    SUBTYPE = 1
BGMADE = 0
BG_ALPHA = 0.5
BG_SINER = DEVICE_MENU.BG_SINER
OB_DEPTH = DEVICE_MENU.OB_DEPTH
obacktimer = DEVICE_MENU.obacktimer
OBM = DEVICE_MENU.OBM
COL_A = DEVICE_MENU.COL_A
COL_B = DEVICE_MENU.COL_B
COL_PLUS = DEVICE_MENU.COL_PLUS
BGSINER = DEVICE_MENU.BGSINER
BGMAGNITUDE = DEVICE_MENU.BGMAGNITUDE
COL_A = DEVICE_MENU.COL_A
COL_B = DEVICE_MENU.COL_B
COL_PLUS = DEVICE_MENU.COL_PLUS
BGMADE = 1
BG_ALPHA = DEVICE_MENU.BG_ALPHA
ANIM_SINER = DEVICE_MENU.ANIM_SINER
ANIM_SINER_B = DEVICE_MENU.ANIM_SINER_B
TRUE_ANIM_SINER = DEVICE_MENU.TRUE_ANIM_SINER
if (SUBTYPE == 0) {
    COL_A = DEVICE_MENU.COL_A
    COL_B = DEVICE_MENU.COL_B
    COL_PLUS = DEVICE_MENU.COL_PLUS
    BGMADE = 0
}

update_strings()

instance_deactivate_object(DEVICE_MENU)
