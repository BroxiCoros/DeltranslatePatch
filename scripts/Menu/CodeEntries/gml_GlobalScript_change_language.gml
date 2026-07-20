// Cambia el idioma activo al `target_lang` indicado. Esto:
//   - actualiza `global.lang` y `global.lang_settings`
//   - recarga la tabla de modos especiales (pueden diferir entre packs)
//   - recarga strings, sprites, sonidos y fuentes del nuevo pack
//   - resetea el estado de versiones del controlador y dispara una
//     nueva consulta HTTP a `files_url + "changes.json"` para que el
//     aviso de "actualización disponible" refleje el idioma nuevo y
//     no el anterior
//   - persiste la elección en `true_config.ini` para próximas sesiones
//
// Se usa tanto desde el menú de configuración (al ciclar con ←/→ en
// "Language") como al inicio, si el juego decide que el idioma guardado
// ya no existe.

function change_language(argument0) //gml_Script_change_language
{
    var target_lang = argument0;
    global.lang = target_lang

    // Si ya tenemos el `settings.json` del idioma en caché (lo hace
    // `scan_languages` en obj_gamecontroller_Create_0), lo usamos
    // directamente. Si no, lo leemos del disco ahora.
    if (variable_global_exists("all_lang_settings") && variable_struct_exists(global.all_lang_settings, target_lang))
    {
        global.lang_settings = variable_struct_get(global.all_lang_settings, target_lang)
    }
    else
    {
        var settings_path = get_lang_folder_path() + "settings.json"
        if (file_exists(settings_path))
            global.lang_settings = scr_load_json(settings_path)
    }

    // Los modos especiales son específicos del pack de idioma: por eso
    // se recargan aquí. Esto también clampea el índice activo si el
    // pack nuevo tiene menos modos.
    scr_load_special_modes()

    // Recarga strings.json, sprites, sonidos y fuentes para el idioma
    // nuevo. `scr_init_localization` ya se encarga de destruir los maps
    // viejos y reconstruirlos.
    scr_init_localization()

    // ---------------------------------------------------------------
    // Refrescar el estado de versión y aviso de actualización
    // ---------------------------------------------------------------
    // Las variables `cur_translation_version`, `last_translation_version`,
    // `lang_changes_call`, etc. viven en `obj_gamecontroller`, así que
    // las tocamos via `with(...)`. Sin esto, el banner de "Actualización
    // disponible" o "Sin actualizaciones" mostraría datos del idioma
    // anterior hasta que el jugador volviera a entrar al menú.
    if (instance_exists(obj_gamecontroller))
    {
        with (obj_gamecontroller)
        {
            // Recalcular la versión local leyendo el `changes.json` del
            // nuevo idioma (queda en `cur_translation_version` y
            // `last_translation_version`).
            update_lang_version()

            // Limpiar cualquier estado de descarga/diff que correspondiera
            // al idioma anterior, para no mezclarlos.
            translation_version_changes_files = []
            translation_version_changes_datas = []
            translation_version_description   = ""
            translation_external_update       = false
            loaded_files                      = []
            loaded_datas                      = []
            loading_error                     = ""

            // Disparar la consulta HTTP al nuevo `files_url` si existe.
            // Solo en Windows, igual que en el Create original.
            if (os_type == os_windows)
            {
                var url = get_lang_setting("files_url", "")
                if (url != "")
                    lang_changes_call = http_get(url + "changes.json")
                else
                    lang_changes_call = -1
            }
        }
    }

    // Persistimos la preferencia para futuras sesiones.
    ossafe_ini_open("true_config.ini")
    ini_write_string("LANG", "LANG_DT", global.lang)
    ossafe_ini_close()
    ossafe_savedata_save()
}
