# Companion assignments: implementation plan

Approved October 24, 2026. The first camp-day stage and the repair/stock-guard stage are built; see [behavior and current limits](COMPANION_CAMP_WORK.md). The remaining stages below are pending. This turns [the agreed design](COMPANION_TASKS_PLAN.md) into small, playable stages.

## Design target

Companions can share a real day's work. Do not add artificial penalties just to preserve difficulty caused by the current sequential whole-party actions. Limits should follow the situation: one person has one job, workers miss rest recovery, tools and supplies must exist, and food must arrive before it can be processed.

Ordinary cooking, water collection and routine animal care stay abstracted. Trading and Veteran remain passive. Hunting, Carpentry and Caregiving move to the relevant assigned work, without granting their old bonus twice.

## 1. A playable camp day

Build a shared day resolver in the simulation before adding separate task buttons. Snapshot workers, health, willingness, jobs and reserved inputs at the start of the day. Resolve costs and results in a fixed, documented order. Advance meals, wages, weather, spoilage and health exactly once.

Expose a camp roster with one standing assignment per companion: Rest, Forage, Dry meat or Nurse a named patient. Keep the leader's clicked action as their own work. Show expected resource use, eligibility and the loss of rest recovery before committing. Assignments persist through multi-day rest, with existing interruptions respected.

Use existing food, medicine and health systems. Reserve actual meat, salt and kits so two workers cannot spend the same inputs. Only morning stock can enter a full-day drying batch; an evening hunting return must wait. Keep small forage contributions together or retain fractional nutrition so dividing work among people does not round away all vitamin C.

Acceptance: a leader can hunt while one companion nurses and another dries an existing batch; resting companions recover, workers do not receive rest recovery, and nobody also contributes to the leader's hauling or passive care bonus. Compare the exact resources, health, time and random state before/after save-load.

Persist assignments with strict validation, character schema 4 and a genuine pre-change save fixture. Preserve old journeys with no assignments as an explicit compatible default.

## 2. Finish the camp roster (implemented)

Add wagon repair and stock guard. Keep repair progress when interrupted. Use the existing stock-theft and night-guard systems rather than rolling two independent defenses. Specify what ordinary workers can repair and what needs a Carpenter before exposing the choice.

Move each specialist benefit only when its replacement task is playable. Test low-trust refusal, illness, broken legs, deaths and departures; reassess eligibility each day and visibly explain an interrupted job. A companion resting as a patient cannot also work.

Deliver stages 1 and 2 as separate reviewed changes if the shared-day refactor is substantial. Each should leave a useful, playable game.

## 3. Away hunting and leaving camp

Add same-day foot hunts with actual ammunition, carried rations, clothing and gear. Spencer confirmed that leader and companion outings must use the same outfit and carrying calculation: only participating people and explicitly allocated animals contribute, with the same health, gear and supply costs. Merely owning a horse or leaving helpers in camp grants no hunting cargo. Apply this shared calculation to the leader minigame as well as delegated hunts. Reuse regional/seasonal hunting and the established retrieval limits. Count the outbound pack plus the catch against carrying capacity; the old whole-party hunt's yield is not a lone hunter's allowance.

Away people cannot defend camp, grant passive specialist benefits, haul for another action or receive wages remotely. Automatic wages must use the same eligibility gate as manual payment.

Before ordinary travel, automatic travel or a flight separates the group, show WAIT / LEAVE WITHOUT / BACK. Returning to an abandoned camp creates a stranded companion with real supplies, health and survival risks. Reuse the wagon-guard survival pattern while keeping its inventory and map marker distinct from an abandoned wagon. Eastward travel can retrieve them.

Acceptance: absent people remain saved and accounted for, no duplicate party slots or supplies appear, and departure warnings cannot be bypassed. Test empty returns, injury delays, a full camp inventory, retrieval, death and save-load at every stage.

## 4. Mounted work

Add one-to-three-day outrider hunts and scouting during travel. Reserve the selected horse or mule and its equipment; it cannot also carry the wagon party, join an escape or serve another worker. Apply existing country, load and animal-condition rules.

Resolve late returns and possible mounted catch-up through trust and temperament. Do not teleport people or animals across a river or route branch. Show expected return timing and explain delays when the traveler returns.

## 5. New backgrounds and crime hooks

Add Soldier for guarding/scouting, distinct from the Veteran special. Add Criminal for quiet theft, with the actual participant owning the crime, witness evidence and consequences. Use existing wanted and combat systems. Quote wages through the same background pricing system as other mercenaries.

Keep nighttime work distinct from full rest; decide its time/recovery accounting before exposing it. Do not build a separate crime simulator.

## 6. Measure the result

Update simulation policies to make assignments through the same public actions as players. Compare brief-stop, sustained-rest and risky travel policies across farmer/carpenter/banker parties, paid/free companions, foot travel and animal-supported travel. Record arrival date, survivors, food, vitamin C, ammunition, wages, refusals and time spent working versus recovering.

Previous journey logs suggest a possible farmer saving of roughly 5-10 days from overlapping non-hunting chores, or 13-26 including comparable hunting output. Those are 25-50 percent overlap scenarios, not new journey results or targets. A lone hunter's smaller haul, worker recovery and supply timing can change them. Affluent parties bought more food and had fewer such days to save.

Run development scenarios first, then freeze sources and validate on unused seeds. Include human checks of the camp roster and the hunting minigame. Judge whether decisions are understandable and useful, particularly on one-day stops; do not force every profession or strategy to the same outcome.
