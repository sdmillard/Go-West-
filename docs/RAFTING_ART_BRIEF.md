# Cascades rafting final-art brief

The raft/obstacle/foam pack was visually approved and installed October27,2026; see [installed artwork](RAFTING_ART.md). The broader Gorge scenery below remains a future brief.

The first playable prototype is documented in [Columbia rafting](COLUMBIA_RAFTING_PROTOTYPE.md). Play it before changing its composition or preparing assets. Keep the simulation's hitboxes and outcomes independent of the drawings.

## Current view contract

- Native activity viewport:432x180, nearest-neighbor pixels; HUD and buttons are outside it.
- Isometric projection: downstream `(1.6,-0.8)` screen pixels per world unit; lateral `(105,52.5)` per channel unit. Current reference anchor `(190,100)`.
- Installed raft72x48 has deck center(36,24) aligned with physics; existing wagon64x48 and palette-recolored travelers16x20 remain. Actual party appearances stay separate from environmental art.
- Clear visual differentiation for rocks, driftwood, foam/current direction, banks and the safe channel. Obstacle circles are removed; the approved rock/log sprites and animated foam now supply the visual cues. Internal channel-edge lines have been removed; the actual coastline is the boundary. Changing the bank art requires matching shoreline geometry in the rafting rules and passing the coast-pixel alignment tests.

## Desired set

Original pre-dam Columbia Gorge scenery at the Cascades, current/whitewater animation, readable rock and log obstacles, raft handling/poling and recoverable collision feedback. A wreck can use broken timbers, floating cargo and survivors reaching shore; individual injury/death details must match the committed outcome, not imply extra unrecorded casualties. Patterns now include side-by-side clusters and a laterally drifting log (see [pattern design](RAFTING_PATTERNS.md)); keep their gaps legible and use motion cues for the log. Preserve at least two seconds of on-screen visibility before a hazard reaches the raft. Keep major obstacles ahead long enough to read and react.

Do not add modern locks, dams, steamboats, railways or later portage infrastructure to1848. The NPS reference in the prototype document supplies the historical context; don't trace a photograph or copy commercial Oregon Trail art. This reach was inhabited and worked, especially through Chinookan fishing, navigation and portage activity; avoid presenting it as a generic empty wilderness.

Follow `art/aseprite/README.md`: Aseprite Lua sources, named project palette, crisp alpha, deterministic builds, upper-left light and editable layers. Produce review renders beside the current prototype and get Spencer's visual approval before installing new artwork. The installed pack has Spencer's visual approval. Further bank/scenery replacements still need their own review.
