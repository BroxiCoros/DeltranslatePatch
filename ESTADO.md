# Estado: idioma nativo (inglés)

Última actualización: **2026-08-08**. Rama `idiomas-nativos-en` del repo principal.

Este documento es para retomar el trabajo sin reconstruir el contexto. El `CHANGES.md` del
repo explica *qué hace* el mod; esto explica *dónde está esto*, *qué está comprobado* y
sobre todo *qué ya se intentó y salió mal*, que es lo que más tiempo costó.

---

## El japonés se descartó (2026-08-08)

Este trabajo nació cubriendo los **dos** idiomas de fábrica del juego, inglés y japonés, y
así se probó en pantalla. Decisión del usuario: **se queda solo el inglés.** El japonés
funcionaba, pero es el que arrastra todo lo caro y lo que quedaba a medias — las fuentes y
sprites `_ja`, los 16 pares (entrada, fuente) ambiguos sin resolver, y los textos del selector
traducidos a mano. El inglés nativo es, literalmente, "correr el código vanilla".

**Qué cambió al quitarlo:** solo las dos listas `native_codes` / `native_names` de los
`scan_languages()` (el del gamecontroller compartido y el del menú), que pasan de
`["en", "ja"]` a `["en"]`. Nada más. El mecanismo entero — `is_native_lang()`, los gemelos
vanilla, `is_english()`, la rama nativa de los `scr_init_localization` — es **agnóstico del
idioma**: mira el flag `native` del settings inyectado, no el código concreto.

**Volver a ofrecer el japonés = volver a añadirlo a esas dos listas.** Lo que quedaba
pendiente para él sigue documentado abajo, sin tocar. Todo el código japonés que quedó por
en medio (los ternarios `(global.lang == "en") ? "Config" : "設定"`, las ramas
`(global.lang == "ja")` de la geometría del menú de opciones, la pasada de fuentes clavadas)
se dejó a propósito: es inalcanzable mientras "ja" no sea nativo, y borrarlo solo añadía
riesgo a algo ya probado.

Abajo, todo lo que hable del japonés describe el estado del mecanismo, no lo que se ofrece
hoy en el selector.

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

La rama está pusheada a `origin` (GitHub, `BroxiCoros/DeltranslatePatch`). Ese repo no tiene
`credential.helper` configurado a ningún nivel, así que un `git push` a secas se queda colgado
esperando credenciales; con `gh` ya autenticado, sale con
`git -c credential.helper='!gh auth git-credential' push` (no deja nada escrito en la config).

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

### Cuánto tarda, y cuánto cuestan los gemelos

Medido el 2026-08-08 en el equipo de siempre (Ryzen 5 5500, 12 hilos, NVMe), parcheando desde
el vanilla limpio y con la caché de disco caliente. Tres rondas de esta rama (84,2 / 82,4 /
85,1 s) y dos de `main`. **Los tiempos absolutos son de esta máquina y no valen como referencia
en otra**; lo que sí viaja es la proporción.

| Segundos | Cap.1 | Cap.2 | Cap.3 | Cap.4 | Cap.5 | Menú | **Total** |
|---|---|---|---|---|---|---|---|
| `Fix.csx` esta rama | 4,2 | 8,5 | 13,1 | 14,1 | 15,1 | 2,5 | **57,4** |
| `Fix.csx` en `main` | 3,3 | 5,1 | 7,1 | 7,4 | 9,1 | 2,2 | **34,3** |
| Sobrecoste | +0,8 | +3,4 | +5,9 | +6,7 | +6,0 | +0,3 | **+23,1** |
| `Borders.csx` | 3,0 | 4,6 | 5,6 | 5,9 | 7,0 | — | **26,1** |

Build entero (los seis `data.win`): **83,9 s esta rama contra 59,3 s en `main`, +41 %.** Un
minuto pasa a ser minuto y veinticinco, así que el coste no molesta en la práctica.

Ojo con la **dispersión**: antes de la pasada de fuentes clavadas, dos rondas seguidas caían
dentro de ~1 s. Ahora el rango es de ~3 s (y una ronda suelta llegó a 89,5 s con la máquina
ocupada). Para comparar dos versiones no basta una ronda de cada una.

Tres cosas que confirma el reparto:

- **Todo el sobrecoste está en `Fix.csx`.** Los `Borders.csx` son byte-idénticos a `main` y
  tardan lo mismo (+3 %, dentro del ruido). Es la comprobación cruzada de que el reloj mide lo
  que debe.
- **La mayor parte sale de los gemelos, no del tamaño del `data.win`.** El Cap.4 es el más caro
  en absoluto aunque el Cap.5 es 54 MB más grande: el Cap.4 tiene 185 gemelos y el Cap.5, 127.
  El gemelo sale entre **~12 ms** (Cap.1 y menú) y **~40 ms** (Cap.5): no es constante, sube con
  el tamaño de las entradas, que es lo esperable si lo que se paga es decompilar la entrada y
  recompilarla en su propio `CompileGroup` (el `TwinCompile` aislado que exige el diseño; ver
  arriba por qué no puede ir en el grupo común).
- **La pasada de fuentes clavadas cuesta ~4,3 s** de los 57,4 (era 53,1 sin ella). Recorre
  `backedList` decompilando cada entrada y su `_old`; el `_old` es trivial, pero son dos
  decompilaciones por entrada tocada.

Para dimensionar lo que falta: cubrir los ~15 `gml_Script_*` de la lista de pendientes añadiría
medio segundo por capítulo, más o menos. El presupuesto de tiempo no es argumento en esa
decisión.

## Qué está hecho y comprobado

### Probado en el juego

- Los cinco capítulos, en español y en los dos idiomas nativos. El japonés sale con sus fuentes
  y sus assets.
- **El menú raíz**, en los dos idiomas nativos: el selector de idiomas se abre y funciona, el
  japonés sale con su fuente, los textos siguen al idioma y la esquina del copyright se ve
  igual que en vanilla. Costó cuatro fallos encadenados; están todos abajo, en su sección.
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
- **Fuentes clavadas** (2026-08-08): 95 sitios devueltos al asset del vanilla y **0 residuos
  inequívocos** en los cinco capítulos; quedan los 16 ambiguos de la lista de pendientes. El
  verificador es el `Ambig2.csx` del anexo.

### Sin probar todavía

- **Los dos arreglos del 2026-08-08 en pantalla**: las fuentes del Cap.4 en japonés nativo
  (resultados del concierto, cuenta 3-2-1, rango) y el menú de opciones del Cap.5, que era
  donde la columna de valores se montaba encima de la etiqueta. Comprobados sobre el
  `data.win`, no vistos todavía en el juego.
- **Los diálogos del menú raíz**: "¿empezar desde el Capítulo 1?" y el de importar partida, en
  japonés. El resto del menú sí se ha visto en pantalla.
- **La GUI de UndertaleModTool.** El arreglo del hilo de UI (`ExecuteInUIThread` alrededor de
  `CreateBlankFunction`) no se puede validar por CLI: ahí ese fallo no se manifiesta nunca.
- **Cambio de idioma en caliente** hacia y desde un nativo, sin reiniciar.

## Lo que falta

1. Probar los dos diálogos del menú en japonés (arriba).
2. **Los `gml_Script_*` con ajustes por idioma no están cubiertos**: unos 15 de los 164, en
   `scr_charbox`, `scr_roomname`, `scr_credit`, `scr_84_get_sound`. **Leer antes la sección de
   abajo sobre los gemelos de script**: se intentó dos veces y rompió el juego las dos.
3. **El selector de idiomas del menú sale en inglés cuando el idioma nativo es el japonés,**
   salvo las cinco etiquetas que se tradujeron a mano (ver abajo). Las que quedan son las de
   `special_mode` y `translated_songs`, que hoy no se dibujan nunca en idioma nativo porque un
   idioma sin pack no ofrece esos interruptores. Si algún día se ofrecen, hay que traducirlas.
4. `TwinObjectOf` no reconoce los eventos `Collision_<objeto>` (la regex pide `_\d+$`). Si un
   objeto con gemelo tiene evento de colisión, ese evento se queda con el código del mod
   mientras el resto corre vanilla. Conviene excluirlos **a propósito** (dentro de una función,
   `other` ya no es la instancia con la que colisionas, así que el gemelo no sería fiel).
5. Quedó un `if (true) {` huérfano en el `scan_languages` del gamecontroller compartido, resto
   de un guard eliminado.
6. Ya **no hace falta compatibilidad con UndertaleModLib 0.8** (confirmado por el usuario,
   2026-08-06): el `#region Обратная совместимость` de `BaseFix.csx` se puede simplificar.
7. **Los 16 pares (entrada, fuente) ambiguos** que la pasada de fuentes clavadas no puede
   decidir sola, porque el vanilla usa **las dos formas** para la misma fuente en la misma
   entrada. Hay que mirarlos sitio por sitio. Son:

   | Cap. | Entrada | Fuente |
   |---|---|---|
   | 2, 3, 4, 5 | `obj_fusionmenu_Draw_0` | `fnt_dotumche` |
   | 3, 4, 5 | `obj_rhythmgame_Draw_0` | `fnt_main` |
   | 3 | `obj_dw_gameshow_screen_Draw_0`, `obj_quizsequence_Draw_0`, `obj_b2westshop_Draw_0` | `fnt_8bit` |
   | 3 | `obj_couchwriter_Draw_0` | `fnt_dotumche` |
   | 4 | `obj_mike_minigame_controller_Draw_0`, `obj_mike_minigame_tv_Draw_0`, `obj_mike_controller_Draw_0` | `fnt_mainbig` |
   | 4 | `obj_mike_attack_controller_Draw_0` | `fnt_main` |
   | 5 | `obj_dw_fcastle_cafe_Draw_0` | `fnt_mainbig` |

   El recuento sale en el log de cada `Fix.csx` ("ambiguos (a mano): N"); si una actualización
   del juego lo mueve, es que cambió el reparto y hay que repasar la tabla.
8. **Los sprites tienen la misma pasada pero sin verificador.** El ternario de
   `CodesWithSprites.json` se aplica a ciegas a todas las entradas: donde
   `chemg_sprite_map` no tiene variante japonesa es un no-op inofensivo, pero **no se ha
   medido la población equivalente en las entradas escritas a mano**, como sí se hizo con las
   fuentes. Conviene portar el `Ambig2.csx` del anexo a sprites antes de darlo por cerrado.

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

Nota sobre el nombre de las fuentes japonesas, que **las dos versiones son ciertas** y por eso
lío tanto: en el `data.win` **vanilla** llevan prefijo (`fnt_ja_main`), y en el **parcheado**
llevan sufijo (`fnt_main_ja`), porque el propio `BaseFix.csx` las renombra al final (el bucle
sobre `Data.Fonts` que hace `Replace("_ja_", "_") + "_ja"`). La nota antigua que hablaba de
sufijo no era falsa: describía el estado después de parchear, que es el único que existe en
tiempo de ejecución. **Cualquier `asset_get_index` sobre una fuente japonesa tiene que usar el
nombre CON SUFIJO**, y si se saca la lista de un volcado, ojo con volcar el vanilla.

### Los cuatro fallos del menú raíz en idioma nativo (2026-08-06)

El menú se dio por hecho en `caf95c1` sin haberlo visto en pantalla. Al probarlo salieron cuatro
fallos encadenados, y ninguno daba error: todos fallaban **en silencio**. Van juntos aquí porque
comparten moraleja — el menú no tiene sistema de localización, así que cada pieza del fork que
vive ahí hay que mirarla una por una.

1. **El botón "Config" hacía el interruptor en↔ja de vanilla.** El pie sube el evento a
   `obj_screen_select` y de ahí al `trigger_event` de `obj_CHAPTER_SELECT`, cuyo
   `toggle_language()` el mod redefine para abrir el selector. Pero `obj_CHAPTER_SELECT` **sí
   lleva gemelo** (su Create está lleno de ternarios `global.lang`), así que en idioma nativo
   corría el `toggle_language()` original: botón que dice "Config" y hace otra cosa, y sin forma
   de volver a un pack. Meterlo en la lista negra habría tirado todo el japonés del menú, que es
   justo lo que se buscaba; se arregla en el pie, que ya está en la lista negra y puede abrir el
   selector él mismo.
2. **`global.lang_map` no se creaba nunca en idioma nativo.** Dos consecuencias. Una, el selector
   seguía sirviendo los textos del **pack anterior** (se quedaba en español, y encima cortado,
   porque la fuente del juego no tiene tildes). Y dos, la gorda:
   `obj_gamecontroller_Create_0` empieza con `if (variable_global_exists("lang_map")) return;`,
   así que sin ese global **cada `room_restart` reejecutaba el Create entero** — y salir del
   selector es un `room_restart` —, que rehace `global.font_map` vacío. Creándolo vacío en la
   rama nativa, el idioma nativo entra por la misma puerta que un pack.
3. **`asset_get_index("fnt_ja_main")` devolvía -1.** Por el renombrado de fuentes de arriba. Con
   una guarda `!= -1`, las cinco altas al `font_map` se saltaban sin decir nada y el selector
   caía a la fuente latina: japonés en blanco. Es el fallo que costó dos rondas de "ya está
   arreglado" y no lo estaba.
4. **`update_language()` caía al relleno `{"name": "English"}`.** No hay carpeta de pack que
   mirar, así que arrancar el juego **ya** en japonés dejaba `global.lang_settings` con ese
   struct de mentira y el selector anunciaba el japonés como "English". Ciclando con ←/→ no se
   ve, porque ahí `change_language` sí lo coge de `global.all_lang_settings`. La rama nativa lo
   saca de esa caché.

Y dos detalles de paridad visual en `obj_ui_version` (la esquina del copyright), que **no lleva
gemelo** porque su vanilla no menciona `global.lang`: vanilla clava `_font = 2` (la fuente
latina) y no consulta el idioma, así que esa esquina se ve igual en inglés que en japonés; el
mod la había cambiado a `scr_get_font("fnt_main")`, que en cuanto el mapa apuntó bien empezó a
devolver la japonesa. Y la línea "Translation version - X" es de cosecha del mod: en idioma
nativo no hay pack cuya versión anunciar, así que se cae y las otras dos vuelven a las
coordenadas de vanilla (`y + 24` e `y + 40`), que el mod había subido 8 px para hacerle sitio.

Traducciones japonesas escritas a mano para las etiquetas del fork que no existen en vanilla
(o sea, sin original que copiar): `設定` (Config, en el pie), `言語設定` (título del selector),
`言語` (Language) y `戻る` (Return). Las de `Yes`/`No` sí son las del juego, `はい` / `いいえ`,
copiadas de `obj_CHAPTER_SELECT_Create_0`.

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

### El criterio de gemelo NO ve los fallos que introduce el propio mod (2026-08-08)

Esta es la clase de fallo que se destapó probando el Cap.4 en japonés nativo, y conviene
entenderla porque **el gemelo no la cubre por diseño**.

El criterio para dar gemelo es "¿el vanilla menciona `global.lang` o `langopt`?". Eso encuentra
los sitios donde el vanilla **tiene** lógica de idioma. No encuentra el caso contrario: donde el
vanilla es deliberadamente **ciego** al idioma y es el mod el que le añade la dependencia.

El ejemplo canónico son las fuentes. El vanilla escribe:

```gml
draw_set_font(fnt_8bit);                  // "aqui la latina SIEMPRE"
draw_set_font(scr_84_get_font("8bit"));   // "aqui la del idioma"
```

Las dos formas conviven a propósito: la primera está en pantallas que no se localizan (los
resultados del concierto, la cuenta 3-2-1, el marcador del ritmo salen en inglés aunque el juego
esté en japonés). El mod convierte **la primera en la segunda**, y como
`scr_84_init_localization` registra `font_map["8bit"] = fnt_ja_8bit`, en japonés nativo esas
pantallas se van a la fuente japonesa y se ven finas. Esa entrada no menciona `global.lang` en
vanilla, así que nunca iba a tener gemelo.

Son **dos poblaciones distintas** y hacen falta dos arreglos:

1. **Las que convierte el patcher**, por `CodesWithFonts.json`. Se arregla en el sitio donde se
   emite la conversión (`BaseFix.csx`, región *Замена шрифтов*): en vez de la llamada pelada, el
   ternario `(is_native_lang() ? fnt_X : scr_84_get_font("X"))`. Una línea, 133 entradas.
2. **Las que ya vienen convertidas** en el GML escrito a mano de `CodeEntries/`. El patcher no
   las toca, así que hay que ir a buscarlas: región *Fuentes clavadas del vanilla en las
   entradas escritas a mano*, al final de `BaseFix.csx`. **95 sitios en 27 pares.**

La clave del segundo arreglo es que **el respaldo `_old` ES el vanilla**, así que sirve de
oráculo: si para una fuente el vanilla usaba solo el literal y nunca la búsqueda, todas las
llamadas de esa entrada vuelven al literal. Si usaba las dos, el criterio no distingue cuál es
cuál y se deja quieta (son los 16 de la lista de pendientes).

Dos trampas al leer el `_old`:

- **No guarda GML, guarda el vanilla como literal escapado** (`var code = "...";`). Hay que
  deshacer el escapado antes de buscar nada; ver `VanillaOf()`. Si se busca en crudo,
  `scr_84_get_font("main")` **nunca casa**, porque en el escapado es `scr_84_get_font(\"main\")`.
  Eso da un falso "0 ambiguos" muy convincente: pasó, y solo se notó al cuadrar los recuentos.
- Los `_old` solo existen para las entradas que el mod toca, que es justo lo que se quiere
  mirar. Iterar `backedList` en vez de `Data.Code` evita decompilar el juego entero.

Los sprites tienen el mismo mecanismo (`CodesWithSprites.json` → `scr_84_get_sprite`) y el mismo
arreglo del punto 1, pero **el del punto 2 no se ha hecho ni medido** para ellos.

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

**Fuentes clavadas** (`Ambig2.csx`) — el que hay que dejar en cero. Para cada entrada con
respaldo, compara el texto parcheado con el vanilla que guarda su `_old` y clasifica cada par
(entrada, fuente) en tres cajones. **INEQUÍVOCOS debe ser 0**: si sale otra cosa, hay sitios que
en idioma nativo se van a la fuente japonesa donde el vanilla usa la latina. AMBIGUOS es la
lista de pendientes (16 hoy) y CORRECTOS son los que ya estaban bien.

```csharp
using System; using System.Linq; using System.Text; using System.Text.RegularExpressions;
var ctx = new GlobalDecompileContext(Data); var st = Data.ToolInfo.DecompilerSettings;
string Dec(UndertaleCode c){ try { return new Underanalyzer.Decompiler.DecompileContext(ctx,c,st).DecompileToString(); } catch { return ""; } }

// OJO: el _old guarda el vanilla como literal ESCAPADO, no como GML. Sin
// deshacer el escapado, scr_84_get_font("main") no casa nunca (ahi es
// scr_84_get_font(\"main\")) y sale un falso "0 ambiguos".
string Van(string name)
{
    var o = Data.Code.ByName(name + "_old"); if (o == null) return null;
    var t = Dec(o); if (!t.StartsWith("var code = \"")) return null;
    t = t.Substring(12); if (t.Length < 3) return null;
    return t.Remove(t.Length - 3).Replace("\\n","\n").Replace("\\\"","\"")
            .Replace("\\_n","\\n").Replace("\\\\","\\");
}

string[] ja = {"main","mainbig","tinynoelle","dotumche","comicsans","small","8bit","8bit_mixed","legend","legend_alt"};
int limpio=0, ambiguo=0, sitios=0, soloLookup=0; var sb=new StringBuilder();
foreach (var c in Data.Code.Where(x => x.ParentEntry == null && !x.Name.Content.EndsWith("_old")
                                    && !x.Name.Content.Contains("scr_native_")))
{
    var van = Van(c.Name.Content); if (van == null) continue;
    var tNew = Dec(c);
    foreach (var k in ja)
    {
        var llamada = "scr_84_get_font(\"" + k + "\")";
        var rx = new Regex(@"(?<!is_native_lang\(\) \? fnt_" + k + @" : )" + Regex.Escape(llamada));
        int n = rx.Matches(tNew).Count; if (n == 0) continue;
        bool literal = Regex.IsMatch(van, @"\bfnt_" + k + @"\b");
        bool lookup  = van.Contains(llamada);
        if (literal && !lookup) { limpio++; sitios += n; sb.AppendLine("  RESIDUO: " + c.Name.Content + " / " + k); }
        else if (literal && lookup) { ambiguo++; sb.AppendLine("  AMBIGUO: " + c.Name.Content + " / " + k); }
        else if (!literal && lookup) soloLookup++;
    }
}
Console.WriteLine("INEQUIVOCOS (debe ser 0): " + limpio + " pares, " + sitios + " sitios");
Console.WriteLine("AMBIGUOS (a mano): " + ambiguo);
Console.WriteLine("CORRECTOS ya: " + soloLookup);
Console.Write(sb.ToString());
```

Portarlo a sprites es cambiar `scr_84_get_font`/`fnt_` por `scr_84_get_sprite`/`spr_` y la lista
`ja` por las claves de `chemg_sprite_map`. Está sin hacer.
