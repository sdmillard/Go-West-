# Feature handoff: crimes against Native people and local justice

Research completed October 27, 2026. **Feature implementation has not started.** This handoff combines the current code audit, verified historical context, remaining evidence gaps and a proposed implementation sequence. Read [frontier detention research](FRONTIER_DETENTION_RESEARCH.md) and [the existing community contacts](NATIVE_CONTACTS.md) alongside it.

## User direction and scope

The player should be able to commit crimes against Native people as against other people. Native victims must be able to resist, survive with injuries, identify an offender, seek recovery of losses, refuse dealings and spread what they know. Responses should follow the actual people, relationships, place and available authorities. A household does not represent its entire nation, and paying for property must not buy away an assault or killing.

The user first authorized research and implementation, then steered this pass to **finish the research and leave a feature handoff**. No Native victims, crime scenes, claim ledgers, court profiles or sentencing changes were installed in this pass. Do not mistake the design below for approved historical punishment tables or completed mechanics.

This connects to the earlier request for short custody and an opportunity to intervene. Custody before a hearing/transfer and imprisonment as a sentence remain separate. Formal authority/venue routing must precede applying sentences to new Native-victim cases.

## Research findings

### Indigenous government and local authority

The Nez Perce Tribe's own history describes self-government, leaders with differing responsibilities and councils. CTUIR's history describes regional political/family/trade relationships and regulation of trade by local leaders. These sources support people who can make and enforce decisions; they do not establish one universal 1848 criminal court or identify every trader as a chief or judge.

Shoshone and Bannock communities are distinct, as are Wasco and neighboring Sahaptin-speaking communities. A language label is not itself a government. The later confederations, reservations, police departments and contemporary court structures must not be projected into 1848. In particular, the modern Nez Perce Peacemaker Code found during research is a contemporary document, not an 1848 sentencing manual.

**Verified historical context is not a verified punishment schedule.** No source consulted establishes exact 1848 customary penalties, a homicide price, a standard prison term or a universal reconciliation procedure for the seven visits. Treat each initial household response as original fictional behavior, with formal community adjudication gated on further specific evidence.

### U.S. legal routes existed, with important limits

The original 1834 Trade and Intercourse Act, sections 16, 18 and 22, provides evidence for compensation after specified convictions, witness/deposition procedures for covered claims, and a property-title rule involving prior possession. It includes restrictive political-status and retaliation provisos. The text is not proof of equal protection or effective enforcement. Its compensation rule cannot be turned into an automatic private shop fine or a payment that erases homicide.

Sections 23–25 distinguish certain military apprehensions/removal to civil authority from criminal jurisdiction, with an exception for offenses between Indigenous people. See the detention report for the limited five-day pre-removal rule. The 1847 amendment's witness-competence provision concerns specified prosecutions, not a blanket rule for every 1848 court.

**Design implication:** preserve Native victims' evidence and distinguish local claims, any community authority and an applicable U.S. process. Do not assign federal jurisdiction from a contact's skin tone, heritage dropdown or a generic “Native” faction. Do not import present-day jurisdiction rules as 1848 law. A recognized court and its legal basis must be explicit before conviction or sentence.

## What exists in this checkout

Seven persistent fictional contacts are defined in `data/native_encounters.json` and `simulation/native_contact_story.gd`. Their current memory concerns work, bargains, introductions and guides; it is not a criminal record. The Native contacts are **not currently crime targets**.

| Visit | Current contact | Existing goods/services that must remain authoritative |
|---|---|---|
| Platte | Pawnee provision keeper | Two 40-unit preserved-food parcels; one salt exchange; household terms |
| Fort Hall | Northern Shoshone provision trader | Two 40-unit food parcels; one work/barter chain; separate from the HBC post store |
| Grande Ronde | Nez Perce horse owner | The existing four-horse sale herd; shared `herders:grande_ronde` stock and agreed coin price |
| Umatilla | Umatilla garden keeper | Two 40-unit food parcels and two four-basket fresh-produce parcels; seasonal in-kind wages draw from the same fresh stock |
| The Dalles | Wasco provision seller | Two 40-unit food parcels and two four-basket dried-produce parcels; one work/introduction chain |
| Deschutes | River pilot | Day guide or limited agreement; no listed household food store or automatic ownership of all crossing facilities |
| Cascades | Upper Chinookan load organizer | Paid portage and one-use labor credit; no listed food store, free ferry or free wagon |

These quantities are existing authored gameplay, not historically measured household wealth. A crime implementation must not clone the HBC/settlement store at the same location or generate an extra herd, wagon or 200-unit food pile for every contact. Define any cash, weapons, personal valuables or additional inventory explicitly as authored stock; research has not supplied historical purses.

The working tree also contains tactical combat code and a `tests/test_tactical_combat.gd` runner entry. Preserve those changes. The relevant interfaces now include `crime_system.begin_tactical_shoot()`, `build_tactical_config()`, `apply_tactical_result()`, and the main UI's tactical window. This research pass did not author those files. Inspect the current combat implementation before connecting new targets; do not work from an older handoff that assumes no combat scene exists.

## Code audit: integration points and traps

### Persistent people and targets

- `simulation/crime_system.gd`: `local_places()`, `local_targets()`, `display_name()`, `actor_id()`, `staff_ids()`, `owner_id()` and persistent `record.actors`/`record.services` already support local people and injuries/deaths.
- Fixed venue ids are often assumed to be route node ids. `staffed()`, `place_label()`, `where()` and `mile()` need a proper venue-to-route mapping if Native household ids are distinct from the landmark. Do not reuse `fort_hall` for both the Native household and the HBC store.
- Existing templates represent passing traders, emigrants or pursuers. Labeling a Native household as one of these just to pass validation risks inheriting the wrong inventory, identities, rhythm and authority. Prefer a validated household venue type or explicit adapter.
- Keep the existing contact identity when it becomes a victim. Use stable ids and the authored contact label; do not replace it with a fresh generic first name or invent a supposedly authentic name/title. Additional relatives/co-workers are fictional individuals, not the whole community.
- `add_venues()` can add fixed venues to older crime snapshots, but must preserve existing deaths, injuries, incidents, actors and stock. Do not reset people on re-entry or after save/load.

### Goods and money

- `simulation/robbery_demand.gd`: `STOCKED`, `stock()`, `theft_stock()`, `quote()`, `take()` and `valid()` currently recognize stores, forts, traders and emigrants. New household support needs its own finite-stock adapter.
- Robbery's current goods enumeration does not include fresh/dried produce. Either extend the typed food-batch transfer properly or explicitly limit the first slice's selectable loot; do not silently turn perishable produce into free shelf-stable food.
- Food bought, bartered or paid as work wages must reduce stealable stock; stolen food must reduce later offers. Individual horses must use the existing herd count and animal-condition machinery. Returning an animal must not heal it or create a replacement.
- `crime_system.valid()` has strict food/cash totals and venue shapes. A new settlement payment cannot simply be added to a cashbox while leaving the old invariant unchanged. Track compensation separately or explicitly validate its flow.
- `save_store.gd` currently restores/validates crime before Native contacts. Cross-ledger validation must run after both are available, or restore the necessary inputs earlier. Do not compare a saved household against an empty newly initialized contact record.

### Witnesses, refusal and news

- Existing crime records distinguish observed facts, identified reports, delayed arrival and departed companions' tales. Reuse these mechanisms; an unseen act must not instantly identify the party to every household.
- A death/wound must be committed through both the normal crime path and the tactical-result path. Deaths cannot report later events or continue providing work, guides, discounts or introductions. Surviving witnesses/relatives may still make a complaint.
- `crime_system.refuses()` reacts to arrived identified reports and tales. Scope local grievance resolution carefully: paying one victim does not erase other reports, but the same settled property claim must not permanently block that victim from accepting an explicitly agreed settlement.
- Family/co-worker follow-up needs an actual link and a channel of knowledge. No automatic all-nation hostility or instant information sharing. Other people may respond to news they actually receive; that is not a racial faction penalty.

### Capture and adjudication

- `crime_system.result()` sends captures/surrenders to `Wanted.trial()`.
- `wanted_system.trial()` currently uses a broadly shared severity table, including automatic leader hanging for a known killing. Its sentence validator enforces that mapping. Adding a Native victim type without changing routing would silently assign the same unsupported process to them.
- **Do not use that universal trial as a stand-in for Native justice.** Do not paper over the issue by automatically killing the accused, imposing invented tribal punishments, or ending the whole party's journey merely because a formal venue has not yet been modeled.
- Accused individuals, grounds/evidence, captor, authority, hearing, custody, referral, verdict and sentence need separate representation. An allegation is not a conviction; an assault is not merely a missing-property balance. Preserve the earlier detention plan's individual custody and successor-leader requirements.

## Proposed first playable slice

1. **Victim/venue adapter.** Add the seven existing contacts and any explicitly authored adult household members to Villainy > Attack someone > Someone here, and to appropriate theft/robbery choices. Make eligibility local to a real visit. Do not make every passing Native person a representative of a nation or an unlimited stock source.
2. **Immediate consequences.** Use the existing weapon, health, assistance, resistance, witness and escape mechanics, including unarmed attacks and tactical combat. Odds depend on these causal factors, not ethnicity. Injury/death and knowledge persist.
3. **Contact-service integration.** Known harms can suspend that household's dealings. A dead pilot cannot honor a guide contract; a dead/hostile crew cannot be bypassed for free portage; a dead horse owner cannot generate a fresh herd. The normal river/route choices must remain coherent without inventing seizure of unrelated services. Old positive work standing must not override violence.
4. **Persistent property claims.** Derive or record actual losses and tie each claim to specific incident/victim ids. An available surviving claimant may accept a voluntary return or an authored offer of compensation. Show exactly what the offer repairs. Refusal, insufficient goods/cash, partial return and multiple claimants need explicit behavior. Do not label an author's private settlement terms as statutory Native law.
5. **Separate violence/public accountability.** Property repair must not restore dead actors, wipe assault/homicide records, settle unrelated victims or erase public complaints. Local acceptance is not government acquittal. A documented, applicable U.S. claim route and a particular community's response are separate layers; neither guarantees a conviction or a prompt remedy.
6. **Coordinate detention work.** Implement authority/venue routing from the earlier report before enabling a capture path that purports to adjudicate these offenses. A guarded hearing/referral should preserve uncertainty and the actual accused identities. Detailed community adjudication, long sentences and incarceration remain evidence-gated. Do not manufacture a generic “tribal jail” for all seven visits.

For the MVP, a household's own grievance and a formal criminal case should be independent statuses. Property repair can resolve the former while a violent/public case remains open. Give a private settlement its own receipt; do not reuse a `tried` sentence or a bounty payoff merely to mark it paid. Arresting a companion must depend on their participation and known evidence, not a Criminal background or the party's appearance.

## Save/data proposal and acceptance checks

This is a suggested contract, not implemented schema:

- Stable `venue_id`, actual route/mile position, `victim_ids`, `incident_ids` and `accused_ids`.
- Observed facts and identification provenance; no future knowledge or dead witnesses.
- Property-loss ledger with item quantities/value basis, returns, cash received and outstanding balance. Receipts refer to exact claims. Keep local agreement, public complaint and legal disposition separate.
- Authority/venue profile and confidence/date rules for any review/referral. Store custody deadlines and party knowledge separately when custody is implemented.
- Migration preserves all existing Native contact memory and crime records, without invented victimization, forgiveness or resurrection. Add rule fingerprints to the explicit migration allowlist when data changes.

Required functional cases:

1. All seven existing contacts appear at the correct location; no off-route attack, duplicated contact or HBC-store substitution.
2. Gun and unarmed attacks reach the real actor; both tactical and ordinary outcomes persist through save/re-entry.
3. Theft/robbery cannot take more than the actual remaining food, produce, horses, purse or valuables; work/trade/robbery share stock.
4. No dead contact continues a guide agreement, work offer or introduction. Surviving individuals retain their own identities.
5. Unseen theft does not produce omniscient hostility. Identified surviving witnesses and informed companions can carry news with actual delays.
6. Resistance/escape can wound or kill party members under ordinary mechanics; ethnicity changes no combat statistic.
7. A declined or unaffordable offer transfers nothing. Repeated load/re-entry cannot collect or refund compensation twice.
8. Returning property/cash repairs only the named property claim. Assault/death, unrelated victims and public records survive.
9. No unsupported court, universal hanging, automatic whole-party guilt or collective hostility is introduced as a shortcut.
10. Older saved contact bargains, finite stock, deaths, prior sentences and tactical integrations remain valid.

Run the relevant local-target, crime, robbery-demand, wanted, Native encounter/contact, food/animal and tactical suites, then the repository's complete `./test.ps1`. Capture the actual Villainy target list and claim UI. All proposed rates, private offers, defender counts and purses should be documented as authored estimates; named customary punishments require a further source.

## Source ledger: what each source establishes

- [1834 Trade and Intercourse Act, original scan](https://www.govinfo.gov/content/pkg/STATUTE-4/pdf/STATUTE-4-Pg729.pdf), printed pp731–733 / digital pp2–4, sections 16–18,22–25. Establishes specified U.S. claims/procedural routes and limits. It neither proves equal enforcement nor supplies the seven communities' customary law. Do not turn its political qualifier into the game's contact-trust score or ignore the restrictions while advertising guaranteed compensation.
- [1847 amendment, original scan](https://www.govinfo.gov/content/pkg/STATUTE-9/pdf/STATUTE-9-Pg203.pdf), section2. A specific federal conviction/witness provision; not a universal witness or court rule for every charge.
- [Nez Perce Tribe: history](https://nezperce.org/about/history/). First-party account of self-government, differing leadership roles and councils. No 1848 criminal penalty table is supplied.
- [CTUIR: brief history](https://ctuir.org/about/brief-history-of-ctuir/), Internal affairs and early trade sections. First-party context for local leaders, kin/trade relations and regulation of trade. It covers changing circumstances across years and distinct peoples, not one all-purpose1848 tribunal.
- [Shoshone-Bannock Tribes: history](https://www.sbtribes.com/about/). Distinct Northern Shoshone/Bannock communities and later 1868 reservation context. No verified 1848 jail, police department or punishment tariff.
- [Confederated Tribes of Warm Springs: history](https://warmsprings-nsn.gov/history/). Distinguishes Wasco and Sahaptin-speaking communities and later reservation changes. Does not establish a generic “Sahaptin nation” or shared court.
- [Pawnee Nation: history](https://pawneenation.org/pawnee-history/) and [Nebraska's Pawnee historical marker](https://history.nebraska.gov/marker-monday-pawnee/). Homeland/community context. No researched 1848 offense schedule or blood-payment tariff was established in this pass.
- [Modern Nez Perce Peacemaker document](https://www.nezperce.org/wp-content/uploads/2018/08/Final-NPTPeacemaker-Code-rcvd-from-Peggy-on-August-20-2018.pdf): reviewed to identify an anachronism. Its modern court structure/provisions are NOT evidence of 1848 practice. A customary-law source from another nation or a much later period cannot fill gaps automatically.

Further research is needed before naming particular 1848 community adjudicators, procedures, penalties or detention sites, and before a detailed federal/state referral map. It is not needed to pretend Native victims lack agency while that work proceeds: persistent people, resistance, observed complaints and clearly authored individual dealings can be implemented without inventing a universal legal system.

## Work completed and remaining

Completed: source review and limits; audit of target/stock/witness/refusal/capture/save/tactical integration; this handoff. **No Native-victim feature patch or feature tests were created.** The current tactical files are existing worktree changes to preserve, not work credited to this research pass. The broad historical detention findings remain in the companion report; do not treat a passing software baseline as proof of historical sentencing accuracy.

Validation on October 27: the full `./test.ps1` baseline completed with exit 0 (107 suites), including tactical combat (83 checks), Native encounters, local contact stories (65 checks) and remaining contacts (42 checks). Log: `.tools/native-justice-research-baseline.log` (local, not source material to commit). This is a baseline check of the existing checkout, not a test of the unimplemented feature. Documentation whitespace check passes. Repository-wide `git diff --check` flags existing extra EOF blank lines in `simulation/crime_system.gd`, `simulation/trail_engine.gd` and `ui/main.gd`; these unrelated runtime edits were preserved.
