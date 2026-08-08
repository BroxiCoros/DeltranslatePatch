// En vanilla esto es `!variable_global_exists("lang") || global.lang == "en"`,
// y controla toda la familia `*loc` (msgsetloc, stringsetloc, c_msgnextsubloc,
// ...): cuando devuelve true, esas funciones NO consultan el mapa de strings y
// devuelven el literal inglés que está incrustado en el propio código.
//
// El mod lo forzaba a `false` siempre, para que todo pasara por el pack de
// idioma. Se mantiene ese comportamiento para los packs, pero se recupera la
// semántica vanilla cuando el idioma activo es el INGLÉS NATIVO del juego: ahí
// no hay pack que consultar y el original ya está en el código. En los
// capítulos 2-5 esto es, literalmente, toda la traducción al inglés (por eso el
// juego solo trae `lang_en.json` en el Cap.1: los demás no lo necesitan).
function is_english()
{
    return is_native_lang() && global.lang == "en";
}
