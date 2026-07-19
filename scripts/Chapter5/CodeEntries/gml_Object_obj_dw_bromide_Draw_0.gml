if (global.interact == 0)
    exit;

if (con < 0)
    exit;

if (_bromide_sprite == -4)
    exit;

draw_sprite(_bromide_sprite, 0, camerax(), _bromide_y);

if (_bromide_sprite == spr_bromide_r && global.lang != "en")
    draw_sprite(scr_84_get_sprite("spr_bromide_r_tag"), 0, camerax() + 263, _bromide_y + 791);
