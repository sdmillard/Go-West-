# Companion hunting follow-up shots

Companions now get up to the leader's configured five shots during each hunting day, bounded by their packed ammunition and actual carrying room. They can shoot again after a miss while the animal remains in sight. A successful animal is removed; it cannot be harvested twice. No extra day or extra daily meal is charged per shot.

An independent local instance of the existing leader hunting model supplies the same empty-day chance, weighted species and one-to-three animals. The existing return-search fraction removes opportunities on the final return day; earlier days remain unaffected. It does not manufacture a new animal for every bullet. Existing companion hit/skill/season modifiers remain. A miss has an authored35% escape chance; otherwise another shot at the animal is possible within the daily budget. These are game abstractions, not measured historical rates.

Empty encounters or time-limited searches use no bullets. Actual hits and misses cost one each. The hunter stops at the daily cap, exhausted ammunition, no visible animals, or less than2lb usable room. Existing physical meat conversion, meals, spoilage, health, encounters, return time and stock wear remain. Returns and the journal report actual animals, shots and hauled meat. The outfitting screen explains the daily shot ceiling.

The private encounter plan is deterministic and does not change leader/trip RNG when previewed. Shots continue to consume the saved private stream during actual hunting. No new persistent schema is needed. A genuine active three-day save from rules3b9a07...34fc6 is whitelisted using the existing compatible-save mechanism; its ammunition, trip and RNG survive loading unchanged. New decisions begin on subsequent days.

Focused tests cover a miss followed by a hit, daily resets, depleted ammo, escaped and killed targets, empty searches, cargo limits, exact mixed-batch audit mass and genuine old-save preservation. The earlier return-time test now checks retained encounter opportunities and bounded shot costs, rather than assuming exactly one bullet on every day.

Re-run the frozen mobile-camp matrix on new development/held-out seeds165000-165003 and175000-175003, same unchanged serial/parallel/mobile strategies and shared equipment, to measure the combined survival and ammo consequences. Keep previous sources/cohorts separate. Full tests and24 store +20 current-policy outlaw integrations are required. No food prices, starting cash, health/carrying curves or bot strategy are changed to make this rule win.
