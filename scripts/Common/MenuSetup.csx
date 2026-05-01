// =====================================================================
// MenuSetup.csx
// =====================================================================
// Configura los game objects que dan vida al sistema de localizacion en
// runtime:
//
//   1. obj_lang_settings: objeto del menu de configuracion de idioma. Se
//      crea con events vacios; los CodeEntries/*.gml correspondientes
//      sobrescriben esos events en la fase de aplicacion (CodeChangesParser).
//
//   2. obj_gamecontroller: el controlador principal del juego. Se le marca
//      Visible = true (modo translator) y se le anaden hooks en eventos
//      DrawGUI, Step, AsyncHTTP, DrawEnd y RoomEnd, igualmente vacios. Los
//      CodeEntries los rellenan despues con la logica del modo translator,
//      lazy reload, etc.
//
// Este modulo depende de Helpers.csx (AddNewEvent, ReplaceGML).
// =====================================================================

using System.IO;
using UndertaleModLib.Models;

// ---- obj_lang_settings ----
var obj_lang_settings = Data.GameObjects.ByName("obj_lang_settings");
if (obj_lang_settings == null) {
    obj_lang_settings = new UndertaleGameObject();
    obj_lang_settings.Name = Data.Strings.MakeString("obj_lang_settings");
    Data.GameObjects.Add(obj_lang_settings);
    AddNewEvent(obj_lang_settings, EventType.Create, 0, "");
    AddNewEvent(obj_lang_settings, EventType.Step, 0, "");
    AddNewEvent(obj_lang_settings, EventType.Draw, 0, "");
    AddNewEvent(obj_lang_settings, EventType.Draw, 0, "");
    if (File.Exists(scriptFolder + "CodeEntries/gml_Object_obj_lang_settings_Other_62.gml"))
        AddNewEvent(obj_lang_settings, EventType.Other, (uint)EventSubtypeOther.AsyncHTTP, @"");
}

// ---- obj_gamecontroller (modo translator) ----
Data.GameObjects.ByName("obj_gamecontroller").Visible = true;

AddNewEvent("obj_gamecontroller", EventType.Draw, (uint)EventSubtypeDraw.DrawGUI, "");
AddNewEvent("obj_gamecontroller", EventType.Step, (uint)EventSubtypeStep.Step, "");
AddNewEvent("obj_gamecontroller", EventType.Other, (uint)EventSubtypeOther.AsyncHTTP, @"");
AddNewEvent("obj_gamecontroller", EventType.Draw, (uint)EventSubtypeDraw.DrawEnd, @"");
AddNewEvent("obj_gamecontroller", EventType.Other, (uint)EventSubtypeOther.RoomEnd, @"");
