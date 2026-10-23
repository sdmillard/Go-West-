# Trail action ribbon and preferences

The logical canvas is now 800 × 360. The original 640-pixel travel area and art retain their pixel sizes; the extra width holds a permanent right ribbon. Default window size is 1600 × 720 with integer scaling and nearest filtering. Smaller monitors fall back to 800 × 360. Full-screen remains letterboxed at integer scale.

| Ribbon | Actions |
| --- | --- |
| Map | Route overview, zoom, pan, wagon focus |
| Guide | Overland guide |
| Party | Individual health, relationships, wages, dismissal and vacancies |
| Travel | Pace and rations |
| Supplies | Cargo, preservation, packing, oxen; buy/trade |
| Camp & Care | Rest duration, medical care, emigrant camp |
| Hunt & Forage | Existing hunting outing or foraging preview |
| People & Places | Local conditions/activities; companion search |
| Villainy | Attack someone → Party member → named companion → attack options; local attacks, theft, robbery; handling the dead |
| History | Journal; memorial book |

Sections open compact trees rather than one long Options list. Opening a section pauses travel without spending a day. Existing costs and confirmation screens apply when an action is committed. Encounters, hunts and crossing reviews still gate services; these buttons do not bypass simulation rules. The ledger area shows current pace and rations even when the Travel section is closed. Continue and Camp remain convenient main-screen controls.

**Options** is now solely for preferences: full-screen, 1×/2× window size and automatic travel display speed (2.5, 1.25 or 0.75 seconds per day). Display speed changes the delay between simulated days, not distance, meals, disease probabilities or any other daily calculation. Preferences are stored separately in `user://preferences.cfg`; journey save format and rule fingerprints do not change. Old five-person and replacement-companion journeys use the same simulation.

No reference-game art was copied. This layout uses the existing original parchment/wood UI, bitmap font and pixel scenes. Native checks cover setup, main trail, each section, preferences and the existing route-map view at the expanded canvas.

Villainy uses nested Back navigation. **Attack someone** offers **Party member** and **Someone here**. The companion branch lists only active nonleader travelers, including recruits. Local attacks open the existing venue encounter (keeper, toll collector, ferryman or nearby traders); individual targeting of every supporting staff actor is not added by this UI change. Theft and robbery have separate preview branches. Opening or backing out of these trees commits no violence or crime. Saved venue previews reopen at their category chooser, with the authoritative encounter choices preserved. Party retains dismissal and wages without an attack button.
