// Aplica una recarga de sprites diferida (lazy reload). Se dispara
// en dos lugares:
//   1. Al inicio de `scr_84_get_sprite`: si algún objeto pide un
//      sprite tras un cambio de idioma, los sprites se actualizan
//      antes de que ese objeto reciba uno desactualizado.
//   2. En el Step de `obj_gamecontroller` al detectar cambio de sala:
//      garantiza que los sprites del idioma nuevo estén cargados
//      antes de hacer cleanup de los outdated.
//
// La función limpia el `chemg_sprite_map` (las entradas viejas son
// simplemente desreferenciadas; los sprites siguen vivos en RAM hasta
// que `scr_cleanup_outdated_sprites` los borre) y luego llama a
// `scr_load_lang_sprites_only` para cargar los nuevos.
//
// Es idempotente: si no hay reload pendiente, no hace nada.

function scr_apply_pending_sprite_reload() //gml_Script_scr_apply_pending_sprite_reload
{
    if (!variable_global_exists("lang_sprites_pending"))
        exit;
    if (!global.lang_sprites_pending)
        exit;

    // Marcamos como aplicado *antes* de cargar sprites, para evitar
    // recursión: `add_sprite` no llama a `scr_get_sprite`, pero por
    // si algún script intermedio lo hace.
    global.lang_sprites_pending = false

    scr_load_lang_sprites_only()
}
