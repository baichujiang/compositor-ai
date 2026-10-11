# Compositor AI application icon

Compositor AI 0.4.2 replaces the inherited upstream application icon with an independent visual identity: a forest-green tile, stacked image canvases and a star. This distinguishes the fork in Finder, the Dock and the app switcher. Native editor behavior and the upstream compatibility baseline are unchanged.

## Asset and generation

- Master: `../Compositor/Assets.xcassets/AppIcon.appiconset/app-icon-1024.png`.
- Generated on 2026-10-11 using the built-in image_gen tool through the imagegen skill, with true alpha transparency. No external logo or upstream icon was used as an image reference.
- The generated PNG was mechanically resized with macOS `sips` to 1024 pixels, then to 512, 256, 128, 64, 32 and 16 pixels. The existing macOS AppIcon catalog retains its ten 1× / 2× slots. All PNGs retain alpha transparency.
- The 1024px master is the editable replacement source for future icon work. The upstream artwork remains in Git history.
- When updating artwork, check the transparent corners and readability at 16/32/64 pixels, build a Release app, and inspect the compiled `AppIcon.icns` and bundle icon metadata. Do not replace a running user's app bundle; distribute a new version and let them save existing documents before replacing their installed copy.

## Final generation prompt

```text
Use case: logo-brand
Asset type: production macOS application icon for Compositor AI, a photo compositing editor with optional AI assistance.
Primary request: Create one original, polished application icon that is clearly distinct from an existing app whose icon is only a blurred blue-to-orange gradient. Do not reuse or imitate any existing company logo.
Subject: a bold, centered stack of three offset image-canvas tiles; a single confident four-point star is integrated into the top tile to convey AI-assisted editing. Use very simple broad geometry, few parts, and a strong distinctive silhouette. The top tile is warm ivory; the two underlying tiles are jade and teal, with restrained dimensional separation. No lettering.
Scene/backdrop: deep forest-green rounded-square macOS icon tile, gentle green illumination and restrained material depth; genuinely transparent outside the rounded-square tile, including corners and surrounding margin.
Composition/framing: square 1024x1024 canvas, straight-on orthographic view. The rounded-square tile occupies approximately 80% of the full canvas width, centered with equal 10% outer transparent margins, matching the visual weight of a native macOS app icon. Center symbol occupies about 60% of the tile, with generous clear space. Crisp shapes and high contrast so the icon remains legible in the Dock at 16px and 32px.
Style/medium: refined contemporary macOS icon, subtle satin dimensionality, clean edges, very soft integrated shadow, minimal visual complexity. Not a screen mockup or product photograph.
Constraints: one icon only, no montage, no device, no text, no letters, no watermark, no tiny decorative details, no border framing the image, no blue-orange blur. Preserve true alpha transparency beyond the tile.
```

