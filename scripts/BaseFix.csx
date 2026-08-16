using UndertaleModLib.Util;
using System.Text.Json;
using System.Linq;
using System.Text;
using System.IO;
using System;
using System.Threading;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

#region Вспомогательные функции

string gameFolder = Path.GetDirectoryName(FilePath) + Path.DirectorySeparatorChar;
string scriptFolder = Path.GetDirectoryName(ScriptPath) + Path.DirectorySeparatorChar;

var globalDecompileContext = new GlobalDecompileContext(Data);
var decompilerSettings = Data.ToolInfo.DecompilerSettings;

#region Обратная совместимость с UndertaleModLib 0.8

Version utmLibVer = System.Reflection.Assembly.GetAssembly(typeof(UndertaleData)).GetName().Version;
bool isUTMLibDot8 = utmLibVer < new Version(0, 9, 0, 0);
object globalsInst = ((Action)IncrementProgress).Target;
Type globalsType = globalsInst.GetType();

Action<Action> ExecuteInUIThread;
if (isUTMLibDot8)
{
    void DummyAction(Action act)
    {
        act();
    }
    ExecuteInUIThread = DummyAction;

    // Если нужно было бы часто/много раз это выполнять, то нужно использовать `Delegate.CreateDelegate()`
    void syncBinding(string resType, bool enable)
    {
        globalsType.GetMethod("SyncBinding").Invoke(globalsInst, [resType, enable]);
    }
    syncBinding("Strings, Code, CodeLocals, Scripts, GlobalInitScripts, GameObjects, Functions, Variables", true);
}
else
{
    var mainThreadAct = globalsType.GetProperty("MainThreadAction")?.GetValue(globalsInst) as Action<Action>;
    ExecuteInUIThread = mainThreadAct;
}

#endregion

var changedCodes = new Dictionary<string, string>();

void CreateBlankFunction(string funcName)
{
    UndertaleCode code = Data.Code.ByName("gml_GlobalScript_" + funcName);
    if (code == null)
    {
        code = new UndertaleCode();
        code.Name = Data.Strings.MakeString("gml_GlobalScript_" + funcName);
        code.ArgumentsCount = (ushort)0;
        code.LocalsCount = (uint)0;

        Data.Code.Add(code);

        UndertaleScript scr = new UndertaleScript();
        scr.Name = Data.Strings.MakeString(funcName);
        scr.Code = code;
        Data.Scripts.Add(scr);

        UndertaleGlobalInit ginit = new UndertaleGlobalInit();
        ginit.Code = code;
        Data.GlobalInitScripts.Add(ginit);

        // // code.ReplaceGML(funcCodeGML, Data);
        // // code.ReplaceGML($"function {funcName}() //gml_Script_{funcName}\n{{}}", Data);
        ReplaceGML(code, $"function {funcName}() //gml_Script_{funcName}\n{{}}");
    }
}

bool ReplaceGML(UndertaleCode code, string text)
{
    // ScriptMessage(code.Name.Content);
    changedCodes[code.Name.Content] = text;
    // CompileGroup group = new(Data);
    // group.QueueCodeReplace(code, text);
    // CompileResult result = group.Compile();

    // if (!result.Successful)
    // {
    //     File.WriteAllText(Path.Combine(scriptFolder, "test.txt"), text);
    //     ScriptMessage("Ошибка при компиляции кода '" + code.Name.Content + "'");
    //     return false;
    // }
    return true;
}

bool ReplaceGML(string codeName, string text)
{
    return ReplaceGML(Data.Code.ByName(codeName), text);
}

bool ReplacePart(UndertaleCode code, List<(string, string)> changes, bool matchWordsBounds = false)
{
    var text = Decompile(code);
    foreach (var pair in changes)
    {
        Regex rx = new Regex(string.Format(@"(?<!""){0}(?!"")", pair.Item1));
        if (matchWordsBounds)
        {
            rx = new Regex(string.Format(@"(?<!"")\b{0}\b(?!"")", pair.Item1));
        }

        if (!rx.IsMatch(text))
        {
            Regex rx_test = new Regex(string.Format(@"{0}", pair.Item1));
            if (matchWordsBounds)
            {
                rx_test = new Regex(string.Format(@"\b{0}\b", pair.Item1));
            }
            if (!rx_test.IsMatch(text)) {
                return false;
            }
        }
        text = rx.Replace(text, pair.Item2);
    }
    
    return ReplaceGML(code, text);
}

bool ReplacePart(UndertaleCode code, string from, string to, bool matchWordsBounds = false)
{
    return ReplacePart(code, new List<(string, string)>() { (from, to) }, matchWordsBounds);
}

bool ReplacePart(string codeName, List<(string, string)> changes, bool matchWordsBounds = false)
{
    return ReplacePart(Data.Code.ByName(codeName), changes, matchWordsBounds);
}

bool ReplacePart(string codeName, string from, string to, bool matchWordsBounds = false)
{
    return ReplacePart(Data.Code.ByName(codeName), from, to, matchWordsBounds);
}

bool AppendToStart(UndertaleCode code, string append)
{
    var text = Decompile(code);
    return ReplaceGML(code, append + "\n" + text);
}

bool AppendToStart(string codeName, string append)
{
    return AppendToStart(Data.Code.ByName(codeName), append);
}

bool AppendToEnd(UndertaleCode code, string append)
{
    var text = Decompile(code);
    return ReplaceGML(code, text + "\n" + append);
}

bool AppendToEnd(string codeName, string append)
{
    return AppendToStart(Data.Code.ByName(codeName), append);
}

void AddNewEvent(UndertaleGameObject obj, EventType evType, uint evSubtype, string codeGML)
{
    UndertaleCode evHandler = null;
    ExecuteInUIThread(() =>
    {
        evHandler = obj.EventHandlerFor(evType, evSubtype, Data); 
    });

    ReplaceGML(evHandler, codeGML);
}

void AddNewEvent(string objName, EventType evType, uint evSubtype, string codeGML)
{
    AddNewEvent(Data.GameObjects.ByName(objName), evType, evSubtype, codeGML);
}

List<string> backedList = new List<string>();

string Decompile(UndertaleCode code)
{
    try
    {
        if (changedCodes.ContainsKey(code.Name.Content))
            return changedCodes[code.Name.Content];

        return new Underanalyzer.Decompiler.DecompileContext(globalDecompileContext, code, decompilerSettings).DecompileToString();
    } catch (Exception e) {
        throw new Exception(string.Format("Ошибка при декомпиляции кода \"{0}\". Если у вас старая версия игры, скачайте новейшую версию. \nЕсли же и так новейшая, то сообщите разработчикам о ошибке.", code.Name.Content));
    }
}

string Decompile(string code)
{
    return Decompile(Data.Code.ByName(code));
}

bool GetOrig(string codeName)
{
    if (backedList.Contains(codeName))
        return true;

    var code = Data.Code.ByName(codeName);
    var oldCode = Data.Code.ByName(codeName + "_old");

    if (code == null)
    {
        ScriptMessage(string.Format("Отсутствует такой кусок кода как \"{0}\". Это скорее всего связано со старой версией игры. Из-за этого могут возникнуть ошибки. А могут и не возникнуть.", codeName));
        // throw new Exception(string.Format("Отсутствует такой кусок кода как \"{0}\". Почему?", codeName));
        return false;
    }

    if (oldCode == null)
    {
        ExecuteInUIThread(() =>
        {
            oldCode = new UndertaleCode();
            oldCode.Name = Data.Strings.MakeString(codeName + "_old");
            Data.Code.Add(oldCode);
        });
    }

    var oldText = Decompile(oldCode);
    if (oldText == "")
    {
        ReplaceGML(oldCode, "var code = \"" + Decompile(code).Replace("\\", "\\\\").Replace("\\n", "\\_n").Replace("\n", "\\n").Replace("\"", "\\\"") + "\";\n");
        oldText = changedCodes[oldCode.Name.Content];
    }
    
    if (oldText != "")
    {
        // ScriptMessage(oldText);
        try
        {
            oldText = oldText.Substring(12);
        }
        catch (Exception err)
        {
            ScriptMessage("Ошибка при декомпиляции кода '" + codeName + "'. Вероятнее всего вы пытаетесь запустить скрипт на старых версиях игры (например, демо-версии).");
            throw new Exception("Ошибка при декомпиляции кода '" + codeName + "'. Вероятнее всего вы пытаетесь запустить скрипт на старых версиях игры (например, демо-версии).");
        }
        // ScriptMessage(oldCode.Name.Content);
        // ScriptMessage(oldText);
        oldText = oldText.Remove(oldText.Length - 3).Replace("\\n", "\n").Replace("\\\"", "\"").Replace("\\_n", "\\n").Replace("\\\\", "\\");
        ReplaceGML(code, oldText);
    }

    backedList.Add(codeName);

    return true;
}

void GetOrigSprite(string spriteName)
{
    // if (Data.Sprites.ByName(spriteName + "_old") == null)
    // {
    //     ExecuteInUIThread(() =>
    //     {
    //         var new_spr = new UndertaleSprite();
    //         Data.Sprites.Add(new_spr);
    //     });
    //     
    // }

    // var code = Data.Code.ByName(codeName);
    // var oldCode = Data.Code.ByName(codeName + "_old");

    // if (oldCode == null)
    // {
    //     ExecuteInUIThread(() =>
    //     {
    //         oldCode = new UndertaleCode();
    //         oldCode.Name = Data.Strings.MakeString(codeName + "_old");
    //         if (ReplaceGML(oldCode, "var code = \"" + Decompile(code).Replace("\\", "\\\\").Replace("\\n", "\\_n").Replace("\n", "\\n").Replace("\"", "\\\"") + "\""))
    //         {
    //             Data.Code.Add(oldCode);
    //         }
    //     });
    // }

    // var oldText = Decompile(oldCode).Substring(12);
    // oldText = oldText.Remove(oldText.Length - 3).Replace("\\n", "\n").Replace("\\\"", "\"").Replace("\\_n", "\\n").Replace("\\\\", "\\");
    // ReplaceGML(code, oldText);

    // backedList.Add(codeName);
}

UndertaleCode AddCreationCodeEntryForInstance(UndertaleRoom.GameObject inst) {
    UndertaleCode code = inst.PreCreateCode;
    if (code == null) {
        ExecuteInUIThread(() =>
        {
            var name = Data.Strings.MakeString("gml_Instance_" + inst.InstanceID.ToString());
            code = new UndertaleCode()
            {
                Name = name,
                LocalsCount = 1
            };
            Data.Code.Add(code);

            UndertaleCodeLocals.LocalVar argsLocal = new UndertaleCodeLocals.LocalVar();
            argsLocal.Name = Data.Strings.MakeString("arguments");
            argsLocal.Index = 0;

            var locals = new UndertaleCodeLocals()
            {
                Name = name
            };
            locals.Locals.Add(argsLocal);
            Data.CodeLocals.Add(locals);
        });
    }

    return code;
}

async Task SaveEntries()
{
    maxCount = 1;
    await Task.Run(() =>
    {
        SetProgressBar(null, "Final compiling", 0, maxCount);

        CompileGroup group = new(Data)
        {
            MainThreadAction = ExecuteInUIThread
        };

        foreach (var c in changedCodes)
        {
            var codeName = c.Key;
            var text = c.Value;
            var code = Data.Code.ByName(codeName);

            group.QueueCodeReplace(code, text);
        }
        
        CompileResult result = group.Compile();

        if (!result.Successful)
        {
            ScriptMessage("Ошибка при компиляции:\n" + result.PrintAllErrors(true));
            // File.WriteAllText(Path.Combine(scriptFolder, "test.txt"), changedCodes["gml_Object_obj_lanino_rematch_enemy_Step_0"]);
            // ScriptMessage("Ошибка при компиляции кода '" + code.Name.Content + "'");
        }

        IncrementProgress();
        UpdateProgressValue(GetProgress());
        // foreach (var c in changedCodes)
        // {
        //     var codeName = c.Key;
        //     var text = c.Value;
        //     var code = Data.Code.ByName(codeName);
        //     CompileGroup group = new(Data)
        //     {
        //         ExecuteInUIThread = ExecuteInUIThread
        //     };
        //     group.QueueCodeReplace(code, text);
        //     CompileResult result = group.Compile();

        //     if (!result.Successful)
        //     {
        //         File.WriteAllText(Path.Combine(scriptFolder, "test.txt"), text);
        //         ScriptMessage("Ошибка при компиляции кода '" + code.Name.Content + "'");
        //     }

        //     IncrementProgress();
        //     UpdateProgressValue(GetProgress());
        // }
    });
}

#endregion

#region Добавление менюшки настроек и правка контроллера

// Менюшка настроек
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

// Режим переводчика
Data.GameObjects.ByName("obj_gamecontroller").Visible = true;

AddNewEvent("obj_gamecontroller", EventType.Draw, (uint)EventSubtypeDraw.DrawGUI, "");
AddNewEvent("obj_gamecontroller", EventType.Step, (uint)EventSubtypeStep.Step, "");
AddNewEvent("obj_gamecontroller", EventType.Other, (uint)EventSubtypeOther.AsyncHTTP, @"");
AddNewEvent("obj_gamecontroller", EventType.Draw, (uint)EventSubtypeDraw.DrawEnd, @"");
AddNewEvent("obj_gamecontroller", EventType.Other, (uint)EventSubtypeOther.RoomEnd, @"");

int maxCount = 0;

#endregion

#region Считывание кусков кода
var codeEntrs = new List<(string, string)>();
void IterateOverCodeEntries(string curPath)
{
    foreach (string fileName in Directory.GetFiles(curPath, "*", SearchOption.AllDirectories))
    {
        if (!fileName.EndsWith(".gml"))
            continue;
        var codeName = Path.GetFileNameWithoutExtension(fileName);
        codeEntrs.Add((codeName, File.ReadAllText(fileName)));
        if (codeName.Contains("GlobalScript") && Data.Code.ByName(codeName) == null)
        {
            CreateBlankFunction(codeName.Substring(17));
        }
    }        
}

// Дичайший костыль
if (!ScriptPath.Contains("Menu")) {
    IterateOverCodeEntries(scriptFolder + "../SharedCodeEntries");
}

IterateOverCodeEntries(scriptFolder + "CodeEntries");

#endregion

#region Gemelos vanilla para los idiomas nativos

// ============================================================================
// GEMELO VANILLA
// ============================================================================
// El mod reemplaza entradas de codigo ENTERAS por versiones reescritas para
// texto traducido: normalizan posiciones, meten escalados para que quepan las
// etiquetas largas y, de paso, pierden los ajustes por idioma de vanilla
// (`langopt(en, ja)` y `if (global.lang == "ja")`). Medido contra el volcado del
// juego: 164 ajustes perdidos en 40 entradas, el 62% en el
// `obj_darkcontroller_Draw_0` de cada capitulo.
//
// Con un pack de idioma eso da igual (la maquetacion es la del mod y es
// coherente), pero con un idioma NATIVO se nota: el jugador espera el juego de
// Toby y ve la maquetacion del mod.
//
// En vez de perseguir cada defecto a mano, aqui se guarda el codigo VANILLA de
// la entrada como funcion (`scr_native_<entrada>`) y se antepone a la version
// del mod un desvio:
//
//     if (is_native_lang()) { scr_native_<entrada>(); exit; }
//
// Asi, en idioma nativo el juego ejecuta literalmente el codigo original. La
// paridad es por construccion, no por parches, y se regenera sola en cada
// actualizacion del juego porque el gemelo sale del data.win nuevo.
//
// Funciona porque `GetOrig()` ya restaura el codigo original en la entrada
// antes de que el mod la pise (es lo que hace idempotente al patcher), asi que
// decompilar justo despues devuelve vanilla.
//
// El codigo de un evento se comporta igual llamado como funcion: `self` sigue
// siendo la instancia que lo llama y `exit` retorna de la funcion.
//
// LIMITES:
//   - Solo eventos de objeto (`gml_Object_*`). Los scripts tendrian que
//     replicar ademas la firma de argumentos; quedan para otra iteracion.
//   - Solo entradas cuyo vanilla tenga logica por idioma: en el resto el gemelo
//     no aporta nada y solo engordaria el data.win.
//   - Lista negra: entradas que sostienen funciones PROPIAS del fork; con
//     gemelo, en idioma nativo esa funcion desapareceria. La critica es
//     DEVICE_MENU_*, desde donde se abre el menu de idioma: sin ella te
//     quedarias en japones sin forma de volver al español.
//   - En idioma nativo el `obj_darkcontroller` corre vanilla, asi que NO sale
//     la fila del borde que añade Borders.csx. Es asumible: ese ajuste se
//     cambia desde un idioma con pack y se sigue respetando (el borde en si
//     sigue dibujandose: lo llevan `obj_time` y `obj_border_controller`, que
//     estan en la lista negra y por tanto no tienen gemelo).
//
//     NO parchear el gemelo desde `Borders.csx` para intentar recuperar esa
//     fila. Se probo y sale mal: los parches de UNA linea son iguales en
//     vanilla y en el codigo del mod, asi que casan contra el gemelo, pero los
//     bloques MULTILINEA estan escritos contra el texto del mod y no casan. El
//     gemelo queda a medio parchear, que es peor que las dos opciones puras:
//       * Cap.5: el Step del gemelo pasaba a 8 filas navegables (`> 6` -> `> 7`,
//         una linea) mientras su Draw seguia sin dibujar la fila del borde (en
//         vanilla solo existe dentro de la rama de consola, y el bloque que
//         aplana ese gate es multilinea) -> el corazon bajaba a una fila que no
//         se dibuja.
//       * Cap.1-4: el corazon se movia a `yy + 140` (una linea) mientras las
//         filas seguian en las posiciones vanilla (`yy + 150`, multilinea)
//         -> cursor 10 px descolocado.
//     Como el gemelo se congela ANTES de que Borders toque nada, dejarlo
//     intacto lo hace consistente por construccion. Si algun dia se quiere la
//     fila del borde en idioma nativo, hay que escribir esos parches una
//     segunda vez CONTRA EL TEXTO VANILLA, no reutilizar los del mod.
//   - El Menu raiz no comparte `SharedCodeEntries`, asi que ahi no existe
//     `is_native_lang()` y el mecanismo se desactiva entero.

var twinBlock = new string[] {
    "obj_gamecontroller_", "obj_lang_settings_", "DEVICE_MENU_",
    "obj_time_", "obj_border_controller_", "obj_initializer2_",
    "obj_date_controller_", "obj_onion_event_",
    "obj_room_ranking_b_", "obj_ch2_lw_cutscenes_short_",
    "obj_dw_church_ripplepuzzle_postgers_",
    // El menu de opciones lleva la fila del BORDE, que es del fork y no existe
    // en el juego (en PC vanilla solo esta en la rama de consola). Con gemelo,
    // en idioma nativo esa fila desaparecia; y parchearla sobre el gemelo desde
    // `Borders.csx` sale mal si se reutilizan los parches del mod (ver la nota
    // de LIMITES de mas arriba). Asi que este objeto corre SIEMPRE la version
    // del mod: la misma regla que `DEVICE_MENU_*`.
    //
    // El 2026-08-15 se saco de aqui y se le escribieron parches del borde
    // contra el texto vanilla, que funcionaba. **Se deshizo al quitar el
    // japones**: lo que recuperaba eran los ajustes `langopt(en, ja)` y
    // `global.lang == "ja"` de vanilla -el 62 % de los 164 medidos-, y esos son
    // codigo muerto si "ja" no se ofrece. Sin japones ese trabajo pasaba a
    // costar un camino nuevo sin comprar nada.
    "obj_darkcontroller_",

    // --- Menu raiz ---------------------------------------------------------
    // `obj_init_pc_Create_0` es el arranque: fija `global.lang` leyendo la
    // clave del mod (`LANG_DT`). Con gemelo leeria la del juego y la eleccion
    // del fork se perderia antes de empezar.
    "obj_init_pc_",
    // El pie de pantalla es de donde cuelga el selector de idiomas del fork.
    // En vanilla ahi solo hay un interruptor que alterna en<->ja, asi que con
    // gemelo te quedarias en japones sin forma de volver al español: es el
    // mismo caso que `DEVICE_MENU_*` en los capitulos.
    "obj_screen_select_footer_",
    // `obj_screen_start` y `obj_ui_choice` definen metodos que el juego NO tiene
    // (`adjust_choices_x`, `adjust_x`, `shift_y`) y que se llaman desde fuera, desde
    // `obj_CHAPTER_SELECT`. Con gemelo, en idioma nativo el Create es el vanilla, esos
    // metodos no se definen y quien los llame revienta:
    //   Variable <unknown_object>.adjust_choices_x(...) not set before reading it
    // En PC sale ese dialogo; en consola es un aborto mudo (pantalla negra). Fue el
    // fallo del 2026-08-14 en Switch: solo salta si hay partida a medias, porque la
    // pantalla de "continuar desde el capitulo N" es la que llama a `adjust_choices_x`.
    // Regla general: un Create que define funciones del fork no puede tener gemelo.
    "obj_screen_start_", "obj_ui_choice_",
    // `obj_CHAPTER_SELECT` tambien sostiene funciones del fork: su
    // `toggle_language()` redefinido (que abre el selector del mod en vez del
    // interruptor en<->ja de vanilla) y la opcion de Ajustes de idioma del
    // aviso de "continuar desde el capitulo N". Con gemelo, en idioma nativo
    // esa opcion no se dibujaba y no habia forma de volver a un pack desde
    // esa pantalla. Misma regla que `DEVICE_MENU_*`.
    "obj_CHAPTER_SELECT_"
};

var twinLangPattern = new System.Text.RegularExpressions.Regex(@"global\.lang|langopt\s*\(|is_english\s*\(");
var twinDone = new HashSet<string>();
var twinBad = new HashSet<string>();
var twinFailed = new List<string>();
// El menu raiz tambien lleva gemelos. Le sirve el mismo mecanismo aunque no
// comparta `SharedCodeEntries`: tiene su propia copia de `is_native_lang()` en
// `Menu/CodeEntries`, y su vanilla es hasta mas facil de recuperar que el de los
// capitulos, porque ahi el ingles y el japones no salen de ningun pack sino de
// ternarios `(global.lang == "en") ? "..." : "..."` y de ids de fuente.
bool twinEnabled = true;

// Nombre del objeto al que pertenece una entrada, quitando el sufijo de evento:
// "gml_Object_obj_darkcontroller_Draw_0" -> "obj_darkcontroller".
var twinEventSuffix = new System.Text.RegularExpressions.Regex(
    @"_(Create|Destroy|CleanUp|PreCreate|Alarm|Step|Collision|Keyboard|KeyPress|KeyRelease|Mouse|Other|Draw|Trigger|Gesture)_\d+$");

string TwinObjectOf(string codeName)
{
    if (!codeName.StartsWith("gml_Object_"))
        return null;

    return twinEventSuffix.Replace(codeName.Substring("gml_Object_".Length), "");
}

bool TwinAllowed(string codeName)
{
    if (!twinEnabled || !codeName.StartsWith("gml_Object_"))
        return false;

    foreach (var b in twinBlock)
        if (codeName.Contains(b))
            return false;

    return true;
}

// Objetos cuyas entradas van con gemelo. Se decide POR OBJETO, no por entrada:
// si el Draw corre vanilla pero el Step se queda con el del mod, el menu se
// descuadra (el cursor navega filas que ya no se dibujan, p.ej. la del borde
// que añade Borders.csx). O todo el objeto, o nada.
var twinObjects = new HashSet<string>();

// Compila UN gemelo en su propio grupo.
//
// `ReplaceGML` no compila nada: solo apunta el texto en `changedCodes` para el
// CompileGroup UNICO de `SaveEntries()`. Y ese grupo es todo-o-nada: si una
// sola entrada no compila, se descartan TODAS las sustituciones del parche y el
// script termina igualmente con rc=0 y "Saved data file to...".
//
// El resto de lo que entra en ese grupo es GML escrito a mano y revisado en el
// repo; el cuerpo de un gemelo, en cambio, es salida del decompilador sobre un
// data.win arbitrario. Basta con que una actualizacion del juego traiga algo
// que Underanalyzer decompile mal para tumbar el parche entero sin avisar.
//
// Por eso los gemelos se compilan aparte del grupo final: si fallan, el peor
// caso es "ese objeto no tiene paridad vanilla" en vez de "el parche no se
// aplico".
//
// Ahora bien, aparte NO quiere decir uno por uno. Antes cada gemelo tenia su
// propio `CompileGroup` y eso resulto ser casi todo el coste del mecanismo:
// medido en el Cap.5, 127 gemelos costaban 5,3 s de los 14,4 s del capitulo, y
// agrupandolos en UN solo `CompileGroup` bajan a 1,3 s. O sea que lo que se
// pagaba no era compilar, era montar el grupo 127 veces.
//
// Asi que se encolan todos y se compilan juntos (`TwinFlush`). El aislamiento
// se conserva igual, porque el grupo sigue siendo distinto del final: si el
// grupo de gemelos se cae entero, se reintenta uno por uno para quedarse solo
// con el culpable, que es lo unico para lo que servia el grupo individual.
var twinQueue = new List<(string Name, string Gml)>();

// El desvio que se antepone a la version del mod. En un solo sitio porque
// `TwinFlush` tiene que saber quitarlo si el gemelo resulta no compilar.
string TwinDispatch(string twinName)
{
    return "// Idioma nativo del juego: ejecutar el codigo original.\n"
        + "if (is_native_lang())\n{\n    " + twinName + "();\n    exit;\n}\n\n";
}

void TwinQueueCompile(string twinName, string gml)
{
    twinQueue.Add((twinName, gml));

    // `CreateBlankFunction` deja apuntado un `function X() {}` en
    // `changedCodes`. Fuera: de esa entrada se encarga el grupo de gemelos, y
    // el grupo final ni la repite ni puede tumbarse por su culpa.
    changedCodes.Remove("gml_GlobalScript_" + twinName);
}

// Compila UN gemelo en su propio grupo. Solo se usa en el camino de respaldo,
// cuando el grupo entero se ha caido y hay que averiguar por culpa de quien.
bool TwinCompileOne(string twinName, string gml)
{
    var code = Data.Code.ByName("gml_GlobalScript_" + twinName);

    CompileGroup group = new(Data)
    {
        MainThreadAction = ExecuteInUIThread
    };

    group.QueueCodeReplace(code, gml);
    CompileResult result = group.Compile();

    if (!result.Successful)
    {
        twinFailed.Add(twinName + ": " + result.PrintAllErrors(true));
        return false;
    }

    changedCodes.Remove(code.Name.Content);

    return true;
}

void TwinFlush()
{
    if (twinQueue.Count == 0)
        return;

    CompileGroup group = new(Data)
    {
        MainThreadAction = ExecuteInUIThread
    };

    foreach (var t in twinQueue)
        group.QueueCodeReplace(Data.Code.ByName("gml_GlobalScript_" + t.Name), t.Gml);

    if (group.Compile().Successful)
        return;

    // Se cayo el grupo entero (`CompileGroup` es todo-o-nada, asi que no queda
    // nada compilado a medias). Uno por uno para aislar al culpable.
    foreach (var t in twinQueue)
    {
        if (TwinCompileOne(t.Name, t.Gml))
            continue;

        // Ese gemelo no compila. Que la funcion quede vacia pero valida, y
        // fuera el desvio de su entrada: si no, en idioma nativo se llamaria a
        // una funcion vacia y esa entrada no dibujaria nada. Sin desvio se
        // queda con la version del mod, que es lo que habia antes del gemelo.
        TwinCompileOne(t.Name, "function " + t.Name + "() //gml_Script_" + t.Name + "\n{\n}");
        twinDone.Remove(t.Name);
        twinBad.Add(t.Name);

        var entryName = "gml_Object_" + t.Name.Substring("scr_native_".Length);
        var dispatch = TwinDispatch(t.Name);

        if (changedCodes.TryGetValue(entryName, out var text) && text.StartsWith(dispatch))
            changedCodes[entryName] = text.Substring(dispatch.Length);
    }
}

string MakeVanillaTwin(string codeName, string vanillaGml)
{
    if (!TwinAllowed(codeName) || string.IsNullOrEmpty(vanillaGml))
        return null;

    string twinName = "scr_native_" + codeName.Substring("gml_Object_".Length);

    if (twinDone.Contains(twinName))
        return twinName;

    if (twinBad.Contains(twinName))
        return null;

    string header = "function " + twinName + "() //gml_Script_" + twinName + "\n{\n";

    try
    {
        // `CreateBlankFunction` toca `Data.Code`, `Data.Scripts` y
        // `Data.GlobalInitScripts`, y esto corre dentro del `Task.Run` de la
        // sustitucion: hay que hacerlo en el hilo de UI, como ya hace
        // `GetOrig()` con su `Data.Code.Add`. Por CLI da igual, pero en la GUI
        // de UMT 0.9 tocar esas colecciones desde otro hilo revienta el
        // binding.
        ExecuteInUIThread(() => CreateBlankFunction(twinName));

        // Solo se encola. Si no compila se vera en `TwinFlush`, que ahi mismo
        // deshace el desvio de esta entrada.
        TwinQueueCompile(twinName, header + vanillaGml + "\n}");

        twinDone.Add(twinName);
        return twinName;
    }
    catch (Exception e)
    {
        twinFailed.Add(codeName + ": " + e.Message);
        twinBad.Add(twinName);
        return null;
    }
}

#endregion

#region Замена кусков кода

var codesWithSpritesIds = new Dictionary<string, List<string>>();
var spriteIdDict = Data.Sprites.Select((item, index) => (item, index))
                               .ToDictionary(x => x.item.Name.Content, x => x.index);

if (File.Exists(scriptFolder + "CodesWithSpritesIds.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "CodesWithSpritesIds.json");
    string json = r.ReadToEnd();
    codesWithSpritesIds = JsonSerializer.Deserialize<Dictionary<string, List<string>>>(json);
}


Dictionary<string, List<Dictionary<string, string>>> jsonCodeUpdates;

if (File.Exists(scriptFolder + "CodeUpdates.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "CodeUpdates.json");
    string json = r.ReadToEnd();
    jsonCodeUpdates = JsonSerializer.Deserialize<Dictionary<string, List<Dictionary<string, string>>>>(json);
}

var codeChanges = new Dictionary<string, List<(string, string, bool)>>();
if (File.Exists(scriptFolder + "CodeChanges.txt")) {
    var changes = File.ReadAllLines(scriptFolder + "CodeChanges.txt");
    var cur_code = "";
    var cur_from = "";
    var cur_to = "";
    int flag = 0;
    bool flag_ignore = false;
    foreach (var str in changes)
    {
        if (str.StartsWith("==="))
        {
            cur_code = str.Substring(4);
            if (!codeChanges.ContainsKey(cur_code))
                codeChanges[cur_code] = new List<(string, string, bool)>();
            flag = 0;
        }
        else
        if (str.StartsWith("---"))
        {
            flag = 1;
            if (str.Length > 3 && str[3] == '#')
            {
                flag_ignore = true;
            }
        }
        else if (str.StartsWith("+++"))
            flag = 2;
        else if (str.StartsWith("%%%"))
        {
            flag = 0;
            codeChanges[cur_code].Add((cur_from.Remove(cur_from.Length - 1), cur_to.Remove(cur_to.Length - 1), flag_ignore));
            cur_from = "";
            cur_to = "";
            flag_ignore = false;
        }
        else
        if (flag == 1)
            cur_from += str + "\n";
        else if (flag == 2)
            cur_to += str + "\n";
    }
    // jsonCodeUpdates = JsonSerializer.Deserialize<Dictionary<string, List<Dictionary<string, string>>>>(json);
}

maxCount = codesWithSpritesIds.Count + codeEntrs.Count + codeChanges.Count;
// maxCount = codeEntrs.Count + jsonCodeUpdates.Count;
await Task.Run(() =>
{
    SetProgressBar(null, "Code entries replacing", 0, maxCount);

    // --- Pasada 1: restaurar el vanilla y quedarnos con su texto -------------
    // `GetOrig()` deja el codigo original en la entrada, asi que decompilar
    // aqui da vanilla. Se cachea para no decompilar dos veces y, sobre todo,
    // para poder decidir los gemelos POR OBJETO antes de pisar nada.
    var vanillaText = new Dictionary<string, string>();
    var entriesOk = new HashSet<string>();
    var replacedNames = new HashSet<string>(codeEntrs.Select(c => c.Item1));

    // Ademas de las entradas que se reemplazan enteras, se miran las que solo
    // toca `CodeChanges.txt` por find&replace: ahi tambien se pierden ajustes de
    // idioma. El caso que lo destapo es `obj_chapter_continue_Create_0`, que en
    // vanilla lleva el japones incrustado
    //   choice_text[0] = (global.lang == "en") ? "Continue to..." : "Chapter ~1へ進む";
    // y que el mod reescribe a una clave de loc que NO existe en el
    // `lang_ja.json` del juego, asi que en japones nativo caia al ingles.
    //
    // AMPLIAR ESTA LISTA es lo que se probo el 2026-08-15 y se deshizo al quitar
    // el japones. Metiendo tambien las poblaciones de `CodesWithFonts`,
    // `CodesWithSprites`, `CodesWithSounds`, `CodesWithSpritesIds` y
    // `ObjectsWithAssignedSprites`, y dando gemelo a TODO objeto que el mod
    // toque, la cobertura del Cap.5 pasaba del 49 % (127 de 260) al 96 % (512 de
    // 532). Funcionaba y costaba ~10 s mas de parcheo, pero lo que compraba era
    // paridad con el vanilla JAPONES; en ingles no se nota, porque las entradas
    // del mod ya estan maquetadas para texto latino. Si algun dia se retoma el
    // japones, esta es la primera pieza que hay que reponer: los detalles y los
    // dos JSON con forma rara estan en el ESTADO.md.
    var twinCandidates = new List<string>();
    twinCandidates.AddRange(codeEntrs.Select(c => c.Item1));
    twinCandidates.AddRange(codeChanges.Keys);

    foreach (var codeName in twinCandidates)
    {
        if (!GetOrig(codeName))
            continue;

        entriesOk.Add(codeName);

        if (twinEnabled && TwinAllowed(codeName) && !vanillaText.ContainsKey(codeName))
        {
            try
            {
                var vgml = Decompile(Data.Code.ByName(codeName));
                vanillaText[codeName] = vgml;

                // Basta con que UNA entrada del objeto tenga logica por idioma
                // para que el objeto entero vaya con gemelo.
                //
                // Este criterio tiene un punto ciego conocido: solo ve los sitios
                // donde el VANILLA habla del idioma, no aquellos donde es el MOD
                // quien le anade la dependencia (reescribir la maquetacion,
                // convertir fuentes). Con japones eso importaba mucho -era la
                // mitad de la superficie- y por eso se amplio y luego se
                // deshizo; ver el comentario de `twinCandidates`. Sin japones el
                // punto ciego apenas se nota, porque en ingles la version del mod
                // y la de vanilla se ven casi igual.
                if (!string.IsNullOrEmpty(vgml) && twinLangPattern.IsMatch(vgml))
                    twinObjects.Add(TwinObjectOf(codeName));
            }
            catch (Exception) { }
        }
    }

    // --- Pasada 2: crear gemelos y sustituir ---------------------------------
    foreach (var code in codeEntrs)
    {
        if (!entriesOk.Contains(code.Item1))
            continue;
        // ScriptMessage(code.Item1);
        // Data.Code.ByName(code.Item1).ReplaceGML(code.Item2, Data);

        string twinName = null;

        if (twinEnabled && vanillaText.ContainsKey(code.Item1)
            && twinObjects.Contains(TwinObjectOf(code.Item1)))
        {
            twinName = MakeVanillaTwin(code.Item1, vanillaText[code.Item1]);
        }

        var gml = code.Item2;

        if (twinName != null)
            gml = TwinDispatch(twinName) + gml;

        ReplaceGML(Data.Code.ByName(code.Item1), gml);
        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }

    // --- Pasada 3: el resto de entradas de los objetos con gemelo ------------
    // Hay entradas que el mod NO reemplaza pero que sí toca despues, por
    // find&replace, `Borders.csx` o `CodeChanges.txt`. El caso que lo destapo:
    // `obj_darkcontroller_Step_0` no esta en CodeEntries, pero Borders le añade
    // la fila del borde al menu. Con el Draw en vanilla y el Step parcheado, el
    // cursor navegaba a una fila que ya no se dibuja.
    //
    // Aqui se congela una copia PRISTINA de esas entradas y se les pone el
    // mismo desvio. Como el gemelo se saca antes de que nadie las toque, el
    // idioma nativo queda inmune a lo que venga despues.
    if (twinEnabled)
    {
        foreach (var obj in twinObjects.ToList())
        {
            var prefix = "gml_Object_" + obj + "_";

            foreach (var c in Data.Code.Where(x => x.Name.Content.StartsWith(prefix)).ToList())
            {
                var name = c.Name.Content;

                // Solo se salta lo que ya proceso la pasada 2 (CodeEntries).
                if (name.EndsWith("_old") || replacedNames.Contains(name))
                    continue;

                // TwinObjectOf evita confundir obj_x con otro objeto cuyo
                // nombre empiece igual (obj_x_algo).
                if (!TwinAllowed(name) || TwinObjectOf(name) != obj)
                    continue;

                // `GetOrig()` tambien aqui, y no un `Decompile()` a pelo: estas
                // entradas no las respalda nadie mas, asi que sin el
                // `<entrada>_old` el patcher deja de ser idempotente. Sobre un
                // data.win YA parcheado, `Decompile` devolveria el codigo con
                // el desvio ya puesto y el gemelo pasaria a ser
                //   scr_native_X() { if (is_native_lang()) { scr_native_X(); exit; } ... }
                // o sea, recursion infinita en cuanto se juega en idioma
                // nativo. Con `GetOrig` la entrada vuelve a vanilla primero y
                // la segunda pasada del patcher da el mismo resultado que la
                // primera.
                if (!GetOrig(name))
                    continue;

                string vgml;
                try
                {
                    vgml = Decompile(c);
                }
                catch (Exception) { continue; }

                var tn = MakeVanillaTwin(name, vgml);

                if (tn == null)
                    continue;

                ReplaceGML(c, TwinDispatch(tn) + vgml);
            }
        }
    }

    // --- Comprobacion de integridad ------------------------------------------
    // Toda entrada de `CodeEntries` tiene que haber pasado por la pasada 2. Si
    // alguna se queda fuera, los scripts del fork se quedan como la funcion vacia
    // que crea `CreateBlankFunction` y el juego arranca sin idiomas... con el
    // patcher diciendo rc=0, 0 errores de compilacion y un data.win mas grande
    // que el vanilla. Paso de verdad al tocar `twinCandidates`, que alimenta
    // tambien `entriesOk`. Es barato comprobarlo y no hay forma de verlo si no.
    var sinAplicar = codeEntrs.Select(c => c.Item1).Where(n => !entriesOk.Contains(n)).ToList();

    if (sinAplicar.Count > 0)
        ScriptMessage("AVISO: " + sinAplicar.Count + " entradas de CodeEntries NO se aplicaron.\n"
            + "Si el juego es de una version antigua es lo esperado (arriba salen una a una).\n"
            + "Si es la version actual, es un fallo del patcher.\n"
            + string.Join("\n", sinAplicar.Take(20)));

    if (twinEnabled)
    {
        // Ahora, con todos encolados, se compilan de una vez.
        TwinFlush();

        ScriptMessage("Gemelos vanilla creados: " + twinDone.Count
            + (twinFailed.Count > 0 ? ("  | FALLIDOS: " + twinFailed.Count + "\n" + string.Join("\n", twinFailed)) : ""));
    }

    foreach (var code in codesWithSpritesIds)
    {
        if (!GetOrig(code.Key))
            continue;
            
        foreach (var spr in code.Value)
        {
            int sprId = spriteIdDict.TryGetValue(spr, out int id) ? id : -1;
            if (sprId == -1)
            {
                ScriptMessage($"Не удалось найти спрайт с именем \"{spr}\"");
            }

            // Не забыть дублировать спрайты в CodesWithSprites, этот кусок кода просто вместо айдишников имена подставляет
            if (!ReplacePart(code.Key, sprId.ToString(), spr))
            {
                // ScriptMessage(string.Format("Ошибка при изменении айдишника \"{0}\" в \"{1}\".", spr, code.Key));
            }
        }

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }

    foreach (var codeName in codeChanges.Keys)
    {
        if (!GetOrig(codeName))
            continue;

        foreach (var change in codeChanges[codeName])
        {
            var from = Regex.Replace(change.Item1, @"\s+", " ");
            from = Regex.Escape(from);
            from = from.Replace(" ", @"\s*").Replace("\\\\", "\\");
            from = from.Replace("{", "{?").Replace("}", "}?");
            if (!ReplacePart(codeName, from, change.Item2) && !change.Item3)
            {
                ScriptMessage(codeName + "\n" + change.Item1);
            }
        }

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }

    // foreach (var codeName in jsonCodeUpdates.Keys) {
    //     GetOrig(codeName);

    //     foreach (var change in jsonCodeUpdates[codeName])
    //     {
    //         ReplacePart(codeName, Regex.Escape(change["old"]), change["new"]);
    //     }

    //     IncrementProgress();
    //     UpdateProgressValue(GetProgress());
    // }

});
#endregion

#region Внедрение спрайтов и звуков


var jsonSpritesAssigned = new Dictionary<string, string>();
var jsonObjSprDraws = new Dictionary<string, List <string>>();
var jsonRooms = new Dictionary<string, List<Dictionary<string, string>>>();
var jsonObjSounds = new Dictionary<string, List <string>>();

if (File.Exists(scriptFolder + "ObjectsWithAssignedSprites.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "ObjectsWithAssignedSprites.json");
    string json = r.ReadToEnd();
    jsonSpritesAssigned = JsonSerializer.Deserialize<Dictionary<string, string>>(json);
}
if (File.Exists(scriptFolder + "CodesWithSprites.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "CodesWithSprites.json");
    string json = r.ReadToEnd();
    jsonObjSprDraws = JsonSerializer.Deserialize<Dictionary<string, List<string>>>(json);
}
if (File.Exists(scriptFolder + "RoomsWithBacksLayers.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "RoomsWithBacksLayers.json");
    string json = r.ReadToEnd();
    jsonRooms = JsonSerializer.Deserialize<Dictionary<string, List<Dictionary<string, string>>>>(json);
}
if (File.Exists(scriptFolder + "CodesWithSounds.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "CodesWithSounds.json");
    string json = r.ReadToEnd();
    jsonObjSounds = JsonSerializer.Deserialize<Dictionary<string, List<string>>>(json);
}

maxCount = jsonObjSprDraws.Count + jsonSpritesAssigned.Count + jsonRooms.Count + jsonObjSounds.Count;
await Task.Run(() =>
{
    SetProgressBar(null, "Sprites and sounds injecting", 0, maxCount);

    foreach (var code in jsonObjSprDraws)
    {
        GetOrig(code.Key);
        foreach (var spr in code.Value)
        {
            // Mismo caso que las fuentes: el vanilla clava el sprite latino a
            // proposito en sitios que no se localizan (los carteles de nombre del
            // minijuego de ritmo, por ejemplo), y chemg_sprite_map lo desviaria a
            // su variante spr_ja_*. En idioma nativo, el asset literal.
            // Donde el mapa no tiene entrada japonesa el ternario es un no-op.
            if (!ReplacePart(code.Key, spr,
                string.Format("(is_native_lang() ? {0} : scr_84_get_sprite(\"{0}\"))", spr), true)) // scr_84_get_sprite
            {
                ScriptMessage(string.Format("Ошибка при добавлении спрайта \"{0}\" в \"{1}\".", spr, code.Key));
            }
        }

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }

    foreach (var obj in jsonSpritesAssigned)
    {
        if (Data.Code.ByName("gml_Object_" + obj.Key + "_Create_0") == null)
        {
            AddNewEvent(obj.Key, EventType.Create, 0,
            string.Format("event_inherited();\nif (sprite_index == {0}) sprite_index = scr_84_get_sprite(\"{0}\");", obj.Value));
        }
        else
        {
            GetOrig("gml_Object_" + obj.Key + "_Create_0");
            AppendToStart("gml_Object_" + obj.Key + "_Create_0",
            string.Format("if (sprite_index == {0}) sprite_index = scr_84_get_sprite(\"{0}\");", obj.Value));
        }

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }

    foreach (var code in jsonObjSounds)
    {
        var lst = new List<(string, string)>();
        foreach (var snd in code.Value)
        {
            lst.Add((snd, string.Format("scr_84_get_sound(\"{0}\")", snd)));
        }
        GetOrig(code.Key);
        ReplacePart(code.Key, lst, true);

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }
});

// Добавление спрайтов

var jsonNewSprites = new Dictionary<string, Dictionary<string, int>>();
if (File.Exists(scriptFolder + "new_sprites.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "new_sprites.json");
    string json = r.ReadToEnd();
    jsonNewSprites = JsonSerializer.Deserialize<Dictionary<string, Dictionary<string, int>>>(json);
}

foreach (var spr in jsonNewSprites)
{
    var newSprite = Data.Sprites.ByName(spr.Key);
    if (newSprite is null) {
        newSprite = new();
        newSprite.Name = Data.Strings.MakeString(spr.Key);
        Data.Sprites.Add(newSprite);
    }

    if (spr.Value.ContainsKey("width"))
    {
        newSprite.Width = (uint)spr.Value["width"];
        newSprite.MarginRight = spr.Value["width"] - 1;
        newSprite.MarginLeft = 0;

        newSprite.Height = (uint)spr.Value["height"];
        newSprite.MarginBottom = spr.Value["height"] - 1;
        newSprite.MarginTop = 0;

        newSprite.CollisionMasks.Clear();
        newSprite.CollisionMasks.Add(newSprite.NewMaskEntry());
    }
    
    if (spr.Value.ContainsKey("origin_x"))
    {
        newSprite.OriginX = spr.Value["origin_x"];
    }
    
    if (spr.Value.ContainsKey("origin_y"))
    {
        newSprite.OriginY = spr.Value["origin_y"];
    }

    if (spr.Value.ContainsKey("frames_num"))
    {
        var r_frames = spr.Value["frames_num"];
        if (r_frames < newSprite.Textures.Count) {
            while (newSprite.Textures.Count > r_frames) {
                newSprite.Textures.RemoveAt(newSprite.Textures.Count - 1);
            }
            // newSprite.Textures.RemoveRange(r_frames, newSprite.Textures.Count - r_frames);
            } else {
            var c = newSprite.Textures.Count;
            for (int i = c; i < spr.Value["frames_num"]; i++)
                newSprite.Textures.Add(new UndertaleSprite.TextureEntry());
        }
    }
}


#endregion

#region Замена шрифтов


var jsonFonts = new Dictionary<string, List<string>>();

if (File.Exists(scriptFolder + "CodesWithFonts.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "CodesWithFonts.json");
    string json = r.ReadToEnd();
    jsonFonts = JsonSerializer.Deserialize<Dictionary<string, List<string>>>(json);
}

maxCount = Math.Max(1, jsonFonts.Sum(e => e.Value.Count));
await Task.Run(() =>
{
    SetProgressBar(null, "Fonts injecting", 0, maxCount);

    foreach (var font in jsonFonts)
    {
        foreach (var scr in font.Value)
        {
            GetOrig(scr);
            // El vanilla clava la fuente aqui a proposito: son sitios que salen en
            // latino aunque el juego este en japones (resultados del concierto, la
            // cuenta 3-2-1, el marcador del ritmo...). Convertirlo en una busqueda
            // por idioma a secas se los lleva a la fuente japonesa, porque
            // scr_84_init_localization registra font_map["8bit"] = fnt_ja_8bit.
            // En idioma nativo hay que devolver el asset literal del vanilla.
            ReplacePart(scr, font.Key,
                "(is_native_lang() ? " + font.Key + " : scr_84_get_font(\"" + font.Key.Substring(4) + "\"))", true);
            IncrementProgress();
            UpdateProgressValue(GetProgress());
        }
    }

    foreach (var font in Data.Fonts)
    {
        if (font.Name.ToString().Contains("_ja_"))
        {
            font.Name.Content = font.Name.ToString().Trim(new char[] { '"' }).Replace("_ja_", "_") + "_ja";
        }
    }
});

#endregion

#region Fuentes clavadas del vanilla en las entradas escritas a mano

// `CodesWithFonts.json` cubre una poblacion: las entradas donde el patcher
// mismo cambia `fnt_X` por `scr_84_get_font("X")`. Hay una SEGUNDA poblacion
// que no cubre: las entradas que el mod sustituye enteras con GML escrito a
// mano en `CodeEntries/`, donde esa conversion ya viene hecha en el archivo.
//
// El fallo es el mismo. Donde el vanilla clava el asset (`draw_set_font(fnt_8bit)`)
// esta diciendo "aqui la latina siempre", porque son pantallas que no se
// localizan; la busqueda las manda a la japonesa, que `scr_84_init_localization`
// registra como `font_map["8bit"] = fnt_ja_8bit`.
//
// El criterio para decidirlo es el respaldo `_old`, que ES el vanilla: si para
// una fuente el vanilla usaba SOLO el asset literal y nunca la busqueda, todas
// las llamadas de esa entrada tienen que volver al literal en idioma nativo.
// Si usaba las dos formas el criterio no distingue cual es cual, y esas se
// dejan como estan y se reportan: hay que mirarlas sitio por sitio.

string[] nativeFontKeys = {
    "main", "mainbig", "tinynoelle", "dotumche", "comicsans",
    "small", "8bit", "8bit_mixed", "legend", "legend_alt"
};

// El `_old` no guarda GML compilable, sino el vanilla como literal escapado
// (ver `GetOrig`). Hay que deshacer el escapado para poder leerlo.
string VanillaOf(string codeName)
{
    var oldCode = Data.Code.ByName(codeName + "_old");
    if (oldCode == null)
        return null;

    var t = Decompile(oldCode);
    if (!t.StartsWith("var code = \"") || t.Length < 15)
        return null;

    t = t.Substring(12);
    return t.Remove(t.Length - 3)
            .Replace("\\n", "\n").Replace("\\\"", "\"")
            .Replace("\\_n", "\\n").Replace("\\\\", "\\");
}

var fontAmbiguous = new List<string>();
int fontPinned = 0;

await Task.Run(() =>
{
    SetProgressBar(null, "Native fonts pinning", 0, Math.Max(1, backedList.Count));

    foreach (var codeName in backedList.ToList())
    {
        var code = Data.Code.ByName(codeName);
        if (code == null || codeName.EndsWith("_old") || codeName.Contains("scr_native_"))
            continue;

        var text = Decompile(code);
        if (!text.Contains("scr_84_get_font("))
            continue;

        var vanilla = VanillaOf(codeName);
        if (vanilla == null)
            continue;

        var updated = text;
        foreach (var key in nativeFontKeys)
        {
            var call = "scr_84_get_font(\"" + key + "\")";

            // Se salta lo que ya lleva el ternario puesto por CodesWithFonts.
            var rx = new Regex(@"(?<!is_native_lang\(\) \? fnt_" + key + @" : )" + Regex.Escape(call));
            if (!rx.IsMatch(updated))
                continue;

            bool usaLiteral = Regex.IsMatch(vanilla, @"\bfnt_" + key + @"\b");
            bool usaBusqueda = vanilla.Contains(call);

            if (!usaLiteral)
                continue;

            if (usaBusqueda)
            {
                fontAmbiguous.Add(codeName + " / fnt_" + key);
                continue;
            }

            fontPinned += rx.Matches(updated).Count;
            updated = rx.Replace(updated, "(is_native_lang() ? fnt_" + key + " : " + call + ")");
        }

        if (updated != text)
            ReplaceGML(code, updated);

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }
});

// La lista de ambiguos esta en ESTADO.md; aqui solo el recuento, para poder
// ver de un vistazo si una actualizacion del juego mueve los numeros.
ScriptMessage(string.Format("Fuentes clavadas en idioma nativo: {0} sitios  |  ambiguos (a mano): {1}",
    fontPinned, fontAmbiguous.Count));

#endregion

