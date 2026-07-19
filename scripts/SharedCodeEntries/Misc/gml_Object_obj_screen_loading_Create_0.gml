_target_chapter = -1;
_init = false;
_callback = -4;
_initialize_text = "";
_y_offset = -16;
_font = fnt_mainbig;

show_loading_screen = function(arg0, arg1)
{
    _target_chapter = arg0;
    _callback = arg1;
    _initialize_text = get_text(_target_chapter);
    _font = get_font();
    _init = true;
    alarm[0] = 1;
};

get_text = function(arg0)
{
    var _text = stringsetsubloc("INITIALIZING\nCHAPTER ~1", string(arg0), "obj_screen_loading_slash_Create_0_gml_1_0");

    if (arg0 == 0)
    {
        _text = stringsetloc("LOADING\nCHAPTER\nSELECT", "obj_screen_loading_slash_Create_0_gml_2_0");
    }

    return _text;
};

get_font = function()
{
    if (room == room_chapter_continue)
        return scr_84_get_font("mainbig");
    else
        return scr_84_get_font("main");
};
