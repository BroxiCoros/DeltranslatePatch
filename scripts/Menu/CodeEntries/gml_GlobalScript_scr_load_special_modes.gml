// Normaliza la configuración de "modos especiales" del pack activo en
// las globales que usa el resto del juego:
//
//   global.special_modes      -> array de structs {prefix, name, description}
//                                 (y opcionalmente name_upper, description_upper)
//                                 El elemento [0] es siempre el modo "por
//                                 defecto" (sin prefix). Los siguientes son
//                                 los modos especiales declarados por el pack.
//   global.special_mode_index -> 0..N-1 (donde N = array_length).
//                                 0 = modo por defecto. 1..N-1 = modos especiales.
//   global.active_sp_prefix   -> prefijo del modo activo, "" si es el default.
//                                 Esto deja a scr_get_lang_string / scr_get_sprite
//                                 sin buscar variante cuando el default está activo.
//   global.special_mode       -> (compat con código existente) bool: index > 0.
//
// El índice se persiste **por idioma** en `true_config.ini` bajo claves
// `LANG.special_mode_index_<lang_code>`, con cadena de fallbacks a las
// claves anteriores del mod (`special_mode_index`, `special_mode`).
//
// Formatos aceptados en settings.json:
//
//   (1) Nuevo formato (recomendado):
//
//       "special_modes": [
//           { "name": "Sin rima", "description": "Traducción estándar." },
//           { "prefix": "sp_1", "name": "Modo rima",
//             "description": "Diálogos con rima activados." },
//           { "prefix": "sp_2", "name": "Modo caló",
//             "description": "Jerga mexicana activada." }
//       ]
//
//       El primer elemento NO debe tener "prefix" (es el modo por defecto).
//       Los demás llevan "prefix" + "name" + "description". Para el Capítulo 1
//       en Light World pueden añadirse los campos opcionales "name_upper" y
//       "description_upper" (si faltan, se usan name/description tal cual).
//
//   (2) Formato heredado (mod original): "special_mode": true
//
//       Sintetiza dos entradas con prefijos "" y "sp", y nombres/descripciones
//       VACÍOS. Esto activa el fallback localizado en obj_lang_settings_Create_0:
//       el "off" muestra el "No"/"Нет" del strings.json (obj_lang_settings_4_0)
//       y el "on" muestra el "Yes"/"Да" (obj_lang_settings_3_0). De esta forma
//       los packs antiguos como el ruso siguen funcionando sin tocar nada.

function scr_load_special_modes() //gml_Script_scr_load_special_modes
{
    var modes_setting = get_lang_setting("special_modes", undefined)

    if (is_undefined(modes_setting))
    {
        // Sin array nuevo -> miramos el flag booleano del mod original.
        if (get_lang_setting("special_mode", false))
        {
            // Dos entradas: default (sin prefix) + un único modo "sp".
            // Sin name/description: caen al fallback localizado del menú.
            // Sintaxis con variables intermedias para no condensar structs
            // dentro del array literal (el parser GML decompilado puede
            // tropezar con structs literales encadenados en una línea).
            var def_mode = {
                prefix: "",
                name: "",
                description: ""
            }
            var sp_mode = {
                prefix: "sp",
                name: "",
                description: ""
            }
            global.special_modes = [def_mode, sp_mode]
        }
        else
        {
            global.special_modes = []
        }
    }
    else
    {
        global.special_modes = modes_setting
    }

    // Lectura del índice persistido para este idioma.
    // Cadena de fallbacks para migrar configs anteriores:
    //   1. `special_mode_index_<lang>` (clave nueva, por idioma).
    //   2. `special_mode_index` (clave global del paso anterior del mod).
    //   3. `special_mode` (booleano histórico del mod original).
    ossafe_ini_open("true_config.ini")
    var key_lang = "special_mode_index_" + global.lang
    var idx = ini_read_real("LANG", key_lang, -1)
    if (idx == -1)
        idx = ini_read_real("LANG", "special_mode_index", ini_read_real("LANG", "special_mode", 0))
    ossafe_ini_close()

    global.special_mode_index = idx

    // Clampeo defensivo. Rangos válidos: [0, array_length-1].
    var modes_len = array_length(global.special_modes)
    if (modes_len == 0)
        global.special_mode_index = 0
    else if (global.special_mode_index < 0 || global.special_mode_index >= modes_len)
        global.special_mode_index = 0

    // Compat: código viejo del mod puede seguir leyendo `global.special_mode`.
    global.special_mode = (global.special_mode_index > 0)

    // Prefijo activo. Cadena vacía cuando es el default.
    if (modes_len > 0)
        global.active_sp_prefix = get_struct_field(global.special_modes[global.special_mode_index], "prefix", "")
    else
        global.active_sp_prefix = ""
}
