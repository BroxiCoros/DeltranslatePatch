// Reconstruye las fuentes-sprite de numeros (damage/hp) tras una recarga de
// sprites en caliente. Necesario porque esas fuentes se crean con
// `font_add_sprite_ext` a partir de sprites que el pack puede localizar (en el
// Cap.5, `spr_numbersfontbig_gold`/`_pink`, que en espanol invierten F$ -> $F).
// Al cambiar de idioma, el sprite dinamico viejo que respaldaba la fuente se
// recarga/borra, pero la fuente seguia apuntando a el -> numeros invisibles.
// Aqui se borran las fuentes viejas y se recrean con el sprite del idioma nuevo.
//
// Los glifos son identicos a los de `obj_initializer2_Create_0` (arranque), que
// es la version activa en juego (incluye F$/P$). Se registra como
// `global.lang_fonts_loader` en `scr_init_localization` y lo invoca
// `scr_load_lang_sprites_only` al terminar de cargar los sprites del idioma
// nuevo. Solo corre en el hot-switch: en el boot las crea el inicializador
// vanilla y esta funcion no se llama.

function scr_reload_damage_fonts()
{
    if (variable_global_exists("damagefont") && font_exists(global.damagefont))
        font_delete(global.damagefont)
    if (variable_global_exists("damagefontgold") && font_exists(global.damagefontgold))
        font_delete(global.damagefontgold)
    if (variable_global_exists("damagefontpink") && font_exists(global.damagefontpink))
        font_delete(global.damagefontpink)
    if (variable_global_exists("hpfont") && font_exists(global.hpfont))
        font_delete(global.hpfont)

    global.damagefont = font_add_sprite_ext(scr_84_get_sprite("spr_numbersfontbig"), "0123456789", 20, 0)
    global.damagefontgold = font_add_sprite_ext(scr_84_get_sprite("spr_numbersfontbig_gold"), "0123456789+-%/F$", 20, 0)
    global.damagefontpink = font_add_sprite_ext(scr_84_get_sprite("spr_numbersfontbig_pink"), "0123456789+-%/P$", 20, 0)
    global.hpfont = font_add_sprite_ext(scr_84_get_sprite("spr_numbersfontsmall"), "0123456789-+", 0, 2)
}
