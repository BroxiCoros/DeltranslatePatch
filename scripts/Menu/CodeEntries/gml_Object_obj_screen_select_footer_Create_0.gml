_init = false;
_parent = -4;
_input_enabled = false;
_choices = [];
_choice_index = 0;
_grid_display = -4;
_alpha = 0;
_fade_in = false;

init = function(arg0)
{
    _parent = arg0;
    // Mismo caso que el "Quit" de abajo: en idioma nativo no hay pack, asi que
    // `scr_get_lang_string` devolveria el literal ingles. Este "Config" es
    // etiqueta del fork y no existe en vanilla (ahi el boton dice
    // "日本語"/"English" porque es el interruptor de idioma), asi que el japones
    // va escrito a mano.
    var language_text = is_native_lang()
        ? ((global.lang == "en") ? "Config" : "設定")
        : scr_get_lang_string("Config", "gml_Object_obj_screen_select_footer_Create_0_0");
    var language_choice = instance_create(x + 260, y + 24, obj_ui_choice);
    language_choice.init(id, language_text, UnknownEnum.Value_5);
    language_choice.set_alpha(0);
    language_choice.y -= 40;
    _choices = [language_choice];
    
    if (!global.is_console)
    {
        // Este objeto no puede correr su gemelo vanilla: es de donde cuelga el
        // selector de idiomas del fork (en vanilla ahi solo hay un interruptor
        // en<->ja). Y como en idioma nativo no hay pack que consultar,
        // `scr_get_lang_string` devolveria el literal ingles. Asi que este
        // texto se lleva los dos idiomas del juego consigo, copiados de su
        // vanilla. Regla general: lo que por necesidad no puede delegar en el
        // gemelo, tiene que traer los idiomas nativos incorporados.
        var quit_text = is_native_lang()
            ? ((global.lang == "en") ? "Quit" : "終了")
            : scr_get_lang_string("Quit", "gml_Object_obj_screen_select_footer_Create_0_1");
        var quit_choice = instance_create(x + 180, y + 24, obj_ui_choice);
        quit_choice.init(id, quit_text, UnknownEnum.Value_4);
        quit_choice.set_alpha(0);
        quit_choice.y -= 40;
        language_choice.x = quit_choice.x + 140;
        _choices = [quit_choice, language_choice];
    }
    
    var version_display = instance_create(x, y, obj_ui_version);
    version_display.set_screen_state(UnknownEnum.Value_4);
    _grid_display = instance_create(x + 584, y + 26, obj_ui_grid);
    _init = true;
};

fade_in = function()
{
    _fade_in = true;
    
    if (_grid_display != -4)
        _grid_display.fade_in();
};

reset = function()
{
    _choice_index = 0;
    
    for (var i = 0; i < array_length(_choices); i++)
    {
        var choice = _choices[i];
        choice.reset();
    }
};

highlight = function()
{
    for (var i = 0; i < array_length(_choices); i++)
    {
        var choice = _choices[i];
        choice.reset();
        
        if (i == _choice_index)
            choice.highlight();
    }
};

enable_input = function()
{
    _input_enabled = true;
};

disable_input = function()
{
    _input_enabled = false;
    
    for (var i = 0; i < array_length(_choices); i++)
    {
        var choice = _choices[i];
        choice.disable_input();
    }
};

trigger_event = function(arg0, arg1)
{
    if (obj_gamecontroller.loading_new_translation_files) {
        audio_play_sound(snd_swing, 50, 0)
        return;
    }
        
    switch (arg1)
    {
        case UnknownEnum.Value_4:
            disable_input();
            _parent.trigger_event(arg0, arg1);
            break;
        
        case UnknownEnum.Value_5:
            disable_input();

            // Este es el boton de "Config". Normalmente sube por
            // `obj_screen_select` hasta el `trigger_event` de
            // `obj_CHAPTER_SELECT`, cuyo `toggle_language()` el mod
            // redefine para abrir el selector del fork.
            //
            // Cuando `obj_CHAPTER_SELECT` llevaba gemelo vanilla, en idioma
            // nativo corria su `toggle_language()` original -el interruptor
            // en<->ja-, asi que el boton decia "Config" y hacia otra cosa, sin
            // forma de volver a un pack. Por eso se abre el selector aqui
            // directamente, que este objeto si esta en la lista negra.
            //
            // Hoy `obj_CHAPTER_SELECT` tambien esta en la lista negra (por la
            // opcion de "Language" de sus avisos), asi que la rama de abajo
            // funcionaria igual. Se deja porque no depende de esa decision.
            if (is_native_lang())
                instance_create_depth(0, 0, 0, asset_get_index("obj_lang_settings"));
            else
                _parent.trigger_event(arg0, arg1);

            break;
    }
};

enum UnknownEnum
{
    Value_4 = 4,
    Value_5
}
