// Reconstruye la fuente-sprite de TV Land tras una recarga de sprites en
// caliente. Mismo patron que `scr_reload_damage_fonts` en el Cap.5, y por el
// mismo motivo: la fuente se crea con `font_add_sprite_ext` a partir de
// `spr_tvlandfont`, que el pack localiza. Al cambiar de idioma el sprite que
// la respaldaba se recarga (y luego se borra en el cleanup), asi que la fuente
// hay que rehacerla contra el sprite del idioma nuevo.
//
// Por que existe esta funcion y no la linea suelta que habia antes:
// `scr_84_get_sprite` empieza aplicando la recarga pendiente
// (`scr_apply_pending_sprite_reload`). Como `scr_switch_game_language` marca
// `lang_sprites_pending = true` ANTES de llamar a `scr_init_localization`,
// tener esa llamada dentro del cuerpo de `init` anulaba el diferido entero:
// los 356 sprites del capitulo (6,2 MB de PNG en el pack de Letra Delta) se
// cargaban sincronos en el frame del cambio de idioma. Era el unico capitulo
// con una llamada asi, y de ahi que el tiron del Cap.3 fuera tan visible.
//
// Se registra como `global.lang_fonts_loader` en `scr_init_localization` y la
// invoca `scr_load_lang_sprites_only` al terminar de cargar los sprites del
// idioma nuevo. En el boot la llama el propio `scr_init_localization`, donde
// los sprites ya estan cargados y `scr_84_get_sprite` no dispara nada.

function scr_reload_tvlandfont()
{
    if (variable_global_exists("tvlandfont") && font_exists(global.tvlandfont))
        font_delete(global.tvlandfont)

    global.tvlandfont = font_add_sprite_ext(scr_84_get_sprite("spr_tvlandfont"), get_chapter_lang_setting("tvlangfont_string", "ABCDEFGHIJKLMNOPQRSTUVWXYZ.?!:…abcdefghijklmnopqrstuvwxyz1234567890"), 0, 1)
}
