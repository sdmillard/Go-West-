# Trail ribbon, place choices and window exits

The logical canvas is 800 × 360. The original 640-pixel travel area and art keep their pixel sizes; extra width holds a permanent right ribbon. The default window is 1600 × 720 with nearest filtering and integer scaling. Smaller displays fall back to 800 × 360.

| Ribbon | Actions |
| --- | --- |
| Map | Route overview, zoom, pan, wagon focus |
| Guide | Overland guide |
| Party | Health, relationships, wages, dismissal and vacancies |
| Travel | Pace and rations |
| Supplies | Direct inventory, Drop supplies, Abandon/recover wagon, oxen |
| Hunt & Forage | Hunting or foraging preview |
| Villainy | Attack someone, steal, rob, handling the dead |
| History | Journal and memorial book |

## Context belongs below the picture

The existing place/story area shows buttons only for opportunities present there: **Store**, **Talk to traders**, **Visit emigrant camp**, **Find companions** when a position is vacant, and **Local activities** at a stop. No permanent camp/trader/recruitment entry remains in the ribbon. The place choices disappear during unresolved encounters, hunts and crossing reviews. Visiting a panel is free; actual transactions, searches and activities retain their existing costs. Recruitment also recognizes nearby emigrant camps.

## Villainy tree

**Attack someone → Party member → named active traveler → attack options.** This includes recruits and excludes dead/departed travelers and the leader. Party no longer contains an attack button; dismissal remains separate.

**Steal → place here → theft** and **Rob → place here → robbery.** Each staffed post, ferry, toll gate, Fort Kearny commissary, passing trading party and emigrant camp within reach is its own branch ("FORT BRIDGER · TRADING STORE >", "AN EMIGRANT CAMP >"), so a camp next to a post can be robbed too. The preview shows only the chosen act and a **< STEAL** / **< ROB** link back; there is no second STEAL/ROB/ATTACK menu inside the preview. Attack previews likewise link back to **< SOMEONE HERE** or **< PARTY MEMBER**, and The dead links back to **< VILLAINY**. A preview restored from a save, which carries no chosen act, lists every act.

**Attack someone → Someone here → named local → attack options.** The list comes from living staff at the current staffed venue, nearby passing traders and nearby emigrant camp. A stable cosmetic name and role identify each fictional actor; naming uses an independent RNG and makes no historical identity claim. Selecting a target never attacks automatically. Guns and unarmed attacks use existing costs and risks.

Committed incidents retain the actual target id. The chosen person receives the injury/death, produces their own remains and is removed from future lists if dead. Attacking a supporting worker does not seize the keeper's stock or waive the toll. Other staff can witness, resist and spread news as before. Saved previews validate the target's place and identity; returning to a preview never rerolls it. Theft and robbery have separate preview branches. Mandatory loot/escape/standoff stages still use the authoritative simulation choices.

## One exit convention

A small **X in the upper-right corner** closes dialogs and the map; Escape is the keyboard alternative. The X uses the existing bitmap-font glyph inside a 14-pixel hit area. Redundant OK/Back-to-trail footer exits are hidden. Explicit committing actions such as Rest, Slaughter, Leave Wagon and Leave This Stone remain visible; X cancels their confirmations. Nested trees have labeled parent links inside the menu, distinct from exiting the window. Closing a committed hunt returns its existing report; closing an active crime panel does not cancel or erase the incident.

## Actual Options

**Options** holds full-screen, 1×/2× window size and automatic-travel display speed (2.5, 1.25 or 0.75 seconds per simulated day). Display speed changes the delay between days, not distance, food, disease or other daily rules. Preferences live separately in `user://preferences.cfg`; no journey-rule fingerprint change is needed for the layout. Current pace/rations remain visible on the main ledger/control panel.

The UI reuses the original parchment/wood theme, bitmap font and pixel scenes. No reference-game artwork was copied. Native checks cover setup, trail, place choices, all ribbon sections, local targets, preferences and map.

## Camp is a location, not a rest command

The main **Camp** button is the single camp entry; the duplicate Camp & Care ribbon entry is removed. Entering camp pauses travel, shows the camp background and opens optional activities, without changing day, supplies, health, wages or RNG. Closing the activities window leaves the party camped; Continue departs. Rest has its own duration/confirmation inside camp. **Preserve meat** is now a camp activity rather than an inventory action; it advances the existing work-day rules and grants no rest-day recovery. Medical care remains accessible there; inventory is opened through the permanent Supplies ribbon button. Camping near a landmark retains the actual stop and its place opportunities.

**Supplies** opens the inventory directly. Drop supplies and Abandon wagon / Choose what to carry are top actions, before the explanatory inventory text. Dropping opens a separate permanent-discard list and spends no day. Abandonment retains the existing pack preview and confirmation; opening it does not abandon anything.


## Inventory and on-foot clarity

Supplies has a load meter and three readable ledgers: Food shows every category's food-value units and physical pounds, including staples; Gear shows quantities and weight; Transport groups wagon/pack capacity, retained oxen, retrieval limits and recovery. Slaughtering oxen, horses or mules for meat lives in the Livestock window with the other butchering. Household/personal gear includes recruited and departed travelers. The misleading perishable-only “tracked food” total is removed. Drop and abandonment remain above the ledger. The main ledger no longer contains the redundant Party/ribbon navigation hint and changes its heading when on foot.

Abandoning the wagon retains surviving oxen as before. A representative herd now follows the walking party; the ledger gives the exact count. Ox injury and wandering-ox events use on-foot wording, including saved pending events, without changing risks, costs or animal damage. Recovery reports distinguish an interrupted backtrack from locating or hitching the wagon; an overweight interruption does not falsely report “wagon found.” Acknowledging the pack-overload notice opens camp so the player can reach discard/preservation actions.

## Exact discard quantities

Drop Supplies now shows each supply, quantity held, total physical pounds and pounds per unit, with an editable whole-number quantity to drop. Food weights are marked as an average when batches differ; the live preview follows the actual earliest-expiring batches removed, so it predicts exact cargo loss rather than multiplying by that average. Confirm Drop Selected to commit all selected rows together, or close with X to leave inventory unchanged. Empty, invalid, fractional, over-stock and encounter-blocked requests cannot commit. No days or random rolls are spent. Camp no longer duplicates the Supplies button.
