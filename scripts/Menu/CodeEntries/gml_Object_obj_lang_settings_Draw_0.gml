draw_set_font(scr_get_font("fnt_main"))
draw_set_halign(fa_center)
draw_set_color(c_white)
draw_text_transformed(xx_mid, 10 * scale, config_text, 2 * scale, 2 * scale, 0)
draw_set_halign(fa_left)

for (var i = 0; i < options_count; i++) {
    draw_set_color((option == i ? c_yellow : c_white))

    if (options[i] == "language") {
        draw_text_transformed(xx_options, yy_options + yyoff_options * i, lang_choice_text, scale, scale, 0)
        var xx_off = string_width(lang_choice_text) * scale

        // Si hay varios idiomas, envolvemos el nombre con "< >" para
        // dar pista visual de que se puede ciclar con ←/→. Si no, el
        // nombre va tal cual (como en el mod original).
        var lang_has_multi = (get_lang_count() > 1)
        var lang_name_str = get_lang_setting("name")
        var lang_display = lang_has_multi ? ("< " + lang_name_str + " >") : lang_name_str

        if (option == i) {
            var link = get_lang_setting("link", "")
            if (link != "")
                draw_rectangle_color(xx_options + xx_off, yy_options + 14 * scale, xx_options + xx_off + string_width(lang_display) * scale, yy_options + 14 * scale + 1, c_blue, c_blue, c_blue, c_blue, false)
        }

        draw_text_transformed(xx_options + xx_off, yy_options + yyoff_options * i, lang_display, scale, scale, 0)

        xx_off += string_width(lang_display) * scale

        draw_text_transformed(xx_options, yy_options + yyoff_options * i + yyoff_options / 3 * 2,
            string(version_text,
                obj_gamecontroller.version_to_string(obj_gamecontroller.cur_translation_version),
                obj_gamecontroller.version_to_string(obj_gamecontroller.last_translation_version),
            )
        , scale * 0.5, scale * 0.5, 0)

        if (option == i) {
            var lang_desc = get_lang_setting("description", "")
            draw_set_halign(fa_center)
            draw_set_color(c_gray)
            draw_text_transformed(xx_mid, yy_options + yyoff_options * options_count, lang_desc, scale, scale, 0)
            draw_set_color(c_white)
            draw_set_halign(fa_left)
        }
    } else

    if (options[i] == "special_mode") {
        draw_text_transformed(xx_options, yy_options + yyoff_options * i, spec_mode_text, scale, scale, 0)

        // Texto del valor actual. "< nombre >" cuando hay más de un modo
        // real (default + ≥1). Cuando solo hay 2 entradas (formato
        // heredado: default + "sp") también, porque sigue habiendo ciclo.
        var sp_value = get_sp_mode_name()
        var sp_display = (array_length(global.special_modes) > 1) ? ("< " + sp_value + " >") : sp_value
        draw_text_transformed(xx_options + string_width(spec_mode_text) * scale, yy_options + yyoff_options * i, sp_display, scale, scale, 0)

        if (option == i) {
            draw_set_halign(fa_center)
            draw_set_color(c_gray)
            draw_text_transformed(xx_mid, yy_options + yyoff_options * options_count, get_sp_mode_desc(), scale, scale, 0)
            draw_set_halign(fa_left)
        }
    } else

    if (options[i] == "enable_translated_songs_switch") {
        draw_text_transformed(xx_options, yy_options + yyoff_options * i, tr_songs_text, scale, scale, 0)
        draw_text_transformed(xx_options + string_width(tr_songs_text) * scale, yy_options + yyoff_options * i, (global.translated_songs ? yes_text : no_text), scale, scale, 0)
    }
}

draw_set_halign(fa_center)
draw_set_color((option == options_count ? c_yellow : c_white))
draw_text_transformed(xx_mid, yy_return, return_text, scale, scale, 0)
draw_set_halign(fa_left)

if (option < options_count) {
    draw_sprite_ext(spr_heart, 0, xx_options - xxoff_heart, (yy_options + 4 * scale + option * yyoff_options), scale, scale, 0, c_white, 1)
} else {
    draw_sprite_ext(spr_heart, 0, (room_width - string_width(return_text) * 2) / 2 - xxoff_heart, yy_return + 4 * scale, scale, scale, 0, c_white, 1)
}
