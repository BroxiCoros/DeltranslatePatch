var fnt;
function scr_get_font(argument0) //gml_Script_scr_get_font
{
    fnt = ds_map_find_value(global.font_map, argument0)
    // Solo devolvemos el handle si es valido. El `|| fnt == -1` original
    // era un bug: devolvia -1 (fuente invalida) en vez de caer al asset.
    if (!is_undefined(fnt) && fnt != -1)
        return fnt
    return asset_get_index(argument0);
}

