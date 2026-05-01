// AUTOGENERADO por tools/regen_localization.csx desde scripts/Chapter4/manifest.json.
// NO editar a mano: cualquier cambio se sobrescribira en la proxima regeneracion.

function scr_init_localization()
{
    if (!variable_global_exists("lang_loaded"))
    {
        global.lang_loaded = "";
        global.loaded_sprites = [];
        global.loaded_sounds = [];
        global.loaded_fonts = [];
    }

    if (global.lang_loaded != global.lang)
    {
        var sprites_list = [
            "bg_alphysalley_ch4",
            "bg_building_cattyhouse",
            "bg_building_diner",
            "bg_building_flowershop",
            "bg_building_hospital",
            "bg_building_library",
            "bg_building_police",
            "bg_building_school",
            "bg_building_store",
            "bg_building_townhall_layer2",
            "bg_dw_bakery",
            "bg_dw_castle_cafe",
            "bg_dw_castle_music_shop_closed",
            "bg_hospital_room2_ch4",
            "bg_hospital_room2_ch4_berdly",
            "bg_hospital_room2_ch4_berdly_sideb",
            "bg_library",
            "bg_noellehouse_dess",
            "bg_noellehouse_dess_closet_door_slide",
            "bg_policebarricade",
            "bg_torielclass_ch2",
            "IMAGE_LOGO",
            "IMAGE_LOGO_CENTER",
            "IMAGE_LOGO_CENTER_CHAPTERNUMBER",
            "IMAGE_LOGO_CENTER_HEART",
            "IMAGE_LOGO_CENTER_HEART_SEPARATED",
            "IMAGE_LOGO_CENTER_SEPARATE",
            "IMAGE_LOGO_CENTER_SHATTER",
            "spr_battleblcon_guei",
            "spr_battleblcon_guei_small",
            "spr_battleblcon_z",
            "spr_battlemsg",
            "spr_battlemsg_f",
            "spr_battlemsg_m",
            "spr_battlemsg_n",
            "spr_bibliox_base",
            "spr_bibliox_head",
            "spr_bibliox_head_beard_stroke",
            "spr_bibliox_hurt",
            "spr_bibliox_intro",
            "spr_bibliox_spare",
            "spr_bibliox_talk",
            "spr_bibliox_talk_lookup",
            "spr_blockler_b_parade",
            "spr_bnamekris",
            "spr_bnameralsei",
            "spr_bnamesusie",
            "spr_btact",
            "spr_btdefend",
            "spr_btfight",
            "spr_btitem",
            "spr_btspare",
            "spr_bttech",
            "spr_castle_bakery_base",
            "spr_castle_cafe_base",
            "spr_castle_dojo_base",
            "spr_castle_dojo_sign_love",
            "spr_castle_shop_new",
            "spr_ch2_keyboard_tile_text",
            "spr_conbini_sign_clopen",
            "spr_conbini_sign_open",
            "spr_conbini_sign_sans",
            "spr_conbini_sign_sans_white",
            "spr_conbini_windows_open",
            "spr_darkmenudesc",
            "spr_dmenu_captions",
            "spr_dw_ads_small_ad",
            "spr_dw_ads_small_buy",
            "spr_dw_ads_small_buy_alt",
            "spr_dw_ads_small_deal",
            "spr_dw_ads_small_look",
            "spr_dw_castle_queen_room_traffic_light",
            "spr_dw_castle_tv",
            "spr_dw_castle_tv_closed",
            "spr_dw_castle_tv_door_mike",
            "spr_dw_churchb_npcstatue_bibliox",
            "spr_dw_churchb_npcstatue_bibliox_bake",
            "spr_dw_church_npc_bibliox_nu",
            "spr_dw_church_organ_icons",
            "spr_dw_church_organ_icons_white",
            "spr_dw_church_organ_icons_white_outline",
            "spr_dw_door_lancer",
            "spr_dw_door_tenna",
            "spr_dw_door_tenna_closed",
            "spr_dw_ranking_doors_narrow_mike_locked",
            "spr_dw_ranking_doors_narrow_mike_unlocked",
            "spr_face_queen",
            "spr_flowershop_sign",
            "spr_gameoverbg_neo",
            "spr_guei_letters",
            "spr_guei_letters_bigger",
            "spr_hpname",
            "spr_lw_conbini_closed_lights",
            "spr_mike_sign",
            "spr_police_station_closed",
            "spr_pressfront_b",
            "spr_quitmessage",
            "spr_recruited_by_oldman",
            "spr_rhythmgame_bg",
            "spr_rhythmgame_bg_spotlights",
            "spr_rhythm_transition",
            "spr_shop_space_ui",
            "spr_sign_closed",
            "spr_spare_z",
            "spr_tenna_armsup_annoyed",
            "spr_tenna_attack",
            "spr_tenna_blossom_animation",
            "spr_tenna_blossom_animation_singleframes",
            "spr_tenna_desperate",
            "spr_tenna_fall_start",
            "spr_tenna_frightened",
            "spr_tenna_grasp",
            "spr_tenna_grasp_anim",
            "spr_tenna_grasp_anim_b",
            "spr_tenna_grasp_b",
            "spr_tenna_grasp_c",
            "spr_tenna_grasp_chef",
            "spr_tenna_grasp_d",
            "spr_tenna_grasp_zoom",
            "spr_tenna_grasp_zoom_static",
            "spr_tenna_hooray",
            "spr_tenna_hooray_alt",
            "spr_tenna_hooray_armsup",
            "spr_tenna_hooray_armsup_teeth",
            "spr_tenna_hooray_chef",
            "spr_tenna_jumpscare",
            "spr_tenna_kick",
            "spr_tenna_laugh",
            "spr_tenna_laugh_pose",
            "spr_tenna_laugh_pose_alt",
            "spr_tenna_laugh_pose_segmented_body",
            "spr_tenna_laugh_pose_teeth",
            "spr_tenna_nose_blossom",
            "spr_tenna_nose_blossom_bloom",
            "spr_tenna_point_at_screen",
            "spr_tenna_point_at_screen_b",
            "spr_tenna_point_at_screen_c",
            "spr_tenna_point_droop",
            "spr_tenna_point_top",
            "spr_tenna_point_up",
            "spr_tenna_point_up_b",
            "spr_tenna_point_up_twofingers",
            "spr_tenna_pose",
            "spr_tenna_pose_headlowered",
            "spr_tenna_pose_headlowered_nose",
            "spr_tenna_pose_headraised",
            "spr_tenna_pose_headraised_nose",
            "spr_tenna_pose_headraised_zoom",
            "spr_tenna_pose_headraised_zoom_greenscreen",
            "spr_tenna_pose_podium",
            "spr_tenna_pose_podium_evil",
            "spr_tenna_sad",
            "spr_tenna_snap",
            "spr_tenna_snap_body",
            "spr_tenna_snap_body_f2",
            "spr_tenna_tie_adjust_a",
            "spr_tenna_tie_adjust_b",
            "spr_tenna_tie_adjust_c",
            "spr_tenna_twirl",
            "spr_tenna_whisper",
            "spr_tenna_whisper_blush",
            "spr_tenna_whisper_chef",
            "spr_tiredmark",
            "spr_tplogo",
            "spr_volume_logo",
            "spr_zapper_volume_text",
            "IMAGE_LOGO_CENTER_SHATTER_PIECES",
            "spr_npc_plugboy",
            "spr_tutu",
            "bg_building_icee_construction",
            "spr_dw_door_queen",
            "spr_castle_dojo_discoball",
            "spr_ghost_house_chimney",
            "spr_plueypoints"
        ];
        var fonts_list   = [
            ["fnt_main", 12],
            ["fnt_mainbig", 24],
            ["fnt_tinynoelle", 7],
            ["fnt_dotumche", 12],
            ["fnt_comicsans", 10],
            ["fnt_small", 6],
            ["fnt_8bit", 12],
            ["fnt_legend", 12],
            ["fnt_main_mono", 12],
            ["fnt_mainbig_mono", 24]
        ];
        global.lang_loaded = global.lang;

        if (variable_global_exists("lang_map"))
        {
            for (var i = 0; i < array_length(global.loaded_sprites); i++)
                sprite_delete(global.loaded_sprites[i]);
            for (var i = 0; i < array_length(global.loaded_fonts); i++)
                font_delete(global.loaded_fonts[i]);
            for (var i = 0; i < array_length(global.loaded_sounds); i++)
                audio_destroy_stream(global.loaded_sounds[i]);

            ds_map_destroy(global.lang_map);
            ds_map_destroy(global.font_map);
            ds_map_destroy(global.chemg_sprite_map);
            ds_map_destroy(global.chemg_sound_map);
            global.chapter_lang_settings = {};
            global.loaded_sprites = [];
            global.loaded_sounds = [];
            global.loaded_fonts = [];
        }

        global.chapter_lang_settings = scr_load_json(get_lang_folder_path() + "chapter4/chapter_settings.json");
        global.font_map = ds_map_create();
        global.lang_missing_map = ds_map_create();
        global.chemg_sprite_map = ds_map_create();
        global.chemg_sound_map = ds_map_create();
        font_add_enable_aa(false);

        // ----- Fuentes -----
        // Carga lazy: fnt_main es la unica fuente visible en los menus
        // previos a partida (DEVICE_MENU, obj_lang_settings). El resto se
        // difiere a global.font_pending_map y se rasteriza la primera vez
        // que alguien la pida (tipicamente despues del loading screen, ya
        // dentro de gameplay). Combinado con global.font_cache en add_font,
        // los cambios sucesivos al mismo idioma cuestan ~0ms.
        if (variable_global_exists("font_pending_map"))
            ds_map_destroy(global.font_pending_map);
        global.font_pending_map = ds_map_create();
        for (var i = 0; i < array_length(fonts_list); i++)
        {
            var _fname = fonts_list[i][0];
            var _fsize = fonts_list[i][1];
            if (_fname == "fnt_main")
                add_font(_fname, _fsize);
            else
                ds_map_add(global.font_pending_map, _fname, _fsize);
        }

        // Tabla de aliases de fuente. La resolucion ocurre en
        // scr_84_get_font / scr_get_font: si la fuente alias no tiene handle
        // valido (archivo ausente, lazy load fallido), se sirve la objetivo.
        // Si el pack provee la fuente alias como archivo, se carga normal.
        if (variable_global_exists("font_alias_targets"))
            ds_map_destroy(global.font_alias_targets);
        global.font_alias_targets = ds_map_create();
        ds_map_add(global.font_alias_targets, "fnt_main_mono", "fnt_main");
        ds_map_add(global.font_alias_targets, "fnt_mainbig_mono", "fnt_mainbig");
        ds_map_add(global.font_alias_targets, "fnt_8bit_mixed", "fnt_8bit");
        ds_map_add(global.font_alias_targets, "fnt_legend_alt", "fnt_legend");

        // ----- Sprites -----
        for (var i = 0; i < array_length(sprites_list); i++)
            add_sprite(sprites_list[i]);

        // Sprites adicionales declarados por el pack para esta lengua.
        var additional_funny_words = get_chapter_lang_setting("additional_funny_words", []);
        for (var i = 0; i < array_length(additional_funny_words); i++)
            add_sprite(additional_funny_words[i]);

        // ----- Sonidos -----
        var sndm = global.chemg_sound_map;
        var sounds_list = [
            "AUDIO_INTRONOISE",
            "snd_alt_takingtoolong",
            "snd_jackolantern_laugh",
            "snd_jackolantern_laugh_small",
            "snd_long_only",
            "snd_pumpkin_scream_mama",
            "snd_pumpkin_scream_mama_end",
            "snd_statue_left",
            "snd_statue_right",
            "snd_statue_up",
            "snd_statue_down",
            "snd_takingtoolongtoolong",
            "snd_taking_too_lol",
            "snd_taking_too_long",
            "snd_taking_too_long_fast",
            "snd_taking_too_long_small",
            "snd_taking_too_long_small_fast",
            "snd_taking_tutu",
            "snd_tem_sing_1",
            "snd_tem_sing_2",
            "snd_tem_sing_3",
            "snd_tem_sing_4",
            "snd_tutu_fast",
            "snd_your_long",
            "snd_your_too_bright",
            "snd_your_tutu"
        ];
        global.songs_list = [
            "AUDIO_INTRONOISE",
            "snd_alt_takingtoolong",
            "snd_jackolantern_laugh",
            "snd_jackolantern_laugh_small",
            "snd_long_only",
            "snd_pumpkin_scream_mama",
            "snd_pumpkin_scream_mama_end",
            "snd_takingtoolongtoolong",
            "snd_taking_too_lol",
            "snd_taking_too_long",
            "snd_taking_too_long_fast",
            "snd_taking_too_long_small",
            "snd_taking_too_long_small_fast",
            "snd_taking_tutu",
            "snd_tem_sing_1",
            "snd_tem_sing_2",
            "snd_tem_sing_3",
            "snd_tem_sing_4",
            "snd_tutu_fast",
            "snd_your_long",
            "snd_your_too_bright",
            "snd_your_tutu",
            "snd_statue_left",
            "snd_statue_right",
            "snd_statue_up",
            "snd_statue_down"
        ];

        for (var i = 0; i < array_length(sounds_list); i++)
            add_sound(sounds_list[i]);

        // Sonidos adicionales declarados por el pack para esta lengua.
        var additional_funny_sounds = get_chapter_lang_setting("additional_funny_sounds", []);
        for (var i = 0; i < array_length(additional_funny_sounds); i++)
            add_sound(additional_funny_sounds[i]);

        // ----- Strings -----
        global.lang_map = ds_map_create();
        scr_lang_load();
        scr_ascii_input_names();
    }
}
