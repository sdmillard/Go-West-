# Western pixel art direction

The game uses original, directly authored pixel assets. Shapes, letters and animation frames are specified in `build_art.gd`; location illustrations are in `location_art.gd`. The PNGs are reproducible exports, committed so playing does not require an art build step. [Location references](LOCATION_REFERENCES.md) record which historical images and written sources informed each place, and which details remain interpretive.

## Presentation

- Native screen: **640 × 360**, initially presented at **1280 × 720**.
- Godot viewport stretch with integer scaling and nearest-neighbor filtering. Larger windows may have letterboxing to keep pixels uniform.
- Fixed earthy palette: canvas cream, ochre, brass gold, dark walnut, sage, prairie green and muted sky blues.
- Original 5 × 7 bitmap alphabet; narrative text displays in uppercase, like early computer adventures.
- Wood frame, brass pins, parchment story and ledger panels, compact clickable controls.
- Prairie and river backgrounds: 432 × 150 pixels, with stepped clouds, hills, grass tufts, wheel ruts and pixel texture.
- Distinct arrival art for Independence, Elm Grove, Wakarusa, Kansas River, Big Blue and the Platte, plus a resting camp. Separate 622 × 273 town-preparation and general-store interiors support the opening flow. Source media is not included in these original pictures.
- Dedicated 432 × 50 ground/horizon layers wrap during travel; distant scenery moves at one-seventh of foreground speed. Both stop when travel pauses. Short town buildings use one window row and every doorway has reserved clearance.
- Crossing scenes distinguish wading oxen and rolling wheels, an unhitched floating wagon with separately swimming livestock, and a wagon on a wooden ferry platform. Mishaps add a brief dip/splash without inventing an overturned wagon or individual drowning outcome.
- Wagon: four 96 × 64 frames. Oxen: four 48 × 32 frames, staggered in play. Discrete wheel spokes, leg motion and a one-pixel wagon bounce during travel.
- Matching Corolla, elder god and lightsaber sprites. No classic game graphics, music, fonts, or commercial art were copied.

This is **16-bit-era art direction**, not emulation of a particular console's hardware, palette or memory restrictions. The graphics continue to be ordinary Godot textures. Pixel art can gain more detail through further deliberate asset work without changing the simulation.

## Rebuild

```text
godot --headless --path . --script art/build_art.gd
godot --headless --path . --editor --import
```

Run `test.ps1` afterward. The art tests check image loading, crisp alpha, actual frame differences, font coverage, and fixed integer presentation. The UI test can capture the whole scene and examples with `-- --capture`.

The motion suite can capture actual crossing frames using `godot --path . --script tests/test_motion.gd -- --capture`. Its frames remain in ignored `.tools/animation-frames/`. With Pillow installed, `art/encode_motion_preview.py` encodes them into `docs/river-crossings.gif`; the GIF is a recording of the real scene, not a separate animation mockup. Pillow is optional and is not needed to play the game.

## Image generation exploration

The built-in image generation tool was used once for a prairie concept before the decision to draw game pixels directly. That concept is not consumed by the game. Its original output remains at `C:\Users\Spencer\.codex\generated_images\01a1616d-2500-77a1-aee5-4b60c5f99b5c\exec-036d2463-0826-4fda-94a0-87873315bd4b.png` as a discarded reference. The final runtime assets are the PNGs in `art/pixels/`, built entirely by the pixel source above.

The exploratory generation prompt was:

> Use case: historical-scene. Asset type: background-only panoramic pixel art for an original 16-bit-era wagon survival game. Primary request: rich authentic hand-pixelled 1990s 16-bit console artwork of the Kansas tallgrass prairie in 1848. Wide 3:1 landscape, approximately 1536 by 512 output, conceptual pixel grid 640 by 214. Scene: spacious blue sky with layered cream clouds, distant rolling blue-green hills, lush golden-green prairie grasses and wildflowers, an empty broad earthen wagon track running horizontally across the lower quarter, foreground grass tufts and small rocks. Clear sunny late spring light, inviting sense of a long journey, subtle ordered dithering, discrete color ramps, crisp intentional pixels, shaded clusters, detailed painterly pixel craft. Camera: side-view game scenery, horizon around the middle. Constraints: EMPTY landscape only, no wagon, no animals, no people, no vehicles, no signs, no buildings, no UI, no borders, no text or watermark. Keep the central foreground road clear for separately composited moving wagon sprites. Original composition, no borrowed game assets, no smooth vector shapes, no blur, no photorealism. Fill entire canvas with landscape.
