// Borra los sprites del idioma anterior que quedaron en RAM tras un
// cambio de idioma en caliente. Se llama desde el Step de
// obj_gamecontroller cuando se detecta que cambiamos de sala (los
// objetos viejos ya se destruyeron y nadie debería estar usando ya
// sus sprite_index).
//
// El array `global.outdated_sprites` se rellena en
// `scr_switch_game_language` con los sprites del idioma viejo
// justo antes de la recarga parcial. Esta función lo vacía.

function scr_cleanup_outdated_sprites() //gml_Script_scr_cleanup_outdated_sprites
{
    if (!variable_global_exists("outdated_sprites"))
        exit;

    var n = array_length(global.outdated_sprites)
    if (n == 0)
        exit;

    for (var i = 0; i < n; i++)
    {
        var spr = global.outdated_sprites[i]
        if (sprite_exists(spr))
            sprite_delete(spr)
    }

    global.outdated_sprites = []
}
