# Trail ribbon, place choices and window exits

The logical canvas is 800 × 360. The original 640-pixel travel area and art keep their pixel sizes; extra width holds a permanent right ribbon. The default window is 1600 × 720 with nearest filtering and integer scaling. Smaller displays fall back to 800 × 360.

| Ribbon | Actions |
| --- | --- |
| Map | Route overview, zoom, pan, wagon focus |
| Guide | Overland guide |
| Party | Health, relationships, wages, dismissal and vacancies |
| Travel | Pace and rations |
| Supplies | Cargo, preservation, packing and oxen |
| Camp & Care | Rest duration and medical care |
| Hunt & Forage | Hunting or foraging preview |
| Villainy | Attack someone, steal, rob, handling the dead |
| History | Journal and memorial book |

## Context belongs below the picture

The existing place/story area shows buttons only for opportunities present there: **Store**, **Talk to traders**, **Visit emigrant camp**, **Find companions** when a position is vacant, and **Local activities** at a stop. No permanent camp/trader/recruitment entry remains in the ribbon. The place choices disappear during unresolved encounters, hunts and crossing reviews. Visiting a panel is free; actual transactions, searches and activities retain their existing costs. Recruitment also recognizes nearby emigrant camps.

## Villainy tree

**Attack someone → Party member → named active traveler → attack options.** This includes recruits and excludes dead/departed travelers and the leader. Party no longer contains an attack button; dismissal remains separate.

**Attack someone → Someone here → named local → attack options.** The list comes from living staff at the current staffed venue, nearby passing traders and nearby emigrant camp. A stable cosmetic name and role identify each fictional actor; naming uses an independent RNG and makes no historical identity claim. Selecting a target never attacks automatically. Guns and unarmed attacks use existing costs and risks.

Committed incidents retain the actual target id. The chosen person receives the injury/death, produces their own remains and is removed from future lists if dead. Attacking a supporting worker does not seize the keeper's stock or waive the toll. Other staff can witness, resist and spread news as before. Saved previews validate the target's place and identity; returning to a preview never rerolls it. Theft and robbery have separate preview branches. Mandatory loot/escape/standoff stages still use the authoritative simulation choices.

## One exit convention

A small **X in the upper-right corner** closes dialogs and the map; Escape is the keyboard alternative. The X uses the existing bitmap-font glyph inside a 14-pixel hit area. Redundant OK/Back-to-trail footer exits are hidden. Explicit committing actions such as Rest, Slaughter, Leave Wagon and Leave This Stone remain visible; X cancels their confirmations. Nested trees have labeled parent links inside the menu, distinct from exiting the window. Closing a committed hunt returns its existing report; closing an active crime panel does not cancel or erase the incident.

## Actual Options

**Options** holds full-screen, 1×/2× window size and automatic-travel display speed (2.5, 1.25 or 0.75 seconds per simulated day). Display speed changes the delay between days, not distance, food, disease or other daily rules. Preferences live separately in `user://preferences.cfg`; no journey-rule fingerprint change is needed for the layout. Current pace/rations remain visible on the main ledger/control panel.

The UI reuses the original parchment/wood theme, bitmap font and pixel scenes. No reference-game artwork was copied. Native checks cover setup, trail, place choices, all ribbon sections, local targets, preferences and map.
