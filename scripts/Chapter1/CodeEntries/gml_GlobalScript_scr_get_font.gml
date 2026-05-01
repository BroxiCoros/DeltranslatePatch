// Resuelve un nombre de fuente completo ("fnt_main") a su handle.
// Mismo flujo que scr_84_get_font pero acepta el nombre con prefijo
// directamente (lo usan los pocos call-sites que no fueron tocados por
// el FontInjector).
//
// Cadena de resolucion: font_map -> font_pending_map (lazy) ->
// font_alias_targets -> asset_get_index. Detalles en scr_84_get_font.

var fnt;
function scr_get_font(argument0) //gml_Script_scr_get_font
{
    // 1. Cache hit.
    fnt = ds_map_find_value(global.font_map, argument0)
    if (!is_undefined(fnt) && fnt != -1)
        return fnt

    // 2. Lazy load.
    if (variable_global_exists("font_pending_map")
        && ds_map_exists(global.font_pending_map, argument0))
    {
        var sz = ds_map_find_value(global.font_pending_map, argument0);
        ds_map_delete(global.font_pending_map, argument0);
        add_font(argument0, sz);
        fnt = ds_map_find_value(global.font_map, argument0);
        if (!is_undefined(fnt) && fnt != -1)
            return fnt;
    }

    // 3. Alias fallback.
    if (variable_global_exists("font_alias_targets")
        && ds_map_exists(global.font_alias_targets, argument0))
    {
        var tgt = ds_map_find_value(global.font_alias_targets, argument0);
        return scr_get_font(tgt);
    }

    // 4. Fallback final.
    return asset_get_index(argument0);
}
