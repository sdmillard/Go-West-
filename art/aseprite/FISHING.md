# Fishing artwork and animation

Original assets supplied in Spencer's fishing-art-drafts.zip. The Lua source is scenes/fishing.lua and uses the unchanged shared lib.lua. All five supplied PNGs reproduce byte-for-byte using the canonical Aseprite kit. Editable .aseprite files and enlarged previews regenerate into the ignored output directory; they are not separately edited source files.

Build review copies with art/aseprite/build.ps1 -Scene fishing, or run Aseprite batch with kit and out script parameters. The output folder must contain a preview directory. Verify using art/aseprite/verify_fishing.lua with kit, out and old (the old Wakarusa PNG) parameters. The verifier is outside scenes so ordinary all-scene builds do not invoke a verifier without its old-image argument.

## Contract

| Asset | Frame | Sheet | Rows |
|---|---|---|---|
| fishing_riverbank | 432 x 150 | 432 x 150 | Background |
| fishing_angler | 32 x 32 | 128 x 128 | Cast, wait, strike, land |
| fishing_bobber | 8 x 8 | 32 x 24 | Idle, nibble, bite/submerge |
| fishing_splash | 16 x 16 | 64 x 16 | Four impact/ripple frames |
| fishing_catch | 16 x 8 | 32 x 8 | Two flop poses; optional standalone asset |

Frame time is 160 ms for presentation. Cast, strike and landing run once; waiting/idle/nibble effects loop. A bite plays the submerge row once and holds its final frame. The land row already contains the fish, so the renderer never draws an additional catch on top.

Angler top-left is (52,108); ground registration (12,30) places feet at (64,138). Water contact is (288,110). Bobber registration is (3,6); splash registration (8,12). The separate cream line renders behind the angler and follows the rod tip of each action frame.

The supplied README's waiting tip was one pixel above its actual source. Runtime uses the source coordinates: local (30,8) for wait frames 0/1, (30,9) for 2/3. Cast tips are (4,2), (17,1), (30,3), (31,12). Strike tips are (29-2*frame,4). Landing has its own painted line and fish.

Exact skin/hair/clothing palette colors allow ui/traveler_palette.gd to recolor the angler using the active leader's appearance. Water, effects, rod and backdrop remain unchanged.

ui/fishing_scene.gd is presentation only. It observes actual cast/catch transitions, animates the supplied sheets, and never modifies activity data, timers, randomness or yields. Repeated refreshes do not restart action animations. ui/fishing_view.gd retains all existing controls and calls the existing fishing simulation.

The review checkout holds draft copies pending Spencer's visual approval under art/aseprite/README.md. Canonical master remains unchanged until approval and merge.

Verification: all 74 Godot suites passed on final runtime/test checkpoint 4fea357, including 78 focused fishing checks. All five PNGs regenerate byte-for-byte and pass the Aseprite size, frame-count, palette and alpha verifier. Native setup, bite, landing and report screens reviewed. Existing 44 integrations belong to the preceding gameplay checkpoint; they were not rerun for this presentation-only change. See docs/fishing-art-evidence.json.
