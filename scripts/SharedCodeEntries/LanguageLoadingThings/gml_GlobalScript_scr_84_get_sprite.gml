function scr_84_get_sprite(argument0) //gml_Script_scr_84_get_sprite
{
    // Modo traductor ("ver en inglés original"): ignorar cualquier
    // sprite traducido y devolver directamente el asset nativo.
    if (global.orig_en) {
        return asset_get_index(argument0)
    }

    // `alt_name` es el nombre con los caracteres no ASCII sustituidos por su
    // `ord()`: en consola los assets del pack se guardan así. Se prueba antes
    // que el nombre literal en cada uno de los mapas.
    var alt_name = scr_letter_fix(argument0), ret = -1;

    // Voces no traducidas: si el jugador apagó "Translated Voices",
    // se usan variantes `spm_` (comportamiento original).
    if (!global.translated_songs) {
        ret = ds_map_find_value(global.chemg_sprite_map, "spm_" + alt_name)
        if (!is_undefined(ret) && ret != -1)
            return ret
        ret = ds_map_find_value(global.chemg_sprite_map, "spm_" + argument0)
        if (!is_undefined(ret) && ret != -1)
            return ret
    }

    // Modo especial activo: variantes `sp_`.
    if (global.special_mode) {
        ret = ds_map_find_value(global.chemg_sprite_map, "sp_" + alt_name)
        if (!is_undefined(ret) && ret != -1)
            return ret
        ret = ds_map_find_value(global.chemg_sprite_map, "sp_" + argument0)
        if (!is_undefined(ret) && ret != -1)
            return ret
    }

    ret = ds_map_find_value(global.chemg_sprite_map, alt_name);
    if (!is_undefined(ret) && ret != -1)
        return ret
    ret = ds_map_find_value(global.chemg_sprite_map, argument0);
    if (!is_undefined(ret) && ret != -1)
        return ret

    return asset_get_index(argument0)
}
