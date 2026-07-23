function scr_lang_load(argument0) //gml_Script_scr_lang_load
{
    var orig_filename = get_lang_folder_path() + "chapter" + string(global.chapter) + "/strings.json"

    var orig_map = scr_84_load_map_json(orig_filename)

    // --- Respaldo cuando no hay pack de idioma instalado ---
    // `lang/` en la raiz del juego la crea el mod (ahi van los packs); el juego
    // de fabrica NO la trae. Si el jugador la borra o aun no ha instalado
    // ningun pack, `scr_84_load_map_json` (vanilla) devuelve undefined porque
    // su rama de "archivo inexistente" esta vacia.
    //
    // Caemos entonces a los strings que el propio juego trae en
    // `chapterN_windows/lang/`. Esto importa sobre todo en el Cap.1: es el
    // unico capitulo escrito al estilo viejo, con miles de llamadas
    // `scr_84_get_lang_string("clave")` de un solo argumento y sin original en
    // linea, asi que sin mapa se queda literalmente sin un solo string y el
    // primer `undefined` revienta en cualquier window_set_caption /
    // font_add_sprite_ext. Los Cap.2-5 usan `stringsetloc("English", "clave")`
    // y ya degradan solos.
    if (is_undefined(orig_map))
        orig_map = scr_84_load_map_json(working_directory + "lang/lang_" + global.lang + ".json")

    if (is_undefined(orig_map))
        orig_map = scr_84_load_map_json(working_directory + "lang/lang_en.json")

    // Ultimo recurso: mapa vacio. Peor que lo anterior (el Cap.1 se quedaria
    // sin texto), pero no deja `global.lang_map` en undefined, que es lo que
    // hacia crashear en el primer `ds_map_find_value`.
    if (is_undefined(orig_map) || !ds_exists(orig_map, ds_type_map))
        orig_map = ds_map_create()

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

    if (!is_undefined(global.lang_map) && ds_exists(global.lang_map, ds_type_map))
        ds_map_destroy(global.lang_map)

    global.lang_map = orig_map
}