# Disease clocks, susceptibility and bandaging

This update corrects the three structural problems in the
[historical/modern audit](DISEASE_EVIDENCE_AUDIT.md). Rest and nursing still support
survival, but the audited illnesses do not disappear simply because more care kits
were used. There is no new income balance pass or economy change.

## Clinical courses and exposure

Smallpox, measles, pneumonia and wound infection now have `calendar_course:true`.
Each active day contributes exactly one recovery step, regardless of rest or care.
Direct care and companion nursing retain their existing health and severity
benefits, materials/fees, worker time and patient-rest constraints. They skip the
extra recovery-step bonus for these four conditions. No damage multiplier or new
severity roll was added to compensate for the longer course.

| Condition | Current active course | Incubation after party exposure |
|---|---:|---:|
| Smallpox | 21 days | 10-14 days |
| Measles | 10 days | 11-12 days |
| Pneumonia | 14 days | No uniform party-contagion rule |
| Wound infection | 10 days | Existing wound-complication pathway |

The durations are **coarse authored courses**, not guarantees of recovery; a
person may die before completing one. Smallpox's first four symptomatic days are
modeled as an early fever phase before close-contact spread. Measles may spread
from symptomatic onset. This approximates symptom/rash timing without adding a
full clinical simulator. The selected incubation bands represent typical courses,
not the entire observed clinical range.

Successful smallpox/measles transmission creates a saved latent exposure, not an
instant active illness. Incubating people have no associated disease damage,
contagion, revealed diagnosis or care-driven clock changes. At the stored onset
day, the disease and source enter their history; first damage begins on the next
tick. Repeated contacts cannot reset or duplicate an existing exposure. Opening
party details or loading a save does not reroll it. Random recognized illness can
still abstract an earlier unobserved exposure; it is not the same event as a known
new party contact.

The clinical basis remains the audit's
[CDC smallpox stages](https://www.cdc.gov/smallpox/hcp/clinical-signs/index.html),
[CDC measles course](https://www.cdc.gov/measles/hcp/communication-resources/clinical-diagnosis-fact-sheet.html)
and [NHS pneumonia overview](https://www.nhs.uk/conditions/pneumonia/). These support
correcting the previous2-5 day care-driven resolutions. They do not establish the
exact course, mortality or efficacy of care for a particular1848 traveler.

Legacy enteric-fever/exhaustion treatment progress, nutritional scurvy recovery,
illness weights, damage, severity odds and seasonal factors have not been broadly
recalibrated. The new incubation bands apply to smallpox/measles; older enteric
spread remains a simpler abstraction. Prior numerical evidence is preserved under
its earlier production rules.

## Susceptibility and wound risk

Disease eligibility now checks the specific disease, existing immunity and any
pending exposure. A broken arm, scurvy or another illness does not grant protection
from an unrelated infection. The same disease/exposure cannot duplicate itself.
The same per-condition rule applies to spontaneous onset and nutritional deficiency;
the existing one party-level spontaneous roll remains unchanged.

Open wounds retain their existing initial two-day complication delay, then remain
at risk **until the modeled wound heals**. The day7 cutoff is gone. Healed wounds
and closed fractures alone have no open-wound infection roll. Existing infection
cannot duplicate itself and may outlast its original wound. This follows the audit's
[UKHSA wound-pathway evidence](https://assets.publishing.service.gov.uk/media/68cab56405e625519a6c9ff1/UKHSA_Surgical_site_infection_leaflet_A4.pdf)
without importing modern surgical infection rates as frontier trauma statistics.

## Cleaning and bandaging

Bandaging is part of **supplied nursing and direct care**, using their existing
care kit or local care fee. There is no additional button, inventory commodity,
extra kit charge or guaranteed sterilization. The nursing target tooltip explains
that it includes wound cleaning and bandaging; actual treatment appears in the
traveler's history and journal. As before, an unsupplied nursing order cannot grant
protection or spend an imaginary kit.

The existing authored dressing modifier0.25 gives **75% lower infection risk for
the covered day**. Individual rest's0.5 modifier stacks with it: **87.5% lower
relative risk** than an untreated working day. With current base risk3.5%, these
are0.875% for dressing alone and0.4375% with rest. They are game settings, not
measured historical bandage efficacy. Daily protection expires and must be renewed
with actual care while the wound remains open. Nursing still supports an infected
patient; a bandage does not retroactively erase an established infection.

Current native previews: [smallpox](disease-clock-smallpox.png) and
[wound care](disease-clock-wound.png). The existing individual health categories
and scrollable details remain in use.

## Saves and proof

New latent exposure records are optional per-person data, validated for known
contagious disease, bounded exposure/onset dates, severity, source type, uniqueness,
active-case duplication and immunity. Main-roster and cached guard/outing paths
apply the same checks. Latent records mature through the same health model away
from the wagon and cannot be used for instant symptoms or indefinite pending clocks.

A genuine pre-correction save with active smallpox, a dressed wound and existing
measles immunity was captured before changing production rules:
`tests/fixtures/pre-disease-clock-save-v1.json`, fingerprint
`481d85555235440051c7fcae5512478a1a6ef942499d096860b96be2723f1bf8`.
Migration preserves its state, profiles, illness progress, dressing and immunity;
it fabricates no earlier exposures or restarts an existing patient's course.
Previously earned recovery progress remains, and future steps use the new rules.

The [post-correction evidence](disease-clock-proof-02.json) replays the original36
controlled course fixtures. Mild cases now finish in21/14/10 days across travel,
rest, nurse and caregiver modes. Serious smallpox/pneumonia cases can die on rest
alone in this fixture, while supplied nursing supports survival across the longer
course. Those deliberately selected severities are not a population mortality
sample. Injury and late-open-wound probes now produce the intended eligibility
and continued risk. This is targeted mechanism verification, not a journey balance
campaign.

`tests/disease_clock_probe.gd` produces immutable raw traces;
`tests/verify_disease_clock_proof.py` rechecks all36 cases, outcomes, publication,
source hashes and the archive under ignored`.tools/disease-clock-proof-archives/`.
Final evidence is version02, including the visible bandaging/history update.
Version01 is excluded development evidence. The old audit remains a record of
previous behavior and must be reproduced using its recorded old sources.

**Validation:** all100 Godot suites pass on the final bandaging/correction code.
The new calendar/exposure suite passes242 checks and the wound/bandaging suite42;
existing disease239, saves149, guard60, companion-task89 and UI checks pass.
Tests cover unchanged disease progress under care, latent onset/no early damage,
injury susceptibility/immunity, duplicate prevention, open/healed wound risk,
funded bandaging/history, malformed data, deterministic future save continuation,
cached records and the genuine legacy fixture. Native panels were inspected.

Full final log `.tools/disease-clock-full-tests-final.log`, SHA-256
`18e10c049012dbabae050fc60f2afb484d8605ba05e383df295d388a82d97e01`.
Final36-case replay `.tools/disease-clock-proof-02.log`; independent verifier
`tests/verify_disease_clock_proof.py` passes against the archived daily traces.
Earlier development failures and version01 traces are excluded.
