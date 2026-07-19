function scr_item_localized_name_inst(argument0, argument1, argument2) //gml_Script_scr_item_localized_name_inst
{
    var item = argument0

    // Персонажи
    if (argument1 == 0 || argument1 == "char")
    switch (item) {

        case 0:
            return " ";

        case 1:
            return stringsetloc(stringsetloc("Aqua", "obj_dw_fcastle_cafe_slash_Create_0_gml_169_0"), "obj_dw_fcastle_cafe_slash_Create_0_gml_169_1");

        case 2:
            return stringsetloc(stringsetloc("Seth", "obj_dw_fcastle_cafe_slash_Create_0_gml_170_0"), "obj_dw_fcastle_cafe_slash_Create_0_gml_170_1");

        case 3:
            return stringsetloc(stringsetloc("Yellow", "obj_dw_fcastle_cafe_slash_Create_0_gml_171_0"), "obj_dw_fcastle_cafe_slash_Create_0_gml_171_1");

        case 4:
            return stringsetloc(stringsetloc("Green", "obj_dw_fcastle_cafe_slash_Create_0_gml_172_0"), "obj_dw_fcastle_cafe_slash_Create_0_gml_172_1");

        case 5:
            return stringsetloc(stringsetloc("Blue", "obj_dw_fcastle_cafe_slash_Create_0_gml_173_0"), "obj_dw_fcastle_cafe_slash_Create_0_gml_173_1");

        case 6:
            return stringsetloc(stringsetloc("Orange", "obj_dw_fcastle_cafe_slash_Create_0_gml_174_0"), "obj_dw_fcastle_cafe_slash_Create_0_gml_174_1");

        case 7:
            return stringsetloc(stringsetloc("Pink", "obj_dw_fcastle_cafe_slash_Create_0_gml_177_0"), "obj_dw_fcastle_cafe_slash_Create_0_gml_177_1");

    }

    if (argument2 != undefined)
        return argument2
    return item
}