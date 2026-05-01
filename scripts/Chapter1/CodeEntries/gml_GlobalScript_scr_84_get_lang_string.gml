function scr_84_get_lang_string(argument0, argument1) //gml_Script_scr_84_get_lang_string
{
    // OJO: en Chapter1 el orden de argumentos es al revés que en los
    // otros capítulos y el Menu:
    //   argument0 = lang_string_id
    //   argument1 = lang_orig  (texto literal fallback)
    // Se mantiene ese contrato original del mod.
    var lang_orig = argument1
    var lang_string_id = argument0
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

    // "Translated Voices/Songs" apagado: preferir variante `spm_`.
    if (!global.translated_songs)
    {
        if (ds_map_find_value(global.lang_map, ("spm_" + lang_string_id)) != undefined)
            str = ds_map_find_value(global.lang_map, ("spm_" + lang_string_id))
    }

    if is_undefined(str)
        return lang_orig

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
