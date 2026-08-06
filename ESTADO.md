# Estado: idiomas nativos (inglés y japonés)

Última actualización: **2026-08-06**. Rama `idiomas-nativos`, punta en `caf95c1`.

Este documento es para retomar el trabajo sin reconstruir el contexto. El `CHANGES.md` del
repo explica *qué hace* el mod; esto explica *dónde está esta rama*, *qué está comprobado* y
sobre todo *qué ya se intentó y salió mal*, que es lo que más tiempo costó.

---

## Qué es esto

Deltranslate reemplaza entradas de código enteras por versiones reescritas para que quepa el
texto traducido. Al hacerlo pierde la lógica por idioma que el juego ya trae para sus dos
idiomas de fábrica: `langopt(en, ja)`, `if (global.lang == "ja")`, fuentes y sprites `_ja`.
Medido contra el volcado del juego: **164 ajustes perdidos en 40 entradas**, el 62 % en el
`obj_darkcontroller_Draw_0` de cada capítulo.

La idea: **si el idioma activo es uno de los que el juego ya trae, apartarse y dejar que corra
su propio código.** El mod solo interviene cuando hay un pack de traducción de por medio.

Dos mecanismos:

1. **`is_native_lang()`** y el alta de `en`/`ja` en `scan_languages()`, para que aparezcan en el
   selector sin que exista ninguna carpeta en `lang/`.
2. **Los "gemelos vanilla"**: `BaseFix.csx` guarda en tiempo de *build* una copia ejecutable del
   código original de cada entrada afectada (`scr_native_<entrada>`) y le antepone un desvío.
   Se regenera sola en cada actualización del juego, porque el gemelo sale del `data.win` nuevo.

```gml
// Idioma nativo del juego: ejecutar el codigo original.
if (is_native_lang())
{
    scr_native_obj_darkcontroller_Draw_0();
    exit;
}
```

Funciona porque `GetOrig()` ya restaura el original antes de que el mod lo pise (es lo que hace
idempotente al patcher), así que decompilar justo después devuelve vanilla. Y porque el código
de un evento se comporta igual llamado como función: `self` sigue siendo la instancia y `exit`
retorna de la función.

## Dónde está todo

| Qué | Dónde |
|---|---|
| Este repo (clon, fuera del principal) | `~/Proyectos/Letra Delta - Repos/DeltranslatePatch-idiomas-nativos` |
| Repo principal (limpio, sin esto) | `~/Proyectos/Letra Delta - Repos/DeltranslatePatch` en `main` |
| Respaldo en parche | `~/Proyectos/Letra Delta - Repos/idiomas-nativos-v2.patch` |
| Build instalado para probar | `~/.local/share/Steam/steamapps/common/DELTARUNE-copia/` |
| **Vanilla (parchear desde aquí)** | `~/.local/share/Steam/steamapps/common/DELTARUNE/` — se reconoce porque **no** tiene `lang/` |
| Pack de idiomas usado en las pruebas | `~/Proyectos/Letra Delta - Repos/DELTARUNE - LETRA DELTA/lang` |
| UndertaleModCli | `~/Proyectos/Letra Delta - Repos/LETRA DELTA/letradelta/herramientas/UTMT_CLI_v0.9.1.1-Ubuntu/UndertaleModCli` |

La rama no está pusheada. `origin` ya apunta a GitHub, así que `git push -u origin
idiomas-nativos` la sube cuando se quiera.

## Reconstruir el build

Siempre **sobre copias**: nunca parchear in-place la carpeta limpia.

```bash
CLI="$HOME/Proyectos/Letra Delta - Repos/LETRA DELTA/letradelta/herramientas/UTMT_CLI_v0.9.1.1-Ubuntu/UndertaleModCli"
SCR="$HOME/Proyectos/Letra Delta - Repos/DeltranslatePatch-idiomas-nativos/scripts"
VAN="$HOME/.local/share/Steam/steamapps/common/DELTARUNE"
DST="$HOME/.local/share/Steam/steamapps/common/DELTARUNE-copia"

# Capítulos: Fix.csx y DESPUÉS Borders.csx sobre su salida
for N in 1 2 3 4 5; do
    cp "$VAN/chapter${N}_windows/data.win" "ch${N}.win"
    "$CLI" load "ch${N}.win"       -s "$SCR/Chapter${N}/Fix.csx"     -o "ch${N}_final.win" -v < /dev/null
    "$CLI" load "ch${N}_final.win" -s "$SCR/Chapter${N}/Borders.csx" -o "ch${N}_final.win" -v < /dev/null
    cp "ch${N}_final.win" "$DST/chapter${N}_windows/data.win"
done

# Menú raíz: solo Fix.csx, sin bordes
cp "$VAN/data.win" menu.win
"$CLI" load menu.win -s "$SCR/Menu/Fix.csx" -o menu_final.win -v < /dev/null
cp menu_final.win "$DST/data.win"
```

**En segundo plano hay que cerrarle stdin (`< /dev/null`)** o el CLI se cuelga esperando, con
0 s de CPU, indefinidamente.

**`rc=0` NO valida un parcheo.** Un error de compilación GML descarta el grupo entero y aun así
sale rc=0 y "Saved data file to...". Hay que correr con `-v` y grepear:

```bash
grep -iE "Failed to find a valid|floating outside|Ошибка при компиляции" *.log
```

Números de referencia con esta rama (si salen otros, algo pasó):

| | Cap.1 | Cap.2 | Cap.3 | Cap.4 | Cap.5 | Menú |
|---|---|---|---|---|---|---|
| Gemelos | 45 | 96 | 169 | 185 | 127 | 15 |
| Tamaño final | 19,8 MB | 78,6 MB | 158,8 MB | 146,8 MB | 200,7 MB | 3,0 MB |

## Qué está hecho y comprobado

### Probado en el juego

- Los cinco capítulos, en español y en los dos idiomas nativos. El japonés sale con sus fuentes
  y sus assets.
- El crash de `scr_asterskip` (Cap.5, hablando con Flowery, **solo en inglés**) resuelto.
- La fila "Borde" del menú de opciones aparece y el cursor cuadra, en todos los idiomas.

### Comprobado sobre el `data.win` (no en pantalla)

- 0 gemelos fallidos y 0 errores de compilación en los seis `data.win`.
- **Idempotencia**: repasar el patcher sobre un `data.win` ya parcheado da el mismo resultado.
  Verificado contando gemelos recursivos (debe ser 0; ver el anexo).
- **Coherencia**: ninguna entrada que corra código del mod llama a un script desviado a vanilla
  (ahora mismo trivial: no hay ninguno).
- Menú: 15 gemelos en `obj_CHAPTER_SELECT`, `obj_screen_start`, `obj_screen_loading`,
  `obj_ui_chapter` y `obj_ui_choice`; `obj_init_pc` y `obj_screen_select_footer` sin gemelo.

### Sin probar todavía

- **El menú raíz en el juego** (commit `caf95c1`). Es lo último que se tocó y no se ha visto en
  pantalla: pantalla de inicio, selector de capítulo, diálogo de "¿empezar desde el Capítulo 1?"
  y el de importar partida, en japonés.
- **La GUI de UndertaleModTool.** El arreglo del hilo de UI (`ExecuteInUIThread` alrededor de
  `CreateBlankFunction`) no se puede validar por CLI: ahí ese fallo no se manifiesta nunca.
- **Cambio de idioma en caliente** hacia y desde un nativo, sin reiniciar.

## Lo que falta

1. Probar el menú en japonés (arriba).
2. **"Config" del pie del menú sigue en inglés.** Es una etiqueta del fork que no existe en
   vanilla, así que no hay original japonés que copiar. Habría que decidir uno (`設定`).
3. **Los `gml_Script_*` con ajustes por idioma no están cubiertos**: unos 15 de los 164, en
   `scr_charbox`, `scr_roomname`, `scr_credit`, `scr_84_get_sound`. **Leer antes la sección de
   abajo sobre los gemelos de script**: se intentó dos veces y rompió el juego las dos.
4. `TwinObjectOf` no reconoce los eventos `Collision_<objeto>` (la regex pide `_\d+$`). Si un
   objeto con gemelo tiene evento de colisión, ese evento se queda con el código del mod
   mientras el resto corre vanilla. Conviene excluirlos **a propósito** (dentro de una función,
   `other` ya no es la instancia con la que colisionas, así que el gemelo no sería fiel).
5. Quedó un `if (true) {` huérfano en el `scan_languages` del gamecontroller compartido, resto
   de un guard eliminado.
6. Ya **no hace falta compatibilidad con UndertaleModLib 0.8** (confirmado por el usuario,
   2026-08-06): el `#region Обратная совместимость` de `BaseFix.csx` se puede simplificar.

## Cosas que costó averiguar (para no repetirlas)

### `ReplaceGML` no compila nada, y el grupo final es todo-o-nada

`ReplaceGML` solo apunta el texto en `changedCodes`; todo se compila al final en un único
`CompileGroup` en `SaveEntries()`. Si **una sola** entrada no compila, se descarta el grupo
entero y el script termina con rc=0 y "Saved data file to...".

Consecuencia para los gemelos: su cuerpo es salida del **decompilador** sobre un `data.win`
arbitrario, no GML escrito a mano y revisado. Basta con que una actualización del juego traiga
algo que Underanalyzer decompile mal para tumbar el parche entero sin avisar. Por eso cada
gemelo se compila **en su propio `CompileGroup`** (`TwinCompile`) y se saca de `changedCodes`;
si falla, se deja la función vacía, no se pone el desvío y se reporta en `twinFailed`.

### La pasada 3 necesita `GetOrig()`, no `Decompile()` a pelo

Las entradas que el mod no reemplaza no las respalda nadie. Sin el `<entrada>_old`, al repasar
el patcher sobre un `data.win` ya parcheado, `Decompile` devuelve el código **con el desvío ya
puesto** y el gemelo pasa a ser:

```gml
scr_native_X() { if (is_native_lang()) { scr_native_X(); exit; } ... }
```

o sea, recursión infinita en cuanto se juega en idioma nativo. **Reproducido: 31 de los 49
gemelos del Cap.1 quedaban recursivos**, con rc=0 y sin un solo aviso.

### `CreateBlankFunction` tiene que ir en el hilo de UI

Muta `Data.Code`, `Data.Scripts` y `Data.GlobalInitScripts`, y se llama desde dentro del
`Task.Run` de la sustitución. Por CLI da igual; en la GUI de UMT 0.9 tocar esas colecciones
desde otro hilo revienta el binding. Va envuelto en `ExecuteInUIThread`, como ya hacía
`GetOrig()` con su `Data.Code.Add`.

### NO parchear el gemelo desde `Borders.csx`

Se intentó encolar los parches de bordes también sobre el gemelo, con
`ThrowOnNoOpFindReplace = false`. **Sale mal**: los parches de una línea son iguales en vanilla
y en el texto del mod, así que casan contra el gemelo; los bloques multilínea están escritos
contra el texto del mod y no casan, y se saltan en silencio. El gemelo queda **a medio
parchear**, que es peor que las dos opciones puras:

- **Cap.5**: el Step del gemelo pasaba a 8 filas navegables (`> 6` → `> 7`, una línea) mientras
  su Draw seguía sin dibujar la fila del borde (en vanilla solo existe dentro de la rama de
  consola, y el bloque que aplana ese gate es multilínea) → el corazón bajaba a una fila que no
  se dibuja.
- **Cap.1-4**: el corazón se movía a `yy + 140` (una línea) con las filas en las posiciones
  vanilla (`yy + 150`, multilínea) → cursor 10 px descolocado.

Como el gemelo se congela **antes** de que Borders toque nada, dejarlo intacto lo hace
consistente por construcción. Los cinco `Borders.csx` son hoy byte-idénticos a `main`.

La solución adoptada para que la fila del borde exista en todos los idiomas fue meter
`obj_darkcontroller_` en la lista negra: ese menú corre **siempre** la versión del mod. Se
pierden los ajustes finos de vanilla ahí (el 62 % de los 164), a cambio de que la fila esté y el
cursor cuadre. Si algún día se quiere el menú vanilla **con** la fila, hay que escribir esos
parches una segunda vez **contra el texto vanilla**, no reutilizar los del mod.

### NO dar gemelo a los `gml_GlobalScript_*` sin resolver antes el grafo de llamadas

Se intentó dos veces y **rompió el arranque las dos**. El razonamiento parecía sólido y no lo es:

1. Criterio *"existe en vanilla → gemelo"*. De las 60 funciones que toca el mod en el Cap.5, 31
   son nuevas del fork y 29 existen en vanilla, así que la pregunta parecía separar sola la
   infraestructura del código de juego. **No lo hace**: entre esas 29 están los resolutores
   (`scr_84_get_sprite`, `_get_sound`, `_get_font`) y la familia `*loc`. El del mod acaba
   siempre en `asset_get_index(...)`, o sea **es total**; el vanilla hace `ds_map_find_value` y
   devuelve `undefined` si la clave no está. Todo el código del mod da por hecho lo primero. Al
   desviarlos, `obj_initializer2_Create_0` (lista negra → corre código del mod) metía `undefined`
   en `font_add_sprite_ext` y **el Cap.5 reventaba nada más entrar**.
2. Criterio afinado *"y que la versión del mod no llame a funciones del fork"*. Seguía roto:
   `scr_windowcaption` es código de juego puro y pasa el filtro, pero lo llama
   `obj_initializer2_Create_0` → `PROCESS_LOGO` con "I32 argument is undefined".

**La regla que haría falta: una función solo puede irse a vanilla si TODOS sus llamadores se van
a vanilla.** Y ahí está el muro: hace falta el **grafo de llamadas**, y no se consiguió sacar.
Se intentó por bytecode, recorriendo primero los `Opcode.Call` y luego **toda** referencia a
función: **no aparecen las llamadas a funciones de usuario de GMS 2.3**, que se compilan como
referencia a una variable global, no como `ValueFunction`. El caso que lo destapó:
`obj_ch5_DWC_Onsen_Step_0` llama a `scr_miniface_init_flowers` y el grafo no lo veía. (Esa
entrada tampoco está en `CodeEntries` ni en `CodeChanges`: la toca el mecanismo de
`CodesWithSprites.json`, así que mirar solo los textos que escribe el mod tampoco basta.)

Si se retoma: el siguiente sitio donde mirar es `ValueVariable`, no `ValueFunction`. Y no
entregar nada sin dejar en cero el verificador del anexo.

En su lugar, el crash de Flowery se arregló **donde está el acoplamiento**: `scr_asterskip` usa
`cur_string_width`, una variable que inventa el mod y que inicializa `obj_writer_Create_0`; en
idioma nativo `obj_writer` corre su gemelo vanilla y no existe. La guarda es
`if (variable_instance_exists(id, "cur_string_width"))`. En japonés no saltaba porque esa línea
vive dentro de `if (aster == 1 && autoaster == 1)` y el japonés no usa los asteriscos.

### El menú raíz no tiene sistema de localización

Es **más fácil** que los capítulos, al revés de lo que parecía. El `data.win` de la raíz no
tiene `scr_84_init_localization`, ni `langopt`, ni `stringsetloc`: el inglés y el japonés viven
en ternarios `(global.lang == "en") ? "Chapter Select" : "チャプター選択"` repartidos por 12
entradas, las fuentes se piden **por id** (`_font = (global.lang == "en") ? 2 : 1`) y
`obj_init_pc_Create_0` ya fija `global.lang` leyendo `LANG.LANG` del `true_config.ini`.

Así que sirve el mismo mecanismo de gemelos: `twinEnabled` es `true` siempre (antes se
desactivaba con `!ScriptPath.Contains("Menu")`), más una copia propia de `is_native_lang()` en
`Menu/CodeEntries`, el alta de en/ja en su `scan_languages` y una rama nativa en su
`scr_init_localization` que aquí no carga nada: solo escribe `LANG.LANG` y suelta las fuentes
del pack anterior.

Nota: las fuentes japonesas del menú usan **prefijo** (`fnt_ja_main`), no sufijo
(`fnt_main_ja`). La nota antigua que decía lo contrario era falsa.

### Lo que no puede delegar en el gemelo tiene que llevar los idiomas encima

En idioma nativo no hay pack, así que `scr_get_lang_string` devuelve su primer argumento: el
literal **inglés**. Eso dejaba en inglés los cinco nombres de capítulo de `scr_init` y el "Quit"
del pie del menú, aunque el vanilla los tiene en japonés. Los dos llevan ahora:

```gml
is_native_lang() ? ((global.lang == "en") ? "Quit" : "終了")
                 : scr_get_lang_string("Quit", "...")
```

con los textos japoneses **copiados del vanilla**, no inventados. Es la frontera natural: el
gemelo cubre todo lo que puede correr vanilla, y lo poco que por necesidad no puede (lista
negra) se lleva los tres idiomas consigo.

### La decisión es POR OBJETO, no por entrada

Si el `Draw` de un objeto corriera vanilla y su `Step` se quedara con el del mod, el cursor de
un menú se desincroniza del layout que se dibuja. Por eso basta con que **una** entrada del
objeto tenga lógica por idioma para que vaya el objeto entero, y por eso existe la pasada 3, que
congela también las entradas que el mod no reemplaza pero que tocan después `Borders.csx` o
`CodeChanges.txt`.

### La lista negra y por qué está cada uno

`obj_gamecontroller_`, `obj_lang_settings_`, `DEVICE_MENU_`, `obj_time_`,
`obj_border_controller_`, `obj_initializer2_`, `obj_date_controller_`, `obj_onion_event_`,
`obj_room_ranking_b_`, `obj_ch2_lw_cutscenes_short_`, `obj_dw_church_ripplepuzzle_postgers_`,
`obj_darkcontroller_`, y en el menú `obj_init_pc_` y `obj_screen_select_footer_`.

El criterio es siempre el mismo: **entradas que sostienen funcionalidad propia del fork**. Con
gemelo, en idioma nativo esa funcionalidad desaparecería. Los casos críticos son `DEVICE_MENU_*`
y `obj_screen_select_footer_`, que es de donde se abre el selector de idiomas: sin ellos te
quedas en japonés sin forma de volver al español.

### Otras dos que ya venían de antes

- **El layout real de `lang/` es "pack suelto"**: `settings.json` + `chapter1..5` en la raíz, no
  subcarpetas por idioma. Eso pone `global.is_single_lang_mode = true`. Ninguna feature nueva
  del selector debe ir detrás de `if (!global.is_single_lang_mode)`: en la instalación real no
  se ejecutaría nunca. El modo suelto solo cambia dónde vive el pack, no que haya selector.
- **El `font_map` usa dos convenciones de clave**: el mod registra `fnt_main`; el juego registra
  `main` (apuntando a `fnt_ja_main`). El código vanilla pide el nombre corto (128 veces solo en
  el Cap.5), así que `scr_84_get_font` y `scr_get_font` prueban las dos.

## Anexo: verificadores

No están en el repo; se usaban como `.csx` sueltos contra un `data.win` ya parcheado:

```bash
"$CLI" load ch5_final.win -s Coherencia.csx < /dev/null
```

**Coherencia** — ninguna entrada que corra código del mod puede llamar a un script desviado a
vanilla. Es el que hay que dejar en cero antes de tocar nada de los gemelos de script. La clave
está en distinguir el código del mod del vanilla puro: **las entradas que el mod toca son
exactamente las que tienen respaldo `_old`**.

```csharp
using System; using System.Linq; using System.IO; using System.Text;
var ctx = new GlobalDecompileContext(Data); var st = Data.ToolInfo.DecompilerSettings;
string Dec(UndertaleCode c){ try { return new Underanalyzer.Decompiler.DecompileContext(ctx,c,st).DecompileToString(); } catch { return ""; } }

var desviados = new List<string>();
foreach (var c in Data.Code.Where(x => x.Name.Content.StartsWith("gml_GlobalScript_")
        && !x.Name.Content.Contains("scr_native_") && !x.Name.Content.EndsWith("_old")))
    foreach (System.Text.RegularExpressions.Match m in
             System.Text.RegularExpressions.Regex.Matches(Dec(c), @"return scr_native_([A-Za-z_0-9]+)\("))
        if (!desviados.Contains(m.Groups[1].Value)) desviados.Add(m.Groups[1].Value);

var sb = new StringBuilder(); int riesgos = 0;
foreach (var c in Data.Code.Where(x => x.Name.Content.StartsWith("gml_Object_") && !x.Name.Content.EndsWith("_old")))
{
    var t = Dec(c);
    if (t.Contains("if (is_native_lang())") && t.Contains("scr_native_")) continue;   // va a vanilla
    if (Data.Code.ByName(c.Name.Content + "_old") == null) continue;                  // el mod no la toca
    foreach (var d in desviados)
        if (System.Text.RegularExpressions.Regex.IsMatch(t, @"\b" + d + @"\s*\("))
        { sb.AppendLine("RIESGO: " + c.Name.Content + " llama a " + d); riesgos++; }
}
sb.AppendLine(riesgos == 0 ? "OK" : ("HAY " + riesgos + " RIESGOS"));
File.WriteAllText(Environment.GetEnvironmentVariable("OUT"), sb.ToString());
```

**Gemelos recursivos** — para comprobar la idempotencia hay que parchear dos veces seguidas el
mismo `data.win` y luego contar los gemelos cuyo cuerpo contenga `is_native_lang`: deben ser
**cero**. También conviene contar los de cuerpo vacío (gemelos que no compilaron) y comprobar que
el número de entradas con desvío coincide con el de gemelos.

**Menú de opciones** — el invariante del número de filas: en Cap.1-4 el gemelo del
`obj_darkcontroller_Step_0` tenía `submenucoord[30] > 6` (7 filas) y la entrada `> 7` (8 filas);
en Cap.5 los dos `> 7`. Ya no aplica desde que `obj_darkcontroller_` está en la lista negra, pero
sirve si alguna vez se le devuelve el gemelo.
