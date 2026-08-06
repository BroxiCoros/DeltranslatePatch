// Copia de `SharedCodeEntries/Misc/gml_GlobalScript_is_native_lang.gml`: el
// menú raíz no comparte esa carpeta (ver el "Дичайший костыль" de BaseFix), así
// que sus funciones van duplicadas aquí, como el resto de las suyas.
//
// ¿El idioma indicado (o el activo) es uno de los NATIVOS del juego?
//
// En el menú raíz esto es todavía más directo que en los capítulos: aquí no hay
// sistema de localización ninguno (`scr_84_init_localization` no existe), el
// juego lleva el inglés y el japonés incrustados en ternarios
// `(global.lang == "en") ? "Chapter Select" : "チャプター選択"` y elige la fuente
// por id (`_font = (global.lang == "en") ? 2 : 1`). O sea que basta con que
// `global.lang` valga "en"/"ja" y con que corra el código original: de eso se
// encarga el gemelo vanilla que monta BaseFix.
function is_native_lang(argument0) //gml_Script_is_native_lang
{
    var code = argument0
    if (is_undefined(code))
    {
        if (!variable_global_exists("lang"))
            return false
        code = global.lang
    }

    if (!variable_global_exists("all_lang_settings"))
        return false

    if (!variable_struct_exists(global.all_lang_settings, code))
        return false

    return get_struct_field(variable_struct_get(global.all_lang_settings, code), "native", false) == true
}
