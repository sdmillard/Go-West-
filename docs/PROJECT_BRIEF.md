Here's a project brief you can give directly to Work. It explains which versions of The Oregon Trail we're using, what each contributes, how to research them, and how to combine everything into our own game.

# Oregon Trail-Inspired Game — Source Material & Development Brief

## 1. Project Overview

We are developing a new, original Oregon Trail-inspired survival game using **Godot 4 and GDScript**.

The objective is to reconstruct the core gameplay experience of the classic *Oregon Trail* games, particularly the 1985 and 1993 editions, while creating a modern, expandable architecture that supports original gameplay systems, custom events, unusual items, and procedurally appearing locations.

The project should initially function as a faithful historical pioneer-survival simulator. A separate optional mode will introduce extremely rare, absurd, and sometimes supernatural encounters, presented in exactly the same serious style as ordinary historical events.

**We are building a new implementation, not modifying or embedding the original commercial executable.**

## 2. Primary Sources of Inspiration

### A. The 1975/1978 BASIC Oregon Trail — Source-Code and Mathematical Reference

**Reference repository:**

[https://github.com/fortran-gaming/oregon-trail-1975](https://github.com/fortran-gaming/oregon-trail-1975)

**Additional historical source:**

*Creative Computing*, May–June 1978:

[https://archive.org/details/creativecomputing-1978-05](https://archive.org/details/creativecomputing-1978-05)

The early BASIC versions are valuable because their source code is publicly accessible for examination.

Use these sources to investigate:

- Travel calculations and distance progression.
- Supply purchasing and consumption.
- Hunting and ammunition mechanics.
- Random-event selection and probabilities.
- Illness, injuries, and resource losses.
- Weather and survival calculations.
- Game difficulty, decision-making, and scoring.

**Implementation approach:** Study the original algorithms, document their behavior, and independently implement appropriate mechanics in GDScript.

Do not assume the BASIC source is public domain simply because it is available online. Examine its provenance and licensing before reproducing code.

Importantly, the BASIC game is not the same as the 1985 game. It is a historical and mathematical reference, not necessarily the blueprint for every system.

### B. The Oregon Trail (1985) — Primary Gameplay and Simulation Reference

This is our **principal gameplay reference**.

We want to reconstruct the recognizable classic Oregon Trail experience.

Study and document:

- Player professions and starting resources.
- Party creation and member management.
- General store and supply purchases.
- Food rations and travel pace.
- Distance, geography, terrain, and weather.
- Disease, injuries, and mortality.
- Wagon maintenance and broken components.
- Hunting and food collection.
- River crossings and available strategies.
- Trading, resting, and forts.
- Historical landmarks and route progression.
- Random events and their consequences.
- Victory conditions and final scoring.
- Difficulty balancing and resource scarcity.

The goal is to reproduce the *behavior and feel* of these systems as accurately as practical, while writing our own implementation.

Where information is available, record original quantities, formulas, event frequencies, and probabilities.

Where it is not available, identify the uncertainty and use informed approximations. Do not present guessed values as verified original mechanics.

### C. The Oregon Trail for Windows 3.1 (1993) — Visual and Interface Reference

This is our **primary interface inspiration**.

Study:

- Mouse-driven menu design.
- Travel and landmark screens.
- Event presentation.
- Illustrated locations.
- Inventory and party status interfaces.
- General store and trading screens.
- Typography, layout, and visual hierarchy.
- Period-appropriate graphical aesthetics.
- How graphics and event text are combined.

We want the visual atmosphere of a 1990s educational computer game, using a modern game engine.

**Do not copy original copyrighted sprites, illustrations, audio, or interface artwork directly.**

Instead, create original pixel art and UI elements inspired by the era.

The resulting interface should feel historically authentic without being a pixel-for-pixel reproduction.

### D. Game Wikis, Manuals, and Historical Documentation — Secondary Research Sources

Use community-maintained game wikis, original manuals, gameplay guides, documented playthroughs, and development retrospectives to reconstruct mechanics not explicitly described in the BASIC source.

One especially useful source is designer R. Philip Bouchard's retrospective:

[https://www.philipbouchard.com/oregon-trail/imagining-design.html](https://www.philipbouchard.com/oregon-trail/imagining-design.html)

Research should include:

- Starting supplies and prices.
- Professions and difficulty modifiers.
- Geographic locations and travel distances.
- Available player decisions.
- Common events and their outcomes.
- Hunting and river-crossing mechanics.
- Disease mechanics and party survival.
- Travel pacing, scoring, and win/loss conditions.

Prioritize original documentation and firsthand development accounts when available. Treat wikis as secondary sources and verify disputed mechanics through gameplay testing where possible.

Maintain a research document identifying which game version each mechanic comes from.

Do not accidentally combine mechanics from different editions while claiming historical fidelity.

## 3. How the Sources Fit Together

| Source                   | Primary contribution                                                           |
| ------------------------ | ------------------------------------------------------------------------------ |
| 1975/1978 BASIC          | Historical algorithms, original rules, early event logic                       |
| 1985 edition             | Core gameplay and simulation design                                            |
| 1993 Windows edition     | Mouse-driven UI, visual presentation, illustrated encounters                   |
| Game wikis               | Reference values, event descriptions, mechanics inventories                    |
| Original manuals         | Intended rules and gameplay guidance                                           |
| Developer retrospectives | Design rationale and historical context                                        |
| Recorded gameplay        | Verification of actual behavior                                                |
| Historical sources       | Accurate geography, nineteenth-century travel conditions, supplies, and prices |

The objective is not to combine every mechanic indiscriminately.

**Use 1985 as the default gameplay baseline, 1993 as the presentation baseline, and the BASIC versions as an additional historical and algorithmic reference.**

Document any intentional differences from the originals.

## 4. Technical Architecture

**Engine:** Godot 4

**Primary language:** GDScript

**Initial platform:** Windows desktop

**Visual style:** Original retro pixel art, inspired by early-1990s educational games

**Content format:** JSON files for events, items, locations, and other moddable data

Separate the project into three major layers.

### A. Simulation Engine

Responsible for:

- Party and character state.
- Health, injuries, illness, and death.
- Resources and inventory.
- Travel distance, pace, and terrain.
- Weather and time progression.
- Hunting and food collection.
- Wagon condition and vehicle mechanics.
- Encounter probabilities.
- Route progression.
- Scoring and victory conditions.

The simulation should operate independently from the graphical interface to enable automated testing.

### B. Graphical Interface

Responsible for:

- Mouse-driven interaction.
- Menus and clickable choices.
- Travel animations.
- Pixel-art illustrations.
- Inventory and party status displays.
- Map and location screens.
- Event dialogue.
- Minigames where appropriate.

Avoid coupling gameplay calculations directly to UI elements.

### C. Data-Driven Content System

Events, items, and special locations should be definable through external data rather than hardcoded into the game's main logic.

Individual events should support:

- Unique identifiers.
- Event categories.
- Trigger conditions.
- Explicit probability and roll timing.
- Associated artwork.
- Dialogue and descriptive text.
- Player choices.
- Consequences and state changes.
- Dependencies on previous events.
- Unique or repeatable occurrence rules.

Provide a generic effect system that can modify supplies, party health, time, inventory, vehicles, and other game variables.

Unrecognized effect types should be validated and rejected instead of silently ignored.

## 5. Gameplay Modes

### Classic Mode

A historically grounded pioneer-survival game, modeled primarily on the 1985 edition.

No deliberately anachronistic or supernatural content.

The simulation should remain challenging and reasonably faithful to its reference.

### Unhinged Mode

The same underlying simulation, with additional rare events, chance locations, unusual items, and occasionally impossible phenomena.

Examples:

- Discovering an abandoned early-2000s economy sedan that can replace the wagon.
- Finding a mysterious energy sword.
- Encountering an elder god from outside reality.
- Discovering a contemporary restaurant in the nineteenth-century wilderness.
- Visiting an impossible structure that appears only on certain journeys.

These encounters should generally be rare and should not replace the survival game with nonstop comedy.

**The humor comes from presenting the impossible as something completely routine.**

The event interface should use the same typography, artwork conventions, and neutral narration as normal historical encounters.

## 6. Chance Locations and Special Items

Build an extensible location system.

Standard historical landmarks always appear according to the route design.

Optional chance locations are selected or generated according to explicit rules, potentially at the beginning of each journey.

Chance locations may offer:

- Trading.
- Rest.
- Supplies.
- Unique items.
- Optional encounters.
- Temporary or persistent modifiers.
- Branching events.

Special items and vehicles should interact with the simulation rather than merely appearing as text.

For example, replacing a wagon with a fictional sedan should affect travel speed, carrying capacity, fuel availability, breakdown risks, and river-crossing options.

This system can be expanded over time without restructuring the entire game.

## 7. Historical Fidelity and Intellectual Property

We are creating an independently implemented game inspired by historical game mechanics.

Follow these principles:

- Write original implementation code.
- Create original artwork and audio.
- Use historical facts and geography freely.
- Study original mechanics without assuming the original code is freely redistributable.
- Avoid copying protected game text, graphics, and distinctive presentation wholesale.
- Use original names and designs for fictional objects inspired by other franchises.
- Choose an independent public-facing title that avoids confusion with existing Oregon Trail trademarks.
- Record licenses and provenance for any third-party assets or code.
- Distinguish private experimentation from materials intended for public distribution.

An original energy sword or fictional economy car can convey the intended joke without directly using another company's protected character artwork or branding.

## 8. Development Priorities

### Milestone 1 — Research and Project Foundation

- Establish the Godot project structure.
- Study the BASIC source and relevant game documentation.
- Create a mechanics reference with source citations and edition labels.
- Define the initial game-state model.
- Establish event and item data schemas.

### Milestone 2 — Playable Survival Prototype

- Create a mouse-driven graphical interface.
- Implement wagon travel, distance, and time.
- Add basic inventory and resource consumption.
- Implement party health.
- Add ordinary random events.
- Create a basic win/loss loop.

### Milestone 3 — Classic Gameplay Systems

- Reconstruct route and landmark progression.
- Implement store and trading systems.
- Add illness and injuries.
- Implement wagon repairs and breakdowns.
- Add river crossings.
- Add hunting.
- Implement scoring and difficulty settings.

### Milestone 4 — Expandable Content

- Add event illustrations.
- Implement rare-event probabilities.
- Add chance locations.
- Implement special persistent items.
- Add alternative transportation.
- Validate content packs and support external modifications.

### Milestone 5 — Testing and Refinement

- Compare gameplay outcomes against documented reference behavior.
- Run automated simulations of many journeys.
- Test event probabilities and rarity.
- Identify softlocks and impossible survival states.
- Balance difficulty.
- Refine interface presentation and animation.

## 9. Initial Playable Target

Build a minimal playable vertical slice containing:

1. A party traveling west in a covered wagon.
2. Working time and distance progression.
3. Food consumption and a basic supply inventory.
4. A few historical events with consequences.
5. An illustrated event window with mouse-clickable choices.
6. At least one rare original absurd encounter implemented through the same event system.
7. Basic victory and failure conditions.
8. A classic/unhinged mode toggle.

Prioritize clean architecture and a runnable project over implementing every historical feature immediately.

## 10. Overall Design Philosophy

The project is fundamentally a historical survival simulator.

The unusual content is an extension of that simulation, not a replacement.

A player should be able to spend an entire journey dealing with ordinary frontier hardships and encounter nothing supernatural.

On another journey, they might discover an impossible building, obtain an inexplicable piece of advanced technology, or meet an ancient intelligence.

The game should treat all of these occurrences with complete seriousness.

**The end goal is an independently developed, historically inspired Oregon Trail-style game that faithfully captures the classic experience while supporting a large, modular library of rare and absurd additions.**

One thing I'd particularly emphasize to Work is keeping a mechanics research ledger: every important rule should be marked as verified from the BASIC source, documented from the 1985 edition, observed in 1993 gameplay, or newly designed by us.

That will prevent us from unintentionally inventing historical mechanics while believing we're faithfully recreating them—and will make it easier to decide where our own additions should begin.