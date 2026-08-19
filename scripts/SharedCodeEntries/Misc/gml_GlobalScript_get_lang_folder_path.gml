function get_lang_folder_path(arg0) //gml_Script_get_lang_folder_path
{
    // Caso explícito: el llamador quiere acceder a un idioma concreto
    // (útil, por ejemplo, para escanear otros paquetes o descargar un
    // idioma distinto al activo sin cambiarlo).
    if (!is_undefined(arg0))
        return global.lang_folder + arg0 + "/"

    // La prioridad la fija scan_languages(): si encontró subcarpetas de
    // idioma válidas devolvemos `lang/<id>/`, donde el id es el nombre de la
    // carpeta, y se ignora cualquier `lang/settings.json` suelto en la raíz.
    //
    // --- Retrocompatibilidad con packs de un solo idioma ---
    // Solo cuando el barrido NO halló ninguna subcarpeta válida quedó
    // `is_single_lang_mode = true` (pack heredado de una única traducción
    // suelta, como los de Neprim / EngDeltranslatePack originales). En ese
    // caso devolvemos `lang/` para no romper nada.
    if (variable_global_exists("is_single_lang_mode") && global.is_single_lang_mode)
        return global.lang_folder

    return global.lang_folder + global.lang + "/"
}

// ---------------------------------------------------------------
// Identidad de un idioma: la CARPETA. Y solo la carpeta.
// ---------------------------------------------------------------
// `global.lang` es el id de un idioma y es el nombre de su subcarpeta de
// `lang/` (en modo pack-suelto, el `lang_code`, porque alli no hay carpeta).
// Manda en las rutas y tambien en las claves del ini (`LANG_DT`,
// `special_mode_<id>`, `translated_songs_<id>`).
//
// El `lang_code` NO es un segundo identificador: no resuelve rutas ni se
// guarda. Solo sirve para acertar el idioma la primera vez (comparado con el
// del sistema, que da codigos ISO) y para nombrar assets del juego base
// (`lang_ja.json`, `fnt_main_ja`).
//
// NO REVIVIR: ni el `lang_code` como id (un pack podia apuntar fuera de su
// carpeta), ni guardarlo en el ini (dos espacios de nombres que traducir en 18
// sitios), ni rescatar un `LANG_DT` desconocido buscandolo entre los
// `lang_code` declarados. Un `LANG_DT` que no sea un id = ese idioma se fue.
// El porque largo esta en CHANGES.md.

// ¿Vale este `lang_code` como codigo? Cadena no vacia y sin `/`, `\` ni `..`.
// Un `"lang_code": 5` sin comillas reventaba el arranque en la primera
// concatenacion: un settings.json malformado debe degradar, no crashear.
function lang_code_is_valid(argument0)
{
    var value = argument0

    if (!is_string(value) || value == "")
        return false

    if (string_pos("/", value) > 0 || string_pos("\\", value) > 0 || string_pos("..", value) > 0)
        return false

    return true
}

// Codigo declarado por el pack, o el id si no lo declara o lo declara mal.
// OJO: la temporal no puede llamarse `id`, que es builtin de GML: el compilador
// rechaza la entrada entera, descarta TODAS las sustituciones del parche y aun
// asi termina con rc=0.
function lang_public_code(argument0)
{
    var lang_id = argument0
    if (is_undefined(lang_id))
        lang_id = global.lang

    if (!variable_global_exists("all_lang_settings"))
        return lang_id

    if (!variable_struct_exists(global.all_lang_settings, lang_id))
        return lang_id

    var declared = get_struct_field(variable_struct_get(global.all_lang_settings, lang_id), "lang_code", lang_id)
    if (!lang_code_is_valid(declared))
        return lang_id

    return declared
}
