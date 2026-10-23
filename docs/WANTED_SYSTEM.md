# Wanted encounters and frontier sentences

Crimes can now catch up with the party after witnesses or former companions carry word along the road. This implements the [approved wanted-system plan](WANTED_SYSTEM_PLAN.md), with the historical and accounting qualifications below.

## Knowledge and pursuit

`simulation/wanted_system.gd` derives notoriety from arrived reports and departed companions' tales. Theft weighs 1, robbery/raid 2, attacks 4, military incidents 5, and reported butchering 3. Unidentified reports count half. Reports and tales about the same act count once. Experience never adds notoriety. Party details show **not known / talked about / wanted / notorious**; no new reputation meter is stored.

Three authored templates create persistent people when met: a Missouri posse, emigrant regulators, and reward seekers. The posse is deliberately restricted to the first **5 guide miles**, a conservative game boundary inside Missouri, and only answers local crimes. This corrects the plan's suggestion of extending a sheriff to the Big Blue, which is beyond Missouri. Regulators answer violent crimes. Reward seekers need an identified violent report or a robbery/raid worth at least $50, a posting at Laramie, Bridger, Hall or Boise, and time for that posting to reach the party. A crime gets one posting; rewards range from $50 to $500. Food in restitution/reward calculations uses the opening five-cent staple price, not a claim about a particular post's tariff.

Daily travel, camp rest, and landmark rest check for pursuers. Base chance is 0.018 per notoriety point, capped at 25%, then halved for each 20 quiet days. Encounters have a 10-day cooldown measured from their resolution. Lawful journeys consume no wanted-system random rolls. Fort Kearny's existing pursuit gains one day per four notoriety points, up to ten days. Only one crime encounter can be active. Already-tried charges cannot trigger the same punishment again; their historical notoriety remains. Payments to reward seekers settle their posting, not all outstanding accusations.

The later-pursuer panel offers surrender, flight, fighting, and a reward-plus-20% payoff for reward seekers only. Flight uses a day, team condition, pace and pursuer odds; a failed flight can wound the party before trial. Flight alone sends no new report. Fighting uses up to three real bullets and a normal day, can wound or kill people, and produces identified news only if witnesses survive an escape. Gunless parties can flee or surrender. Original crime scenes retain their existing escape and soldier-breakout choices.

## Capture and sentences

Original-scene captures, surrender and later pursuits now share trials. Existing saved terminal custody losses remain terminal; the migration does not revive a lost journey.

- Theft: double the stolen value, first cash and then held goods; trust losses.
- Robbery/raid or reported butchering: stolen value taken; a captured leader is wounded; recorded helpers may be banished.
- Nonfatal shooting or assault: restitution and helper banishment, with a chance of ox or wagon seizure.
- A known killing: hanging ends the journey. Killing a pursuer during the present fight counts even before its news has traveled.

Voluntary surrender avoids flogging. Punishment damage is capped nonfatally even with health traits; a resulting wound can still matter during later survival. Goods and cash cannot go negative. If the party cannot pay, available goods are confiscated, with no invented stock or cash. Seizure can leave the wagon without a team or leave the party on foot and overloaded, requiring ordinary camp/supply decisions. A seized wagon cannot be recovered. Banishment reuses immediate-departure supply accounting; it only applies to recorded participants, not every witness. Older incidents without participant detail conservatively do not invent guilty helpers. Older breakouts without per-incident death details do not retroactively invent a specific killing.

Every trial records its charges, date, surrender status, payment, goods, banished helpers, seizure, and summary in the incident and journal. The ordinary game screen shows the result before it is acknowledged. Crime record **v9** adds a `bounties` list; v8 upgrades to an empty list without altering prior evidence or random state. The previous rules fingerprint `7b11c6894279c30b4dfe0a8cb9333dee8bc16853aa02b4ec7c5ce04a24dd8e81` is compatible through `economy_v1`.

## Historical limits

This is authored frontier-justice gameplay, not a reconstruction of uniform sentencing law or measured pursuit rates. The handoff's broad statement that there was "no civil law west of the Missouri" must not be treated literally: Indigenous nations had their own laws, Oregon had a provisional government, and Oregon Territory was created in 1848. The game models the uneven access of this emigrant party to organized enforcement, not an absence of law or government.

- [National Park Service: Death and Danger on the Emigrant Trails](https://www.nps.gov/articles/000/death-on-trails.htm) distinguishes rare murders from the more common accidental gunshot deaths.
- [BLM: Emigrant Trails of Southern Idaho](https://www.blm.gov/sites/default/files/documents/files/Library_Idaho_CulturalResourceSeries01.pdf) discusses rapid emigrant justice and trials. Evidence from later overland years informs the regulator abstraction; it is not proof of these exact 1848 encounters.
- [Oregon State Archives chronology](https://sos.oregon.gov/blue-book/explore/Pages/chronology-1543-1850.aspx) documents provisional government and the 1848 territorial transition.
- [National Archives: United States and Western Territories, December 1848](https://www.archives.gov/legislative/features/nm-az-statehood/us-map.html) provides jurisdictional context.

Posting rewards at company posts and the precise reward, restitution, banishment, seizure and cooldown rules are transparent game estimates. Laramie and Bridger remain private trading posts, Hall and Boise HBC posts; none becomes an army garrison. Fort Kearny remains the route's army-pursuit source.

## Verification

`tests/test_wanted.gd` covers arrived and unidentified knowledge, deduplication, experience neutrality, lawful RNG stability, region gates, decay, reward posting/integrity, each encounter choice, trial rows, helper departure, low-health punishment, saved encounters/results, v8 migration, and the native UI path. `tests/outlaw_journeys.gd` records wanted encounter and sentence counts and uses its existing fight-then-surrender policy. Full-suite and clean-checkout journey results are recorded in the current handoff after validation. The existing survival campaigns are preserved; new journey output is integration evidence, not a completed balance campaign.
