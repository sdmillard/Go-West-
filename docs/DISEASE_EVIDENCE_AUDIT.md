# Historical and modern evidence audit: disease rules


**Historical checkpoint:** the subsequent [disease-clock corrections and bandaging](DISEASE_CLOCK_CORRECTIONS.md) update supersedes the original timing, susceptibility and wound-risk rules below.
Audited October27,2026 against production3a9db2c. **The disease catalog is broadly
defensible; the shared recovery and susceptibility rules need correction.** This
is an evidence/code audit with controlled diagnostics, not another journey balance
campaign. Production code, wages, prices and disease tuning remain unchanged.

## Findings that warrant a focused correction

### 1. Care shortens the biological course too much

Current `party_health.tick` advances every ordinary condition by two recovery
steps on a rest day instead of one. Nursing adds another two steps, or three for
a caregiver, and reduces severity before daily condition damage. When elapsed
steps reach the JSON threshold, the condition disappears; its contagion disappears
with it. There is no separate minimum calendar course or convalescent state.

A36-case controlled engine probe varied smallpox/pneumonia/measles, all three
severity levels, and four policies. For a well supplied patient starting at85
health, the **mild-case** results were:

| Condition | Travel exertion | Rest | Ordinary nurse | Caregiver nurse |
|---|---:|---:|---:|---:|
| Smallpox | 18 days | 9 days | 5 days | 4 days |
| Pneumonia | 12 days | 6 days | 3 days | 3 days |
| Measles | 10 days | 5 days | 3 days | 2 days |

These are actual engine calendar days until condition removal, not independently
sampled disease durations or measured journey results. Nursing also clears all
three chosen severity levels within the same respective short durations in this
fixture. That is not a population recovery/fatality estimate: severity was deliberately
selected, and food, other illness, weather and care availability were controlled.

CDC describes smallpox incubation followed by several clinical stages; its
[clinical account](https://www.cdc.gov/smallpox/hcp/clinical-signs/index.html) does
not support clearing the full illness after four days of nursing. The
[NHS pneumonia overview](https://www.nhs.uk/conditions/pneumonia/) gives a usual
modern recovery scale of2-4 weeks; improvement within days is not equivalent to
resolution, and modern treated outcomes cannot be transplanted to1848. CDC's
[measles course](https://www.cdc.gov/measles/hcp/communication-resources/clinical-diagnosis-fact-sheet.html)
includes roughly11-12 days before initial symptoms, then a later rash lasting
several days. A two-day nurse-driven resolution cannot stand in for that course.

There is also **no incubation after party exposure**: `_spread` immediately begins
the recipient's active condition, which becomes a source on a later tick.
Random symptomatic onset can abstract earlier unobserved exposure, but same-day
symptoms from a newly observed party transmission cannot. Contagion should follow
disease timing, not how many care kits have been used.

**Recommended bounded fix:** separate calendar illness progression/contagion from
rest and nursing benefits. Care can support health, reduce complications and aid
functional recovery without deleting a viral course in a few days. Add an
exposure-to-onset delay for direct party contagion. This does not require modern
antivirals, a hospital system or a new minigame. Choose coarse documented disease
phases; do not simply multiply damage to offset a longer clock.

### 2. Another injury grants unintended disease protection

Both ordinary illness onset and `_spread` require `member.conditions.is_empty()`.
A broken arm, scurvy, or another unrelated condition consequently prevents a person
from contracting smallpox or measles through those paths. This is an inherited
shared-system rule, not intentional protection supplied by the new disease data.

The diagnostic forced transmission probability to1 for clarity: a healthy contact
caught smallpox while the contact with a broken arm did not. No parameter tuning
can repair that eligibility gate. Being injured is not immunity; WHO describes
[measles susceptibility](https://www.who.int/news-room/fact-sheets/detail/measles)
in terms of lacking effective immunity, not lacking another injury.

**Recommended bounded fix:** check immunity and the same disease's presence
rather than requiring an empty condition list. Apply explicit complication rules
where appropriate. Test mixed injury/illness cases so a new illness is neither
blocked nor duplicated by accident. Do not introduce a new blanket mortality
penalty for every person with two conditions as a shortcut.

### 3. Infection risk ends at day7 even if the wound remains

The released wound model permits progression through12 ordinary steps, but
`infection_chance` becomes exactly zero on day8. An actual untreated wound in the
probe is still present on days8 and11 while its complication risk is zero. That is
a hard calendar immunity cliff, not simply a lower risk as healing proceeds.

[UKHSA wound monitoring guidance](https://assets.publishing.service.gov.uk/media/68cab56405e625519a6c9ff1/UKHSA_Surgical_site_infection_leaflet_A4.pdf)
describes infection appearing from2-3 days after surgery until the wound heals,
usually2-3 weeks, and occasionally later. This supports rejecting a universal
day7 guarantee. It is modern **surgical** evidence, not a rate estimate or exact
calendar model for every1848 gunshot, laceration or animal injury.

**Recommended bounded fix:** allow risk while the modeled wound remains open,
possibly declining with healing. Preserve the existing rest/real-care benefit,
one-infection limit, delayed first infection damage and truthful history. A closed
fracture alone should still not be treated as an open wound.

## What is supported, and what remains an abstraction

| Rule | Evidence assessment |
|---|---|
| Smallpox, measles and pneumonia can belong in a trail game | NPS lists them for emigrant trails across1841-1869. This does not establish a local1848 outbreak or daily incidence. |
| Smallpox spreads among close contacts | CDC supports it, including contaminated bedding/clothes. A daily0.06 trial is our abstraction, not the historical household attack rate. |
| Smallpox/measles survivor immunity lasts through a journey | Consistent with CDC descriptions of prolonged smallpox immunity and measles immunity after infection. |
| Smallpox vaccination is outside this increment | A scope omission, not historical absence: WHO documents vaccination long before1848. Party coverage and local supply are not established. |
| Pneumonia has multiple causes | CDC supports multiple causal germs. No universal pneumonia-to-pneumonia contagion roll is defensible as an abstraction; some underlying infections remain transmissible. |
| Winter weighting for pneumonia | A plausible coarse respiratory/exposure approximation, not proof that cold itself causes infection or that our monthly multipliers fit trail data. |
| Wounds can become infected and remain dangerous | Supported by wound-pathway evidence and later19th-century medical context. No blanket automatic infection of a closed fracture. |
| Wound infection does not use party contagion | A simplification: bacteria may be transferred by hands, instruments or dressings. It is not a claim that wound-associated organisms cannot be transmitted. |
| Cholera appears from1849 in this itinerary | Consistent with NPS's gold-rush trail epidemic context. It does not mean cholera first existed anywhere in1849. |
| All travelers start without recorded smallpox/measles protection | Not an established1848 population fact. Prior infection/vaccination history is presently unmodeled; do not infer universal historical susceptibility. |

[NPS trail context](https://www.nps.gov/articles/000/death-on-trails.htm),
[CDC smallpox spread](https://www.cdc.gov/smallpox/causes/index.html),
[CDC smallpox clinical course](https://www.cdc.gov/smallpox/hcp/clinical-signs/index.html),
[CDC measles history/immunity](https://www.cdc.gov/pinkbook/hcp/table-of-contents/chapter-13-measles.html),
[WHO vaccination history](https://www.who.int/news-room/spotlight/history-of-vaccination/history-of-smallpox-vaccination),
[CDC pneumonia causes](https://www.cdc.gov/pneumonia/about/),
[NPS cholera chronology](https://www.nps.gov/articles/000/cholera-a-trail-epidemic.htm).

## Numbers that are not established historical measurements

No source found here validates our0.03 party onset roll,0.25 smallpox selection
weight,6% daily contact roll,5/3 damage values,3.5% daily wound complication risk,
or50%/75% reductions from rest/dressing. These are explicitly authored settings.
A missing quantitative source is not by itself a reason to change every number.

The smallpox weight is a **relative draw weight**, not a0.25% incidence. Its actual
chance depends on other eligible diseases, region, month, nutrition, exposure and
susceptible party members. CDC's approximate60% historical unvaccinated household
attack rate is cumulative close-contact experience, not a6%-per-day measurement.
The approximate30% unvaccinated case fatality across smallpox forms is also not a
target for equally weighted severity fixtures or a fit for a particular healthy
party receiving perfect care.

Six independent3.5% untreated wound rolls yield about19.2% cumulative probability;
four independent rest-modified1.75% rolls yield about6.8%. These are arithmetic
illustrations, not observed frontier infection rates; healing and care change the
number of eligible rolls. Modern clean-surgery infection rates must not be used
as direct estimates for dirty frontier trauma without antibiotics. NPS's
[later period-care account](https://www.nps.gov/gett/learn/education/a-nation-at-war-traveling-trunk-table-5-the-medical-corps-at-war.htm)
provides qualitative context, not a measured1848 dressing efficacy.

## Reproduction and disposition

`tests/disease_evidence_probe.gd` is a diagnostic, not a regression test asserting
that these problems should persist. It uses the actual engine's daily tick, real
nurse assignments and real care-kit consumption. The course fixture has five
healthy85 travelers, May1848, steady pace, filling rations, ample supplies, clear
weather, and other onset/contagion/complication hazards disabled. It advances no
journey miles. Separate forced-transmission and ordinarily progressing wound
probes demonstrate the eligibility gate and risk cutoff.

[Compact evidence](disease-evidence-audit-01.json) includes every case, source/rule
hashes, the clinical source list, diagnostic probes and raw-trace SHA-256. Raw
version02 is archived under ignored`.tools/disease-evidence-archives/raw-01.json`;
version01 was an earlier development probe with a snapshot-only wound query and
is excluded from the published evidence. The final probe refuses overwrites.

**No production fixes are merged as part of this audit.** The next implementation
should address the three structural findings above, with focused tests. No fresh
broad journey balance pass, wage adjustment or new fatality target is recommended.

**Validation:** all99 regression suites pass. The36 diagnostic courses and two
focused behavior probes report zero simulation errors; the independent Python
verifier checks every published row against its archived daily trace and source
hashes. Tests passing confirms the released implementation, not medical realism.
Recheck locally with `tests/verify_disease_evidence.py` using the bundled Python
runtime. Full suite log `.tools/disease-evidence-full-tests-01.log`, SHA-256
`1bf471ea938ed07196c55b68e08407cba630567ef47a311ef37e025a7c55a8a8`.
Diagnostic log `.tools/disease-evidence-probe-02.log`; verification log
`.tools/disease-evidence-verification-final.log`.
