var jp = variable_global_exists("lang") && global.lang == "ja";
timer++;
var str;

//if (jp)
//{
//    if (timer < 10)
//        str = "ナ";
//    else if (alt)
//        str = "ナ           ガ ッ";
//    else
//        str = "ナ　ガ           イ";
//}

var phrases = get_chapter_lang_setting("jack_phrases", [
    ["YOUR", "       ", "    ", " LONG  "],
    ["  LO", "       ", "    ", " NG  "],
]);

var timings = get_chapter_lang_setting("jack_timings", [
    [0, 0, 30, 30],
    [0, 0, 5, 5]
]);

var ind = 0;
if (alt)
{
    str = stringsetloc("LO          NG", "obj_yourlong_slash_Draw_0_gml_20_0");
    var ind = 1;
}
else
{
    str = stringsetloc("YOUR          LONG", "obj_yourlong_slash_Draw_0_gml_22_0");
    var ind = 0;
}


var str = "";
var it = 0;
var str_max = "";

while (it < array_length(phrases[ind])) {
    if (timer >= timings[ind][it]) {
        str += phrases[ind][it];
    }
    str_max += phrases[ind][it];
    it++;
}

draw_set_alpha(1);
draw_set_color(c_white);

//if (jp)
//    draw_set_font(fnt_ja_mainbig);
//else

//draw_set_font(fnt_mainbig);
draw_set_font(scr_84_get_font("mainbig_mono"));

var t = 20;
var num = 1 + ((3 - jp) * (timer > (t - (25 * alt))));
var small = 1;
var step = (15 - (8 * small));

for (var pos = 1; pos <= ceil(string_length(str) / (1 + (timer < (t - (25 * alt))))); pos++)
    draw_text(x - (step * string_length(str_max) / 2) + irandom_range(-num, num) + (15 * pos) + (28 * alt), y + irandom_range(-num, num), string_char_at(str, pos));

if (timer > (55 - (30 * alt)))
    instance_destroy();
