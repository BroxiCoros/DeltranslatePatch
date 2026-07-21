instance_deactivate_all(true)
instance_activate_object(obj_input)
instance_activate_object(obj_gamecontroller)

// Defensiva: si la lista de idiomas no fue inicializada por
// obj_gamecontroller_Create_0, la dejamos vacía para que el menú no
// crashee. En caso normal este bloque no hace nada.
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
    spec_mode_desc_disabled = stringsetloc("Special Mode disabled\ndescription (leave space\nif no need)", "obj_lang_settings_8_0")
    spec_mode_desc_enabled = stringsetloc("Special Mode enabled\ndescription (leave space\nif no need)", "obj_lang_settings_9_0")
    version_text = stringsetloc("Current version - {0}; Latest available - {1}", "obj_lang_settings_10_0")

    options = ["language"]

    spec_mode_switch = false
    translated_songs_switch = false

    if (get_lang_setting("special_mode")) {
        array_push(options, "special_mode")
        spec_mode_switch = true
    }

    if (get_lang_setting("enable_translated_songs_switch")) {
        array_push(options, "enable_translated_songs_switch")
        translated_songs_switch = true
    }

    options_count = array_length(options)
}

// ¿Cuántos idiomas hay? Decide si la opción "Language" cicla con ←/→
// (más de uno) o solo abre el link (uno solo, compat).
get_lang_count = function() {
    return array_length(global.languages_list)
}

update_strings()
