# Tactical combat

An isometric, turn-based rifle fight on a 12×10 grid. Spencer's rule (2026-10-31): **if you fight, you play the fight.** Choosing to fight with bullets in hand always opens the grid, and there is no quick-odds shortcut. Non-fighting choices (pay, flee, go around) are unchanged.

## When it opens

- **Trail events:** bandits (Defend the wagon), riders (Defend / Circle and guard), Cayuse riders (Stand your ground) and horse thieves (Ride after the thieves). Friendly riders never start a fight.
- **Villainy:** the Shoot and Breakout commands, resisted robberies, and "Fight out the skirmish" during an escape or standoff with living staff present.
- It needs at least one bullet, except when riding after horse thieves: a party out of balls still fights, with clubbed rifles. A standoff's own Breakout choice opens the fight, so no duplicate button appears there. Headless study policies and tests still settle fights by the old odds in `simulation/combat.gd` and `simulation/crime_system.gd`, so balance studies do not measure grid play.

## Rules (data/tactical_combat.json)

- Initiative order with 8/6/5 action points by health. Moving costs 1 AP per tile (2 with a broken leg).
- Snap shot 4 AP, called shot 6 AP (torso, legs, arms or head), reload 5 AP (6 with a broken arm), clubbed rifle 3 AP when adjacent.
- Each shot uses one ball from the party's real stock. Base hit 78%, with modifiers for range, point blank, half cover, wounds and soldiers.
- Hits deal real damage and can wound, break a leg or arm, or kill. Results sync back to party health when the fight ends.
- Venue maps: trading post, fort, ferry, toll gate, roadside camp and emigrant halt. Roadside fights use the roadside camp map, or the emigrant halt map when circling wagons.

## Stun and death saves

Modeled on Cyberpunk 2020's stun/shock and death saves, at Spencer's request ("if you get clipped in real life that's crazy"). Values are in `saves` in the rules file.

- Every fighter has a **Body** save of 6 (soldiers 7). That means a 60% chance to stay up after a light hit, getting progressively harder the more injured you are.
- **Combat experience** (Spencer's addition) raises the party's Body save: +1 after one won roadside fight and +2 after three, plus +1 for a traveler with the Veteran special. The most it can reach is 9. Opponents keep 6 or 7. The selected traveler's current save is shown in the inspector as SAVE.
- Wound penalty by health: light 75+ (0), serious 50–74 (−1), critical 25–49 (−2), mortal under 25 (−3, and −1 more for each further 5 health lost).
- **Stun/shock save:** every hit that does not kill rolls a d10. If the roll is at or under Body minus the wound penalty, the fighter stays up. Otherwise they drop senseless. A senseless fighter is alive but out of the fight and cannot be targeted. At the start of each of their turns they roll again to come round, and getting up spends that turn.
- **Death save:** a mortally wounded fighter rolls a d10 at the start of each of their turns, needing Body minus their mortal level (0 at 20–24 health, 1 at 15–19, and so on). One failure and they die of their wounds. Death saves stop when the fight ends; afterwards the ordinary wound, infection and nursing rules take over.
- Knocking the last opponent senseless wins the fight without killing him. Falling back drags senseless companions along, exposed to the same parting fire. If every gun hand left standing is down or senseless, the fight is lost.

## Ending a fight

- **Victory:** every opponent is down or yielded. Trail events apply the choice's normal result (recovered horses included). Crimes continue to the loot or escape stage.
- **Retreat:** units leave from the gold chevrons at the south-west edge. Units still in the open draw parting fire. Retreating costs at least what the event's own flee choice costs (the day and the team strain). A pulled-back crime shootout rolls the scene's normal escape or breakout capture odds; it is never a guaranteed escape.
- **Surrender** (crimes) goes to trial. **Defeat** means every gun hand is down.
- A journey cannot be saved while a fight is open. Loading a save made before the fight starts the event fresh.

## Lethality

Spencer reviewed this on 2026-10-31 and kept it as built. In a 200-fight study per event, a scripted player that deploys behind cover and moves to cover won every fight. A traveler was killed in about 40% of bandit and Cayuse fights and about 10% of horse-thief fights. Someone was hurt in every fight. A player who stands in the open loses someone in most bandit fights. For comparison, the old odds (still used by headless studies) were a 25–30% chance of one wound. Choosing to fight is a real risk; paying, fleeing and going around remain the safe options.

## Historical notes

- Fort Kearny's 1848 garrison was a volunteer battalion living in sod buildings and tents. The fort map has no stockade, and the Mounted Riflemen are not shown, because they arrived in 1849.
- Opponent names and roles are fictional.

## Practice

`play-combat-prototype.cmd` opens an isolated practice fight. Tests: `tests/test_tactical_combat.gd`.
