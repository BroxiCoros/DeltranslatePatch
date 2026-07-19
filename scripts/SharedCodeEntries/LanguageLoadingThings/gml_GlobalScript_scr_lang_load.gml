function scr_lang_load(argument0) //gml_Script_scr_lang_load
{
    var orig_filename = get_lang_folder_path() + "chapter" + string(global.chapter) + "/strings.json"

    var orig_map = scr_84_load_map_json(orig_filename)

    if (argument0 == true) {
        var size = ds_map_size(global.used_strings)
        var key = ds_map_find_first(global.used_strings)
        for (var i = 0; i < size; i++;) {
            if (ds_map_find_value(global.lang_map, key) != ds_map_find_value(orig_map, key)) {
                ds_map_set(global.changed_strings, ds_map_find_value(global.lang_map, key), ds_map_find_value(orig_map, key))
            }
            key = ds_map_find_next(global.used_strings, key)
        }
    }

    ds_map_destroy(global.lang_map)
    global.lang_map = orig_map
}