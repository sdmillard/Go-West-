# Aseprite art pipeline

Scene art can be drawn by Lua scripts that run in [Aseprite](https://www.aseprite.org/) without opening its window. A script places every pixel, the same way `art/build_art.gd` and `art/location_art.gd` do. Aseprite adds layers, animation frames, sprite sheets and a layered `.aseprite` file that a person can open and touch up. Any model or person who can run a shell command can use it.

The game itself never needs Aseprite. Finished PNGs are committed in `art/pixels/` under the same names and sizes as before, so the engine and UI do not change when a picture is replaced.

## Getting Aseprite

Use one of these:

1. **Steam or itch.io copy** (paid). `build.ps1` finds the default Steam install by itself.
2. **Compile it on Windows:** `powershell -ExecutionPolicy Bypass -File art/aseprite/install_aseprite.ps1`. It needs Git and Visual Studio 2022 with the "Desktop development with C++" workload. It builds a headless Aseprite into `.tools/aseprite/bin/`, which Git ignores.
3. **Compile it on Linux** (cloud sessions): `art/aseprite/install_aseprite.sh`. The script lists the apt packages it needs. It takes about 10 minutes on 4 cores.

License: Aseprite's EULA (section 2(g)) allows compiling the source for your own personal use. A compiled binary must not be committed, uploaded or shared. Art made with it belongs to this project.

You can also pass a path explicitly: `-Aseprite C:\path\to\aseprite.exe`, or set the `ASEPRITE` environment variable.

## Building scenes

```text
./art/aseprite/build.ps1                              # every scene, review copies only
./art/aseprite/build.ps1 -Scene independence          # one scene
./art/aseprite/build.ps1 -Scene independence -Install # also copy into art/pixels/
art/aseprite/build.sh [--install] [scene ...]         # Linux/macOS
```

Output goes to `art/aseprite/out/`, which Git ignores and Godot skips:

- `<name>.png`: the flattened picture at native size.
- `<name>.aseprite`: the layered file, for opening in Aseprite.
- `preview/<name>_x3.png`: a 3× nearest-neighbour copy for review.

After `-Install`, run `godot --headless --path . --editor --import` and then `./test.ps1`. `tests/test_art.gd` checks exact sizes, crisp alpha and that every route stop has art.

## Seasons

`build.sh --seasons [scenes...]` (or `build.ps1 -Seasons`, not yet written) also builds `location_<name>_winter.png` and `location_<name>_autumn.png` for every location script. Those builds pass `season=winter` or `season=autumn`, and `K.season` is set to match.

- `K.elm`, `K.willow` and `K.conifer` draw bare, turned or snow-laden trees themselves. A scene that paints its own broadleaf crowns takes its colours from `K.leaves(dark, mid, light)` (see `wakarusa.lua`).
- `K.save` then repaints the flattened picture. In winter, grass and sage become snow, far hills turn pale, and snow lies on the top edge of evergreens and roofs. In autumn the grass dries to tan. Rock colours (ochre, gold, sand, silt) are left alone, so buttes, cliffs, sod and adobe keep their colour.
- Never call `K.rnd` in season-only code. It would shift every later random mark, so the seasonal picture would stop matching the summer one.
- Put `-- no seasons` near the top of a script to skip it. Indoor scenes, trading counters, the night camp, Independence and the endings are skipped this way.

ui/main.gd `_scene_season()` picks the version: winter in snow weather or from December to February (Eagle Creek and Oregon City only when snowing), autumn in October and November.

## How to work

1. **Look at every render.** Open the `_x3` preview and judge it before you go on. Most problems only show up when you look: a cupola floating above its roof, oxen that read as dogs, a wagon parked across a door. A model that cannot view images should not author art with this pipeline.
2. **Show Spencer before you install.** Put the old picture beside the new one. Install only scenes he has approved.
3. **Scripts are the source.** The `.aseprite` file is regenerated on every build. If someone hand-edits a scene in Aseprite, commit that file under `art/aseprite/hand/` and stop regenerating that scene.

## Rules for the art

- **Sizes:** route and camp scenes are 432 × 150. `location_town_setup` and `location_store` are 622 × 273. Travel ground and horizon layers are 432 × 50. Wagon frames are 96 × 64 and oxen frames 48 × 32, four frames side by side. Check `tests/test_art.gd` for the current list.
- **Palette:** use the named colours in `K.HEX` in `lib.lua`. The first block is the game's original palette. If a scene needs a new shade, add it to `K.HEX` with a clear name rather than writing a hex value in the scene.
- **Light** comes from the upper left: left faces are lit, right-hand side walls and undersides are in shade, and shadows fall to the lower right.
- **Pixels:** everything sits on the integer grid. No antialiasing, no partial alpha, no resampling.
- **Original work:** never paste or trace a photograph, museum image or another game's art. Use references only for what was there.
- **History:** follow `art/LOCATION_REFERENCES.md` and `art/WESTERN_REFERENCES.md`. Show places as they were in 1848. For example, Fort Laramie and Fort Bridger were private trading posts, and Fort Kearny was the only army post on the route. Do not add later buildings because a good picture of them exists. Record new references in those files.
- **Determinism:** use `K.rnd`, seeded by `K.canvas`, never `math.random`. Then a scene rebuilds pixel for pixel.

## Writing a scene

Make `scenes/<scene>.lua`:

```lua
local K = dofile(app.params.kit)
local W, H = 432, 150
K.canvas(W, H, 1848)           -- size and random seed

K.layer("sky", function()      -- layers stack bottom to top
  K.rect(0, 0, W, 70, "sky")
  K.cloud(40, 16, 1.4)
end)
K.layer("figures", function()
  K.wagon(56, 128, 1)
  K.team(110, 128, 1, {"dark"}, {"light", true})
end)

K.save("location_elm_grove")   -- must match the art/pixels/ file it replaces
```

`scenes/independence.lua` is the worked example.

## Kit reference (`lib.lua`)

| Group | Functions |
| --- | --- |
| Canvas | `canvas(w, h, seed)`, `layer(name, fn)`, `save(name)`, `rnd(n)`, `at(x, y)` returns the colour name already painted |
| Primitives | `px`, `rect`, `line`, `ellipse(cx, cy, rx, ry, c)`, `poly({{x, y}, ...}, c)`, `dither(x, y, w, h, a, b)` (checkerboard), `blend(x, y, w, a, b)` (3-row 25/50/75% band) |
| Sky | `cloud(x, y, scale)`, `sky(w, bottom, clouds, haze)` (banded sky; vary the cloud list per scene) |
| Buildings | `bricks`, `clapboard`, `side_wall` (receding shaded wall), `hip_roof`, `chimney`, `windows(x, y, w, n, frame, shutter)`, `door`, `sign` |
| Landscape | `smooth(pts)` (Catmull-Rom over `{x, y, half_width}`), `ribbon(pts, c, grow)`, `river(pts, bank, glints)`, `ridge(x0, x1, base, floor, height_fn, fill, lit, shade)` |
| Nature | `elm(x, y, scale)`, `conifer`, `boulder`, `sage`, `willow`, `basalt` |
| Figures | `wagon(x, y, facing)`, `wheel`, `ox(x, y, facing, coat, pale)`, `team(x, y, facing, far, near)`, `person(x, y, coat, hat, skirt)`, `barrel`, `crate`, `shadow` |

Coordinates for figures are ground contact points, so things line up on the street. `facing` is `1` for right and `-1` for left. Ox coats are `light`, `dark` and `red`.

When you draw something two scenes could share, such as a river bank, rock face, pine, fort wall or tipi, add it to `lib.lua` instead of the scene.

## Status and plan

| Step | Scope | State |
| --- | --- | --- |
| 1 | Pipeline, kit, build and install scripts, this guide | Done |
| 2 | First screens: Independence, town setup, store | Independence drafted (not installed) |
| 3 | Travel: wagon and oxen frames, travel backgrounds | Not started |
| 4 | Route scenes, about 10 per pass: Kansas, Platte, Rockies, Oregon | All rebuilt once; weak scenes being redone (batch 1: burnt_river, devils_gate, deschutes, john_day, the_dalles, wakarusa) |
| 5 | Runtime-drawn figures (walkers, hunt animals, swimmers, graves) as sprite sheets; needs small changes in `ui/trail_view.gd` and `ui/hunt_view.gd` | Not started |
| 6 | Optional ambient animation (smoke, water) | Not started |

Update this table when a scene is installed.

## Installed rafting pack

`scenes/rafting.lua` builds the approved isometric raft, four-frame obstacle/debris sheet and water foam. Installed October27,2026 after Spencer approved the in-game comparison. Layouts and runtime anchors: [rafting artwork](../../docs/RAFTING_ART.md).

## Installed Wasco encounter scene

Spencer approved the Wasco trading-landing draft on October27,2026. `scenes/encounter_wasco.lua` now outputs `encounter_the_dalles.png` (432×150), installed with the same pixel data as the approved preview. Build with `-Scene encounter_wasco`; the presentation registry switches from the normal Dalles landmark only during the community visit or local recruitment. Six further scenes remain briefed, not approved or installed. See [the encounter art brief](../../docs/NATIVE_ENCOUNTER_ART_BRIEF.md) for references and historical limits.
