# Approved Cascades rafting artwork

Spencer approved the in-game before/after preview on October27,2026 and requested installation. The live Cascades activity now uses the new isometric sprites, with all temporary collision circles removed. It is available through the normal Columbia river route and through `play-rafting-prototype.cmd`.

## Source and layout

Original project artwork: `art/aseprite/scenes/rafting.lua`. It uses the existing named palette in `lib.lua`, upper-left lighting, integer pixels and binary alpha. No external art, tracing or image generation is used. Rebuild review copies with `./art/aseprite/build.ps1 -Scene rafting`; install approved outputs with `-Install`.

- `rafting_obstacles.png`:128x96, four32x32 frames per row. Rows0/1/2 hold faceted basalt with eddies, bark/end-grain driftwood, and broken wreck timbers. Water-contact anchor16,22 for rocks/logs. Foam and debris vary over the animation cycle.
- `rafting_foam.png`:128x16, four32x16 current crests, displayed at6frames/second with offset phases.
- `rafting_raft.png`:72x48 lashed timber deck. Its deck center36,24 is placed on the physical raft position. Existing approved wagon/traveler layers keep their placements and actual party palettes.

The renderer uses ground contact to draw hazards behind or in front of the raft. Rocks/logs retain their normal appearance after contact; a short foam burst marks actual recorded impacts. There are no collision rings, invisible guide lines or red obstacle outlines. Wreck art depicts floating wood, with individual casualties still determined and reported by the simulation.

The approved crossing-bank background is reused. This pack polishes the raft, obstacles and water motion; dedicated Columbia Gorge bank scenery remains a possible later art pass. The water-contact bounds, generated course, steering, damage and casualty rules remain the tested gameplay baseline. Saves use the same rules fingerprint because this update changes rendering, art and instruction text.

## Validation

Art suite:1030 checks, zero failures. It checks sprite sizes, populated cells, distinct animation frames and crisp alpha. All three PNGs rebuild byte-for-byte identically in a second Aseprite run. Native main-game entry, moving-hazard and actual wreck/report captures were inspected. All102 regression suites pass, including1030 art checks and491 rafting checks (`.tools/rafting-art-full-tests.log`).

Local review comparison: `.tools/rafting-art-review/comparison.png` (before left, approved after right). Installed captures: `.tools/rafting-moving-6.png`, `.tools/rafting-installed-wreck.png`, `.tools/rafting-installed-report.png`. Close and reopen a running game or practice app to load the new art and renderer.
