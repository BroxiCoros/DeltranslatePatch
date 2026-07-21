function scr_84_get_lang_string(argument0, argument1) //gml_Script_scr_84_get_lang_string
{
    var lang_orig = argument1
    var lang_string_id = argument0
    var str = ds_map_find_value(global.lang_map, lang_string_id)

    if global.special_mode
    {
        if (ds_map_find_value(global.lang_map, ("sp_" + lang_string_id)) != undefined)
            str = ds_map_find_value(global.lang_map, ("sp_" + lang_string_id))
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
        var orig = ds_map_find_value(global.orig_map, lang_string_id)
        if (orig != str) {
            ds_map_set(global.lang_to_orig, str, orig)
            ds_map_set(global.orig_to_lang, orig, str)
        }
        
        if (global.orig_en && orig != undefined) {
            return ds_map_find_value(global.orig_map, lang_string_id)
        }

        ds_map_set(global.used_strings, lang_string_id, lang_orig)
    }

    return str;
}