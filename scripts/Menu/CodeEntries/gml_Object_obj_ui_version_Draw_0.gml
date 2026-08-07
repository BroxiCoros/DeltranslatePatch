draw_set_color(c_gray);
draw_set_alpha(_alpha);
draw_set_font(_font);

// En idioma nativo no hay pack, así que no hay versión de traducción que
// anunciar: se cae la tercera línea (que es de cosecha del mod) y las otras dos
// vuelven a las coordenadas de vanilla, y + 24 e y + 40. El mod las sube a
// y + 16 e y + 32 precisamente para hacerle sitio a la que ahora no está.
if (is_native_lang()) {
    if (_copyright_enabled)
        draw_text_transformed(x + 16, y + 24, _copyright_text, _scale, _scale, 0);

    draw_text_transformed(x + 16, y + 40, _version_text, _scale, _scale, 0);
} else {
    if (_copyright_enabled)
        draw_text_transformed(x + 16, y + 16, _copyright_text, _scale, _scale, 0);

    draw_text_transformed(x + 16, y + 32, _version_text, _scale, _scale, 0);
    draw_text_transformed(x + 16, y + 48,
        string(scr_get_lang_string("Translation version - {0}", "gml_Object_obj_ui_version_Draw_0_1"),
            obj_gamecontroller.version_to_string(obj_gamecontroller.cur_translation_version)
        ),
    _scale, _scale, 0);
}
draw_set_color(c_white);
draw_set_alpha(1);
