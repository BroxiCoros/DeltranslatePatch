function scr_miniface_init_flowers()
{
    global.wide_pref_size = 2;
    var face_list = [scr_84_get_sprite("spr_miniface_aqua"), scr_84_get_sprite("spr_miniface_seth"), scr_84_get_sprite("spr_miniface_orange"), scr_84_get_sprite("spr_miniface_green"), scr_84_get_sprite("spr_miniface_yellow"), scr_84_get_sprite("spr_miniface_blue")];
    
    for (var i = 0; i < array_length(face_list); i++)
        global.writerimg[i] = face_list[i];
}
