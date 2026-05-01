# Registro de cambios

Historial completo de cambios introducidos en este *fork* respecto al repositorio *upstream* de [Neprim / Lazy-Desman](https://github.com/Lazy-Desman/DeltranslatePatch). Los cambios se presentan en orden cronológico de implementación.

---

## Cambios funcionales (previos al refactor)

Modificaciones al comportamiento del mod que se realizaron antes de la reorganización estructural. Todos son aditivos o correctivos; no rompen la compatibilidad con los paquetes de idioma existentes.

### Soporte multi-idioma restaurado

El *upstream* había eliminado la capacidad de tener varios paquetes de idioma conviviendo en la misma instalación. Este *fork* la restaura y la extiende:

- La carpeta `lang/` puede contener subcarpetas por idioma (`lang/es_mx/`, `lang/ru/`, etc.). Cada subcarpeta es un paquete independiente con su propio `settings.json`, `strings.json`, `sprites/`, etc.
- Compatibilidad hacia atrás con la estructura plana del mod original (`lang/settings.json` directamente en la raíz); si existe, se trata como un único idioma.
- En el menú, la opción *Language* permite ciclar entre todos los paquetes disponibles con ←/→.
- El idioma elegido se persiste en `true_config.ini` bajo `LANG.LANG_DT`.
- Cambio de idioma en caliente dentro de *gameplay* sin perder la partida.
- Las actualizaciones descargadas vía `changes.json` se copian a la subcarpeta del idioma activo si la estructura es multi-idioma, o a `lang/` si es plana.

### Modos especiales rediseñados

El sistema de *special modes* fue reescrito desde cero para soportar un número arbitrario de modos declarativos:

`settings.json` declara los modos con este esquema:

```json
"special_modes": [
    {
        "name": "Modo normal",
        "description": "Traducción estándar."
    },
    {
        "prefix": "sp_1",
        "name": "Modo rima",
        "description": "Diálogos en verso activados."
    },
    {
        "prefix": "sp_2",
        "name": "Modo caló",
        "name_upper": "MODO CALÓ",
        "description": "Jerga mexicana activada.",
        "description_upper": "JERGA MEXICANA ACTIVADA."
    }
]
```

- El primer elemento es el modo por defecto y no lleva `prefix`.
- Los demás llevan `prefix`, que se usa como prefijo en `strings.json` y en los sprites (`sp_1_<id>`, `sp_2_<id>`).
- `name_upper` y `description_upper` son opcionales; si faltan, se usa `name`/`description`. Solo se aplican en el Capítulo 1 Light World.
- La persistencia del modo activo es por idioma: `LANG.special_mode_index_<lang_code>` en `true_config.ini`. Cambiar a un idioma con menos modos clampea el índice a 0 en sesión sin sobrescribir el valor guardado del otro idioma.
- Retrocompatibilidad con el formato antiguo `"special_mode": true`: sintetiza internamente dos entradas (default + un modo `sp_`) tomando nombres y descripciones de los strings localizados del menú, igual que hacía el *upstream*.

### Corrección de errores: tecla R en `obj_lang_settings_Step_0`

**Archivo afectado:** `gml_Object_obj_lang_settings_Step_0.gml` en el menú de todos los capítulos y en el menú principal.

El *upstream* disparaba `room_restart()` ante cualquier pulsación de la tecla `R`, sin condición alguna. Era una *feature* de desarrollo que cualquier usuario podía activar accidentalmente durante el juego.

Dos correcciones aplicadas:

1. **Gateo por `global.translator_mode`**: la tecla `R` solo dispara el reinicio si el modo traductor está activo. Los usuarios finales nunca ven este comportamiento; solo se activa en contextos de desarrollo.
2. **`audio_stop_all()` antes del reinicio**: evita que la música en bucle se duplique al reiniciar la sala, un efecto secundario que dejaba múltiples instancias del mismo audio reproduciéndose en paralelo.

---

## Refactor estructural (etapas 1–6)

Reorganización del código en seis etapas sucesivas. Ninguna de las etapas altera el comportamiento observable del mod; todos los cambios son de estructura, legibilidad y rendimiento interno. El sistema de paquetes de idioma (`lang/`, `chapter_settings.json`, `settings.json`) es completamente compatible sin modificaciones.

---

### Etapa 1 — Manifiestos por capítulo y generador de localización

**Motivación:** los tres archivos GML de localización por capítulo (`scr_init_localization`, `scr_lang_reload_partial`, `scr_load_lang_sprites_only`) estaban escritos a mano y sincronizados manualmente entre sí. Cualquier cambio en sprites, sonidos o fuentes requería editar los tres archivos coordinadamente, con alto riesgo de desincronización.

**Cambios:**

- **`scripts/Chapter{1,2,3,4}/manifest.json`** (archivo nuevo por capítulo): manifiesto declarativo que actúa como fuente única de verdad para sprites, sonidos, canciones, fuentes, aliases y *extra loaders* (`button_sounds`, `tvlandfont`, `additional_funny_assets`). Los doce `.gml` de localización se generan en memoria a partir del manifiesto en cada ejecución de `Fix.csx`; no hay pasos previos de regeneración manual.
- **`scripts/Common/LocalizationGenerator.csx`** (módulo nuevo): lee un manifiesto y emite los tres `.gml` de localización del capítulo. No se ejecuta directamente; lo carga `tools/regen_localization.csx`.
- **`tools/regen_localization.csx`** (archivo nuevo): punto de entrada del regenerador. Procesa los cuatro capítulos en una sola ejecución desde UndertaleModTool (`Scripts → Run other script`). No toca el `data.win`; solo escribe los `.gml` en disco. El generador es determinista: dos ejecuciones seguidas producen los mismos bytes.
- **Soporte para `font_overrides`**: `add_font.gml` fue reescrito para admitir ajustes de tamaño y rango de fuentes desde `chapter_settings.json` y `settings.json`, sin necesidad de volver a compilar el mod.

**Bugs corregidos en esta etapa:**

- **`scr_get_font.gml`** (todos los capítulos y menú): condición `if (!is_undefined(fnt) || fnt == -1)` corregida a `if (!is_undefined(fnt) && fnt != -1)`. El bug original devolvía `-1` cuando la fuente no estaba en `font_map`, en lugar de caer al *fallback* `asset_get_index`. Con `&&`, el *fallback* se ejecuta correctamente.
- **`BaseFix.csx` — `AppendToEnd(string, string)`**: la sobrecarga con parámetro `string` llamaba internamente a `AppendToStart` en lugar de `AppendToEnd`, invirtiendo el resultado. Corregido.

---

### Etapa 2 — Modularización de `BaseFix.csx`

**Motivación:** `BaseFix.csx` tenía 688 líneas monolíticas mezclando utilidades de bajo nivel, configuración de objetos del juego, *parsing* del DSL, inyección de *assets* y decoración de salas.

**Cambios:**

El archivo queda reducido a 35 líneas que orquestan seis módulos en `scripts/Common/`. El orden de carga importa; CS-Script trata `#load` como inclusión textual, y cada módulo solo ve lo declarado en los anteriores.

| Módulo | Responsabilidad |
|---|---|
| `Helpers.csx` | Funciones de bajo nivel: `ReplaceGML`, `AppendToStart/End`, `Decompile`, `GetOrig`, `AddNewEvent`, `SaveEntries`. Variables de contexto compartidas (`gameFolder`, `scriptFolder`, `changedCodes`, etc.). |
| `MenuSetup.csx` | Configuración de `obj_lang_settings` y de los *hooks* en `obj_gamecontroller` (eventos DrawGUI, Step, AsyncHTTP, DrawEnd, RoomEnd). |
| `CodeChangesParser.csx` | *Parser* del DSL de `CodeChanges.txt`. Carga de `CodeEntries/*.gml` y de `CodesWithSpritesIds.json`. Aplica los cambios al código en bloque. |
| `AssetInjector.csx` | Inyección de `scr_84_get_sprite` y `scr_84_get_sound` en el código del juego. Creación de sprites *placeholder* vía `new_sprites.json`. Carga de `RoomsWithBacksLayers.json`. |
| `FontInjector.csx` | Inyección de `scr_84_get_font` vía `CodesWithFonts.json`. Normalización de fuentes `_ja_`. |
| `RoomDecorator.csx` | Función `BuildRoomDecorationCode(...)` que antes vivía copiada en los cuatro `Fix.csx` por capítulo con variaciones menores. |

Cada `Fix.csx` quedó reducido entre un 40 % y un 70 % en líneas de código ejecutable. Los mensajes de error visibles al usuario (en `Decompile`, `GetOrig`, `SaveEntries`) se tradujeron del ruso al inglés.

---

### Etapa 3 — Decoración de salas declarativa

**Motivación:** los preámbulos de decoración específicos de cada capítulo (carteles de Queen en el Cap. 2, *TV posters* en el Cap. 3, tienda de Rurus en el Cap. 1) vivían como literales C# embebidos en cada `Fix.csx`. Añadir o quitar una decoración requería editar código C#.

**Cambios:**

- **`scripts/Chapter{1,2,3}/extra_decorations.json`** (archivo nuevo): esquema declarativo de marcadores y decoraciones por sala. Cap. 4 no lo necesita (no tenía preámbulo).
- **`RoomDecorator.csx`**: nuevas funciones `LoadAndBuildExtraDecorations()` y `BuildExtraDecorationsCode(JsonElement)`.

Ahora añadir un marcador a una sala es editar el JSON y volver a ejecutar `Fix.csx`; no se toca ningún archivo C#. El output GML es funcionalmente equivalente al de los preámbulos originales (validado con normalización de *whitespace* y evaluación de expresiones aritméticas).

---

### Etapa 4 — Limpieza

Etapa cosmética sin cambios funcionales en *runtime*.

- **Mensajes en ruso traducidos al español neutro**: comentarios en `.gml`, `.csx` y `.txt` que no se mostraban al usuario pero estaban escritos en ruso, incluido un texto vulgar en `Chapter4/CodeChanges.txt`.
- **Texto ruso conservado intencionalmente**: los campos `description_ru` de `changes.json` (parte del esquema) y los strings `"Нет"`/`"Да"` de `scr_load_special_modes.gml` (datos de retrocompatibilidad con packs rusos).
- **Código muerto eliminado**: stub `GetOrigSprite(string)` en `Helpers.csx` y alias `changedCodesRecord` en `CodeChangesParser.csx`.
- **Nomenclatura corregida** en `AssetInjector.csx`: `jsonSpritesAssgned` → `objectsWithAssignedSprites`, `jsonObjSprDraws` → `codesWithSprites`, `jsonObjSounds` → `codesWithSounds`. Todos los nombres ahora coinciden con los archivos JSON que representan.

---

### Etapa 5 — Corrección de errores y refinamientos

**Bugs corregidos:**

- **Duplicado `fnt_tinynoelle` en Cap. 1**: `manifest.json` del Cap. 1 declaraba la fuente dos veces (réplica del bug del mod base). Eliminada la entrada duplicada; `add_font("fnt_tinynoelle", 7)` se llama ahora una sola vez.

- **`scr_lang_reload_partial` no recargaba `button_sounds`**: tras un cambio de idioma en caliente, los sonidos del piano-puzzle (Cap. 2) y los de la *rhythm-game* (Cap. 3) seguían usando los *samples* del idioma anterior. Corregido: se añade el bloque `add_sound("snd_speak_and_spell_X")` en `reload_partial` para los capítulos con `button_sounds` en `extra_loaders`. El generador emite el bloque solo si el manifiesto lo declara.

- **`scr_lang_reload_partial` no recreaba `global.tvlandfont`**: la fuente derivada del sprite `spr_tvlandfont` (Cap. 3, *running-line* del *rhythm-game*) quedaba apuntando a un sprite borrado por `scr_cleanup_outdated_sprites` tras un cambio de idioma. Corregido en `scr_load_lang_sprites_only` (que corre *después* de que los sprites estén disponibles): borra la fuente vieja con `font_delete` y crea la nueva con `font_add_sprite_ext`.

**Refactor:**

- **`Chapter2/Fix.csx` — bloque del *keyboard puzzle***: la función `PatchKeyboardPuzzleRoom` y un bucle `foreach` separado procesaban las tres salas de teclado con código duplicado. Unificado: `PatchKeyboardPuzzleRoom` acepta ahora un `Func<Dictionary<string,string>, string>` que construye la expresión GML. Las tres salas se procesan con la misma función pasando *lambdas* distintas. Sin cambio funcional.

**Nota:** el experimento de centralizar todas las directivas `using` en un único `_Usings.csx` fue intentado y revertido. Las directivas `using` en CS-Script tienen ámbito léxico estricto y no se propagan a través de `#load` en ninguna dirección. Cada módulo sigue declarando sus propios `using`.

---

### Etapa 6 — Carga diferida de fuentes y caché global

**Motivación:** el cambio de idioma a japonés (o cualquier idioma CJK) causaba bloqueos de 1–2 segundos en Cap. 4. Causa raíz: las fuentes JA tienen ~1 700 glifos cada una (vs. ~200 las latinas), y `font_add()` rasteriza síncronamente todos los glifos del rango en el momento de la llamada. Cap. 4 cargaba 10 fuentes en `scr_lang_reload_partial`; al cambiar de idioma se rasterizaban ~16 800 glifos en un solo *frame*.

**Cambios:**

- **Carga diferida**: `scr_init_localization` y `scr_lang_reload_partial` rasterizan únicamente `fnt_main` en el momento (la única fuente que los menús pre-*gameplay* necesitan). El resto se registra en `global.font_pending_map` (nuevo `ds_map`: nombre → tamaño base). Los resolvers `scr_84_get_font` y `scr_get_font` consultan `font_pending_map` antes del *fallback* a `asset_get_index` y rasterizan al vuelo si la fuente pedida está pendiente. Las fuentes diferidas se rasterizan distribuidas en los primeros *frames* de *gameplay*, durante la transición a partida donde el jugador tolera latencia.

- **Caché global de *handles*** (`global.font_cache`): `add_font` indexa los *handles* de `font_add` por la tupla `(path resuelto, size, range)`. Si la sesión ya rasterizó esa combinación (p. ej. el jugador hace JA → ES → JA), el segundo viaje a JA reutiliza el *handle*: 0 ms. Las fuentes cacheadas no entran en `global.loaded_fonts` y no las borra el `font_delete` de `reload_partial`. Impacto en memoria: hasta ~50 MB extras en el peor caso (todas las fuentes de Cap. 4 × varios idiomas CJK); aceptable.

- **Tabla declarativa de aliases** (`global.font_alias_targets`): el bloque de aliases inline era incompatible con la carga diferida (una fuente pendiente no está aún en `font_map`). Solución: el generador emite una tabla estática de alias → fuente objetivo; los resolvers la consultan como último *fallback*. Solo se emite en capítulos con aliases declarados en el manifiesto (Cap. 3: 2 entradas; Cap. 4: 4 entradas).

- **`scr_invalidate_font_cache.gml`** (archivo nuevo por capítulo): borra todos los *handles* cacheados y vacía `global.font_cache`. Disponible para enlazar con el flujo de actualización del mod si en el futuro se reemplazan archivos `.ttf` en caliente.

**Resultado:**

| Escenario | Antes | Ahora |
|---|---|---|
| Primer cambio a JA en la sesión | ~1–2 s de bloqueo | ~150–300 ms (1 fuente) |
| Cambios sucesivos JA → ES → JA | ~1–2 s cada uno | ~5 ms (*cache hit*) |
| *Stutter* al entrar en partida | Imperceptible | Imperceptible (carga distribuida) |
| Memoria extra (peor caso) | 0 | ~50 MB |

---

## Resumen de archivos por etapa

| Etapa | Archivos nuevos | Archivos modificados |
|---|---|---|
| Funcional | `scr_load_special_modes.gml` ×5, `obj_gamecontroller_Create_0.gml` ×5, `obj_lang_settings_*.gml` ×20 | — |
| 1 | `Chapter*/manifest.json` ×4, `Common/LocalizationGenerator.csx`, `tools/regen_localization.csx`, 12 `.gml` autogenerados | `BaseFix.csx`, `add_font.gml` ×5, `scr_get_font.gml` ×5 |
| 2 | `Common/{Helpers,MenuSetup,CodeChangesParser,AssetInjector,FontInjector,RoomDecorator}.csx` | `BaseFix.csx`, `Chapter*/Fix.csx` ×4 |
| 3 | `Chapter{1,2,3}/extra_decorations.json` | `RoomDecorator.csx`, `Chapter*/Fix.csx` ×4 |
| 4 | — | Comentarios y nombres en `.gml`, `.csx`, `.txt` |
| 5 | — | `Chapter1/manifest.json`, `scr_lang_reload_partial.gml` ×4, `scr_load_lang_sprites_only.gml` ×4, `Chapter2/Fix.csx` |
| 6 | `scr_invalidate_font_cache.gml` ×4 | `LocalizationGenerator.csx`, `add_font.gml` ×4, `scr_84_get_font.gml` ×4, `scr_get_font.gml` ×4, 8 `.gml` autogenerados |
