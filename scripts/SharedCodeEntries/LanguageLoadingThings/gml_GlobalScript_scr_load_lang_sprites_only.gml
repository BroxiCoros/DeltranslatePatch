// Recarga SOLO los sprites del idioma activo al chemg_sprite_map.
// Chapter-agnóstico: itera `global.sprites_list` (la define
// `init_global_vars`, así que persiste tras el boot).
//
// NO borra los sprites viejos: el codigo que llama
// (`scr_switch_game_language`) ya los movio a `global.outdated_sprites`
// para borrarlos despues, en `scr_cleanup_outdated_sprites` al cambiar
// de sala. Aqui solo vaciamos el map (desreferencia) y lo repoblamos
// con los sprites del idioma nuevo.

function scr_load_lang_sprites_only() //gml_Script_scr_load_lang_sprites_only
{
    if (variable_global_exists("chemg_sprite_map"))
        ds_map_clear(global.chemg_sprite_map);
    else
        global.chemg_sprite_map = ds_map_create();

    for (var i = 0; i < array_length(global.sprites_list); i++)
        add_sprite(global.sprites_list[i]);

    // Sprites adicionales declarados por el pack para esta lengua.
    var additional_funny_words = get_chapter_lang_setting("additional_funny_words", []);
    for (var i = 0; i < array_length(additional_funny_words); i++)
        add_sprite(additional_funny_words[i]);

    // Con los sprites del idioma nuevo ya cargados, reconstruir las fuentes-
    // sprite que dependan de ellos (p.ej. las de numeros del Cap.5). Cada
    // capitulo que lo necesite registra su `lang_fonts_loader` en
    // `scr_init_localization`; los que no, no lo definen y esto no hace nada.
    // Como esta funcion solo se llama en el hot-switch (en el boot los sprites
    // los carga otro loop), no hay doble creacion de fuentes.
    if (variable_global_exists("lang_fonts_loader"))
        global.lang_fonts_loader();
}
