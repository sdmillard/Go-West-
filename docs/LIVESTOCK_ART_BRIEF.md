# Livestock art brief

Initial scope: dairy cows, goats and chickens. Artwork can proceed before historical research establishes prices, production and care rates. No gameplay numbers are encoded in art.

## Required assets

Use the existing Aseprite Lua pipeline, named palette, integer pixels, upper-left lighting and nearest-neighbor previews. Original artwork only; full transparency or full opacity, no partial alpha. Commit reproducible Lua sources. Produce review drafts before live installation.

| Asset | Frame size | Layout |
|---|---|---|
| livestock_cow.png | 48 x 44 | Eight columns; row 0 idle, row 1 walk right |
| livestock_goat.png | 48 x 44 | Eight columns; row 0 idle, row 1 walk right |
| livestock_chicken.png | 48 x 44 | Eight columns; row 0 idle/peck, row 1 walk right; bird occupies only a small part of frame |
| livestock_coop.png | 32 x 32 | One transparent frame: small ventilated wooden transport coop, suitable for a wagon overlay |
| cross_livestock_cow.png | 48 x 40 | Eight columns; rows walk, wade, swim in the existing crossing perspective |
| cross_livestock_goat.png | 48 x 40 | Eight columns; rows walk, wade, swim in the existing crossing perspective |
| livestock_icons.png | 16 x 16 | Three columns: cow, goat, chicken |

Travel ground contact: bottom-center at (24,39), matching the horse-frame ground height. Keep smaller animals appropriately scaled inside their frames; do not enlarge a chicken to fill its cell. Cow should read as a dairy cow rather than a yoked ox. No tack or rider. Match body scale and colors to existing horses/oxen. For crossings, use the existing cross_horses.lua registration point (12,34) and waterline conventions; inspect it before drawing. Do not bake water into walking rows. Chickens travel in a coop; no swimming chicken sheet is requested.

Shared playback target: eight frames, 12 frames per second. Idle animation should be gentle and loop without a jump. Keep feet/body registration steady. No text, UI, food yield, blood or death scene painted into these assets.

## Deliverables

Provide Lua source, native PNG sheets, layered Aseprite files, 3x nearest-neighbor previews and a contact sheet showing each animal beside the existing ox/horse for scale. Include sample travel/camp/crossing compositions with separate foreground sprites. Keep drafts separate from installed textures until Spencer approves them, following art/aseprite/README.md.

## Mechanical design to research separately

Animals are assets with purchase/resale/slaughter value and care costs, not free generators. Research historical feasibility, lactation/egg production, sex and breeding assumptions, forage/water, seasonal decline, disease/losses, ferry/toll treatment and actual usable calories before choosing numbers. Reuse existing freshness, preservation, trading, animal-condition and crossing accounting where appropriate. Initial scope excludes a breeding simulation, newborn sprites and a new animal task minigame.
