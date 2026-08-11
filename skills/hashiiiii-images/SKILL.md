---
name: hashiiiii-images
description: Use this skill to create project images, especially flat geometric images with a dark background and one accent color.
---

# Images

First, select vector or raster output. If words fully describe the image, write SVG code with the procedure below.

Do not make a flat geometric image as a raster image.

The process controls the image quality. Limit the design language. Then compare candidates at their target sizes before you select one.

## When to Use

- Use this skill for logo marks, icons, favicons, promo tiles, and README header images.
- Use this skill for an OSS style with two to four shapes and one accent color.

If the image is illustrative or photorealistic, use a raster image generator. Then use a process that removes the background.

## Gather Requirements First

Collect four inputs before you create an image. The request and the repository can already contain some inputs.

For each missing input, ask the user. Ask one question at a time. Include the default in each question.

Do not draw until you know all four inputs. A temporary accent or an exploratory draft still uses assumptions.

An incorrect background or color invalidates the complete contact sheet. One early question prevents work on incorrect candidates.

| Input | Confirm | Default to offer |
|-------|---------|------------------|
| Target | Identify the asset and its smallest usable size. | If the request does not specify a target, always ask. |
| Colors | Identify the accent color and the intended background. | Use a dark background and one accent color. |
| Motif | Identify the name meaning, domain concepts, and motifs to avoid. | Use the project name and README. |
| Output | Identify the file formats and target paths. | Create an SVG mark and PNG files at the target sizes. |

The target supplies the sizes for step 3. The motif supplies the metaphor list for step 2.

## The Recipe

1. **Define the design language.** Use two to four basic shapes for each mark. Use one accent color for each mark. Prefer negative space to additional detail. Do not use gradients or text.
2. **List metaphors.** Write at least four visual metaphors from the project domain. Include the name meaning and the tool function. Give one metaphor to each candidate.
3. **Create a contact sheet.** Put four to six candidate tiles in one SVG. Show each candidate at approximately 100 px. Also show it at its smallest target size. Use the intended background color. Render the SVG. Then inspect the PNG at its actual sizes.
4. **Select one candidate.** Refine it with coordinate changes. If no candidate works, change the constraints. Then create a new contact sheet. Do not refine a weak candidate.
5. **Deliver only the foreground mark.** Do not put a background tile in the final SVG. The context supplies the background. Use `fill-rule="evenodd"` subpaths for transparent holes. Do not use shapes that have the background color.

Render loop:

```bash
rsvg-convert -w 1200 sheet.svg -o sheet.png   # inspect visually
for s in 16 32 48 128; do rsvg-convert -w $s -h $s mark.svg -o mark-$s.png; done
```

## Quick Reference

| Target | Verify at |
|--------|-----------|
| Favicon or browser tab | 16 px |
| Toolbar or extension list | 32 px and 48 px |
| Store listing, README | 128 px+ |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Use temporary colors or sizes before the user answers questions. | Ask one question for each missing input before you draw. Include a default. |
| Refine the first idea. | Compare four to six candidates before you select one. |
| Use an illustrative pictogram. | If its description needs a verb, reduce the image to an abstract form. |
| Put a background rectangle in the mark. | Deliver only the foreground. The context supplies the background. |
| Fill holes with the background color. | Use `fill-rule="evenodd"` to make the holes transparent. |
| Inspect legibility only at full size. | Put the small and large sizes next to each other. |
