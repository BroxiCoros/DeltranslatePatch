function scr_get_sprite(argument0) //gml_Script_scr_get_sprite
{
    // Voces no traducidas: si el jugador apagó "Translated Songs", se
    // usan variantes `spm_` (equivalente al comportamiento original).
    if (!global.translated_songs) {
        var ret = ds_map_find_value(global.chemg_sprite_map, "spm_" + argument0)
        if (!is_undefined(ret))
            return ret
    }

    // Modo especial activo: se intenta primero `<prefix>_<sprite_name>`.
    // El prefijo lo pone `scr_load_special_modes` (p. ej. "sp", "sp_1"...).
    if (variable_global_exists("special_mode_index") && global.special_mode_index > 0) {
        var sp_key = global.active_sp_prefix + "_" + argument0
        var ret = ds_map_find_value(global.chemg_sprite_map, sp_key)
        if (!is_undefined(ret) && ret != -1)
            return ret
    }

    // Sprite traducido "normal", si el pack lo provee.
    var ret = ds_map_find_value(global.chemg_sprite_map, argument0);
    if (!is_undefined(ret) && ret != -1)
        return ret
    return asset_get_index(argument0)
}
