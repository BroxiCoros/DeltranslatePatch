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
  (sprites diferidos para no cortar el render).
- **Modos especiales rediseñados:** número arbitrario de modos con `prefix`
  (`sp_1`, `sp_2`…) para sprites, strings y sonidos; índice persistido por
  idioma; compatible con `special_mode: true` heredado.
- **`font_settings`:** override de tamaño y rango de glifos por fuente desde
  `settings.json` / `chapter_settings.json` (el de capítulo gana).
- **Fuentes por capítulo:** variantes `<fuente>_chapterN.ttf/otf`.
- **Bordes** opcionales (NXRUNE de IRUZZ): `ChapterN/Borders.csx` tras el
  `Fix.csx` del capítulo.

### Correcciones

- **Crash del tablero (Cap. 3):** `add_font` declara sus temporales como locales
  (`var`); antes `path` de instancia pisaba `obj_mainchara_board.path`
  (`mp_grid_path`).
- **`scr_get_font`:** deja de devolver `-1` (fuente inválida) como handle válido.

### Notas

- El cambio de idioma en caliente reutiliza `scr_init_localization` con el bucle
  de sprites diferido (no hay `scr_lang_reload_partial` separado): reusa la carga
  específica de cada capítulo sin duplicarla.
- La caché/carga diferida de fuentes del refactor **no** se portó: el sistema de
  fuentes quedó *eager* como el upstream (es optimización de rendimiento, no de
  correctitud; se puede añadir si el cambio a japonés resulta lento).

Detalle completo y decisiones de diseño en [`docs/migracion-upstream.md`](docs/migracion-upstream.md).
