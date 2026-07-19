function scr_textsetup(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7, argument8, argument9, argument10) //gml_Script_scr_textsetup
{
    myfont = argument0
    mycolor = argument1
    writingx = argument2
    writingy = argument3
    charline = argument4
    shake = argument5
    rate = argument6
    textsound = argument7
    hspace = argument8
    vspace = floor(floor(argument9 * get_lang_setting("line_height_factor", 1)))
    special = argument10
    colorchange = 1
    xcolor = mycolor
}

