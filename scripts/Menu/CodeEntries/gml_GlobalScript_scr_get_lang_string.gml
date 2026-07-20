function scr_get_lang_string(argument0, argument1) //gml_Script_scr_get_lang_string
{
    var lang_orig = argument0
    var lang_string_id = argument1
    var str = ds_map_find_value(global.lang_map, lang_string_id)

    // Modo especial: si hay un modo activo (index > 0), intentamos primero
    // la variante con prefijo correspondiente. `global.active_sp_prefix`
    // es, por ejemplo, "sp" (retrocompat) o "sp_1", "sp_2", etc.
    // `scr_load_special_modes` lo deja consistente con el índice activo.
    if (variable_global_exists("special_mode_index") && global.special_mode_index > 0)
    {
        var sp_key = global.active_sp_prefix + "_" + lang_string_id
        var sp_str = ds_map_find_value(global.lang_map, sp_key)
        if (sp_str != undefined)
            str = sp_str
    }

    if (is_undefined(str))
        return lang_orig
    return str;
}
