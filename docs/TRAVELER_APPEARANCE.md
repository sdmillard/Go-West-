# Traveler appearance and personal background

October 23, 2026. Appearance is original pixel-art customization, independent of personality, occupation, wages, health, trust and attraction.

## Player controls and generation

In a companion's EDIT sheet choose **APPEARANCE & PERSONAL BACKGROUND**. Choose one of six skin palettes, five hair colors, six clothing palettes and two existing outfit silhouettes (coat/hat or dress/bonnet), with a live sprite preview. Heritage/upbringing is optional editable text, limited to64characters. The leader has a **LOOK** button next to their name. Choices persist through the store and the departure transaction.

Generate a Companion assigns these details through a separate seeded stream, preserving existing personality/name generation draws. Initial travelers have generated looks too. The heritage examples are descriptive starting points, not a historical census distribution or automatic assignment of skills, values, skin tone or names. All visual choices remain independently editable. Heritage-specific name pools and historical cultural encounters are future work.

NPS documents a much broader emigrant experience than a uniformly white party: [African Americans on the Oregon Trail](https://www.nps.gov/articles/000/african-americans-on-the-oregon-trail.htm) and its [research overview](https://www.nps.gov/oreg/learn/historyculture/research.htm) provide historical context. This cosmetic layer does not claim to simulate period racial laws or cultural experiences. Named Indigenous nations and other backgrounds can be entered as personal text; researched nation-specific generation/content has not been added.

## Rendering and persistence

Walking figures, walking/swimming river crossings, the visible hunter and View Party portraits use each current traveler's own palette. Death or departure does not shift another person's appearance into their place. Hunting retains its functional hunting-coat silhouette, with matching skin/hair/clothing colors; choosing a walking outfit is not a gender or orientation setting. Small hat/bonnet-covered sprites show hair only where exposed. Baked location paintings remain scenery, rather than personalized party portraits.

The Aseprite walker and hunter sources add a unique exposed-hair swatch. Runtime palette substitution works on copies of original sprite images and caches color variants. Alpha, outline and animation dimensions stay intact. Rebuild sources through the existing Aseprite pipeline. No proprietary art was used.

Appearance is stored in character profiles and validated on load. Older records without it retain unspecified identity and the original palette; they are not rerandomized. The previous master rules signature is accepted. The romance checkbox also now explicitly explains that friendship/rivalry changes are independent.

## Verification

Appearance checks cover deterministic generation and palette coverage, invalid fields/saves, exact save/load, legacy appearance, actual UI edits and generation, matching simulation outcomes under different looks, palette rendering in all four sprite sheets, unchanged source images/alpha/dimensions, cache reuse and active traveler identity mapping.
