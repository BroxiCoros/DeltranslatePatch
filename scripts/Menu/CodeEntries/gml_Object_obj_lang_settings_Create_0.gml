instance_deactivate_all(true)
instance_activate_object(obj_input)
instance_activate_object(obj_gamecontroller)
instance_activate_object(obj_init_pc)
instance_activate_object(obj_init_console)

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

// En idioma nativo no hay pack, así que `stringsetloc` devuelve su literal:
// el inglés. Este objeto está en la lista negra (es de donde se cambia de
// idioma, no puede correr un gemelo vanilla), así que le toca traerse los dos
// idiomas del juego encima, igual que el "Quit" del pie.
//
// Estas etiquetas son del fork y no existen en vanilla, o sea que no hay
// original japonés que copiar: van escritas a mano. Las únicas sacadas del
// juego son はい / いいえ, que salen tal cual en `obj_CHAPTER_SELECT_Create_0`.
native_text = function(en_str, ja_str) {
    return (global.lang == "en") ? en_str : ja_str
}

update_strings = function() {
    var nat = is_native_lang()

    config_text = nat ? native_text("LANGUAGE CONFIG", "言語設定") : stringsetloc("LANGUAGE CONFIG", "obj_lang_settings_1_0")
    return_text = nat ? native_text("Return", "戻る") : stringsetloc("Return", "obj_lang_settings_2_0")
    yes_text = nat ? native_text("Yes", "はい") : stringsetloc("Yes", "obj_lang_settings_3_0")
    no_text = nat ? native_text("No", "いいえ") : stringsetloc("No", "obj_lang_settings_4_0")
    lang_choice_text = (nat ? native_text("Language", "言語") : stringsetloc("Language", "obj_lang_settings_5_0")) + ": "
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
