// =====================================================================
// Helpers.csx - utilidades de bajo nivel para los Fix-*.csx
// =====================================================================
// Funciones genericas para inspeccionar y modificar el data.win:
//   - ReplaceGML / ReplacePart / AppendToStart / AppendToEnd: edicion de
//     codigo GML decompilado (cambios en memoria, se commit despues con
//     SaveEntries).
//   - Decompile: decompila un UndertaleCode con cache local (changedCodes).
//   - GetOrig: respaldo del codigo original en un *_old para que un
//     re-aplicado del parche no acumule diffs sobre diffs.
//   - CreateBlankFunction / AddNewEvent / AddCreationCodeEntryForInstance:
//     creacion de funciones, events y precreate code para instancias.
//   - SaveEntries: compilacion final en lote de todos los cambios.
//
// Variables globales que expone (visibles a los modulos cargados despues
// con #load):
//   - gameFolder, scriptFolder: rutas resueltas desde el FilePath/ScriptPath.
//   - globalDecompileContext, decompilerSettings: contexto de decompilacion.
//   - changedCodes: dict acumulador de cambios (CodeName -> texto GML nuevo).
//   - backedList: nombres de codigos que ya tienen su *_old creado.
//   - maxCount: contador de progreso compartido entre regiones.
//
// El parche se aplica en dos fases:
//   1. Acumulacion: cada modulo edita changedCodes en memoria.
//   2. Commit: SaveEntries() compila todos los cambios al data.win en bloque.
// =====================================================================

using UndertaleModLib.Util;
using System.Text.Json;
using System.Linq;
using System.Text;
using System.IO;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

string gameFolder = Path.GetDirectoryName(FilePath) + Path.DirectorySeparatorChar;
string scriptFolder = Path.GetDirectoryName(ScriptPath) + Path.DirectorySeparatorChar;

var globalDecompileContext = new GlobalDecompileContext(Data);
var decompilerSettings = Data.ToolInfo.DecompilerSettings;
SyncBinding("Strings, Code, CodeLocals, Scripts, GlobalInitScripts, GameObjects, Functions, Variables", true);

var changedCodes = new Dictionary<string, string>();

// -----------------------------------------------------------------
// Creacion de funciones GML vacias (registradas como GlobalScript)
// -----------------------------------------------------------------

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

        ReplaceGML(code, $"function {funcName}() //gml_Script_{funcName}\n{{}}");
    }
}

// -----------------------------------------------------------------
// Edicion de codigo GML (en memoria; se confirma en SaveEntries)
// -----------------------------------------------------------------

bool ReplaceGML(UndertaleCode code, string text)
{
    changedCodes[code.Name.Content] = text;
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
        Regex rx = new Regex(pair.Item1);
        if (matchWordsBounds)
        {
            rx = new Regex(string.Format(@"\b{0}\b", pair.Item1));
        }

        if (!rx.IsMatch(text))
        {
            return false;
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
    return AppendToEnd(Data.Code.ByName(codeName), append);
}

// -----------------------------------------------------------------
// Events e instancias
// -----------------------------------------------------------------

void AddNewEvent(UndertaleGameObject obj, EventType evType, uint evSubtype, string codeGML)
{
    ReplaceGML(obj.EventHandlerFor(evType, evSubtype, Data), codeGML);
}

void AddNewEvent(string objName, EventType evType, uint evSubtype, string codeGML)
{
    AddNewEvent(Data.GameObjects.ByName(objName), evType, evSubtype, codeGML);
}

UndertaleCode AddCreationCodeEntryForInstance(UndertaleRoom.GameObject inst) {
    UndertaleCode code = inst.PreCreateCode;
    if (code == null) {
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
    }
    return code;
}

// -----------------------------------------------------------------
// Decompilacion + sistema de respaldo (*_old)
// -----------------------------------------------------------------

List<string> backedList = new List<string>();

string Decompile(UndertaleCode code)
{
    try
    {
        if (changedCodes.ContainsKey(code.Name.Content))
            return changedCodes[code.Name.Content];

        return new Underanalyzer.Decompiler.DecompileContext(globalDecompileContext, code, decompilerSettings).DecompileToString();
    } catch (Exception e) {
        // Mensaje al usuario en ingles (puede ser cualquier idioma).
        throw new Exception(string.Format(
            "Error decompiling code \"{0}\". If you have an old game version, download the latest. " +
            "If you are already on the latest, report this bug to the developers.",
            code.Name.Content));
    }
}

string Decompile(string code)
{
    return Decompile(Data.Code.ByName(code));
}

/// <summary>
/// Si es la primera vez que se toca este codigo en la sesion, guarda el
/// original en un UndertaleCode hermano llamado <codeName>_old (codificado
/// como literal de string GML para esquivar la decompilacion). Despues
/// restaura el codigo a su version original. Esto evita que re-ejecutar
/// los Fix-*.csx encadene diff-sobre-diff cada vez.
/// </summary>
bool GetOrig(string codeName)
{
    if (backedList.Contains(codeName))
        return true;

    var code = Data.Code.ByName(codeName);
    var oldCode = Data.Code.ByName(codeName + "_old");

    if (code == null)
    {
        ScriptMessage(string.Format(
            "Missing code chunk \"{0}\". This is most likely due to an old game version. " +
            "Errors may or may not occur because of this.",
            codeName));
        return false;
    }

    if (oldCode == null)
    {
        oldCode = new UndertaleCode();
        oldCode.Name = Data.Strings.MakeString(codeName + "_old");
        Data.Code.Add(oldCode);
    }

    var oldText = Decompile(oldCode);
    if (oldText == "")
    {
        ReplaceGML(oldCode, "var code = \"" + Decompile(code).Replace("\\", "\\\\").Replace("\\n", "\\_n").Replace("\n", "\\n").Replace("\"", "\\\"") + "\";\n");
        oldText = changedCodes[oldCode.Name.Content];
    }

    if (oldText != "")
    {
        try
        {
            // Quita el prefijo "var code = \""
            oldText = oldText.Substring(12);
        }
        catch (Exception err)
        {
            var msg = string.Format(
                "Error decompiling code '{0}'. You are most likely running this script on an old game version (e.g. demo).",
                codeName);
            ScriptMessage(msg);
            throw new Exception(msg);
        }
        // Quita el sufijo "\";\n" y revierte los escapes que metimos al guardar.
        oldText = oldText.Remove(oldText.Length - 3).Replace("\\n", "\n").Replace("\\\"", "\"").Replace("\\_n", "\\n").Replace("\\\\", "\\");
        ReplaceGML(code, oldText);
    }

    backedList.Add(codeName);

    return true;
}

// -----------------------------------------------------------------
// Compilacion en lote
// -----------------------------------------------------------------

int maxCount = 0;

async Task SaveEntries()
{
    maxCount = 1;
    await Task.Run(() =>
    {
        SetProgressBar(null, "Final compiling", 0, maxCount);

        CompileGroup group = new(Data);
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
            ScriptMessage("Compilation error:\n" + result.PrintAllErrors(true));
        }

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    });
}
