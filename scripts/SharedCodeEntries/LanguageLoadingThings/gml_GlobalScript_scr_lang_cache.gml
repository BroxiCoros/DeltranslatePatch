// Cache de idiomas ya cargados.
//
// El coste de cambiar de idioma no esta en el codigo: esta en leer del disco
// los PNG del pack, decodificarlos y subirlos a la GPU, rasterizar las fuentes
// y parsear el strings.json del capitulo. Los idiomas NATIVOS del juego son
// instantaneos precisamente porque no hacen nada de eso: sus assets ya viven
// dentro del data.win desde que arranca el ejecutable, y
// `scr_84_init_localization` se limita a reapuntar unos ds_map.
//
// Esta cache replica ese comportamiento para los packs: en vez de destruir los
// assets del idioma que dejamos (que es lo que hacia antes
// `scr_init_localization`, obligando a recargarlo todo al volver), se guardan
// tal cual y se reasignan los globales al activarlos. Cambiar de idioma pasa a
// ser reasignar punteros, igual que en nativo.
//
// Lo que se guarda por idioma son los cuatro ds_map que consultan los
// resolvedores (`scr_84_get_sprite`, `scr_84_get_sound`, `scr_get_font`,
// `scr_84_get_lang_string`), el `lang_missing_map`, los tres arrays de recursos
// creados en runtime y el `chapter_lang_settings` del pack. Los globales
// mantienen su nombre de siempre y siguen apuntando al idioma activo, asi que
// todo el codigo que los lee (del juego y del mod) no se entera de nada.
//
// Consecuencia de diseno: los assets ya no se borran nunca mientras dure el
// capitulo. Por eso desaparecen `outdated_sprites` / `outdated_sounds` y sus
// dos cleanups: existian solo para liberar lo del idioma viejo, con el riesgo
// de dejar un `sprite_index` colgando o cortar una voz a mitad. Lo que no se
// borra no puede quedar colgado.
//
// Lo que cuesta es memoria: el pack de Letra Delta ocupa unos 39 MB
// descomprimidos en el Cap.3 (el peor), 3-20 MB en los demas, y cada capitulo
// es un ejecutable aparte, asi que nunca se suman. Con un solo pack instalado
// no hay coste extra frente a lo de antes: esos MB ya estaban cargados
// mientras jugabas en ese idioma; lo unico que cambia es que ahora siguen ahi
// mientras juegas en otro.

function scr_lang_cache_init()
{
    if (!variable_global_exists("lang_cache"))
        global.lang_cache = {}
}

// ¿Hay una entrada utilizable para este idioma? Se comprueba que los ds_map
// sigan vivos: el codigo vanilla de `scr_84_init_localization` destruye los
// cuatro globales al entrar en un idioma nativo, y aunque los desconectamos
// antes de llamarlo, mas vale no fiarse de una id de ds_map ajena.
function scr_lang_cache_has(argument0)
{
    var code = argument0
    scr_lang_cache_init()

    if (!variable_struct_exists(global.lang_cache, code))
        return false

    var e = variable_struct_get(global.lang_cache, code)
    var maps = ["sprite_map", "sound_map", "font_map", "lang_map"]

    for (var i = 0; i < array_length(maps); i++)
    {
        var m = variable_struct_get(e, maps[i])
        if (is_undefined(m) || !ds_exists(m, ds_type_map))
        {
            // Entrada corrupta: se descarta para que el llamador recargue.
            variable_struct_remove(global.lang_cache, code)
            return false
        }
    }

    return true
}

// Guarda el estado actual bajo `code`. Lo llama `scr_init_localization` justo
// antes de cargar otro idioma, con el codigo del que estaba activo.
//
// Los idiomas NATIVOS no se cachean nunca, y de esa regla depende que todo lo
// demas sea seguro: sus ds_map los crea y los destruye `scr_84_init_localization`
// (codigo vanilla que no controlamos), asi que guardar esas ids seria guardar
// algo que el juego puede destruir a nuestras espaldas. Como nunca entran aqui,
// los globales durante un idioma nativo son siempre del vanilla y nadie mas los
// referencia: por eso `scr_lang_cache_discard_current` puede destruirlos sin
// mirar. Y como los packs SI se cachean siempre, nunca se destruye nada suyo.
function scr_lang_cache_save(argument0)
{
    var code = argument0
    if (is_undefined(code) || code == "")
        exit;

    if (is_native_lang(code))
        exit;

    scr_lang_cache_init()

    // Nada que guardar si todavia no se ha cargado ningun pack (primer boot).
    if (!variable_global_exists("chemg_sprite_map") || !ds_exists(global.chemg_sprite_map, ds_type_map))
        exit;

    var e = {}
    variable_struct_set(e, "sprite_map", global.chemg_sprite_map)
    variable_struct_set(e, "sound_map", global.chemg_sound_map)
    variable_struct_set(e, "font_map", global.font_map)
    variable_struct_set(e, "lang_map", global.lang_map)
    variable_struct_set(e, "missing_map", variable_global_exists("lang_missing_map") ? global.lang_missing_map : -1)
    variable_struct_set(e, "sprites", variable_global_exists("loaded_sprites") ? global.loaded_sprites : [])
    variable_struct_set(e, "sounds", variable_global_exists("loaded_sounds") ? global.loaded_sounds : [])
    variable_struct_set(e, "fonts", variable_global_exists("loaded_fonts") ? global.loaded_fonts : [])
    variable_struct_set(e, "chapter_settings", variable_global_exists("chapter_lang_settings") ? global.chapter_lang_settings : {})

    variable_struct_set(global.lang_cache, code, e)
}

// Activa un idioma ya cacheado reasignando los globales. Devuelve false si no
// estaba, y entonces el llamador tiene que cargarlo del disco como siempre.
function scr_lang_cache_load(argument0)
{
    var code = argument0

    if (!scr_lang_cache_has(code))
        return false

    var e = variable_struct_get(global.lang_cache, code)

    global.chemg_sprite_map = variable_struct_get(e, "sprite_map")
    global.chemg_sound_map = variable_struct_get(e, "sound_map")
    global.font_map = variable_struct_get(e, "font_map")
    global.lang_map = variable_struct_get(e, "lang_map")

    var mm = variable_struct_get(e, "missing_map")
    if (!is_undefined(mm) && mm != -1 && ds_exists(mm, ds_type_map))
        global.lang_missing_map = mm
    else
        global.lang_missing_map = ds_map_create()

    global.loaded_sprites = variable_struct_get(e, "sprites")
    global.loaded_sounds = variable_struct_get(e, "sounds")
    global.loaded_fonts = variable_struct_get(e, "fonts")
    global.chapter_lang_settings = variable_struct_get(e, "chapter_settings")

    return true
}

// Destruye los cuatro ds_map globales actuales. Solo se puede llamar cuando el
// idioma que dejamos era NATIVO: sus maps los creo el vanilla y, por la regla
// de arriba, no hay ninguna entrada de cache apuntando a ellos. Sin esto,
// alternar pack -> nativo -> pack iria dejando cuatro ds_map huerfanos por
// vuelta (poca cosa, unos cientos de entradas, pero es una fuga y es evitable).
function scr_lang_cache_discard_current()
{
    var maps = ["chemg_sprite_map", "chemg_sound_map", "font_map", "lang_map"]

    for (var i = 0; i < array_length(maps); i++)
    {
        if (!variable_global_exists(maps[i]))
            continue

        var m = variable_global_get(maps[i])
        if (!is_undefined(m) && ds_exists(m, ds_type_map))
            ds_map_destroy(m)
    }
}

// Desconecta los globales de la cache SIN destruir nada, dejando en su lugar
// ds_map nuevos y vacios.
//
// Es lo que hay que hacer antes de llamar a `scr_84_init_localization` (la
// ruta de idioma nativo): esa funcion vanilla hace `ds_map_destroy` de los
// cuatro globales, y si apuntan a los de un pack cacheado se lleva por delante
// la cache del pack, dejando ids muertas dentro del struct. Con esto destruye
// los desechables que le dejamos y la cache queda intacta.
function scr_lang_cache_detach()
{
    global.chemg_sprite_map = ds_map_create()
    global.chemg_sound_map = ds_map_create()
    global.font_map = ds_map_create()
    global.lang_map = ds_map_create()

    // Los recursos creados en runtime pertenecen al idioma que acabamos de
    // guardar en la cache; el nativo no crea ninguno.
    global.loaded_sprites = []
    global.loaded_sounds = []
    global.loaded_fonts = []
}
