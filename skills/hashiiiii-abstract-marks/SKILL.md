---
name: hashiiiii-abstract-marks
description: Use when creating a logo mark, app or extension icon, favicon, or repository header mark — especially a flat, abstract, geometric one in the modern OSS style (dark background, single accent color).
---

# Abstract Marks

Flat geometric marks are fully describable in words, so they should be written as SVG code — never generated as raster images. The quality lever is not the drawing; it is the harness: constrain the design language, explore several candidates side by side, verify at real target sizes, then converge on one.

## When to Use

- Logo marks, icons, favicons, promo tiles, README header marks
- Anything in the "2-4 shapes, one accent color" OSS aesthetic

When NOT to use: illustrative or photorealistic artwork (mascots, rich 3D icons) — use a raster image generator and a background-removal pipeline instead.

## The Recipe

1. **Fix the design language first.** One mark = 2 to 4 primitives (circles, polygons, lens shapes). One accent color per mark. Negative space over added detail. No gradients, no text.
2. **List metaphors before drawing.** Write down 4+ visual metaphors from the project's domain (what the name means, what the tool does). Each candidate gets one metaphor.
3. **Produce a contact sheet, not a mark.** One SVG containing 4-6 candidate tiles. Each tile shows the candidate large (~100 px) AND at the smallest target size (16-32 px), on the intended background color. Render it and LOOK at the PNG — judge small-size legibility with your eyes, not by reasoning about it.
4. **Pick, then converge.** Iterate on the chosen candidate with coordinate-level edits. If none work, change the constraint set and produce the next sheet — do not polish a weak candidate.
5. **Deliver the mark as foreground only.** No background tile baked into the final SVG — the background belongs to the context (README header, store tile, favicon). Punch holes with `fill-rule="evenodd"` subpaths, not background-colored shapes, so the mark survives on any background.

Render loop:

```bash
rsvg-convert -w 1200 sheet.svg -o sheet.png   # inspect visually
for s in 16 32 48 128; do rsvg-convert -w $s -h $s mark.svg -o mark-$s.png; done
```

## Quick Reference

| Target | Verify at |
|--------|-----------|
| Favicon / browser tab | 16 px |
| Toolbar, extension list | 32 / 48 px |
| Store listing, README | 128 px+ |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Polishing the first idea | Explore 4-6 candidates on a sheet before converging |
| Illustrative pictogram (a scene with a subject doing something) | If describing it needs a verb, it is an illustration — reduce to an abstract form |
| Background rectangle baked into the mark | Foreground only; backgrounds live in the context |
| Holes filled with the background color | `fill-rule="evenodd"` so holes are transparent |
| Judging legibility at full size only | Put the small size on the sheet next to the large one |
