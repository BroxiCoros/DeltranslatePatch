// Resuelve "main" -> handle de fuente. Es la API que consume todo el
// codigo de juego tras el FontInjector (las llamadas hardcodeadas a
// fnt_X estan reescritas a scr_84_get_font("X")).
//
// Cadena de resolucion:
//   1. font_map: si la fuente ya esta cargada, devolverla.
//   2. font_pending_map: si quedo diferida tras el ultimo cambio de
//      idioma (lazy load), rasterizarla ahora y devolverla.
//   3. font_alias_targets: si esta declarada como alias de otra fuente
//      (p. ej. fnt_main_mono -> fnt_main), resolver la objetivo
//      recursivamente. La objetivo puede a su vez estar pending y se
//      cargara lazy en la recursion.
//   4. asset_get_index: fallback al asset estatico del juego (puede
//      devolver -1 si tampoco existe).
//
// Diferencia respecto al mod base: el primer chequeo rechaza -1, no
// solo undefined. La version anterior devolvia -1 si la entrada estaba
// en el map con ese valor, saltandose los fallbacks. Esto se alinea con
// scr_get_font, que ya hacia la comprobacion estricta.

function scr_84_get_font(argument0) //gml_Script_scr_84_get_font
{
    var fnt_full = "fnt_" + argument0;

    // 1. Cache hit (fuente ya cargada en este idioma).
    var ret = ds_map_find_value(global.font_map, fnt_full);
    if (!is_undefined(ret) && ret != -1)
        return ret;

    // 2. Lazy load (fuente diferida en el ultimo switch de idioma).
    if (variable_global_exists("font_pending_map")
        && ds_map_exists(global.font_pending_map, fnt_full))
    {
        var sz = ds_map_find_value(global.font_pending_map, fnt_full);
        ds_map_delete(global.font_pending_map, fnt_full);
        add_font(fnt_full, sz);
        ret = ds_map_find_value(global.font_map, fnt_full);
        if (!is_undefined(ret) && ret != -1)
            return ret;
    }

    // 3. Alias fallback (fuente declarada como alias en el manifest).
    if (variable_global_exists("font_alias_targets")
        && ds_map_exists(global.font_alias_targets, fnt_full))
    {
        var tgt = ds_map_find_value(global.font_alias_targets, fnt_full);
        // tgt es nombre completo ("fnt_main"); scr_84_get_font espera
        // sin prefijo "fnt_". Quitamos los 4 chars iniciales.
        return scr_84_get_font(string_delete(tgt, 1, 4));
    }

    // 4. Fallback final: asset estatico (puede ser -1).
    return asset_get_index(argument0);
}
