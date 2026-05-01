// Resuelve un nombre de fuente a su font_index. Primero intenta el font_map
// (fuentes cargadas por el sistema de localizacion). Si no esta cargada,
// cae al asset_get_index, que puede devolver -1 si tampoco existe como
// asset estatico. Comportamiento consistente con scr_84_get_font.
//
// Nota sobre el cambio respecto al mod base: la condicion era
//   if (!is_undefined(fnt) || fnt == -1)
// que devolvia fnt aunque fuese -1, saltandose el fallback. Aqui se usa &&
// para que solo retorne fnt si es valido (no undefined Y distinto de -1).

var fnt;
function scr_get_font(argument0) //gml_Script_scr_get_font
{
    fnt = ds_map_find_value(global.font_map, argument0)
    if (!is_undefined(fnt) && fnt != -1)
        return fnt
    return asset_get_index(argument0);
}
