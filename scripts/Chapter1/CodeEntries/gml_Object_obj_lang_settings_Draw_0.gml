// Codigo adaptado de DEVICE_MENU (animaciones de fondo y BG_ALPHA fade)

if (BGMADE == 1)
{
    ANIM_SINER += 1
    ANIM_SINER_B += 1
    BG_SINER += 1
    if (BG_ALPHA < 0.5)
        BG_ALPHA += (0.04 - BG_ALPHA / 14)
    if (BG_ALPHA > 0.5)
        BG_ALPHA = 0.5
    __WAVEHEIGHT = 240
    __WAVEWIDTH = 320
    for (i = 0; i < (__WAVEHEIGHT - 50); i += 1)
    {
        __WAVEMINUS = BGMAGNITUDE * (i / __WAVEHEIGHT) * 1.3
        if (__WAVEMINUS > BGMAGNITUDE)
            __WAVEMAG = 0
        else
            __WAVEMAG = BGMAGNITUDE - __WAVEMINUS
        draw_background_part_ext(IMAGE_MENU, 0, i, __WAVEWIDTH, 1, ((sin(i / 8 + BG_SINER / 30)) * __WAVEMAG), (-10 + i - BG_ALPHA * 20), 1, 1, image_blend, (BG_ALPHA * 0.8))
        draw_background_part_ext(IMAGE_MENU, 0, i, __WAVEWIDTH, 1, ((-(sin(i / 8 + BG_SINER / 30))) * __WAVEMAG), (-10 + i - BG_ALPHA * 20), 1, 1, image_blend, (BG_ALPHA * 0.8))
    }
    T_SINER_ADD = (sin(ANIM_SINER_B / 10)) * 0.6 - 0.25
    if (T_SINER_ADD >= 0)
        TRUE_ANIM_SINER += T_SINER_ADD
    draw_sprite_ext(IMAGE_MENU_ANIMATION, (ANIM_SINER / 12), 0, (10 - BG_ALPHA * 20 + __WAVEHEIGHT - 70), 1, 1, 0, image_blend, (BG_ALPHA * 0.46))
    draw_sprite_ext(IMAGE_MENU_ANIMATION, (ANIM_SINER / 12 + 0.4), 0, (10 - BG_ALPHA * 20 + __WAVEHEIGHT - 70), 1, 1, 0, image_blend, (BG_ALPHA * 0.56))
    draw_sprite_ext(IMAGE_MENU_ANIMATION, (ANIM_SINER / 12 + 0.8), 0, (10 - BG_ALPHA * 20 + __WAVEHEIGHT - 70), 1, 1, 0, image_blend, (BG_ALPHA * 0.7))
}




draw_set_font(scr_84_get_font("main"))
draw_set_halign(fa_center)
draw_set_color(COL_A)
draw_text_shadow(xx_mid, 10 * scale, config_text, 2 * scale, 2 * scale, 0)
draw_set_halign(fa_left)

for (var i = 0; i < options_count; i++) {
    draw_set_color((option == i ? COL_B : COL_A))

    if (options[i] == "language") {
        draw_text_shadow(xx_options, yy_options + yyoff_options * i, lang_choice_text, scale, scale, 0)
        var xx_off = string_width(lang_choice_text) * scale

        var lang_has_multi = (get_lang_count() > 1)
        var lang_name_str = get_lang_setting("name")
        var lang_display = lang_has_multi ? ("< " + lang_name_str + " >") : lang_name_str

        if (option == i) {
            var link = get_lang_setting("link", "")
            if (link != "")
                draw_rectangle_color(xx_options + xx_off, yy_options + 14 * scale, xx_options + xx_off + string_width(lang_display) * scale, yy_options + 14 * scale + 1, c_blue, c_blue, c_blue, c_blue, false)
        }

        draw_text_shadow(xx_options + xx_off, yy_options + yyoff_options * i, lang_display, scale, scale, 0)

        xx_off += string_width(lang_display) * scale

        if (option == i) {
            var lang_desc = get_lang_setting("description", "")
            draw_set_halign(fa_center)
            draw_set_color(TYPE ? c_aqua : c_gray)
            draw_text_shadow(xx_mid, yy_options + yyoff_options * options_count, lang_desc, scale, scale, 0)
            draw_set_color(COL_A)
            draw_set_halign(fa_left)
        }
    } else

    if (options[i] == "special_mode") {
        draw_text_shadow(xx_options, yy_options + yyoff_options * i, spec_mode_text, scale, scale, 0)

        // "< nombre >" si hay >1 entrada en special_modes (default + ≥1).
        var sp_value = get_sp_mode_name()
        var sp_display = (array_length(global.special_modes) > 1) ? ("< " + sp_value + " >") : sp_value
        draw_text_shadow(xx_options + string_width(spec_mode_text) * scale, yy_options + yyoff_options * i, sp_display, scale, scale, 0)

        if (option == i) {
            draw_set_halign(fa_center)
            draw_set_color(TYPE ? c_aqua : c_gray)
            draw_text_shadow(xx_mid, yy_options + yyoff_options * options_count, get_sp_mode_desc(), scale, scale, 0)
            draw_set_halign(fa_left)
        }
    } else

    if (options[i] == "enable_translated_songs_switch") {
        draw_text_shadow(xx_options, yy_options + yyoff_options * i, tr_songs_text, scale, scale, 0)
        draw_text_shadow(xx_options + string_width(tr_songs_text) * scale, yy_options + yyoff_options * i, (global.translated_songs ? yes_text : no_text), scale, scale, 0)
    }
}

draw_set_halign(fa_center)
draw_set_color((option == options_count ? COL_B : COL_A))
draw_text_shadow(xx_mid, yy_return, return_text, scale, scale, 0)
draw_set_halign(fa_left)

if (option < options_count) {
    draw_sprite_ext(spr_heartsmall, 0, xx_options - xxoff_heart, (yy_options + 4 * scale + option * yyoff_options), scale, scale, 0, COL_A, 1)
} else {
    draw_sprite_ext(spr_heartsmall, 0, (xx_mid - string_width(return_text) / 2) - xxoff_heart, yy_return + 4 * scale, scale, scale, 0, COL_A, 1)
}
