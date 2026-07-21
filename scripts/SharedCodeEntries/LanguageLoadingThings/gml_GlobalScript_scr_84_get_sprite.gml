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

    // Voces no traducidas: si el jugador apagó "Translated Voices",
    // se usan variantes `spm_` (comportamiento original).
    if (!global.translated_songs) {
        var ret = ds_map_find_value(global.chemg_sprite_map, "spm_" + argument0)
        if (!is_undefined(ret) && ret != -1)
            return ret
    }

    // Modo especial activo: variantes `sp_`.
    if (global.special_mode) {
        var ret = ds_map_find_value(global.chemg_sprite_map, "sp_" + argument0)
        if (!is_undefined(ret) && ret != -1)
            return ret
    }

    var ret = ds_map_find_value(global.chemg_sprite_map, argument0);
    if (!is_undefined(ret) && ret != -1)
        return ret
    return asset_get_index(argument0)
}
