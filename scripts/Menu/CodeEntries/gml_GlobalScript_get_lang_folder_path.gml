function get_lang_folder_path(arg0) //gml_Script_get_lang_folder_path
{
    // Caso explícito: el llamador quiere acceder a un idioma concreto
    // (útil, por ejemplo, para escanear otros paquetes o descargar un
    // idioma distinto al activo sin cambiarlo).
    if (!is_undefined(arg0))
        return global.lang_folder + arg0 + "/"

    // --- Retrocompatibilidad con packs de un solo idioma ---
    // Si `lang/settings.json` existe directamente en la raíz, asumimos
    // que el pack usa la estructura vieja (una única traducción suelta,
    // como los packs de Neprim / EngDeltranslatePack originales). En ese
    // caso seguimos devolviendo `lang/` para no romper nada.
    if (file_exists(global.lang_folder + "settings.json"))
        return global.lang_folder

    // --- Modo multi-idioma ---
    // La estructura esperada es `lang/<lang_code>/settings.json`,
    // p. ej. `lang/es_mx/`, `lang/en/`, `lang/ja/`, etc.
    return global.lang_folder + global.lang + "/"
}
