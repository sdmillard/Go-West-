# Returning along the trail and guarding the wagon

The Travel menu now offers Turn East / Turn West. Turning itself changes neither position nor supplies; moving back spends ordinary calendar days, meals, weather exposure and encounter risk. The geographic road retains its valid westward graph coordinates while heading controls movement. East retraces the branch actually taken. Red roads on the map retain the journey's visited extent.

A river stop remembers the direction of approach. Continuing across requires a crossing; turning away before crossing does not. Returning after crossing requires another real crossing and produces the same supply/injury history. Existing crossing pictures and animations are reused with the camera facing the destination bank; no additional art is needed. Upstream travel on the Columbia rafting branch is unavailable: a downstream raft is not an upstream road. This first return-travel slice does not invent an upstream portage route.

Continue east from Independence to leave the expedition peacefully. The end screen says **Your character decided to go back east.** It is separate from reaching Oregon or dying, and can be saved.

## Wagons and places

An abandoned wagon has exact road/branch coordinates and a last-known amber map marker. CACHE on the map pans to that marker. Travel stops at its position; Supplies offers **Inspect Wagon Here** when physically present. The old remote backtrack button is removed. The old simulation recovery method remains only for existing regression harness compatibility.

Stores offer a walking party one empty replacement wagon per post, with oxen bought separately. Returning to Independence now exposes its general store. Finite stock, staffing, hostility, money and existing counter rules still apply. Buying does not create a team, food, household equipment or a second salable wagon. A replacement wagon can return to the old cache and collect its contents; the game supports one active vehicle and one cache, not a wagon fleet.

The **$75 base price** is a period-informed game estimate with existing regional markups. The [End of the Oregon Trail museum's broad outfitting compilation](https://historicoregoncity.org/2019/04/03/outfitting-for-the-journey/) lists a $70 covered wagon; the [National Park Service's emigrant-trail overview](https://home.nps.gov/articles/000/traveling-emigrant-trails.htm) discusses roughly $85 wagons and additional covering costs. These are broad comparisons, not a verified May 1848 price at each fort. One wagon per store and the Independence shop staff are authored opportunities, not reconstructed shop inventories or named historical people.

## Companions left behind

Before leaving a wagon, choose zero to four living companions as guards; the leader must travel. The packing preview removes their hauling capacity and traveling personal gear. Choose carried food, clothing, bullets and other goods; the remainder stays in the wagon. Guard slots remain reserved until their fate is learned, preventing duplicate recruits.

Each real elapsed day advances the offscreen camp with its own saved random stream:
- Cached perishable food spoils before meals. Guards eat only cached food, at the ration setting in force when assigned.
- Clothing and the camp's season/region affect winter exposure; ordinary individual illnesses, injury recovery, hunger and vitamin-C deficiency apply. Nutrition histories remain separate after reunion.
- If food falls below three days and cached bullets and healthy hauling capacity remain, guards attempt one abstract regional hunt, spending one actual bullet. Availability, authored hit chance, season, existing species yields, food conversion and health/broken-leg hauling apply. An outing can return empty. Meat spoils normally; guards do not automatically preserve, forage, butcher oxen or consume human remains.
- Guard health and ammunition reduce cache-loss risk, with a nonzero floor. The existing unattended cumulative loss curve is converted into conditional increments on a separate stream. Deaths, hunger and broken trust can leave the wagon unguarded. A successful raid can injure or kill guards; survivors can flee with bounded cached supplies.
- Paid contracts continue while their guard is alive and assigned. Missed wages still affect trust. Wages cannot be paid remotely; settle before separation and after reunion.

Away roster entries show last-known health, not a live report. Return in person to reveal the dated camp log, remaining supplies, survivors, departures and deaths. Surviving guards rejoin; unknown deaths/departures release slots on discovery. Remains are placed at the actual camp, or marked lost with a ruined cache. Household gear is conserved across splitting, walking, replacement purchases and reunion. A dead traveling group still loses the expedition; remote guards do not automatically become a new player party.

Camp hunting, winter exposure, departure odds and protection are authored abstractions, not historical mortality estimates. Loss may happen despite guards. The map remains last-known information, never a guarantee of recoverable goods.

## Party creation and compatibility

**Generate Party** generates all four companions together using the existing seeded character generator. It preserves the leader, profession, date and supply cart and resets previous pair bonds; individuals remain editable.

Old journeys default westward. Optional heading, road history, cache coordinates and guard records are validated. Historical crime/remains locations may lie west of the returning party. Both previously published produce and bandit rule signatures migrate as full-route economy updates, preserving inventory and position.

Tests cover actual reversal and repeated crossings, chosen-branch retracing, toll retreat, eastward ending, save round trips, finite counter purchases, hidden guard outcomes, separate food/ammo, failed and successful hunts, health-based carrying, slot reservation, cache loss and exact gear conservation. The existing forward survival campaign predates these additions; targeted tests and forward integration regressions do not establish human difficulty or optimal return-trip strategy.
