// Invalida el cache de fuentes (global.font_cache).
//
// Llamar tras cambiar archivos de fuente del pack en disco (p. ej.
// cuando la actualizacion en caliente via changes.json reescribe un
// `.ttf`). De lo contrario, el cache seguiria sirviendo el handle
// rasterizado del archivo viejo, ya que la clave del cache es
// (path, size, range) y el path no cambia entre versiones.
//
// La funcion borra todos los handles de font_add que tenemos cacheados
// y vacia el cache. Las fuentes activas en font_map quedan colgadas
// (estan en uso por draw_set_font); el sistema las refrescara en el
// proximo cambio de idioma o cuando se llame add_font para esa fuente.
//
// Idempotente: si el cache no existe, no hace nada.

function scr_invalidate_font_cache() //gml_Script_scr_invalidate_font_cache
{
    if (!variable_global_exists("font_cache"))
        exit;

    var keys = ds_map_keys_to_array(global.font_cache);
    for (var i = 0; i < array_length(keys); i++)
    {
        var h = ds_map_find_value(global.font_cache, keys[i]);
        if (!is_undefined(h) && h != -1)
            font_delete(h);
    }
    ds_map_destroy(global.font_cache);
    global.font_cache = ds_map_create();
}
