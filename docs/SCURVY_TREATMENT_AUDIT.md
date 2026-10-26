# Why scurvy can linger

October 26, 2026. This is a diagnostic replay, not a new survival comparison or a change to health rules.

## What the game currently does

Scurvy requires 14 recovery steps. A sufficiently nutritious working day adds one, a resting day two; nursing can separately advance condition recovery. A day without enough vitamin-C food leaves accumulated progress intact but adds none. Adequate produce stops scurvy's own damage that day. Other illness, exhaustion and starvation can still damage the same person. Missing produce resumes scurvy damage at its existing severity.

The current food threshold is a shared 0.5 fresh-equivalent lb per active traveler. Fresh produce has four fresh-equivalent pounds per food unit/basket. Dried produce retains only 25% of that vitamin value, so one dried basket supplies one fresh-equivalent pound. **Five travelers consume three dried baskets to meet one day's threshold.** Twenty starting dried baskets therefore cover six complete five-person treatment days, with two baskets remaining. They are not twenty treatment days. Actual party size, other greens and meals can change that arithmetic.

Shop stock is finite: base post maximum eight baskets, road traders four, camps three, with availability rolls. A small roadside purchase can therefore be only a day or two of treatment. These are authored game assumptions, not verified vitamin assays or historical stock records.

The model is also binary: a shared serving below the threshold does not advance recovery for anyone. For example, two fresh-equivalent pounds for five people receive no scurvy-recovery credit despite being consumed. Recovery is not literally stuck, but this creates a harsh cutoff. There is no per-patient produce allocation or nutrient-store simulation. Do not interpret the threshold as a real medical requirement.

## Eight exact journey replays

Daily read-only records follow all four standard-May planning65 confirmation seeds 525000–525003, both no-stock and two-goat arms. They capture actual meal vitamin value, required threshold, stored produce, loose camp greens, each member's deficiency gap and scurvy progress before/after each actual day.

Every previously recorded journey field matches the published mastery result exactly. No resources, decisions, outcomes or random draws changed. Six of the eight journeys have no active main-party scurvy days in these traces. Two explain the persistent cases:

- No-stock seed 525002: the leader develops scurvy on day 178 with 89 health. Across 28 later days with active scurvy, only **two** supply adequate vitamin-C food. Recovery reaches just 2/14 before death on day 206. The party eventually reaches Oregon with three originals; completion does not mean the patient recovered.
- Goat seed 525000: one member develops scurvy on day 227 and another on day 252. Across 42 days with at least one active patient, only **one** meets the shared treatment threshold. This journey is lost. Those are calendar days with a patient, not a count of distinct patient-days or proof scurvy alone caused the loss.

The first case has no stored produce through the onset/treatment window. Foraging sometimes supplies loose greens, but most days supply none and a one-pound shared serving is insufficient for its four-person party. Adequate greens on days 179 and 182 advance recovery; subsequent untreated days leave it paused. Later produce purchases on days 257/260 occur long after the patient's death.

Across these eight replays, there are no days with stored produce before settlement and zero vitamin value served. This narrow check finds no evidence of carried produce being silently ignored; it does not exhaust all saves, detached actors, parties or food mixtures. The full-party threshold, partial intake, route supply gaps and drying-retention assumption remain design/calibration concerns.

## Evidence and limits

NIH describes vitamin-C deficiency developing after sustained low intake, with timing influenced by body stores. That supports treating deficiency over time, rather than making one shared food-weight cutoff a physiological law. [NIH vitamin C fact sheet](https://ods.od.nih.gov/factsheets/VitaminC-HealthProfessional/).

Clinical treatment can improve functions within days while symptoms take longer; this broadly supports recovery taking time, but does not validate the game's basket sizes, retention factor, daily damage or rest multiplier. [Merck professional reference](https://www.merckmanuals.com/professional/nutritional-disorders/vitamin-deficiency-dependency-and-toxicity/vitamin-c-deficiency?media=print). These sources inform game design, not player treatment advice.

The next change should make treatment coverage and progress visible, then evaluate gradual/per-person nutrient coverage and realistic produce preservation. Merely shortening the timer would leave the underlying supply and all-or-nothing problems. Do not infer that the 25% dried-produce value has been scientifically validated by this audit.

## Reproduction

[Compact results](scurvy-trace-summary-01.json). Test-only observer/campaign `tests/scurvy_trace_observer.gd` and `tests/scurvy_trace_campaign.gd`; verifier `tests/summarize_scurvy_trace.py`. Raw local reports `.tools/hunting-scurvy-trace-standard-{none,goats}-01.json`, separate hash-checked copies `.tools/scurvy-trace-archives/`. Eight replays are not eight new independent survival trials.

The verifier checks complete cohorts, raw logs, every previously published journey field, daily continuity, source fingerprints and byte-equivalent normalized simulation/data against merged master03c2b4b. All88 Godot suites pass, including14 state/RNG neutrality and treatment trace checks. Full log `.tools/scurvy-audit-full-tests.log`. Rules and simulation remain unchanged.

Run the trace campaign with the same standard farmer/shared-horse/foot/mobile/support-work/support-fishing/aware-stock/fodder settings as mastery planning65, seeds525000–525003, May, 65% aim, separately no-stock and goats; use the labels above and four seeds. Existing output paths are protected from overwrite. After full tests, run `python -B tests/summarize_scurvy_trace.py`.
