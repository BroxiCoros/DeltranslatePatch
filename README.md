# DeltranslatePatch (*fork* con refactor)

*Fork* del mod [*Deltranslate*](https://github.com/Lazy-Desman/DeltranslatePatch) de Neprim, mantenido por **BroxiCoros** como base de *scripts* del proyecto [*LetraDelta*](https://github.com/BroxiCoros/LetraDelta) (traducción al español americano de *DELTARUNE*).

A partir del [repositorio *upstream* de LazyDesman](https://github.com/Lazy-Desman/DeltranslatePatch), este *fork* introduce primero un conjunto de cambios funcionales (restauración del soporte multi-idioma, rediseño de modos especiales, corrección de errores) y luego un refactor estructural en seis etapas que reorganiza el código sin cambiar el comportamiento observable, corrige varios errores latentes e introduce carga diferida de fuentes para acelerar el cambio de idioma. Los detalles completos están en [`CHANGES.md`](CHANGES.md).

Junto con el refactor, este repositorio también incluye los *scripts* y los recursos gráficos para la **versión con bordes** (basada en [*NXRUNE*](https://github.com/IruzzArcana/NXRUNE) de IRUZZ), integrados en la misma jerarquía de carpetas. La opción se activa o desactiva en el momento de aplicar los parches mediante una bandera del *patcher*; no requiere descargas adicionales.

---

## Contenido del repositorio

```
scripts/
├── BaseFix.csx                punto de entrada compartido (#load de los módulos)
├── changes.json               manifiesto de versiones consumido por el sistema de actualización del mod
├── Common/                    módulos reutilizables: Helpers, MenuSetup, AssetInjector, FontInjector, etc.
├── Menu/                      parches del data.win raíz (selector de capítulos)
├── Chapter1/                  parches del data.win del capítulo 1
│   ├── Fix.csx                entrada principal de parcheo del capítulo
│   ├── Borders.csx            parches de la versión con bordes (NXRUNE)
│   ├── Borders/               recursos gráficos de los bordes (PNG)
│   ├── manifest.json          declaración de sprites, sonidos y fuentes a localizar
│   ├── CodeChanges.txt        parches al GML del juego en un DSL propio
│   └── ...
├── Chapter2/                  estructura análoga al capítulo 1
├── Chapter3/                  estructura análoga al capítulo 1
└── Chapter4/                  estructura análoga al capítulo 1
```

Cada subcarpeta de capítulo contiene un `Fix.csx` (entrada de parcheo principal), un `Borders.csx` (parches de la versión con bordes), un `manifest.json` declarativo, un archivo `CodeChanges.txt` con parches al GML descompilado y varios JSON adicionales que controlan la inyección de recursos.

---

## Cambios funcionales respecto al *upstream*

Estos cambios alteran el comportamiento del mod. Todos son compatibles con los paquetes de idioma existentes; no se requieren cambios en `lang/`, `settings.json` ni `chapter_settings.json`.

### Soporte multi-idioma restaurado

El *upstream* había eliminado la capacidad de tener varios paquetes de idioma en la misma instalación. Este *fork* la restaura:

- `lang/` puede contener subcarpetas por idioma (`lang/es_mx/`, `lang/ru/`, etc.), cada una con su propio `settings.json`, `strings.json`, `sprites/`, etc.
- Compatibilidad con la estructura plana del mod original: si `lang/settings.json` existe directamente en la raíz, se trata como un único idioma.
- La opción *Language* del menú permite ciclar entre todos los paquetes disponibles con ←/→, con persistencia en `true_config.ini` bajo `LANG.LANG_DT`.
- Cambio de idioma en caliente dentro de *gameplay* sin perder la partida.

### Modos especiales rediseñados

El sistema de modos especiales fue reescrito para soportar un número arbitrario de modos declarados en `settings.json`:

```json
"special_modes": [
    { "name": "Modo normal", "description": "Traducción estándar." },
    { "prefix": "sp_1", "name": "Modo rima", "description": "Diálogos en verso." },
    { "prefix": "sp_2", "name": "Modo caló", "description": "Jerga mexicana." }
]
```

El primer elemento es el modo por defecto (sin `prefix`). Los demás llevan `prefix`, que se usa como prefijo en `strings.json` y en los sprites. El índice activo se persiste por idioma en `true_config.ini`. El formato antiguo `"special_mode": true` sigue siendo compatible.

### Correcciones de errores

**Tecla R sin condición en `obj_lang_settings_Step_0`** — El *upstream* disparaba `room_restart()` ante cualquier pulsación de `R` sin restricción alguna, una herramienta de desarrollo que cualquier usuario podía activar accidentalmente. Correcciones aplicadas:

1. La tecla `R` ahora solo funciona si `global.translator_mode` está activo.
2. Se añade `audio_stop_all()` antes de `room_restart()` para evitar que la música en bucle se duplique al reiniciar la sala.

### Ajuste de fuentes desde `settings.json` y `chapter_settings.json`

El pack de idioma puede afinar el tamaño y el rango de glifos de cualquier fuente sin recompilar el mod, mediante la clave `font_settings` en `settings.json` (efecto global) o en `chapter_settings.json` (efecto por capítulo, con prioridad sobre el global):

```json
"font_settings": {
    "fnt_main": {
        "size": 18,
        "range": [2, 255]
    },
    "fnt_8bit": {
        "size": 8
    }
}
```

Cada entrada es el nombre lógico de la fuente (igual que el nombre del asset en el juego). Los campos disponibles son:

- `size` — tamaño en puntos con el que se rasterizará la fuente. Sustituye al tamaño declarado en el manifiesto del capítulo.
- `range` — rango de puntos de código Unicode a incluir, como `[inicio, fin]`. Si se omite, se usa `fonts_range` de `settings.json` o el valor por defecto `[2, 128]`.

Ambos campos son opcionales: se puede especificar uno solo sin el otro.

### Fuentes de reemplazo por capítulo

Si se necesita usar un archivo de fuente diferente para la misma fuente lógica según el capítulo (por ejemplo, porque `fnt_8bit` tiene un diseño distinto en el capítulo 4), basta con colocar en `fonts/` un archivo con el sufijo `_chapterN`:

```
lang/
└── es_mx/
    └── fonts/
        ├── fnt_8bit.ttf           ← usado en capítulos sin archivo específico
        └── fnt_8bit_chapter4.ttf  ← usado automáticamente en el capítulo 4
```

El motor busca primero `<nombre>_chapterN.ttf` (y `.otf`); si no existe, cae al archivo genérico. El código del juego sigue solicitando `fnt_8bit` sin cambios: el reemplazo es transparente.

---

## Resumen del refactor

El refactor es compatible con el sistema de paquetes de idioma existente. Los detalles técnicos de cada etapa están en [`CHANGES.md`](CHANGES.md).

- **Etapa 1.** Manifiestos JSON por capítulo como fuente única de verdad. Los tres `.gml` de localización (`scr_init_localization`, `scr_lang_reload_partial`, `scr_load_lang_sprites_only`) se generan en memoria a partir del manifiesto en cada ejecución de `Fix.csx`, sin pasos previos de regeneración manual. Se añade soporte para `font_settings` (ajuste de tamaño y rango de fuentes desde `settings.json` y `chapter_settings.json`). Errores corregidos: comportamiento de respaldo de `scr_get_font` y de `AppendToEnd(string, string)`.
- **Etapa 2.** Modularización de `BaseFix.csx`: de 688 líneas monolíticas a 35 líneas que orquestan seis módulos reutilizables (`Helpers`, `MenuSetup`, `CodeChangesParser`, `AssetInjector`, `FontInjector`, `RoomDecorator`).
- **Etapa 3.** Decoración de salas declarativa, definida en `extra_decorations.json` por capítulo. Antes vivía como literales C# embebidos en cada `Fix.csx`.
- **Etapa 4.** Limpieza: comentarios en ruso traducidos al español, código muerto eliminado, nomenclatura corregida.
- **Etapa 5.** Corrección de errores: `scr_lang_reload_partial` ahora recarga `button_sounds` y `tvlandfont` correctamente. Eliminado el duplicado de `fnt_tinynoelle` en el Cap. 1. Refactor del bloque del *keyboard puzzle* del Cap. 2.
- **Etapa 6.** **Carga diferida de fuentes** y caché global. Solo `fnt_main` se rasteriza en el momento del cambio de idioma; el resto se aplaza hasta el primer uso. Los cambios de idioma a JA/CN/KR pasan de bloqueos de 1–2 segundos a ~150–300 ms en el primer cambio y ~5 ms en los siguientes (vía caché).

---

## Cómo se aplica el parche

El flujo dual sigue siendo el del *upstream*: a través de UndertaleModTool (manual) o a través de `DeltaPatcherCLI` (automático, lo que utiliza el [instalador de *LetraDelta*](https://github.com/BroxiCoros/InstaladorLetraDelta)).

### Mediante UndertaleModTool (uso manual o desarrollo)

1. Localizar el `data.win` raíz y los de `chapter1_windows/` ... `chapter4_windows/`.
2. Para cada uno, abrir el `data.win` correspondiente en UndertaleModTool, ir a `Scripts → Run other script` y ejecutar el `Fix.csx` adecuado:
   - `data.win` raíz → `scripts/Menu/Fix.csx`
   - `chapter1_windows/data.win` → `scripts/Chapter1/Fix.csx`
   - … y así con los otros capítulos.
3. Guardar cada `data.win`.

Si se desea la versión con bordes, ejecutar `scripts/ChapterN/Borders.csx` después de `Fix.csx` en el mismo `data.win` antes de guardar.

### Mediante el instalador automático

El [`InstaladorLetraDelta`](https://github.com/BroxiCoros/InstaladorLetraDelta) descarga el `scripts.7z` de la versión `latest` de este repositorio y aplica los parches automáticamente. Los usuarios finales no necesitan utilizar UndertaleModTool.

---

## El DSL de `CodeChanges.txt`

Cada `Chapter*/CodeChanges.txt` es un archivo de parches al GML descompilado del juego. La sintaxis es la siguiente:

```
=== gml_Object_obj_X_Step_0
--- # (opcional: # = ignorar si no se encuentra)
texto a buscar
multilínea
+++
texto de reemplazo
%%%
```

Los marcadores y sus significados:

- `===` — nombre del código GML que se va a parchear.
- `---` — inicio del patrón de búsqueda. Si va seguido de `#`, el parche se ignora silenciosamente cuando el patrón no aparece (útil para parches que solo aplican en ciertas versiones del juego).
- `+++` — fin del patrón, inicio del reemplazo.
- `%%%` — fin del bloque. A continuación se puede abrir otro `---`/`+++`/`%%%` para el mismo código, o saltar a otro código con `===`.

Las reglas de coincidencia son:

- Los espacios consecutivos del patrón se colapsan a `\s*` (no es necesario indentar de forma exacta).
- Las llaves `{` y `}` son opcionales (`{?`/`}?`).
- Los caracteres especiales de las expresiones regulares se escapan automáticamente.

La implementación completa vive en `scripts/Common/CodeChangesParser.csx`.

---

## Publicación automatizada del `scripts.7z`

El flujo `.github/workflows/zip_scripts.yml` se dispara con cada *push* que toca `scripts/**` y publica una versión flotante llamada `latest` con dos archivos:

- `scripts.7z` — toda la carpeta `scripts/` (incluidos los `Borders.csx` y los PNG) empaquetada con compresión rápida (LZMA2 nivel 1, prioridad: descarga rápida sobre tamaño reducido).
- `dt_changes.json` — copia de `scripts/changes.json` con prefijo `dt_`. Es el manifiesto que consume el cliente del mod en línea para detectar nuevas versiones.

El proceso es transparente: se trabaja como siempre, se hacen `commit` y `push`, y la versión `latest` se actualiza sola. Tanto el instalador como el cliente del mod ven siempre la última.

---

## Compatibilidad

Esta versión está alineada con *DELTARUNE* capítulos 1–4. Las versiones más antiguas no están soportadas.

---

## Repositorios del proyecto

- **[BroxiCoros/LetraDelta](https://github.com/BroxiCoros/LetraDelta)** — pack de español (`lang/`).
- **[BroxiCoros/LetraDelta-EN](https://github.com/BroxiCoros/LetraDelta-EN)** — pack de inglés (`lang/`).
- **[BroxiCoros/DeltranslatePatch](https://github.com/BroxiCoros/DeltranslatePatch)** — este repositorio.
- **[BroxiCoros/InstaladorLetraDelta](https://github.com/BroxiCoros/InstaladorLetraDelta)** — instalador `.exe` para Windows.

---

## Créditos y reconocimientos

A **Neprim**, autor original del mod [*Deltranslate*](https://github.com/Lazy-Desman/DeltranslatePatch).

A **IRUZZ**, por el código de [*NXRUNE*](https://github.com/IruzzArcana/NXRUNE), del que se toman los recursos y la lógica de la versión con bordes.

A **BroxiCoros**, cambios funcionales, refactor (etapas 1–6) y mantenimiento de este *fork*.

### Contacto

- **Discord de *LetraDelta*:** https://discord.gg/ndkjnhXPPr
- **Discord de *Deltranslate* (*upstream*):** https://discord.com/invite/K98BzHZG9P

---

## Aviso legal

Este proyecto es un mod no oficial sin vínculo alguno con Toby Fox ni con *DELTARUNE*. Todos los derechos sobre el juego pertenecen a sus respectivos propietarios. Este repositorio contiene únicamente código de parcheo; no se distribuyen aquí archivos propiedad de los autores del juego original.
