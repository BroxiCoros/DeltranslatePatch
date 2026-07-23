function get_lang_folder_path(arg0) //gml_Script_get_lang_folder_path
{
    // Caso explícito: el llamador quiere acceder a un idioma concreto
    // (útil, por ejemplo, para escanear otros paquetes o descargar un
    // idioma distinto al activo sin cambiarlo).
    if (!is_undefined(arg0))
        return global.lang_folder + arg0 + "/"

    // La prioridad la fija scan_languages(): si encontró subcarpetas de
    // idioma válidas, estamos en modo multi-idioma y devolvemos
    // `lang/<lang_code>/` (p. ej. `lang/es_mx/`, `lang/en/`, `lang/ja/`),
    // aunque exista un `lang/settings.json` suelto en la raíz: ese se ignora.
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
