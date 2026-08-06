// El `global.font_map` puede venir de dos sitios, y cada uno usa una
// convención de clave distinta:
//
//   - El mod (`add_font`): claves CON prefijo -> "fnt_main", "fnt_mainbig".
//   - El juego (`scr_84_init_localization`, que es quien manda con los idiomas
//     nativos): claves SIN prefijo -> "main", "mainbig", "dotumche"...,
//     apuntando a `fnt_ja_main`, `fnt_ja_dotumche`... cuando el idioma es
//     japonés.
//
// El código del juego llama siempre con el nombre corto
// (`scr_84_get_font("main")`, 128 veces solo en el Cap.5), así que hay que
// probar las dos claves: buscando solo "fnt_" + nombre, en japonés nativo no se
// encontraría ninguna fuente y el texto saldría con la latina, sin kana.
//
// El respaldo final también prueba primero `fnt_<nombre>`: `asset_get_index("main")`
// no existe como asset y devolvía -1, o sea una fuente inválida.
function scr_84_get_font(argument0) //gml_Script_scr_84_get_font
{
	var alt_name = scr_letter_fix(argument0), ret = -1;

    ret = ds_map_find_value(global.font_map, "fnt_" + alt_name);

    if (!is_undefined(ret) && ret != -1)
        return ret

    ret = ds_map_find_value(global.font_map, "fnt_" + argument0);

    if (!is_undefined(ret) && ret != -1)
        return ret

    // Convención sin prefijo (la que usa `scr_84_init_localization`).
    ret = ds_map_find_value(global.font_map, alt_name);

    if (!is_undefined(ret) && ret != -1)
        return ret

    ret = ds_map_find_value(global.font_map, argument0);

    if (!is_undefined(ret) && ret != -1)
        return ret

    var asset = asset_get_index("fnt_" + argument0);

    if (asset != -1)
        return asset

    return asset_get_index(argument0)
}
