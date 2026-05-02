// Carga una fuente del pack de idioma con tamano y rango de glifos
// configurables por el traductor.
//
// argument0: nombre logico de la fuente (p. ej. "fnt_main").
// argument1: tamano por defecto (size base, definido en el manifiesto).
//
// Resolucion de tamano y rango (de mayor a menor prioridad):
//   1. chapter_settings.json -> font_settings.<fnt_name>.{size,range}
//   2. settings.json         -> font_settings.<fnt_name>.{size,range}
//   3. argument1                                            (size por defecto)
//      get_lang_setting("fonts_range") o [2, 128]            (range por defecto)
//
// Cache (introducido para acelerar el cambio de idioma a JA):
//   Las fuentes japonesas tienen ~1.700 glifos (vs ~200 las latinas), y
//   font_add() las rasteriza sincronamente. Para evitar re-rasterizar al
//   volver a un idioma ya visto en la sesion (p. ej. JA -> ES -> JA),
//   guardamos los handles en global.font_cache, indexados por la tupla
//   (path resuelto, size, rango). El cache es duenio del ciclo de vida:
//   las fuentes cacheadas NO se anaden a global.loaded_fonts y por tanto
//   NO las borra scr_lang_reload_partial. Si se necesita liberarlas, eso
//   es responsabilidad de scr_invalidate_font_cache (p. ej. tras la
//   actualizacion en caliente de archivos del pack).
//
// Compatible con packs antiguos: si no hay font_settings, todo funciona
// igual que antes.

function add_font(argument0, argument1) //gml_Script_add_font
{
    fnt_name = argument0
    fnt_size = argument1

    // ----- Range por defecto (preserva comportamiento del mod base) -----
    fonts_range = get_lang_setting("fonts_range")
    if (is_undefined(fonts_range)) {
        fonts_range = [2, 128]
    }

    // ----- Override por fuente: tamano y rango -----
    // Primero global (settings.json), despues chapter (chapter_settings.json).
    // El de capitulo gana sobre el global.
    var global_overrides = get_lang_setting("font_settings", undefined)
    if (!is_undefined(global_overrides) && is_struct(global_overrides) && variable_struct_exists(global_overrides, fnt_name)) {
        var ovr = variable_struct_get(global_overrides, fnt_name)
        if (is_struct(ovr)) {
            if (variable_struct_exists(ovr, "size"))
                fnt_size = variable_struct_get(ovr, "size")
            if (variable_struct_exists(ovr, "range"))
                fonts_range = variable_struct_get(ovr, "range")
        }
    }
    var chapter_overrides = get_chapter_lang_setting("font_settings", undefined)
    if (!is_undefined(chapter_overrides) && is_struct(chapter_overrides) && variable_struct_exists(chapter_overrides, fnt_name)) {
        var ovr = variable_struct_get(chapter_overrides, fnt_name)
        if (is_struct(ovr)) {
            if (variable_struct_exists(ovr, "size"))
                fnt_size = variable_struct_get(ovr, "size")
            if (variable_struct_exists(ovr, "range"))
                fonts_range = variable_struct_get(ovr, "range")
        }
    }

    path = get_lang_folder_path() + "fonts/"
    // Override por capitulo. Si el pack provee un archivo
    // `<fnt_name>_chapter2.ttf` (u .otf) en `fonts/`, lo usa con
    // prioridad sobre el archivo generico `<fnt_name>.ttf`. Esto
    // sirve para casos donde una fuente compartida por nombre
    // (p. ej. fnt_8bit) en realidad es distinta entre capitulos:
    // el codigo de juego sigue pidiendo "fnt_8bit" sin saber del
    // override, pero aqui cargamos el archivo correcto. Si el
    // archivo con sufijo no existe, todo se comporta como antes.
    filename_ttf_chapter = ((path + fnt_name) + "_chapter2.ttf")
    filename_otf_chapter = ((path + fnt_name) + "_chapter2.otf")
    filename_ttf = ((path + fnt_name) + ".ttf")
    filename_otf = ((path + fnt_name) + ".otf")

    // ----- Resolver QUE archivo se va a usar (si alguno) -----
    // Antes este if/else if entrelazaba la resolucion con la llamada
    // a font_add. Lo separamos para poder consultar el cache antes de
    // rasterizar.
    var resolved_path = ""
    if (file_exists(filename_ttf_chapter))      resolved_path = filename_ttf_chapter
    else if (file_exists(filename_otf_chapter)) resolved_path = filename_otf_chapter
    else if (file_exists(filename_ttf))         resolved_path = filename_ttf
    else if (file_exists(filename_otf))         resolved_path = filename_otf

    // Asset built-in (Deltarune original) usado para heredar bold/italic
    // y como fallback si no hay archivo del pack.
    font = asset_get_index(fnt_name)

    if (resolved_path != "") {
        // ----- Cache por (path, size, rango) -----
        // Indexamos el handle por el path resuelto y los parametros de
        // rasterizacion. Distintos idiomas tienen distintos paths
        // (.../lang/ja/fonts/fnt_main.ttf vs .../lang/es/fonts/fnt_main.ttf)
        // asi que cada idioma vive en su propia entrada. Override por
        // capitulo (`_chapter2.ttf`) tambien produce key distinta.
        if (!variable_global_exists("font_cache"))
            global.font_cache = ds_map_create()

        var cache_key = ((resolved_path + "|") + string(fnt_size) + "|") + string(fonts_range[0]) + ("-" + string(fonts_range[1]))
        var cached = ds_map_find_value(global.font_cache, cache_key)
        if (!is_undefined(cached)) {
            // Cache hit: el handle sigue vivo en RAM, lo reutilizamos.
            ds_map_set(global.font_map, fnt_name, cached)
            exit;
        }

        // Cache miss: rasterizar y guardar. NO anadir a loaded_fonts
        // porque ya no queremos que el switch borre estas fuentes
        // (las queremos persistir entre cambios de idioma).
        font = font_add(resolved_path, fnt_size, font_get_bold(font), font_get_italic(font), fonts_range[0], fonts_range[1])
        ds_map_add(global.font_cache, cache_key, font)
        ds_map_set(global.font_map, fnt_name, font)
        exit;
    }

    // ----- Sin archivo en el pack: caer al asset estatico del juego -----
    // Deltarune trae fuentes _ja built-in que se usaban si el pack no
    // suministraba la propia. Los handles asi obtenidos NO son nuestros
    // (no llamamos font_add) y por tanto no van al cache ni a loaded_fonts.
    if ((asset_get_index(fnt_name + "_" + global.lang)) != -1)
        font = asset_get_index(fnt_name + "_" + global.lang)
    ds_map_set(global.font_map, fnt_name, font)
}
