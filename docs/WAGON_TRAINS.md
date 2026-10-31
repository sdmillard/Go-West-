# Expandable parties and wagon trains

The starting character screen remains five travelers. Additional companions join through the existing searches at populated stops and nearby trading/emigrant camps. A full starting party can now search: no death or dismissal is required to create a sixth place. New people retain generated personalities, appearances, relationships, contracts and individual health. They eat normal daily rations, require clothing, carry personal gear and receive wages under their actual contracts. They bring no free food or ammunition.

## Buying and organizing wagons

Buy additional empty wagons at stocked settlement counters. Existing researched wagon prices, regional factors, trading benefits and finite local stock are reused. There is no five-wagon or ten-traveler gameplay cap. Each additional wagon needs an available driver and at least one separate ox; buying the needed oxen in the same basket is supported. A shop's limited stock is a local supply limit, not a global wagon cap. The previous32-person archive ceiling is removed; saved-file size and defensive parser bounds still exist.

**Supplies > Wagons & teams** opens a compact scrolling ledger. Assign each wagon its driver and up to six individual oxen, or use the automatic assignment button. A person or ox cannot serve two wagons. Away outriders, wagon-cache guards, dead/departed people and nursing patients cannot drive the traveling train. Drivers may be released with Unassigned so assignments can be swapped. Livestock still shows individual animal conditions; use the wagon ledger for multiple teams.

The same weak-team rules apply separately: four oxen are the normal baseline, five/six get the existing modest bonus, and smaller teams pull less and move more slowly. An underpowered or worn team limits the train's pace. New purchases retain healthy individual animals instead of inheriting the old team's condition. Extra led oxen remain available for swapping.

Each frame adds2500lb of storage guideline. Working capacity is summed from its own team's625lb per ox, capped at2500lb per wagon. Supplies are a shared train inventory, loaded proportionally to team capacity; this is not a new per-item manual packing interface. Empty frames add neither free provisions nor household belongings. Household/personal gear keeps its real existing total. Overloading uses the existing movement penalties.

A missing driver, empty team or exhausted team stops movement without silently advancing the day. If a driver dies during a travel day, that day's time/meals still pass, but the train stops before receiving travel miles. Reassign available people/animals, recruit or buy replacements where possible, or reduce the train.

## Reducing the train

- Sell additional empty frames at the normal settlement counter. Shared goods, people and animals stay with the remaining wagons, and the quote shows reduced capacity. Selling the final wagon retains the existing keep/sell/leave packing review.
- **Leave >** beside an extra wagon permanently discards that empty frame after an in-game confirmation. People, animals and goods stay with the party; review the reduced cargo allowance and reassign freed oxen. This is a last-resort way to resolve a driver shortage on the road. The final wagon uses the established packing flow.
- **Abandon train / Choose packs** leaves all currently owned frames and the selected cached goods at the existing map marker. Guards and offscreen camp rules still apply. Recovering it restores the actual frames, preserving wagon numbers and damage, then requires valid drivers/teams. Independent caches of individual wagons at several locations are not introduced in this pass.

Breakdowns identify one actual frame. Repairing with a spare or camp work clears that wagon's obligation; alternatively leave that damaged extra frame behind. A broken frame stops the convoy. Frame condition currently distinguishes sound and broken; there is no newly invented gradual wear system.

## Crossings and presentation

Ferry and wagon-road tolls charge per frame, with existing livestock head charges added separately. Open offers refresh when wagon count changes. Ford/float risks roll separately for each wagon; mishaps remove actual shared goods and injure the corresponding driver. The crossing history records which wagons had accidents. Existing single-wagon outcomes and casualty rules are retained.

The road view reuses approved wagon/ox art to show a representative train, while the ledger gives exact counts. Large walking parties are represented by a bounded on-screen group; the actual roster remains scrollable. River animations and the Cascades steering activity represent the convoy rather than spawning a separate minigame for every raft.

## Saves and checks

Older journeys without a wagon ledger remain single-wagon journeys (or packers) until the ledger is needed. Starting-party and archived identities are retained. New records validate frame numbers, unique drivers, unique draft animals, repair identity and agreement with the animal ledger. Malformed shapes are rejected before accessing nested fields. Existing prices/data files are unchanged, so no rules-fingerprint migration is required.

Focused wagon-train tests:72checks, zero failures (`.tools/train-tests.log`). Cases include actual sixth-person recruitment,36-person roster saves and meals, a six-wagon purchase, disjoint teams/conditions, driver loss, extra-frame sales/discards, damaged frames, full-train cache recovery, ferry pricing and independent crossing losses, malformed saves and UI assignment. Recruitment46 and robbery-demand46 checks pass. All103 regression suites pass (`.tools/wagon-train-full-tests-02.log`); final targeted wagon-train72, robbery-demand46 and UI checks also pass. Native captures of the compact ledger, expanded roster, road train and supplies menu were inspected. This is functional/regression coverage, not a claim that large-convoy survival has received a new balance campaign.
