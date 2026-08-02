# Cambios — DeltranslatePatch (fork LetraDelta)

## Migración a la arquitectura del upstream

Cambio estructural: el fork pasa de una base **plana** (la lógica de idioma
duplicada a mano por cada capítulo) a basarse directamente en el *patcher* del
**upstream de Neprim** (Lazy-Desman/DeltranslatePatch), que mantiene esa lógica
en una copia única en `scripts/SharedCodeEntries/`, importada recursivamente por
`BaseFix.csx`. Las funciones propias se reaplican como *overlay* fino sobre esa
base.

**Motivo:** con la base plana, cada cambio del upstream había que portarlo a
mano a 5-6 copias, y las omisiones se caían en silencio. El caso que lo detonó:
`BaseFix.csx` (plano) no recursaba las subcarpetas de `CodeEntries/`, así que el
código de subcarpetas como `SideB/` (animación del final de la ruta rara del
Cap. 5) y `WideFacesShift/` **nunca se aplicaba**. Con el importador recursivo
del upstream, entra correctamente.

### Funciones propias (reaplicadas sobre el upstream)

- **Multi-idioma:** escaneo de `lang/<código>/`, selección persistida en
  `true_config.ini` (`LANG.LANG_DT`), selector con ←/→ en el Menu raíz y en
  Ajustes in-game, y **cambio de idioma en caliente** dentro de los capítulos
  (sprites **y sonidos** diferidos para no cortar el render ni el audio).
  Las subcarpetas de idioma tienen prioridad: si `lang/` contiene al menos un
  `lang/<código>/settings.json` válido, se usa el modo multi-idioma y se
  **ignora** cualquier `lang/settings.json` suelto en la raíz. Solo se cae al
  pack heredado de un único idioma en la raíz cuando no hay ninguna subcarpeta
  válida.
- **Modo especial y voces dobladas por idioma:** los dos interruptores Sí/No
  del upstream se recuerdan por *pack* (`LANG.special_mode_<código>` y
  `LANG.translated_songs_<código>` en `true_config.ini`) en vez de en una
  única clave global, y se releen al cambiar de idioma. Así no se arrastran a
  un pack que no ofrece ese interruptor: el caso feo era apagar "Voces
  dobladas" en un pack y pasar a otro sin el interruptor, que quedaba con las
  voces apagadas (y con las variantes `spm_` de textos y sprites activas) sin
  forma de volver a encenderlas desde el menú. Las claves `special_mode` y
  `translated_songs` del upstream se siguen leyendo como respaldo la primera
  vez, para no perder la preferencia anterior del jugador. Los valores por
  defecto son los del upstream: modo especial apagado, voces dobladas
  encendidas.
- **Config diferida en consola (`scr_console_read_lang_config`):** en
  Switch/PS4/PS5 `ossafe_ini_open` no lee del disco sino de `global.savedata`,
  un mapa que se rellena de forma asíncrona y que todavía no existe cuando
  corre el Create de `obj_gamecontroller`. El upstream difiere ahí la lectura
  de sus dos claves globales; este fork necesita diferir más, porque sus
  claves son por idioma y hace falta saber cuál está activo antes de poder
  leerlas. El script (uno por árbol, compartido y Menu) se llama desde el
  `Step`/`Draw_73` cuando `ld_load_state` llega a 2, y además **recupera el
  idioma guardado** (`LANG.LANG_DT`), conmutándolo en caliente si difiere del
  de arranque. En escritorio no interviene: allí todo se sigue leyendo en el
  Create.
- **`font_settings`:** override de tamaño y rango de glifos por fuente desde
  `settings.json` / `chapter_settings.json` (el de capítulo gana).
- **Fuentes por capítulo:** variantes `<fuente>_chapterN.ttf/otf`.
- **Bordes** opcionales (NXRUNE de IRUZZ): `ChapterN/Borders.csx` tras el
  `Fix.csx` del capítulo. Sobre el parche original de NXRUNE:
  - **Con el borde en «Ninguno», el juego recupera su tamaño original.** NXRUNE
    pasa el juego a 16:9 de forma incondicional: mete siempre la
    `application_surface` en el recuadro interior del marco (320 px de margen
    lateral, 60 px arriba y abajo) y fija la ventana a 640x360, se dibuje o no
    un borde; al desactivarlos quedaban franjas negras y el juego más chico que
    sin el mod. Ahora el layout, el tamaño de ventana y la posición del mensaje
    de salida consultan `global.screen_border_id`: con «Ninguno» se usa la
    fórmula vanilla (centrar y maximizar) y la ventana vuelve a 4:3.
  - **El ajuste se recuerda fuera de la partida:** se espeja en `true_config.ini`
    (`BORDER.TYPE`), el ini global que el juego ya usa para la pantalla completa,
    para que la pantalla de selección de partida lo respete. Cada partida sigue
    guardando el suyo en su `keyconfig_<n>.ini`, que manda en cuanto se carga.
  - **Sin precarga de texturas en PC (Cap. 2-5):** NXRUNE encendía el
    precargador de consola (`obj_prefetchtex`), que carga una página de texturas
    por frame; de ahí la animación del perro con barra de progreso, y varios
    segundos de espera, al entrar a un capítulo. Se vuelve a la carga perezosa
    del PC vanilla.

### Correcciones

- **Crash del tablero (Cap. 3):** `add_font` declara sus temporales como locales
  (`var`); antes `path` de instancia pisaba `obj_mainchara_board.path`
  (`mp_grid_path`).
- **`scr_get_font`:** deja de devolver `-1` (fuente inválida) como handle válido.
- **Crash del Cap. 1 sin pack de idioma:** `scr_lang_load` cae a los strings de
  fábrica del juego (o a un mapa vacío) cuando no hay pack instalado, en vez de
  dejar `global.lang_map` en `undefined` y reventar en el primer string.
- **Logo de intro en macOS (Cap. 5):** al saltar la intro, macOS usa una ventana
  de transición más larga; deja de dibujar el logo (`dontdraw`) en ese tramo para
  que no se quede colgado en pantalla.
- **Crash de Ajustes → idioma sin partidas:** `obj_lang_settings` solo lee y
  escribe las variables de fondo de `DEVICE_MENU` cuando existen (UI oscura,
  `SUBTYPE == 1`); sin partidas guardadas sale la UI verde de Gaster, donde no
  existían y entrar en Config reventaba.

### Notas

- El cambio de idioma en caliente reutiliza `scr_init_localization` con los
  bucles de sprites **y sonidos** diferidos (no hay `scr_lang_reload_partial`
  separado): reusa la carga específica de cada capítulo sin duplicarla.
- **Sonidos diferidos:** los sprites usan un cargador compartido (listas
  genéricas), pero el bloque de sonidos es específico de cada capítulo
  (button sounds en Ch2/3, funny sounds en Ch3/4, voicelines + Flowery en Ch5).
  Por eso cada capítulo define su propio `scr_load_lang_sounds_only` y lo
  registra en `global.lang_sounds_loader`; el código compartido lo invoca por
  referencia (así el Menu, que no carga sonidos, no rompe el enlazado). Al
  limpiar los streams viejos se salta con `audio_is_playing` los que aún suenan,
  para no cortar una voz a mitad. En Ch5 el loader re-cachea las voces de
  Flowery tras recargar.
- La caché/carga diferida de fuentes del refactor **no** se portó: el sistema de
  fuentes quedó *eager* como el upstream (es la última pieza síncrona del switch;
  es optimización de rendimiento, no de correctitud; se puede añadir si el cambio
  a japonés resulta lento).
