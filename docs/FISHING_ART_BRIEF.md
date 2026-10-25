# Fishing minigame art brief

The playable first slice uses existing Wakarusa river scenery and native retro controls. Dedicated artwork can be developed independently of simulation/fishing.gd, which owns reach, casts, bite timing and catch outcomes. Please keep the art change focused on Lua sources and draft assets; coordinate before editing ui/fishing_view.gd.

Follow [the Aseprite pipeline](../art/aseprite/README.md): use the named existing palette, integer coordinates, crisp alpha, upper-left light and original artwork. Produce and visually inspect enlarged draft previews. Show Spencer the drafts for approval before installing them. No new image-generation dependency or copied classic-game art is needed.

## Proposed asset contract

These names and sizes are a proposed handoff contract; the current UI does not load them yet. Notify the implementation thread if a different layout is needed.

| Asset | Native frame | Sheet | Use |
|---|---|---|---|
| fishing_riverbank.png | 432 x 150 | One image | Clear near shore at left, fishable water to the right |
| fishing_angler.png | 32 x 32 | 4 columns x 4 rows, 128 x 128 | Rows cast, wait, strike, land; four frames per action |
| fishing_bobber.png | 8 x 8 | 4 columns x 3 rows, 32 x 24 | Rows idle, nibble, submerged bite |
| fishing_splash.png | 16 x 16 | 4 columns, 64 x 16 | Cast impact / hooked-fish splash |
| fishing_catch.png (optional) | 16 x 8 | 2 columns, 32 x 8 | A small landed river fish; not a giant salmon trophy |

## Composition

- Design the riverbank for an angler whose feet sit around (64, 138), facing right. Leave room above/right for a simple pole and line. A separate pole layer is welcome if needed; agree its frame size before integration.
- Reserve open water around (288, 110) for the bobber and splashes. Keep the line legible against the water.
- Keep the picture free of labels, meters and buttons. The UI already renders the activity status, reaction window, CAST/STRIKE and return control.
- Do not put a rifle into the angler's hands. Use the existing traveler skin/clothing palette colors so the renderer can recolor the leader.
- The early version uses one representative bank. Avoid a named landmark or buildings that would be wrong at other river stops. Later regional variants can replace the background without changing gameplay.
- A modest hook-and-line arrangement suits the slice. Do not introduce modern spinning reels, plastic lures or visible underwater targets as assumptions about the gameplay.

Please deliver Lua sources, the proposed asset dimensions and enlarged previews first. List animation row/frame order and any registration points. The implementation thread will connect frames to the model's ready, waiting, bite and landed outcomes after art approval.
