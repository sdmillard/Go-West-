# Agent notes: Westward, Probably

Instructions for any coding agent (Codex, Claude, or another) working in this repository.

- Read `README.md`, then `docs/CLAUDE_HANDOFF.md` for current state, design commitments and working rules.
- Godot 4.5.1, GDScript. Run `./test.ps1` (Windows) before handing work back; the portable runtime lives in ignored `.tools/godot/`.
- `research/local/` is third-party material and must stay out of Git.
- **Art:** new and replacement pixel art is made with the Aseprite Lua pipeline. Follow `art/aseprite/README.md` for installing Aseprite, building scenes, the review loop and the art rules. The older GDScript painters (`art/build_art.gd`, `art/location_art.gd`, `art/western_locations.gd`) still produce the pictures that have not been replaced yet.
