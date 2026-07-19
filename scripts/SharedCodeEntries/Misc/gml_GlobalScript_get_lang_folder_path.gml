function get_lang_folder_path(arg0)
{
    if (!is_undefined(arg0))
        return global.lang_folder + arg0 + "/"
        
    return global.lang_folder
}

