function scr_84_get_sprite(argument0) //gml_Script_scr_84_get_sprite
{
    // Lazy reload de sprites: si hay un cambio de idioma en caliente
    // pendiente, lo aplicamos AHORA, antes de que este objeto reciba
    // un sprite del idioma viejo. La función es idempotente; si no hay
    // pendiente no hace nada (coste despreciable por llamada).
    if (variable_global_exists("lang_sprites_pending") && global.lang_sprites_pending)
        scr_apply_pending_sprite_reload()

    // Modo traductor ("ver en inglés original"): ignorar cualquier
    // sprite traducido y devolver directamente el asset nativo.
    if (global.orig_en) {
        return asset_get_index(argument0)
    }

    // Modo especial activo: se intenta primero `<prefix>_<sprite_name>`.
    // El prefijo lo pone `scr_load_special_modes` (p. ej. "sp", "sp_1"...).
    // Nota: Chapter1 NO tiene rama `spm_` aquí (tiene que ver con cómo
    // el mod original distinguía voces no traducidas solo desde Ch2+).
    if (variable_global_exists("special_mode_index") && global.special_mode_index > 0) {
        var sp_key = global.active_sp_prefix + "_" + argument0
        var ret = ds_map_find_value(global.chemg_sprite_map, sp_key)
        if (!is_undefined(ret) && ret != -1)
            return ret
    }

    var ret = ds_map_find_value(global.chemg_sprite_map, argument0);
    if (!is_undefined(ret) && ret != -1)
        return ret
    return asset_get_index(argument0)
}
