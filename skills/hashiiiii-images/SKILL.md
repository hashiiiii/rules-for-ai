---
name: hashiiiii-images
description: Use this skill to create project images, especially flat geometric images with a dark background and one accent color.
---

# Images

Use this skill for logos, icons, favicons, promo tiles, README headers, and other flat geometric assets. Create flat geometry as SVG with two to four shapes and one accent color. For illustrative or photorealistic images, use a raster generator and remove the background.

## Requirements

Before drawing, establish these four inputs from the request or repository:

- Target and smallest usable size. Ask if the target is missing.
- Accent and background colors. Offer a dark background and one accent color.
- Project meaning and motifs to avoid. Offer the project name and README as sources.
- Output formats and paths. Offer an SVG mark and PNGs at target sizes.

Ask one question at a time for missing details. Do not draw until the four inputs are clear.

## The Recipe

1. Use two to four basic shapes, one accent color, negative space, and no gradients or text.
2. List at least four metaphors from the project name and function; assign one to each candidate.
3. Create one SVG contact sheet with four to six candidates, each shown at about 100 pixels and at the smallest target size against the intended background. Render it and inspect PNGs at the actual sizes.
4. Select a candidate and refine its coordinates. If none works, change the constraints and make a new sheet.
5. Deliver only the foreground SVG mark. Use `fill-rule="evenodd"` for transparent holes; do not draw background-colored shapes.

Render loop:

```bash
rsvg-convert -w 1200 sheet.svg -o sheet.png   # inspect visually
for s in 16 32 48 128; do rsvg-convert -w $s -h $s mark.svg -o mark-$s.png; done
```
