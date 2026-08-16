# Estado: idioma nativo (inglés)

Última actualización: **2026-08-15**. En `main`.

Este documento es para retomar el trabajo sin reconstruir el contexto. El `CHANGES.md` del
repo explica *qué hace* el mod; esto explica *dónde está esto*, *qué está comprobado* y
sobre todo *qué ya se intentó y salió mal*, que es lo que más tiempo costó.

---

## El japonés: probado dos veces, descartado dos veces

Este trabajo nació cubriendo los **dos** idiomas de fábrica del juego. Se retiró el japonés el
2026-08-08, se volvió a poner el 2026-08-15, y **se volvió a retirar el mismo día tras jugarlo**.
Decisión del usuario, y con razón. Si algún día se retoma, esta sección es lo que hay que leer
antes.

**Poner o quitar el japonés es un solo sitio**: las listas `native_codes` / `native_names` de los
dos `scan_languages()` (el gamecontroller compartido y el del menú). El mecanismo entero —
`is_native_lang()`, los gemelos, `is_english()`, la rama nativa de los `scr_init_localization`,
la pasada de fuentes clavadas — es **agnóstico del idioma**: mira el flag `native` del settings.

**Por qué no sale a cuenta, que no es lo que parecía.** La primera vez se retiró creyendo que el
japonés era lo que hacía lento el parcheo. Eso era **falso** y quedó medido: lo caro son los
gemelos, que sirven igual al inglés, y añadir el japonés cuesta **0 ms**. El motivo real es otro,
y es de mantenimiento: el japonés deja fallos de maquetación que hay que arreglar de uno en uno,
y vuelven con cada actualización del juego. Salen de tres sitios, y **ninguno lo cierra el
mecanismo de gemelos**:

1. **Los ~75 `gml_GlobalScript_*` por capítulo.** No pueden llevar gemelo: hace falta el grafo de
   llamadas y no se pudo extraer (se intentó dos veces y rompió el arranque las dos). Ahí vive
   ~el 9 % de los 164 ajustes por idioma.
2. **Los 16 pares (entrada, fuente) ambiguos**, que hay que decidir sitio por sitio.
3. **Lo que el fork INVENTA y vanilla no tiene** — la fila del BORDE. No hay original que copiar,
   así que hay que maquetarla a mano para cada idioma. En inglés cabe; en japonés no.

**El inglés nativo no da ese problema**, y por eso se queda: la maquetación del mod está hecha
para texto latino de anchura parecida a la inglesa, así que aunque una entrada corra la versión
del mod en vez de la de vanilla, se ve bien igualmente. Dicho al revés: que el inglés funcione no
es prueba de que el mecanismo esté completo, es prueba de que el inglés perdona. El japonés era
lo único que lo ejercía de verdad.

**Qué habría que reponer para intentarlo otra vez**, todo medido y probado el 2026-08-15 antes de
deshacerse:

- Las dos listas → `["en", "ja"]` / `["English", "日本語"]`.
- **La cobertura total de gemelos** (ver la sección de cobertura). Con el criterio de hoy, en el
  Cap.5 solo 127 de 260 entradas caen a vanilla; ampliándolo eran 512 de 532.
- **Los parches del BORDE contra el texto vanilla**, para sacar `obj_darkcontroller_` de la lista
  negra (ver su sección). Funcionaba, pero seguía sin resolver la fila inventada.
- Lo que **no** hizo falta deshacer y ya está puesto: el ayudante `lang_text` de
  `obj_CHAPTER_SELECT` con los textos japoneses del vanilla, y todo el código japonés
  inalcanzable que se dejó a propósito.

Lo que **no** hay que volver a hacer: creer que el problema es el tiempo de parcheo, y reutilizar
los parches del mod sobre el gemelo.

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
| Esto (ya en el repo principal) | `~/Proyectos/Letra Delta - Repos/DeltranslatePatch`, rama `main` |
| Clon histórico donde se desarrolló | `~/Proyectos/Letra Delta - Repos/DeltranslatePatch-idiomas-nativos` — **obsoleto**, `main` está por delante en todo |
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
SCR="$HOME/Proyectos/Letra Delta - Repos/DeltranslatePatch/scripts"
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

Números de referencia (si salen otros, algo pasó). Remedidos sobre `main` el 2026-08-15:

| | Cap.1 | Cap.2 | Cap.3 | Cap.4 | Cap.5 | Menú |
|---|---|---|---|---|---|---|
| Gemelos | 45 | 96 | 169 | 185 | 127 | 6 |
| Fuentes clavadas | 1 | 3 | 47 | 8 | 36 | 0 |
| Ambiguos (a mano) | 0 | 1 | 6 | 6 | 3 | 0 |
| Tamaño final | 19,8 MB | 78,6 MB | 158,8 MB | 146,8 MB | 200,7 MB | 3,0 MB |

Los ambiguos suman **16**, que son exactamente los pares de la tabla de pendientes.

Con la cobertura ampliada que se probó y se deshizo, los gemelos eran 108/349/832/534/516/8 y
los tamaños subían ~1-3 MB por capítulo.

### Cuánto tarda, y cuánto cuestan los gemelos

Remedido el **2026-08-15** en el equipo de siempre (Ryzen 5 5500, 12 hilos, NVMe), parcheando
desde el vanilla limpio y con la caché de disco caliente. **Los tiempos absolutos son de esta
máquina y no valen como referencia en otra**; lo que sí viaja es la proporción. Ojo con la
dispersión: el rango entre rondas es de ~3 s, así que para comparar dos versiones no basta una
ronda de cada una.

| Segundos (`Fix.csx`) | Cap.1 | Cap.2 | Cap.3 | Cap.4 | Cap.5 | **Total** |
|---|---|---|---|---|---|---|
| Un `CompileGroup` por gemelo | 3,9 | 7,9 | 11,8 | 13,0 | 14,4 | **51,0** |
| **Todos en un grupo (hoy)** | **3,8** | **6,3** | **9,2** | **9,6** | **11,5** | **40,3** |
| Sin gemelos (referencia) | 3,4 | — | — | — | 9,1 | — |
| Cobertura total (probada y deshecha) | 4,0 | 7,6 | 11,9 | 10,9 | 14,1 | 48,4 |

Build entero de los seis `data.win`, con bordes y copias incluidas: **~65 s**.

**El coste de los gemelos no era compilar: era montar el `CompileGroup`.** En el Cap.5 los 127
gemelos costaban 5,3 s (14,4 s con ellos contra 9,1 s sin ellos). Cronometrando solo las
llamadas a `Compile()`, 2,4 s de esos 5,3 eran los 127 grupos individuales. Al encolarlos todos
en **un** grupo, el sobrecoste del capítulo baja a ~1,3 s. Es decir, casi todo lo que se pagaba
era el montaje del grupo repetido 127 veces, no el trabajo de compilar.

El aislamiento no se pierde: el grupo de gemelos sigue siendo distinto del grupo final del
patcher, así que un gemelo que no compile no puede tumbar el parche. Lo único que cambia es que
para saber **cuál** falló hay que reintentar uno por uno, y eso solo ocurre cuando algo va mal
(`TwinFlush` en `BaseFix.csx`).

**Verificado que el cambio no altera la salida**: se decompilaron todas las entradas de los dos
builds (el de grupos individuales y el de grupo único) y se compararon una a una —
**Cap.1: 1513 entradas, 0 diferencias. Cap.5: 12350 entradas, 0 diferencias.** El `data.win`
no sale byte-idéntico, pero solo por el orden de serialización; el contenido es el mismo. El
verificador es el `DumpAll.csx` del anexo (decompila todas las entradas raíz a una carpeta,
y luego `diff -rq` entre las dos).

**Lo que NO merece la pena, y por qué.** Se estudió sustituir el gemelo compilado por una
**copia del bytecode vanilla** (copiar la lista de instrucciones al cuerpo de la función en vez
de decompilar y recompilar). Ventaja real: el gemelo pasaría a ser una copia exacta y
desaparecería la dependencia del decompilador. Pero:

- **El ahorro de tiempo ya está cogido.** Lo que iba a ahorrar era justo el `Compile()` de los
  gemelos (2,4 s en el Cap.5), y agrupar los grupos ahorra más (4,0 s) con un cambio de 40
  líneas.
- **Hay que clonar instrucciones a mano.** `UndertaleInstruction` no tiene copia: son dos
  palabras empaquetadas (`_firstWord`, `_primitiveValue`) donde el valor comparte sitio con el
  puntero de la cadena de ocurrencias de variables y funciones. Compartir los objetos entre dos
  entradas corrompe esas cadenas; clonarlos mal, también, y en silencio.
- **No vale para todas.** 38 de los 628 gemelos salen de entradas con **entradas hijas**
  (funciones anónimas y structs declarados dentro del evento: `obj_yellow_trial_manager_Create_0`
  tiene 202, `obj_dw_fcastle_cafe_Other_13` 184). Esas hijas viven como (offset, longitud) dentro
  del bytecode del padre, así que copiar el padre las deja apuntando a otro sitio. Habría que
  duplicarlas y repuntarlas.

Si algún día se quiere la fidelidad bit a bit, la vía que evita todo eso es **no mover bytecode
ninguno**: dejar la entrada vanilla intacta, colgarla de un objeto pantalla creado al vuelo y
desviar con `event_perform_object(obj_native_X, <tipo>, <num>)` en vez de con una llamada a
función. La entrada no se toca, así que hijas, `CodeLocals` y locales siguen válidos solos.

### Cuánto se cubre, y la cobertura total que se probó y se deshizo

El número que hay que mirar no es "cuántos gemelos" sino **qué porcentaje de lo que el mod toca
cae a vanilla en idioma nativo**. Lo mide el `Cobertura.csx` del anexo, sobre un `data.win` ya
parcheado: "el mod la toca" es tener respaldo `_old`, "va a vanilla" es llevar el desvío.

| Cap.5 | Entradas que el mod toca | A vanilla | Corren código del mod |
|---|---|---|---|
| **Criterio de hoy** (`twinLangPattern`) | 260 | 127 (**49 %**) | 133 |
| Ampliado, sin las poblaciones de los JSON | 328 | 231 (70 %) | 97 |
| Cobertura total (probada y deshecha) | 532 | 512 (**96 %**) | 20 |

**La cobertura total funcionaba**, y con ella las 20 restantes eran exactamente la lista negra —
cero sin explicar, clasificadas una a una con el `PorQue.csx` del anexo. Se deshizo al quitar el
japonés: lo que compraba era paridad con el vanilla **japonés**, y costaba ~10 s de parcheo más
y ~380 entradas por capítulo cambiando de comportamiento.

**Cómo se rehace** (dos cambios en `BaseFix.csx`, ambos en el bloque de los gemelos):

1. El criterio pasa de `if (!vacío && twinLangPattern.IsMatch(vgml))` a `if (!vacío)`: gemelo a
   todo objeto que el mod toque.
2. `twinCandidates` suma las demás poblaciones. **Ojo con la forma de cada JSON, que no es la
   misma**, y equivocarse no da error, solo cobertura de menos sin que se note:
   - `CodesWithSprites` / `CodesWithSounds` / `CodesWithSpritesIds` → la clave **es** la entrada;
   - `CodesWithFonts` → la clave es la **fuente** (`fnt_8bit`), las entradas son los **valores**;
   - `ObjectsWithAssignedSprites` → la clave es el **objeto**, hay que expandirla a sus entradas.

**Y la trampa que casi cuela un build roto:** `twinCandidates` alimenta también `entriesOk`, que
es lo que habilita la pasada 2. Al filtrarla a "solo `gml_Object_`", los scripts del fork dejaron
de reemplazarse y `is_native_lang` / `scr_init_localization` se quedaron como la función vacía de
`CreateBlankFunction` — con el patcher diciendo **rc=0, 0 errores y un `data.win` más grande**.
De ahí viene la guarda que avisa si alguna entrada de `CodeEntries` no llegó a aplicarse, y el
chequeo rápido: decompilar `gml_GlobalScript_is_native_lang` y ver que mida ~759 caracteres y no
~30.

### Por qué el inglés no delataba nada de esto

Con el criterio viejo, la mitad de lo que el mod reescribe corria codigo del mod tambien en
idioma nativo, y **en ingles no se notaba**: las entradas del mod estan maquetadas para texto
latino de anchura parecida a la inglesa, asi que se ven bien igualmente. El japones es lo unico
que ejerce la cobertura de verdad, y cada hueco sale a la superficie como un fallo visual. Que
"el ingles funciona" no era prueba de que el mecanismo estuviera bien; era prueba de que el
ingles perdona.

## Qué está hecho y comprobado

### Probado en el juego

- Los cinco capítulos, en español y en inglés nativo. **Reprobado el 2026-08-15** con el
  patcher de hoy (gemelos en un solo `CompileGroup`): sin cambios de comportamiento.
- **El menú raíz** en inglés nativo: el selector de idiomas se abre y funciona, los textos
  siguen al idioma y la esquina del copyright se ve igual que en vanilla. Costó cuatro fallos
  encadenados; están todos abajo, en su sección.
- En japonés se probó todo lo anterior el 2026-08-15 y **funcionaba**, con los defectos de
  maquetación que llevaron a descartarlo (ver la sección del japonés).
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

**Ojo: casi todo lo de esta lista es del japonés, que hoy no se ofrece.** Se deja porque es la
lista de la compra si algún día se retoma; nada de esto afecta al inglés nativo.

1. Los avisos del selector en japonés se arreglaron el 2026-08-15 y **están puestos** (el
   ayudante `lang_text` de `obj_CHAPTER_SELECT`), aunque hoy sean inalcanzables. No hay nada que
   hacer ahí.
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
5. Ya **no hace falta compatibilidad con UndertaleModLib 0.8** (confirmado por el usuario,
   2026-08-06): el `#region Обратная совместимость` de `BaseFix.csx` se puede simplificar.
6. **Los 16 pares (entrada, fuente) ambiguos** que la pasada de fuentes clavadas no puede
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
7. **Los sprites tienen la misma pasada pero sin verificador.** El ternario de
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
algo que Underanalyzer decompile mal para tumbar el parche entero sin avisar. Por eso los
gemelos se compilan **fuera del grupo final** y se sacan de `changedCodes`.

**Fuera del grupo final, pero todos juntos (2026-08-15).** Al principio cada gemelo tenía su
propio `CompileGroup`, y eso costaba casi todo el tiempo del mecanismo (ver la sección de
tiempos: 5,3 s de sobrecoste en el Cap.5, de los que 2,4 s eran los 127 grupos). Ahora se
encolan (`TwinQueueCompile`) y se compilan de una vez en `TwinFlush`, que corre al final de la
pasada 3. El aislamiento es el mismo, porque lo que protege el parche es que el grupo sea
**distinto** del final, no que sea uno por gemelo. Un grupo por gemelo solo servía para saber
**cuál** falló, y eso ahora se hace reintentando uno por uno **solo si** el grupo se cae —
o sea, nunca en el camino normal. Al aislar al culpable se le deja la función vacía y, esto es
lo importante, **se le quita el desvío a su entrada** (`changedCodes`, quitando el prefijo que
genera `TwinDispatch`): si no, en idioma nativo esa entrada llamaría a una función vacía y no
dibujaría nada, que es peor que quedarse con la versión del mod.

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

### Los bordes en el gemelo: cómo se hace, y por qué está deshecho

**Primero, cómo se hizo mal**, que es lo que no hay que repetir. Se intentó encolar los parches
de bordes *del mod* también sobre el gemelo, con `ThrowOnNoOpFindReplace = false`. Los de una
línea son iguales en vanilla y en el texto del mod, así que casaban; los bloques multilínea están
escritos contra el texto del mod y **no** casaban, y se saltaban en silencio. El gemelo quedaba a
medio parchear, que es peor que las dos opciones puras: en el Cap.5, Step a 8 filas navegables
con el Draw dibujando 7; en Cap.1-4, corazón 10 px descolocado. Se revirtió, y
`obj_darkcontroller_` se metió en la lista negra para que ese menú corriera siempre la versión
del mod.

**Después se hizo bien** (2026-08-15): un **segundo** juego de parches escritos contra el texto
vanilla, en un bloque al final de cada `Borders.csx`, con `ThrowOnNoOpFindReplace = true`.
Funcionó en los cinco capítulos: gemelo y entrada del mod con las mismas 8 filas, corazón en
`yy + 140` y la fila del borde en `yy + 305`.

**Y está deshecho**, junto con el japonés. El motivo: lo que recuperaba eran los ajustes
`langopt(en, ja)` y `global.lang == "ja"` de vanilla — el 62 % de los 164 medidos — y esos son
código muerto si "ja" no se ofrece. Sin japonés pasaba a costar un camino nuevo sin comprar nada.
`obj_darkcontroller_` volvió a la lista negra.

Si se retoma, esto es lo que hay que saber. Cuatro diferencias entre los dos textos:

| | vanilla | mod |
|---|---|---|
| condición de la fila | `if (global.is_console)` | `if (global.is_console \|\| os_type == os_android)` |
| array de opciones | `border_options` | `border_options_tr` |
| columna de valores | `xx + 430` | `_selectXPos` |

Y el gemelo lleva **un nivel más de indentación**, porque su cuerpo vive dentro de una función.

**El error que costó la primera pasada:** `Borders.csx` no decompila con los ajustes por defecto,
sino con `RemoveSingleLineBlockBraces` y `EmptyLineAroundBranchStatements`. El texto contra el
que casan los parches **no** es el de un volcado normal: los `if` de una sentencia van sin llaves,
hay líneas en blanco alrededor de las ramas, **y esas líneas llevan su indentación dentro**. Los
patrones hay que sacarlos de un volcado hecho con esos mismos ajustes (`DumpB.csx` del anexo).

La escalera es la misma en los cinco capítulos: **8 filas, paso 35, empezando 20 px más arriba
que el vanilla** (130, 165, 200, 235, 270, 305, 340, 375), corazón en `yy + 140`. El Cap.5 va
aparte: su menú no tiene forma regular (la fila de "Simplify VFX" se cambia por "Voice Clips" o
"Feather" según la partida).

**Lo que NO arregla, y es lo que zanjó la discusión.** La fila del borde es del fork: vanilla
nunca la dibuja en PC, así que no hay maquetación original que copiar. En japonés se sale del
marco, y el bloque de "Feather" del Cap.5 (etiqueta en `yy + 200`, valor en `yy + 200 + 16`) se
superpone — **igual en el gemelo que en la versión del mod**, porque la geometría la inventa el
fork en las dos. Eso solo se arregla maquetando a mano, idioma por idioma.

**De regalo, un arreglo que sí es genérico y está anotado por si vuelve:** el vanilla pone la
columna de valores en `xx + 385` solo si el idioma es japonés **y** estamos en consola; en PC la
deja en 430, porque ahí la fila del borde no existe y 430 nunca tuvo que alojar un valor japonés
largo. Quitando el `&& global.is_console` queda
`(global.lang == "ja") ? (xx + 385) : (xx + 430)`, que es la respuesta del propio juego a
"japonés + fila de borde".

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

### Los avisos de `obj_CHAPTER_SELECT` (2026-08-15)

El mismo fallo, encontrado en pantalla por el usuario: en japonés nativo, el aviso de
"¿continuar desde el capítulo N?" salía **en inglés**, aunque el botón de "Language" sí
aparecía. Es exactamente el síntoma de la regla de arriba: `obj_CHAPTER_SELECT_` entró en la
lista negra **para** que ese botón exista (en vanilla no existe), y al correr siempre código
del mod, sus catorce `scr_get_lang_string` devolvían el literal inglés.

Arreglado con un ayudante en el propio Create, para no repetir el ternario catorce veces:

```gml
lang_text = function(en_text, ja_text, pack_key)
{
    if (is_native_lang())
        return (global.lang == "en") ? en_text : ja_text;

    return scr_get_lang_string(en_text, pack_key);
};
```

Los tres textos que llevan el número del capítulo en medio (`create_continue_screen`,
`create_start_next_screen`) **no** pueden usarlo: el japonés coloca el número en otro sitio
(`"Chapter " + N + "から続けますか？"` frente a `"Continue from Chapter " + N + "?"`), así que
ahí se arma la frase entera en cada rama.

Todos los japoneses salen del vanilla del menú raíz, menos "Language" → `言語`, que es etiqueta
del fork (en vanilla el botón del pie dice `"日本語"`/`"English"`, porque es el interruptor de
idioma, no un menú).

**La geometría se dejó como está**: el mod pasa `init(id, texto, opciones, -26, -40)` y llama a
`adjust_choices_x()`, valores pensados para tres opciones y texto traducido, mientras el vanilla
usa `choice_offset = (global.lang == "ja") ? -20 : 0` con dos. Cambiarla tocaría también el
español, y el usuario reportó que solo fallaba el texto.

### La decisión es POR OBJETO, no por entrada

Si el `Draw` de un objeto corriera vanilla y su `Step` se quedara con el del mod, el cursor de
un menú se desincroniza del layout que se dibuja. Por eso basta con que **una** entrada del
objeto tenga lógica por idioma para que vaya el objeto entero, y por eso existe la pasada 3, que
congela también las entradas que el mod no reemplaza pero que tocan después `Borders.csx` o
`CodeChanges.txt`.

### El criterio de gemelo NO ve los fallos que introduce el propio mod (2026-08-08)

El criterio es "¿el vanilla menciona `global.lang` o `langopt`?". Eso encuentra los sitios donde
el vanilla **tiene** lógica de idioma. No encuentra el caso contrario: donde el vanilla es
deliberadamente **ciego** al idioma y es el mod el que le añade la dependencia. O sea que el
criterio no puede ver una clase entera de fallos que existe para prevenir.

El caso que lo dejó claro en pantalla (2026-08-15) fue `obj_choicer_neo` en el Cap.5: su vanilla
no menciona el idioma en ninguna línea -fija `fnt_8bit` y calcula las posiciones con
`string_width`-, así que nunca califica, y en japonés las respuestas salían montadas unas sobre
otras. **Sin japonés esto casi no se nota**, porque en inglés la versión del mod y la de vanilla
se ven parecidas; con japonés era la mitad de la superficie, y por eso se amplió el criterio y
luego se deshizo (ver la sección de cobertura).

El ejemplo de las fuentes de abajo es aparte y sigue vigente pase lo que pase con el criterio:
ahí el gemelo no basta, porque la conversión la hace el patcher **después** de congelarlo.

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
`obj_darkcontroller_`, `obj_screen_start_`, `obj_ui_choice_`, `obj_CHAPTER_SELECT_`, y en el
menú `obj_init_pc_` y `obj_screen_select_footer_`.

`obj_darkcontroller_` **salió** de la lista el 2026-08-15 al escribir los parches del borde
contra el texto vanilla, y **volvió** el mismo día al quitar el japonés: el 62 % de ajustes que
recuperaba eran los `langopt(en, ja)` y los `global.lang == "ja"`, código muerto sin japonés.

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

**DumpAll** — vuelca TODAS las entradas raíz decompiladas a una carpeta, para comparar dos
`data.win` por contenido y no por bytes. Es lo que hay que usar cuando un cambio del patcher
altera el md5 pero no debería cambiar nada: dos volcados y un `diff -rq`. Se usó para validar
que agrupar los `CompileGroup` de los gemelos no cambia la salida (Cap.1: 1513 entradas, 0
diferencias; Cap.5: 12350, 0).

```bash
DUMP_OUT=dumpA "$CLI" load nuevo.win   -s DumpAll.csx < /dev/null
DUMP_OUT=dumpB "$CLI" load antiguo.win -s DumpAll.csx < /dev/null
diff -rq dumpA dumpB
```

```csharp
using System; using System.IO; using System.Linq;
EnsureDataLoaded();
string outDir = Environment.GetEnvironmentVariable("DUMP_OUT");
Directory.CreateDirectory(outDir);
var ctx = new GlobalDecompileContext(Data);
int ok = 0, fail = 0;
foreach (var code in Data.Code.ToList())
{
    if (code.ParentEntry != null) continue;                 // las hijas van dentro del padre
    string name = code.Name?.Content;
    if (string.IsNullOrEmpty(name)) continue;
    string gml;
    try { gml = new Underanalyzer.Decompiler.DecompileContext(ctx, code, Data.ToolInfo.DecompilerSettings).DecompileToString(); ok++; }
    catch (Exception e) { gml = "<<FALLO AL DECOMPILAR>> " + e.Message; fail++; }
    File.WriteAllText(Path.Combine(outDir, name.Replace('/', '_') + ".gml"), gml);
}
Console.WriteLine("DUMPALL entradas=" + ok + " fallos=" + fail);
```

Ojo: `GlobalDecompileContext` va **sin** el prefijo `Underanalyzer.Decompiler.` (en UMTLib 0.9
vive en `UndertaleModLib.Decompiler`), mientras que `DecompileContext` sí lo lleva.

**Cobertura** — el verificador mas util de todos: cuanto de lo que el mod toca cae a vanilla en
idioma nativo. Sobre un `data.win` ya parcheado. "El mod la toca" es tener respaldo `_old`; "va a
vanilla" es que su texto lleve `is_native_lang()` y `scr_native_`. Hoy el Cap.5 da
**512 de 532 (96 %)**, y las 20 restantes son la lista negra. Si baja, algo se salio de las
poblaciones de `twinCandidates`.

```csharp
using System; using System.IO; using System.Linq; using System.Collections.Generic;
EnsureDataLoaded();
var ctx = new GlobalDecompileContext(Data);
string Dec(UndertaleCode c){ try { return new Underanalyzer.Decompiler.DecompileContext(ctx,c,Data.ToolInfo.DecompilerSettings).DecompileToString(); } catch { return ""; } }
int toca = 0, vanilla = 0, mod = 0, scripts = 0;
var sinDesvio = new List<string>();
foreach (var c in Data.Code.ToList())
{
    var n = c.Name?.Content;
    if (c.ParentEntry != null || string.IsNullOrEmpty(n) || n.EndsWith("_old") || n.Contains("scr_native_")) continue;
    if (Data.Code.ByName(n + "_old") == null) continue;
    if (n.StartsWith("gml_GlobalScript_")) { scripts++; continue; }
    if (!n.StartsWith("gml_Object_")) continue;
    toca++;
    var t = Dec(c);
    if (t.Contains("is_native_lang()") && t.Contains("scr_native_")) vanilla++;
    else { mod++; sinDesvio.Add(n); }
}
File.WriteAllText(Environment.GetEnvironmentVariable("OUT"),
    string.Format("toca={0} vanilla={1} mod={2} scripts={3}\n{4}", toca, vanilla, mod, scripts,
                  string.Join("\n", sinDesvio.OrderBy(x => x))));
```

**DumpB** — igual que `DumpAll`, pero decompilando con **los mismos ajustes que `Borders.csx`**:

```csharp
var st = new Underanalyzer.Decompiler.DecompileSettings() {
    RemoveSingleLineBlockBraces = true,
    EmptyLineAroundBranchStatements = true,
    EmptyLineBeforeSwitchCases = true,
};
```

Es de donde hay que sacar los literales de cualquier parche nuevo de `Borders.csx`. Con los
ajustes por defecto el texto NO coincide -los `if` de una sentencia salen con llaves y no hay
lineas en blanco entre ramas-, y el parche no casa. Ojo tambien: esas lineas en blanco llevan su
indentacion dentro, asi que copiarlas a mano es pedir problemas.

**Gemelos recursivos** — para comprobar la idempotencia hay que parchear dos veces seguidas el
mismo `data.win` y luego contar los gemelos cuyo cuerpo contenga `is_native_lang`: deben ser
**cero**. También conviene contar los de cuerpo vacío (gemelos que no compilaron) y comprobar que
el número de entradas con desvío coincide con el de gemelos.

**Menú de opciones** — el invariante del número de filas: en Cap.1-4 el gemelo del
`obj_darkcontroller_Step_0` tenía `submenucoord[30] > 6` (7 filas) y la entrada `> 7` (8 filas);
en Cap.5 los dos `> 7`. No aplica mientras `obj_darkcontroller_` esté en la lista negra, pero
sirve si alguna vez se le devuelve el gemelo. Con los parches del borde contra el texto vanilla
el invariante pasa a ser que **los dos digan `> 7`**, con la fila en `yy + 305` y el corazón en
`yy + 140`.

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
