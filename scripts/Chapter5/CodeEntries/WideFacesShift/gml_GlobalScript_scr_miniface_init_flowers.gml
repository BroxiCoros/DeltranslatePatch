function scr_miniface_init_flowers()
{
    global.wide_pref_size = 2;
    var face_list = [4883, 2166, 3293, 2554, 4857, 1689];
    
    for (var i = 0; i < array_length(face_list); i++)
        global.writerimg[i] = face_list[i];
}
