# Journey records and gravestones

**Current update:** [Economy and preservation](ECONOMY_AND_PRESERVATION.md) adds salt inventory and preserved-batch type/expiry to saved journeys. Verified prior full-road saves migrate without changing cash, food, people, dates or RNG; zero salt is granted. Future prices change while saved pending quotes remain valid.

The development order is food/load/yield/survival baseline, then save/load, then gravestones, then route expansion. All four stages now have a playable implementation; the continuous road reaches Oregon City. See [route expansion](ROUTE_EXPANSION.md) for the supported itinerary and remaining branches.

## Save and load

The bottom toolbar has **Save** and **Load**. Saving pauses travel and replaces the single journey slot. Loading is available from the opening setup as well as a running or terminal journey and resumes with travel paused. A failed load leaves the current journey intact. Outfitting carts and active hunts are not saved; finish/depart first. The interface also blocks saving/loading during a crossing animation or its unacknowledged result, keeping committed outcomes and presentation aligned. These are manual saves; there is no autosave or multi-slot browser yet.

The save includes party conditions/deaths/personal histories, inventory and fresh-meat batches, date, location, pace/rations, pending encounters or river/service choices, underlying unresolved stops, journal, supply/crossing histories, wet-ground/weather state, encounter cooldowns and hunting outing count. All three ongoing simulation RNG states are stored as decimal strings, avoiding JSON number precision loss. A later hunt is recreated from the journey seed and saved outing count.

`simulation/save_store.gd` writes versioned plain JSON. It validates field types, bounds, party consistency, condition identifiers, effect fields and a fingerprint of the gameplay JSON rules before replacing the in-memory simulation. It does not deserialize objects or run code. A temporary file is flushed and renamed into place; the previous save is retained as `.bak`, with recovery if replacement fails. If the main slot is missing or invalid and the backup can load, Load explicitly reports that it recovered the previous record. A rules mismatch reports incompatibility and preserves the files. A verified migration now upgrades the previous opening-route rules: a party saved at the old Platte completion continues west without spending a day or losing supplies. Other unknown rule sets still fail safely; schema changes need an explicit migration. The explicit chapter endpoint is retained for regression fixtures.

Files use Godot's `user://` directory: with the normal Windows environment, `%APPDATA%\WestwardProbably\journey.json` and `journey.json.bak`. Tests redirect APPDATA into the project's ignored `.tools/userdata` and use separate `test-*` files, so they do not touch the player's actual records. Persistent user data is not committed to the repository.

## Gravestones

After all travelers are lost, the ending offers **Leave a Gravestone** and **Memorial Book**. The editor previews an original pixel marker and accepts a 90-character epitaph; a blank inscription gets a default. It records the party leader's name, the journey's actual date and guide mile. The marker commemorates the lost party.

A companion who dies while others continue can get a stone too, but only over a grave the party actually digs (**The dead → Bury**). Right after the burial the editor opens titled with that person's name. The stone reads "Here lies", the name, the date of death and the grave's guide mile. Declining leaves the grave unmarked, and the remains panel returns either way. A body carried on, left lying, butchered or lost gets no stone. Each stone records a `kind`: `party` or `companion`. Books written before companion stones have no `kind` and read as party stones; an unknown kind is refused as damage. A companion stone counts toward the same 100-stone limit, and later journeys find it on the road like any other.

**Leave This Stone** writes to `user://gravestones.json`, separately from the save slot. Starting or loading a different journey does not erase memorials. The archive retains up to 100 stones; repeated edits to the same seeded party/date/mile loss update its entry rather than duplicating it. A full or malformed archive reports an error and preserves existing data. It also retains the previous file as a backup; automatic backup recovery currently applies to journey saves, not the memorial archive.

Later travel can pause at a previously recorded mile to read a stone; simulation time, supplies and pending encounters stay unchanged. Each marker is announced once during a running UI session. Loading resets this presentation visit list, so a marker precisely at the restored position may be shown again on the next advance. If several stones share an interval, all are noted in the journal and the first opens; all remain readable in **History → Memorial Book**. This is a local memorial system, with no online sharing.

[Bouchard's firsthand design account](https://www.philipbouchard.com/oregon-trail/imagining-design.html) describes creating a tombstone after death and retaining it for later players on the same disk. That persistent-player-memory idea informs this feature. Our archive, exact-mile trigger, marker art and controls are new implementation choices, not a claim that all emigrants had carved stone markers or that this matches every classic edition's tombstone algorithm.

## Verification

The save suite checks full JSON round trips and 120 subsequent decision steps across eight seeds, fresh meat, conditions, fractional cash, unresolved crossings, service-return state, malformed rules/effects, file replacement, backup recovery and real Save/Load controls. The graves suite checks eligibility (including companion graves and older books), persistence, deduplication, inscription limits, corrupt-file preservation, editor preview and later roadside reading. Rendered captures are in `gravestone.png` and `provisions.png`.
