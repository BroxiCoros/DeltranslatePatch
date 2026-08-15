// Reconstruye la fuente-sprite de TV Land tras una recarga de sprites en
// caliente. Mismo patron que `scr_reload_damage_fonts` en el Cap.5, y por el
// mismo motivo: la fuente se crea con `font_add_sprite_ext` a partir de
// `spr_tvlandfont`, que el pack localiza. Al cambiar de idioma el sprite que
// la respaldaba se recarga (y luego se borra en el cleanup), asi que la fuente
// hay que rehacerla contra el sprite del idioma nuevo.
//
// Es funcion y no una linea suelta porque hay dos momentos en que hace falta:
// cuando el idioma se carga del disco (la llama `scr_init_localization` justo
// despues de los sprites) y cuando se activa desde la cache, donde no se carga
// nada y hay que rehacerla a mano. Para ese segundo caso se registra en
// `global.lang_fonts_loader`, que invocan la rama de cache de
// `scr_init_localization` y `scr_lang_preload_others`.
//
// Nota historica: cuando existia la carga diferida de sprites, tener esta
// llamada dentro del cuerpo de `init` anulaba el diferido entero -porque
// `scr_84_get_sprite` aplicaba la recarga pendiente antes de resolver- y los
// 356 sprites del capitulo (6,2 MB de PNG en el pack de Letra Delta) se
// cargaban sincronos en el frame del cambio. De ahi que el tiron del Cap.3
// fuera el mas visible. Ese mecanismo ya no existe.

function scr_reload_tvlandfont()
{
    if (variable_global_exists("tvlandfont") && font_exists(global.tvlandfont))
        font_delete(global.tvlandfont)

    global.tvlandfont = font_add_sprite_ext(scr_84_get_sprite("spr_tvlandfont"), get_chapter_lang_setting("tvlangfont_string", "ABCDEFGHIJKLMNOPQRSTUVWXYZ.?!:…abcdefghijklmnopqrstuvwxyz1234567890"), 0, 1)
}
