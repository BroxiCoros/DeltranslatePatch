function scr_get_lang_string(argument0, argument1) //gml_Script_scr_get_lang_string
{
    var lang_orig = argument0
    var lang_string_id = argument1
    var str = ds_map_find_value(global.lang_map, lang_string_id)

    // Modo especial: si hay un modo activo (index > 0), intentamos primero
    // la variante con prefijo correspondiente. `global.active_sp_prefix` es,
    // por ejemplo, "sp" (retrocompat) o "sp_1", "sp_2", etc.
    if (variable_global_exists("special_mode_index") && global.special_mode_index > 0)
    {
        var sp_key = global.active_sp_prefix + "_" + lang_string_id
        var sp_str = ds_map_find_value(global.lang_map, sp_key)
        if (sp_str != undefined)
            str = sp_str
    }

    if (!global.translated_songs)
    {
        if (ds_map_find_value(global.lang_map, ("spm_" + lang_string_id)) != undefined)
            str = ds_map_find_value(global.lang_map, ("spm_" + lang_string_id))
    }

    if is_undefined(str)
        return lang_orig
        // show_error((((("No such a string \"" + lang_string_id) + "\" in ") + global.lang) + " localization file."), 1)
    
    if (global.translator_mode) {
        if (lang_orig != str) {
            ds_map_set(global.lang_to_orig, str, lang_orig)
            ds_map_set(global.orig_to_lang, lang_orig, str)
        }
        
        if (global.orig_en)
            return lang_orig

        ds_map_set(global.used_room_strings, lang_string_id, str);
        ds_map_set(global.used_strings, lang_string_id, lang_orig)
    }
 
    return str;
}