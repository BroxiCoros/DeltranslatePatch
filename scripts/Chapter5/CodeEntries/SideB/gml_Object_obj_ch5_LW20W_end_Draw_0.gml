var cam = scr_getcam();

if (!surface_exists(mysurf))
    mysurf = surface_create(320, 240);

surface_set_target(mysurf);
draw_sprite_ext(spr_pxwhite, 0, 0, 0, 320, 240, 0, c_black, 1);

if (index >= 0)
{
    var _x = 104;
    var _y = 32;
    if (sprite_frames_num == 1) {
        draw_sprite(scr_84_get_sprite("spr_chapter_insert_prompt_letters"), 0, _x, _y);

        for (var i = index; i < blocksLength; i++)
        {
            with (blocks[i])
                draw_sprite_ext(spr_pxwhite, 0, x + _x, y + _y, w, h, 0, c_black, 1);
        }
    } else {
        draw_sprite(scr_84_get_sprite("spr_chapter_insert_prompt_letters"), index, _x, _y);
    }
}

surface_reset_target();

if (doshade)
{
    shader_replace_simple_set_hook(shader);
    shader_set_uniform_f(u_time, time);
    shader_set_uniform_f(u_aber, aberration);
}

draw_surface_ext(mysurf, cam.x, cam.y, 1, 1, 0, image_blend, 1);
shader_replace_simple_reset_hook();
