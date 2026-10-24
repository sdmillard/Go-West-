# Horse balance pass (October 24, 2026)

This is step 5 of the horse travel plan: compare wagon, mounted, packing and walking journeys. Spencer's rule is that not every outfit has to be equally viable. It just must not be bullshit: no free wins, and no outfit that betrays what the player paid for.

The pass builds on the survival calibration merged in PRs #82 and #83 (see [TOTAL_SURVIVAL_BALANCE.md](TOTAL_SURVIVAL_BALANCE.md) and [HISTORY_AND_MOUNT_BALANCE.md](HISTORY_AND_MOUNT_BALANCE.md)). It uses that work's `tests/mount_balance_campaign.gd`, with salt-preserving hunters, April and May departures, carpenter and banker, and development seeds 75000 to 75005. That gives 12 journeys per row. It does not use the declared held-out seeds.

```
godot --headless --path . --script tests/mount_balance_campaign.gd -- --label=<new> --seed-start=75000 --seeds=6 --modes=mounted --months=4,5 --strategies=salt --professions=carpenter,banker
```

## On the rules from #83

| Outfit | Profession | Arrived | Median days | Miles per moving day | Rest days | Hunts |
|---|---|---|---|---|---|---|
| wagon | carpenter | 12/12 | 204 | 13.4 | 19 | 4 |
| wagon | banker | 12/12 | 204 | 13.4 | 18 | 2 |
| mounted | carpenter | 2/12 | 288 | 18.4 | 16 | 55 |
| mounted | banker | 11/12 | 242 | 17.3 | 43 | 31 |
| packing | carpenter | 0/12 | | 13.6 | 41 | 73 |
| packing | banker | 5/12 | 358 | 13.3 | 63 | 67 |

**The bullshit:** a banker who pays about $200 more for horses than for a wagon arrives five weeks later. The horses rest on almost a fifth of all days, because sagebrush, high country and forest forage all add wear on top of load and pace, while camp recovery is capped by the season.

## Changes

- **Lower forage strain** (`mounts.forage_strain`): sagebrush 2 → 1, highcountry 1 → 0, forest 1 → 0. Horses still take sagebrush harder than oxen. The #83 load, pace, winter and seasonal-recovery rules are unchanged.
- **Mules thrive on poor forage.** An all-mule string takes no forage strain, which fits their reputation on the Oregon and California trails.
- **Load drag for animals starts later.** In the daily distance, drag for packing, mounted and doubled-up parties now starts at 75% of capacity instead of 50%. People carrying their own packs still slow down at half load. The wear threshold `light_work_load` (0.5) is unchanged.
- **Journal fix:** walkers lighten "the packs", not the wagon.

## After

| Outfit | Profession | Arrived | Median days | Miles per moving day | Rest days | Hunts |
|---|---|---|---|---|---|---|
| mounted | carpenter | 4/12 | 234 | 19.2 | 10 | 56 |
| mounted | banker | 12/12 | 183 | 18.8 | 22 | 16 |
| packing | carpenter | 5/12 | 299 | 13.6 | 23 | 62 |
| packing | banker | 9/12 | 311 | 13.4 | 33 | 55 |

The wagon rows are unchanged, because none of these rules touch a wagon party.

## Reading it

- **Mounted is the fast, expensive choice again.** A banker on horseback now arrives in a median 183 days, against 204 by wagon, and every seed made it. Horses cost more, carry a third of the food, and leave the party buying food at western prices.
- **Mounted is a trap for poorer families, and an honest one.** A carpenter who spends most of the purse on horses hunts constantly and usually starves. The outfitter shows the cash left before departure. Horses were a rich man's road.
- **Packing is lean and hungry, not broken.** It costs less than a wagon and has nothing to break, but it carries little and moves at about a wagon's pace. Most well-funded packers arrive, late; poorer ones often don't.
- **Walking from Independence with no animals stays unviable by design**, as #83 found: five people carry about four days' food. No 1848 family went west that way, and a couple of pack mules turn it into packing.

The long overall journeys (a well-funded wagon takes about 204 days, against a historical four to six months) come from the survival model and policy caution, not from horses. #83 lists them as open: scurvy, shop and care delays, and reserve policy.
