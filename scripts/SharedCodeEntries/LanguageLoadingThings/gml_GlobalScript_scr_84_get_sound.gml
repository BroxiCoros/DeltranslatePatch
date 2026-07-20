function scr_84_get_sound(argument0) //gml_Script_scr_84_get_sound
{
    // Lazy reload de sonidos: si hay un cambio de idioma en caliente
    // pendiente, lo aplicamos AHORA, antes de resolver este sonido, para
    // no devolver el stream/asset del idioma viejo. Idempotente; sin
    // pendiente el coste por llamada es despreciable.
    if (variable_global_exists("lang_sounds_pending") && global.lang_sounds_pending)
        scr_apply_pending_sound_reload()

    if (global.orig_en)
        return asset_get_index(argument0)
        
    if (!global.translated_songs && array_includes(global.songs_list, argument0)) {
        return asset_get_index(argument0)
    }
        
    if (global.special_mode) {
        var ret = ds_map_find_value(global.chemg_sound_map, "sp_" + argument0)

        if (!is_undefined(ret))
            return ret
    }
    var ret = ds_map_find_value(global.chemg_sound_map, argument0);

    if (!is_undefined(ret))
        return ret
    return asset_get_index(argument0)
}

