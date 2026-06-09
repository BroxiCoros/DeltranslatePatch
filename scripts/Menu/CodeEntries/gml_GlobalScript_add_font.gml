function add_font(argument0, argument1) //gml_Script_add_font
{
    var fnt_name = argument0
    var fnt_size = argument1
    var fonts_range = get_lang_setting("fonts_range", [32, 128])
    var path = get_lang_folder_path() + "fonts/"
    var filename_ttf = ((path + fnt_name) + ".ttf")
    var filename_otf = ((path + fnt_name) + ".otf")
    var font = asset_get_index(fnt_name)
    if file_exists(filename_ttf)
        font = font_add(filename_ttf, fnt_size, font_get_bold(font), font_get_italic(font), fonts_range[0], fonts_range[1])
    else if file_exists(filename_otf)
        font = font_add(filename_otf, fnt_size, font_get_bold(font), font_get_italic(font), fonts_range[0], fonts_range[1])
    else if ((asset_get_index(fnt_name + "_" + global.lang)) != -1)
        font = asset_get_index(fnt_name + "_" + global.lang) 
    ds_map_add(global.font_map, fnt_name, font)
}

