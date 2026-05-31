# Rendering optimization plan

## Current bottlenecks

The main frame path is in `src/cache_render.asm`. Dense tube layouts exceed the frame
budget when CBL audio rendering is active because the renderer still spends too much
time in per-row CPU copies and in work that does not actually change every frame.

## Prioritized work

1. `DrawFontGlyph` still performs software transparency checks (`cp FONT_BACKGROUND_INDEX`)
   per pixel for title/pause text. Rework it as a high-priority cleanup: use hardware
   transparency where safe, or preconverted font data and unrolled/`ldi` row copies so
   text drawing does not keep a slow per-pixel branch path.

2. `CacheDrawTubeHead` is the biggest visible hot path. Tube bodies already use the
   vertical accelerator path, but tube heads still use `ldir` with per-row stack saves.
   Replace this with horizontal accelerator copies and remove most row-level stack work.

3. `CacheDrawScore` currently redraws the bottom HUD every frame: score, high score,
   medal, footer, and clear rectangles. These elements are mostly static. Add dirty
   flags per double-buffer page and redraw only when score/high score/medal/footer
   actually needs updating.

4. `CacheDrawBird` copies 12 rows of 17 bytes with `ldir`. Move it to the horizontal
   accelerator path through the transparent `#5C` VRAM alias.

5. Check whether small digits benefit from the accelerator. If the accelerator only wins
   for blocks larger than about 12 bytes, 8-byte digit rows should stay on CPU or be
   optimized by unrolling instead of using accelerator setup per row.

6. Add earlier culling for offscreen tubes before page mapping and full draw/restore
   setup. This avoids paying setup cost for tubes that are fully outside the playfield.

## CBL note

CBL adds both FIFO writes and interrupt overhead. After the graphics hot paths above are
lighter, revisit the CBL service policy: FIFO priming, chunk size, and whether service can
be moved to a more controlled point in the frame.
