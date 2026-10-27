# Infectious disease and wound complications

This increment adds **smallpox, pneumonia and wound infection** to the existing
individual health system. Measles was already implemented with contagion and
survivor immunity. No new health bar or separate disease minigame is introduced.

## Current inventory

The14 conditions are dysentery, cholera, typhoid fever, measles, mountain fever,
exhaustion, scurvy, smallpox, pneumonia, wound infection, broken arm, broken leg,
snakebite and wound. Cholera's existing1849 chronology restriction stays intact;
scurvy remains a nutritional deficiency, not a random or contagious illness.

- **Smallpox:** an uncommon possible share of the existing illness onset roll,
  available in1848, with party contagion and survivor immunity. It can be fatal
  through the ordinary individual health system. Base onset weight0.25,
  transmission chance0.06 per eligible contact/day, damage5 times severity and
  recovery18 steps. Rest and existing care can support recovery; no guaranteed cure.
- **Pneumonia:** a winter-weighted illness, damage5 times severity and recovery12
  steps. The syndrome has several causes, so this increment does not make every
  pneumonia case a generic person-to-person infection. Existing weather/exposure
  risk applies; cold weather is not represented as a pathogen itself.
- **Wound infection:** a separate possible complication of an existing open
  `wound`, never a spontaneous illness or consequence of every closed fracture.
  It adds its own condition, history, damage and potential death cause. It may
  persist after the original wound heals and does not spread to companions.

The party-level spontaneous onset probability remains0.03/day before existing
modifiers. New illnesses share that roll; they do not each get a separate daily
onset roll. Injury complications have their own conditional roll.

## Wound care

For an active open wound, days2-7 after injury are the authored risk window.
Base daily complication chance is0.035; individual rest multiplies it by0.5 and
actual wound care that day by0.25. New infection begins after the day's existing
condition damage, so a newly infected person does not take a hidden extra damage
charge immediately. Existing infection cannot duplicate itself; healed wounds,
absent/dead travelers and unrelated injuries do not trigger this complication.

Ordinary direct care and supplied companion nursing dress a wound. The existing
care action still costs its kit or local fee and calendar day; nursing still
requires a reserved worker, patient and real care kit. Nursing preparation dresses
the wound **before** that day's risk roll. An order without supplies grants no
protection. Protection expires with its recorded day, including after saving,
packing, leaving a guard or reuniting. Normal care also retains its previous health,
severity and recovery effects. Care kits abstract supportive supplies, not antibiotics.

Party details explain the risk and show infection as an additional condition.
Health history and the journal use the existing health-notice pipeline; fatal cases
record the actual disease/complication. Generated probabilities, damage, durations
and care modifiers are **authored game estimates**, not fitted1848 epidemiology,
clinical treatment advice or measured historical fatality rates.

## Historical basis and limits

The National Park Service's [Death and Danger on the Emigrant Trails](https://www.nps.gov/articles/000/death-on-trails.htm)
lists smallpox, pneumonia and measles among trail diseases, and describes gunshot
wounds and accidents. Its discussion covers1841-1869; it does not establish a
specific smallpox outbreak in every place on our1848 itinerary. The low smallpox
weight is a game choice, not a reconstructed annual incidence.

The NPS [Civil War medicine account](https://www.nps.gov/gett/learn/education/a-nation-at-war-traveling-trunk-table-5-the-medical-corps-at-war.htm)
describes severe difficulty treating infection without antibiotics. This is later
19th-century context, not proof of an exact1848 dressing procedure or prevention
rate. Modern germ theory, antibiotics and guaranteed sterilization are not silently
supplied to the party. Existing simplified care remains a gameplay abstraction.

Incubation stages, vaccination records, isolation orders, scarring, amputation and
hospital admission are outside this increment. Exposure is not assigned by a
traveler's culture, ethnicity or appearance. Earlier balance campaigns remain
archived evidence for their old production rules; they are not current-rule balance
claims. No new broad balance campaign was run for this feature.

## Saves and validation

A genuine pre-change save containing an active wound and prior measles immunity
was captured before changing the rules: `tests/fixtures/pre-infection-save-v1.json`,
fingerprint`12857a4f70d605d9fdb8d5541696d5661359cb4c950646ba55bb433ae41281fe`.
The migration preserves its existing state, health conditions, immunity and profiles.
New optional dressing metadata is integer/date/condition validated both in the
main roster and cached guard/outing records; it cannot grant indefinite future care.

Focused tests exercise real onset/progression, immunity, contagion, no immediate
infection damage, wound prerequisites/window, rest/care modifiers, complication
persistence and death causes, malformed rules, kit-funded and unfunded nursing,
direct care, exact saves, cached guards, and the genuine legacy fixture.
Native party panels were inspected at800x360: [wound/infection](wound-infection.png)
and [smallpox](smallpox-party.png).

**All99 Godot suites pass.** Final affected checks pass again after save-bound
validation refinements: health30, saves149, wagon guards60 and disease expansion41.
Full log `.tools/disease-expansion-full-tests-01.log`, SHA-256
`ce841d2d5e9fc20a75264aaf14ffaf7ed5d9d9929589d6b632bbafd9e545c16d`.
Final focused logs `.tools/disease-expansion-final-test_*.log`; final infection
log is `disease-expansion-final-test_infection-02.log`. Native preview log has no errors.
Earlier failed development checks are retained and excluded.
