_copyright_enabled = false;
_copyright_text = scr_get_lang_string("(C) Toby Fox 2018-2026", "gml_Object_obj_ui_version_Create_0_0");
_version_text = scr_get_lang_string("DELTARUNE ", "gml_Object_obj_ui_version_Create_0_1") + get_version();
_scale = 1;
_alpha = 1;
// Vanilla fija `_font = 2` (fnt_main) y NO mira el idioma: el copyright y la
// versión se ven igual en inglés que en japonés. Este objeto no lleva gemelo
// (su vanilla no menciona `global.lang`, así que no califica para uno), o sea
// que la paridad hay que ponerla a mano. Con `scr_get_font("fnt_main")` a
// secas, desde que el mapa de fuentes apunta bien, en japonés nativo salía
// `fnt_main_ja`, que dibuja el latín distinto.
_font = is_native_lang() ? asset_get_index("fnt_main") : scr_get_font("fnt_main");

set_screen_state = function(arg0)
{
    if (arg0 == UnknownEnum.Value_4)
        _copyright_enabled = true;
};

set_alpha = function(arg0)
{
    _alpha = arg0;
};

enum UnknownEnum
{
    Value_4 = 4
}
