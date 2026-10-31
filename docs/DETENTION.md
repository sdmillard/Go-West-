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

County jail days for an unpaid fine are served on the spot. The party waits in Independence until the term is over, and the days come off the season.

## Saves

Crime record **v10** adds a `custody` block to a held incident and four sentence fields: `authority`, `verdict`, `jail_days` and `imprisoned`. Version 9 sentences become emigrant-company convictions with no jail time, exactly as they were tried. Saved custody is checked: the hearing day must match its authority, the accused cannot be duplicated, and a voucher cannot be one of the accused. The previous rules fingerprint `bd9000a01c1cfd8482a0e2e345f43adccb0c5aefcccf30f09da3ec265084e2c2` is compatible through `economy_v1`.

## Historical limits

Hearing days, conviction odds, bail, fine and jail-day rates are game estimates, not a reconstruction of the 1845 Missouri code. The supported facts are the 1841 Jackson County jail, the 1836 Jefferson City penitentiary, Fort Kearny's mid-1848 start, and the 1834 act's limited military custody before removal to civil authority. See the research report for sources and open questions.

## Next

- **Jailbreak:** a prison break played as a tactical fight. Any fight opens the tactical mini-game.
- **Leader death ends the journey,** as agreed with Spencer, in its own change.
- Later: Native justice (docs/NATIVE_JUSTICE_HANDOFF.md), Oregon City civil court, and dated militia cases.

## Verification

`tests/test_detention.gd` covers county custody and its save checks, bail, fines worked off in jail, discharge, vouching, the penitentiary for the leader and for a companion, the emigrant jury, the v9 upgrade and the graphical panel. `tests/test_wanted.gd` now passes through custody before every sentence, including the army sending a leader east.
