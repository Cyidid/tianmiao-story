# Generated Image Prompts

These prompts were used with the built-in image generation tool. The outputs are source/reference assets only; they are not `.moc3` Live2D model exports.

## model-sheet

```text
Use case: illustration-story
Asset type: Live2D Cubism production character sheet for a macOS desktop pet
Input image role: identity reference for the exact cat; preserve the same gray-white tabby cat identity, huge round eyes, pink inner ears, triangular smiling mouth, cheek whiskers, gray forehead and tail stripes.
Primary request: Create a high-resolution hand-drawn model sheet for the same cat, not a new character. Include a neutral front sitting pose, front standing pose, side view, back view, and three-quarter view. Keep the head upright in neutral poses, not permanently tilted. The cat must be cute, soft 2.5D anime watercolor/ink style, clean readable contour, stable proportions, same stripe placement, same eye spacing and face identity.
Layout: horizontal character-board layout on a perfectly flat solid #00ff00 chroma-key background for background removal. Add small labels in English only: front sit, front stand, side, back, 3/4. No decorative background, no shadows, no text other than those labels.
Technical constraints: crisp edges, generous padding around every pose, no white matte, no checkerboard, no watermark, no extra characters, no props.
```

## rejected motion-reference

The first generated motion-reference image was rejected because it drifted into a different kitten identity. It must not be used for Cubism production.

The current `alpha/motion-reference.png` is generated locally by `scripts/generate_live2d_source_package.py` from the first front-facing cat in `alpha/model-sheet.png`, so all six cells preserve the selected cat identity instead of mixing in another generated kitten.
