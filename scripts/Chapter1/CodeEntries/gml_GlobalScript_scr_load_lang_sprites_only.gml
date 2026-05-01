// AUTOGENERADO por tools/regen_localization.csx desde scripts/Chapter1/manifest.json.
// NO editar a mano: cualquier cambio se sobrescribira en la proxima regeneracion.
//
// Carga los sprites del idioma actual al chemg_sprite_map. NO borra los
// sprites viejos: el codigo que llama (scr_switch_game_language) ya los
// movio al array global.outdated_sprites para borrarlos despues, en
// scr_cleanup_outdated_sprites al cambiar de sala.

function scr_load_lang_sprites_only()
{
    var sprites_list = [
        "bg_alphysalley",
        "bg_building_cattyhouse",
        "bg_building_diner",
        "bg_building_flowershop",
        "bg_building_hospital",
        "bg_building_icee_sign",
        "bg_building_library",
        "bg_building_police",
        "bg_building_school",
        "bg_building_store",
        "bg_building_townhall",
        "bg_building_townhall_layer2",
        "bg_hospital_room2",
        "bg_library",
        "bg_policebarricade",
        "bg_rurus_shop",
        "bg_seam_shopfront",
        "bg_torielclass",
        "IMAGE_LOGO",
        "IMAGE_LOGO_CENTER",
        "IMAGE_LOGO_CENTER_HEART",
        "spr_battlemsg",
        "spr_blockler_b",
        "spr_blockler_o",
        "spr_bnamekris",
        "spr_bnameralsei",
        "spr_bnamesusie",
        "spr_btact",
        "spr_btdefend",
        "spr_btfight",
        "spr_btitem",
        "spr_btspare",
        "spr_bttech",
        "spr_castle_shop",
        "spr_chartarget",
        "spr_checkers_milk",
        "spr_darkmenudesc",
        "spr_dmenu_captions",
        "spr_fieldmuslogo",
        "spr_headkris",
        "spr_headralsei",
        "spr_headsusie",
        "spr_hpname",
        "spr_kingr_asleep",
        "spr_pressfront_b",
        "spr_quitmessage",
        "spr_thrashbody_b",
        "spr_thrashfoot_b",
        "spr_thrashlogo",
        "spr_thrashstats",
        "spr_tiredmark",
        "spr_tplogo",
        "sp_IMAGE_LOGO",
        "sp_IMAGE_LOGO_CENTER",
        "sp_IMAGE_LOGO_CENTER_HEART",
        "sp_spr_blockler_b",
        "sp_spr_blockler_o"
    ];

    // Vaciamos el map; las entradas apuntan a los sprites viejos, que ya
    // estan en outdated_sprites. Tras add_sprite el map vuelve a estar
    // lleno con los sprites del idioma nuevo.
    if (variable_global_exists("chemg_sprite_map"))
        ds_map_clear(global.chemg_sprite_map);
    else
        global.chemg_sprite_map = ds_map_create();

    for (var i = 0; i < array_length(sprites_list); i++)
        add_sprite(sprites_list[i]);

    // Chapter1: variantes especiales de spr_blockler en funcion de
    // get_chapter_lang_setting("boob"). Replica el bloque correspondiente
    // de scr_init_localization (Chapter1 lo tiene).
    var boob = get_chapter_lang_setting("boob", "boob");
    for (var i = 0; i < string_length(boob); i++)
        add_sprite("spr_blockler_" + string_char_at(boob, i + 1), 4);
}
