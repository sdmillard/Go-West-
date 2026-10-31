# Farm shepherd art

Approved by Spencer on October 27, 2026 after reviewing the dark-coated revision against the original supplied dog pack. The approved sprite is now installed at `art/pixels/dog.png`. The first working-dog gameplay slice is now implemented; see [Working dogs](WORKING_DOGS.md).

## Historical and visual basis

Use **farm shepherd**, an informal working type, rather than claiming a modern registered pedigree for an 1848 animal. The [English Shepherd Club history](https://englishshepherd.org/breed-history/) describes multipurpose British shepherd dogs brought to North America beginning in the 1800s, selected for herding, guarding and hunting. Registration in 1927 is later than the game's setting. This establishes a plausible reference type, not proof that a particular Oregon Trail party owned one.

The [UKC English Shepherd standard](https://www.ukcdogs.com/docs/breeds/english-shepherd.pdf) is a modern anatomical reference: sturdy muscular legs, deep chest, folded ears, furnished coat and feathered tail. Spencer supplied a side-view engraving to clarify proportions and dark/pale markings. The sprite is original integer-pixel drawing, not a traced or embedded copy of that image. Reference artwork is not redistributed.

## Asset contract

- Source: `art/aseprite/scenes/dog.lua`, using the shared named palette.
- PNG: 384 x 132; 8 columns and 3 rows of 48 x 44 cells.
- Rows: idle, walk_right, sit. Eight frames at 12 fps per animation.
- Ground anchor: (24,39); mirror horizontally for left-facing travel.
- Three editable layers: far legs/tail, body/near legs, head/markings.
- Binary alpha, no filtering. The current pack has no swimming or injury animation.
- Regenerated layered `.aseprite` and enlarged review PNG remain under ignored build output.

Rebuild with `art/aseprite/build.ps1 -Scene dog`; use `-Install` only for approved changes. The generator needs no external image or original archive. The art suite checks grid, alpha, padding, occupied cells and distinct animation frames.

## Gameplay integration

See [Working dogs](WORKING_DOGS.md) for purchases, care, hunting, camp watch, save compatibility and remaining scope. The runtime draws the approved cells at half size next to people, using nearest-neighbor sampling; the management panel shows a larger portrait.

## Validation

Godot 4.5.1 import succeeded. All 100 suites in `test.ps1` pass, including 1,003 art checks. Log: local `.tools/dog-art-full-tests.log`. The independent installed-source rebuild SHA-256 is `25ba3c9353edda5a60b535ac066fc3d0a3387f6355f9bc90f98dab56fe99558f`, identical to the approved draft PNG. Simulation and data rules are unchanged.
