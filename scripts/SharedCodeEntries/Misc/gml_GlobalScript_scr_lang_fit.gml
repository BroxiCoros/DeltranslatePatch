// Escala horizontal para que una etiqueta traducida quepa en su hueco.
//
// El mod comprime las etiquetas largas con `min(1, ancho / string_width(txt))`,
// porque las traducciones son más largas que el inglés original. Con un idioma
// NATIVO eso está de más y encima se nota: el japonés supera el ancho de
// referencia, se comprime, y el valor numérico (que se dibuja en una x fija)
// queda separado de su etiqueta por un hueco que en el juego original no
// existe. Vanilla dibuja esas etiquetas siempre a escala 1.
//
// Así que en idioma nativo devolvemos 1 y dejamos la maquetación original.
function scr_lang_fit(argument0, argument1) //gml_Script_scr_lang_fit
{
    if (is_native_lang())
        return 1;

    return min(1, argument0 / string_width(argument1));
}
