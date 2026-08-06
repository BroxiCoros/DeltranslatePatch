var fnt;
// Simétrico a `scr_84_get_font`, pero al revés: aquí se llama con el nombre
// largo (`scr_get_font("fnt_main")`), que es como registra las claves el mod.
// Con un idioma nativo el mapa lo llenó el juego con el nombre corto ("main"),
// así que si falla la primera búsqueda se reintenta sin el prefijo `fnt_`;
// si no, en japonés estos sitios caerían a la fuente latina y perderían el kana.
function scr_get_font(argument0) //gml_Script_scr_get_font
{
    fnt = ds_map_find_value(global.font_map, argument0)
    // Solo devolvemos el handle si es valido. El `|| fnt == -1` original
    // era un bug: devolvia -1 (fuente invalida) en vez de caer al asset.
    if (!is_undefined(fnt) && fnt != -1)
        return fnt

    if (string_copy(argument0, 1, 4) == "fnt_")
    {
        fnt = ds_map_find_value(global.font_map, string_delete(argument0, 1, 4))

        if (!is_undefined(fnt) && fnt != -1)
            return fnt
    }

    return asset_get_index(argument0);
}
