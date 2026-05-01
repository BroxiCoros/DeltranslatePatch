function scr_credit(arg0, arg1, arg2 = 1) constructor
{
    header = arg0;
    text_line = arg1;
    columns = arg2;
}

function generate_credits()
{
    var credits = [];
    credits[0] = [
        new scr_credit([
            stringsetloc("-Main Artist-", "scr_credit_slash_scr_credit_gml_18_0"), 
            stringsetloc("-Main Animator-", "scr_credit_slash_scr_credit_gml_19_0")
        ], [
            stringsetloc("Temmie Chang", "scr_credit_slash_scr_credit_gml_20_0")
        ])
    ];
    credits[1] = [
        new scr_credit([
            stringsetloc("-Main Team-", "scr_credit_slash_scr_credit_gml_29_0")
        ], [
            stringsetloc("Sarah O'Donnell", "scr_credit_slash_scr_credit_gml_30_0"), 
            stringsetloc("Taxiderby", "scr_credit_slash_scr_credit_gml_31_0"), 
            stringsetloc("Fred Wood", "scr_credit_slash_scr_credit_gml_32_0"), 
            stringsetloc("Jean Canellas", "scr_credit_slash_scr_credit_gml_33_0"), 
            stringsetloc("AlexMdle", "scr_credit_slash_scr_credit_gml_34_0"), 
            stringsetloc("PureQuestion", "scr_credit_slash_scr_credit_gml_35_0"), 
            stringsetloc("Robert Sephazon (Producer)", "scr_credit_slash_scr_credit_gml_38_0")
        ])
    ];
    credits[2] = [
        new scr_credit([
            stringsetloc("-Main Team-", "scr_credit_slash_scr_credit_gml_44_0_b")
        ], [
			stringsetloc("Henri Beeres (Enjl)", "scr_credit_slash_scr_credit_gml_45_0"),
			stringsetloc("Joost (waddle)", "scr_credit_slash_scr_credit_gml_46_0"),
			stringsetloc("Sara Spalding (SaraJS)", "scr_credit_slash_scr_credit_gml_47_0"),
			stringsetloc("Robert Sephazon (Producer)", "scr_credit_slash_scr_credit_gml_48_0")
		]),
        new scr_credit([
			stringsetloc("Mike Maker (PC ver.)", "scr_credit_slash_scr_credit_gml_54_0_b")
		], [
			stringsetloc("Andy Brophy", "scr_credit_slash_scr_credit_gml_55_0")
		])
    ];
    credits[3] = [
		new scr_credit([
			stringsetloc("-BG, Costume, Titan Concept Art-", "scr_credit_slash_scr_credit_gml_56_0")
		], [
			stringsetloc("Gigi DG", "scr_credit_slash_scr_credit_gml_57_0")
		]),
			new scr_credit([
			stringsetloc("-Old Man's Theme Arrangement-", "scr_credit_slash_scr_credit_gml_71_0")
		], [
			stringsetloc("Alex Rosetti", "scr_credit_slash_scr_credit_gml_72_0")
		]),
			new scr_credit([
			stringsetloc("-Vocals (Sanctuary, Credits)-", "scr_credit_slash_scr_credit_gml_73_0")
		], [
			stringsetloc("Itoki Hana", "scr_credit_slash_scr_credit_gml_74_0")
		])
    ];
    credits[4] = [
		new scr_credit([
			stringsetloc("-Live Piano Editing-", "scr_credit_slash_scr_credit_gml_88_0")
		], [
			stringsetloc("Lena Raine", "scr_credit_slash_scr_credit_gml_89_0")
		]),
			new scr_credit([
			stringsetloc("-Titan Hand, Kris Piano Anim-", "scr_credit_slash_scr_credit_gml_90_0")
		], [
			stringsetloc("Smallbu Animation", "scr_credit_slash_scr_credit_gml_91_0")
		]),
			new scr_credit([
			stringsetloc("-Pixel Art Assistance-", "scr_credit_slash_scr_credit_gml_102_0")
		], [
			stringsetloc("Clairevoire", "scr_credit_slash_scr_credit_gml_103_0"),
			stringsetloc("Satoshi Maruyama", "scr_credit_slash_scr_credit_gml_104_0")
		])
    ];
    credits[5] = [
		new scr_credit([
			stringsetloc("-Additional FX-", "scr_credit_slash_scr_credit_gml_113_0")
		], [
			stringsetloc("James Begg", "scr_credit_slash_scr_credit_gml_114_0")
		]),
			new scr_credit([
			stringsetloc("-Additional Animation Assistance-", "scr_credit_slash_scr_credit_gml_120_0_b")
		], [
			stringsetloc("Mariel Kinuko Cartwright", "scr_credit_slash_scr_credit_gml_121_0")
		])
    ];
    credits[6] = [
		new scr_credit([
			stringsetloc("-Guest Character Design-", "scr_credit_slash_scr_credit_gml_64_0")
		], [
			stringsetloc("(Lancer, Rudinn, Hathy)", "scr_credit_slash_scr_credit_gml_67_0"),
			stringsetloc("(Clover, King, Jevil)", "scr_credit_slash_scr_credit_gml_68_0"),
			stringsetloc("Kanotynes", "scr_credit_slash_scr_credit_gml_69_0")
		]),
			new scr_credit([
			stringsetloc("-Ch. 2&3 Guest Character Design-", "scr_credit_slash_scr_credit_gml_146_0")
		], [
			stringsetloc("Samanthuel Gillson (splendidland)", "scr_credit_slash_scr_credit_gml_147_0"),
			stringsetloc("NELNAL", "scr_credit_slash_scr_credit_gml_148_0")
		])
    ];
    credits[7] = [
		new scr_credit([
			stringsetloc("-3D Assets, Anim, Posing-", "scr_credit_slash_scr_credit_gml_129_0")
		], [
			stringsetloc("Chelsea Saunders (pixelatedcrown)", "scr_credit_slash_scr_credit_gml_130_0")
		]),
			new scr_credit([
			stringsetloc("-Development Tools (Cool)-", "scr_credit_slash_scr_credit_gml_164_0")
		], [
			stringsetloc("Juju Adams", "scr_credit_slash_scr_credit_gml_165_0")
		]),
			new scr_credit([
			stringsetloc("-UT Character Design-", "scr_credit_slash_scr_credit_gml_171_0")
		], [
			stringsetloc("Betty Kwong (Temmie)", "scr_credit_slash_scr_credit_gml_172_0"),
			stringsetloc("Magnolia Porter (Snowdrake, Monster Kid)", "scr_credit_slash_scr_credit_gml_173_0")
		])
    ];

    var translators_credits = get_chapter_lang_setting("translators_credits", json_parse("[[{\"header\": [\"-Japanese Localization-\"],\"text_line\": [\"8-4, Ltd.\"],\"columns\": 1},{\"header\": [\"-Translator-\"],\"text_line\": [\"Keiko Fukuichi\"],\"columns\": 1}],[{\"header\": [\"-Localization Producers-\"],\"text_line\": [\"Tina Carter\", \"John Ricciardi\"],\"columns\": 1},{\"header\": [\"-Localization Support-\"],\"text_line\": [\"Hiroyuki Matsushita\", \"Yutaka Ohbuchi\", \"Sami Ragone\", \"Alissa Staples\", \"JP Wentz\"],\"columns\": 1}]]"))
    // TODO: rellenar con creditos del traductor (lista localizada)
    credits[8] = translators_credits[0];
    credits[9] = translators_credits[1];


    credits[10] = [
        new scr_credit([
            stringsetloc("-Platform Programming-", "scr_credit_slash_scr_credit_gml_207_0")
        ], [
            stringsetloc("Sarah O'Donnell", "scr_credit_slash_scr_credit_gml_208_0"), 
            stringsetloc("Henri Beeres (Enjl)", "scr_credit_slash_scr_credit_gml_209_0")
        ]), 
        new scr_credit([
            stringsetloc("-Programming Support-", "scr_credit_slash_scr_credit_gml_214_0")
        ], [
            stringsetloc("Gregg Tavares", "scr_credit_slash_scr_credit_gml_215_0")
        ]), 
        new scr_credit([
            stringsetloc("-Japanese Graphics-", "scr_credit_slash_scr_credit_gml_221_0")
        ], [
            stringsetloc("256graph", "scr_credit_slash_scr_credit_gml_222_0"), 
            stringsetloc("Satoshi Maruyama", "scr_credit_slash_scr_credit_gml_223_0")
        ])
    ];
    credits[11] = [
        new scr_credit([
            stringsetloc("-QA-", "scr_credit_slash_scr_credit_gml_231_0"), 
            stringsetloc("DIGITAL HEARTS Co., Ltd.", "scr_credit_slash_scr_credit_gml_234_0")
        ], [
            stringsetloc("Yoshikazu Hironaka", "scr_credit_slash_scr_credit_gml_235_0"), 
            stringsetloc("Riku Shimizu", "scr_credit_slash_scr_credit_gml_236_0"), 
            stringsetloc("Akira Ishiki", "scr_credit_slash_scr_credit_gml_237_0"), 
            stringsetloc("Hidemi Miyauchi", "scr_credit_slash_scr_credit_gml_238_0"), 
            stringsetloc("Kazutaka Kawahara", "scr_credit_slash_scr_credit_gml_239_0"), 
            stringsetloc("Yuta Nishimura", "scr_credit_slash_scr_credit_gml_240_0"), 
            stringsetloc("Daisuke Nakaie", "scr_credit_slash_scr_credit_gml_241_0"), 
            stringsetloc("Shinji Yasue", "scr_credit_slash_scr_credit_gml_242_0"), 
            stringsetloc("Taishi Mukaigawara", "scr_credit_slash_scr_credit_gml_243_0"), 
            stringsetloc("Hiromasa Tokida", "scr_credit_slash_scr_credit_gml_244_0"), 
            stringsetloc("Yuki Takeuchi", "scr_credit_slash_scr_credit_gml_245_0"), 
            stringsetloc("Yu Takamori", "scr_credit_slash_scr_credit_gml_246_0"), 
            stringsetloc("Yuta Doi", "scr_credit_slash_scr_credit_gml_247_0"), 
            stringsetloc("Yuki Wada", "scr_credit_slash_scr_credit_gml_248_0"), 
            stringsetloc("Satoru Watanuki", "scr_credit_slash_scr_credit_gml_249_0"), 
            stringsetloc("Monami Katayama", "scr_credit_slash_scr_credit_gml_250_0")
        ], 2)
    ];
    credits[12] = [
        new scr_credit([
            stringsetloc("-Super Testers-", "scr_credit_slash_scr_credit_gml_251_0")
        ], [
            stringsetloc("DruidVorse", "scr_credit_slash_scr_credit_gml_252_0")
        ]), 
        new scr_credit([
            stringsetloc("-Website-", "scr_credit_slash_scr_credit_gml_253_0")
        ], [
            stringsetloc("Brian Coia", "scr_credit_slash_scr_credit_gml_254_0")
        ])
    ];
    credits[13] = [
		new scr_credit([
			stringsetloc("-Fangamer Testing-", "scr_credit_slash_scr_credit_gml_263_0")
		], [
			stringsetloc("Chris Warriner", "scr_credit_slash_scr_credit_gml_264_0"),
			stringsetloc("Ryan Alyea", "scr_credit_slash_scr_credit_gml_265_0"),
			stringsetloc("Alexandro Arvizu", "scr_credit_slash_scr_credit_gml_266_0"),
			stringsetloc("Dan Moore", "scr_credit_slash_scr_credit_gml_267_0"),
			stringsetloc("Jack Murphy", "scr_credit_slash_scr_credit_gml_268_0"),
			stringsetloc("heavenchai", "scr_credit_slash_scr_credit_gml_269_0"),
			stringsetloc("Charlie Verdin", "scr_credit_slash_scr_credit_gml_270_0"),
			stringsetloc("Steven Thompson", "scr_credit_slash_scr_credit_gml_271_0")
		], 2),
			new scr_credit([
			stringsetloc("-Trailers & All Video Editing-", "scr_credit_slash_scr_credit_gml_277_0")
		], [
			stringsetloc("Everdraed", "scr_credit_slash_scr_credit_gml_278_0")
		])
    ];
    credits[14] = [
        new scr_credit([
            stringsetloc("-Special Thanks-", "scr_credit_slash_scr_credit_gml_281_0")
        ], [
            stringsetloc("Hiroko Minamoto", "scr_credit_slash_scr_credit_gml_288_0"), 
            stringsetloc("Graeme Howard", "scr_credit_slash_scr_credit_gml_289_0"), 
            stringsetloc("Yutaka Sato (Happy Ruika)", "scr_credit_slash_scr_credit_gml_290_0"), 
            stringsetloc("All 8-4 & Fangamer Staff", "scr_credit_slash_scr_credit_gml_293_0"), 
            stringsetloc("Claire & Andrew", "scr_credit_slash_scr_credit_gml_294_0"), 
            stringsetloc("Brian Lee", "scr_credit_slash_scr_credit_gml_295_0"), 
            stringsetloc("YoYo Games", "scr_credit_slash_scr_credit_gml_296_0")
        ])
    ];
    return credits;
}
