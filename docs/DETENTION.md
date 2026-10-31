# Custody, court day and prison

When the party is caught or gives itself up, the sentence no longer comes at once. The accused are first held by whoever caught them. The kind of custodian decides where the case is heard and what the court can order. This is the first playable slice of [frontier detention research](FRONTIER_DETENTION_RESEARCH.md). Code: `simulation/detention.gd`, with sentences in `wanted_system.gd` `trial()`. Rules: the `detention` block of `data/crime_scenes.json`.

## Who holds the accused

| Captor | Custodian | Hearing | What the court can order |
|---|---|---|---|
| Missouri posse, or a capture at the Independence store (inside the posse's 5 guide miles) | Jackson County sheriff, brick county jail at Independence (built 1841) | 3 days | Theft: a fine of twice the value taken, at least $5. Any part the party cannot pay is served in the county jail at $1 a day, up to 30 days. Robbery or assault: the state penitentiary at Jefferson City, plus restitution. A killing: hanging. |
| Soldiers at Fort Kearny, or the Kearny pursuit detachment (only once the post exists, from June 1848) | Army guard | 2 days | Theft: paying back twice the value. Anything violent: sent east under escort to a civil court. Soldiers do not hang civilians. |
| Regulators, reward seekers, and captures at trading posts, ferries, toll gates, traders and emigrant camps | An emigrant company's own jury | Next day | The earlier frontier sentences: restitution, whipping for a captured leader, banishment of helpers, possible seizure of oxen or wagon, hanging for a killing. |

Laramie, Bridger, Hall and Boise remain private or HBC trading posts. None of them gains a court or a jail. Oregon City is the end of the road and has no custody case yet.

## Who is held

The party's acting leader answers for it, together with the companions recorded as taking part in the charged acts. Witnesses and bystanders are not held. Unpaid wages, trust and departures follow the existing systems.

## While they are held

The custody panel replaces all other actions. The party cannot travel or trade until the case is settled.

- **Wait for the hearing.** The rest of the party camps nearby. Each day costs ordinary meals, weather and illness, exactly like resting.
- **Ask a companion to speak for the accused.** Only once, only from a companion who did not take part and does not object to the act (robbery, or murder for violence). It lowers the conviction odds by 15 points.
- **Post bail (Missouri only, not for a killing).** Bail is at least $10 for theft, $100 for robbery and $150 for assault, or twice the value taken if that is more. The accused walk free and the party leaves Missouri, so the bail is forfeited. The case counts as answered: the posse does not come back for it, but the crime's notoriety stays.

At the hearing the custodian convicts with an authored chance: county 80%, army 90%, emigrant jury 85%. If nobody has named the party for certain (only unidentified reports), the chance is halved. A discharge frees the accused, costs nothing and also settles the charge.

## Prison and the end of the journey

The leader is the player. A leader sent to the penitentiary, sent east under escort, or hanged ends the journey, with its own loss reason. A companion sent away leaves the party alive. They take nothing from the wagon: no food, no spare clothing, only their personal gear. Their place in the party records says where they were sent. The rest of the party carries on.

Short stays are served on the spot: the days waiting for court, and county jail days for an unpaid fine (up to 30). The party waits in Independence until the leader is let out, and the days come off the season. Long terms (penitentiary, sent east, hanging) end the journey, as Spencer decided.

**Abandonment.** Each day the leader sits in custody, every companion who is not held has a chance to give up and leave: 2% a day at trust 50, scaled by (100 − trust) / 50, so full trust never leaves and low trust leaves fast. Loyal companions never leave. Those who go take their departure share like any companion who flees, and are recorded in the custody's `abandoned` list.

## Saves

Crime record **v10** adds a `custody` block (authority, days, accused, voucher, abandoned) to a held incident and four sentence fields: `authority`, `verdict`, `jail_days` and `imprisoned`. Version 9 sentences become emigrant-company convictions with no jail time, exactly as they were tried. Saved custody is checked: the hearing day must match its authority, the accused cannot be duplicated, and a voucher cannot be one of the accused. The previous rules fingerprint `bd9000a01c1cfd8482a0e2e345f43adccb0c5aefcccf30f09da3ec265084e2c2` is compatible through `economy_v1`.

## Historical limits

Hearing days, conviction odds, bail, fine and jail-day rates are game estimates, not a reconstruction of the 1845 Missouri code. The supported facts are the 1841 Jackson County jail, the 1836 Jefferson City penitentiary, Fort Kearny's mid-1848 start, and the 1834 act's limited military custody before removal to civil authority. See the research report for sources and open questions.

## Jailbreak

Added October 31, 2026. The guards and odds are authored game values, not historical events.

- **When it's offered:** the custody panel offers "Break them out" when at least one free companion would kill if it came to that and the party has a loaded gun. Free means not held, and the leader is always held.
- **What happens when you choose it:** custody ends as an escape, so the original crime is reported like any getaway. A new `assault` incident opens against the guards in a standoff:
  - County: the jailer and two deputies at `jail_county:<id>`.
  - Army: a sergeant and three soldiers at `jail_army:<id>`.
  - Emigrant company: three company guards at `jail_company:<id>`.
  - Council: the household's own living kin, at the household itself.
- **The fight:** it is always the tactical mini-game. The prisoners fight bare-handed, because their arms are held. The rescuers carry the party's remaining arms, and every guard fights, the jailer included.
- **Win:** everyone gets away and the prisoners take back their arms. The jailbreak is an assault, or a killing if a guard dies, with witnesses, reports and the usual Wanted consequences.
- **Lose or surrender:** the whole party is taken back into custody by the same authority. The court hears the jailbreak and the original crime.
- **Retreat:** like any standoff retreat, it rolls the guards' escape odds.
- **How it's recorded:** the broken custody is marked `custody.broken`. `Detention.broken_custody()` finds it as the incident just before the jailbreak.

## Next

- Later: Oregon City civil court, and dated militia cases.

## Verification

`tests/test_detention.gd` covers county custody and its save checks, bail, fines worked off in jail, discharge, vouching, the penitentiary for the leader and for a companion, the emigrant jury, the v9 upgrade and the graphical panel. `tests/test_wanted.gd` now passes through custody before every sentence, including the army sending a leader east.
