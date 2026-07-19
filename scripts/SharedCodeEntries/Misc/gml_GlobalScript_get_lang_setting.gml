function get_lang_setting(argument0, argument1) //gml_Script_get_lang_setting
{
    var val = variable_struct_get(global.lang_settings, argument0)
    if (is_undefined(val))
        return argument1
    return val
}

