extends SceneTree

const Simulation = preload("res://simulation/trail_engine.gd")
const TacticalCombat = preload("res://simulation/tactical_combat.gd")
const SaveStore = preload("res://simulation/save_store.gd")
const Main = preload("res://ui/main.tscn")

var failures := 0
var checks := 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)


func _initialize() -> void:
	await process_frame
	_test_pure_tactical_model()
	_test_wounds_and_infection_integration()
	_test_crime_and_save_validation()
	_test_roadside_and_wanted_encounters()
	_test_bug_regressions()
	await _test_ui_integration()
	print("Tactical combat: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_pure_tactical_model() -> void:
	var tc := TacticalCombat.new()
	check(not tc.rules.is_empty(), "Tactical combat rules load from data/tactical_combat.json")
	for kind in ["store", "fort", "ferry", "toll", "traders", "emigrants"]:
		var s := tc.start_session({
			"seed": 184801,
			"venue_kind": kind,
			"place_name": "Test " + kind,
			"bullets": 10,
			"squad": [
				{"id": "0", "name": "SPENCER", "health": 90},
				{"id": "1", "name": "SAM", "health": 55},
				{"id": "2", "name": "JO", "health": 30},
			],
			"enemies": [
				{"uid": "keeper:test", "name": "Keeper", "role": "owner", "health": 100},
				{"uid": "clerk:test", "name": "Clerk", "role": "clerk", "health": 100},
			],
		})
		check(bool(s.get("active", false)), "Session starts active for venue: " + kind)
		var u0 := tc.get_unit(s, "0")
		var u1 := tc.get_unit(s, "1")
		var u2 := tc.get_unit(s, "2")
		check(int(u0.get("max_ap", 0)) == 8, "Healthy traveler gets 8 AP")
		check(int(u1.get("max_ap", 0)) == 6, "Worn traveler gets 6 AP")
		check(int(u2.get("max_ap", 0)) == 5, "Critical traveler gets 5 AP")

	# Test movement, LoS, Cover, Called Shots, and Muzzleloader Reload cycle.
	var session := tc.start_session({
		"seed": 42,
		"venue_kind": "store",
		"place_name": "Fort Bridger",
		"bullets": 4,
		"squad": [
			{"id": "0", "name": "SPENCER", "health": 100},
			{"id": "1", "name": "SAM", "health": 100},
		],
		"enemies": [
			{"uid": "keeper:fort_bridger", "name": "Bridger · trader", "role": "owner", "health": 100},
		],
	})
	var p0 := tc.get_unit(session, "0")
	var e0 := tc.get_unit(session, "keeper:fort_bridger")
	check(not bool(session.get("started", true)), "Session starts in pre-combat deployment phase")
	check(session.get("initiative_order", []).size() == 3, "Initiative order includes all combatants")
	tc.step(session, {"type": "place", "unit_id": "0", "x": 3, "y": 7})
	check(int(p0.get("x", 0)) == 3 and int(p0.get("y", 0)) == 7, "Player can place units in deployment zone before combat starts")

	# Place p0 and e0 in clear range to test exact shot mechanics.
	p0["x"] = 5
	p0["y"] = 5
	e0["x"] = 5
	e0["y"] = 2

	# Store counter is at (5, 3) -> directly in front of e0 at (5, 2) from shooter at (5, 6),
	# or if e0 is at (5, 2) and counter is at (5, 3), step from e0 toward p0 is (5, 3) which is Half Cover!
	var cov := tc.target_cover_from(session, 5, 5, 5, 2)
	check(bool(cov.get("in_cover", false)), "Defender behind store counter receives directional cover")

	var snap_prev := tc.shot_preview(session, "0", "keeper:fort_bridger", "snap", "torso")
	var legs_prev := tc.shot_preview(session, "0", "keeper:fort_bridger", "called", "legs")
	var arms_prev := tc.shot_preview(session, "0", "keeper:fort_bridger", "called", "arms")
	var head_prev := tc.shot_preview(session, "0", "keeper:fort_bridger", "called", "head")
	check(bool(snap_prev.get("can_shoot", false)), "Loaded rifle with 8 AP can fire Snap Shot")
	check(int(snap_prev.get("ap_cost", 0)) == 4, "Snap Shot costs 4 AP")
	check(int(legs_prev.get("ap_cost", 0)) == 6, "Called Shot costs 6 AP")
	check(float(head_prev.get("hit_chance", 1.0)) < float(snap_prev.get("hit_chance", 0.0)), "Head Called Shot has lower hit chance than center-mass")
	check(float(legs_prev.get("hit_chance", 1.0)) < float(snap_prev.get("hit_chance", 0.0)), "Legs Called Shot has accuracy penalty")

	# Move e0 into the open at (5, 4) for guaranteed high accuracy and test Called Shot to Legs.
	e0["x"] = 5
	e0["y"] = 4
	tc.rng.seed = 1
	tc.step(session, {"type": "shoot", "unit_id": "0", "target_id": "keeper:fort_bridger", "mode": "called", "body_part": "legs"})
	check(not bool(p0.get("loaded", true)), "Firing single-shot muzzleloader leaves rifle unloaded")
	check(int(p0.get("ap", 0)) == 2, "Called Shot deducts 6 AP from 8 AP")
	check(int(session.get("bullets_left", 0)) == 3, "Firing consumes 1 lead ball from party supply")
	var after_shot := tc.shot_preview(session, "0", "keeper:fort_bridger", "snap", "torso")
	check(not bool(after_shot.get("can_shoot", true)), "Unloaded muzzleloader cannot fire again before reloading")

	# End turn advances to the next person in the initiative counter, and wrapping the counter advances the round and refreshes p0's AP.
	var guard := 0
	while (String(session.get("active_unit_id", "")) != "0" or guard == 0) and guard < 5:
		guard += 1
		tc.step(session, {"type": "end_turn"})
	check(int(session.get("round", 0)) >= 2, "Wrapping the initiative order advances to Round 2")
	check(int(p0.get("ap", 0)) == 8, "Player AP refreshes when their turn comes back around in initiative")
	tc.step(session, {"type": "reload", "unit_id": "0"})
	check(bool(p0.get("loaded", false)), "Reload action rams ball and seats cap")
	check(int(p0.get("ap", 0)) == 3, "Reload costs 5 AP (leaving 3 AP)")
	# Verify that reloading while adjacent to cover returns resting pose to 'crouch' (cover stance)
	p0["x"] = 5
	p0["y"] = 4
	p0["loaded"] = false
	p0["ap"] = 8
	tc.step(session, {"type": "reload", "unit_id": "0"})
	check(String(p0.get("pose", "")) == "crouch", "Reloading behind cover returns resting stance to crouch")

	# Clubbed rifle stock at adjacent tile costs 3 AP and uses 0 bullets.
	p0["x"] = 5
	p0["y"] = 5
	e0["x"] = 5
	e0["y"] = 4
	var bullets_before_club := int(session.get("bullets_left", 0))
	tc.step(session, {"type": "shoot", "unit_id": "0", "target_id": "keeper:fort_bridger", "mode": "club"})
	check(int(session.get("bullets_left", 0)) == bullets_before_club, "Clubbed rifle strike consumes no powder or ball")


func _test_wounds_and_infection_integration() -> void:
	var game := Simulation.new(1848, "classic", true)
	game.depart("carpenter", ["SPENCER", "SAM", "JO", "LOU", "PAT"], 5, {"oxen": 4, "food": 400, "clothing": 5, "bullet_boxes": 2, "medicine": 3})
	for i in range(game.characters.profiles.size()):
		game.characters.profiles[i]["morality"] = "ruthless"
	game.route_path = game.route.main_path_to("fort_bridger")
	game.state.merge({"day": 40, "landmark": "fort_bridger", "next_landmark": "fort_bridger", "miles": 989, "leg_length": 0, "leg_miles": 0}, true)
	game._arrive_landmark(true, false)
	game.open_crime()
	check(game.start_tactical_combat("shoot"), "start_tactical_combat('shoot') initializes session at Fort Bridger")

	# Simulate player unit 0 taking a gunshot wound and broken arm during the fight, and winning.
	var s: Dictionary = game.tactical_session
	var u0: Dictionary = game.tactical.get_unit(s, "0")
	u0["health"] = 62
	u0["wound"] = true
	u0["wound_severity"] = 2
	u0["wounds_taken"] = 1
	u0["broken_arm"] = true
	u0["new_broken_arm"] = true

	for u in s.get("units", []):
		if String(u.get("team", "")) == "enemy":
			u["health"] = 0
	s["shots_fired"] = 2
	s["bullets_left"] = int(s.get("bullets_start", 40)) - 2
	s["resolved"] = true
	s["active"] = false
	s["outcome"] = "victory"

	check(game.finish_tactical_combat(), "finish_tactical_combat settles combat into simulation")
	var leader: Dictionary = game.party_health.members[0]
	check(int(leader.health) == 62, "Leader health reflects gunshot damage taken in tactical combat")
	check(leader.conditions.any(func(c): return c.id == "wound"), "Gunshot hit in tactical combat creates real 'wound' condition in party_health")
	check(leader.conditions.any(func(c): return c.id == "broken_arm"), "Arm hit in tactical combat creates 'broken_arm' condition in party_health")

	# Verify post-combat wound infection risk and wound dressing!
	var wound_day := int(game.state.day)
	var min_days := int(game.party_health.wound_infection.get("min_days", 1))
	var check_day := wound_day + min_days
	var undressed_risk: float = game.party_health.infection_chance(0, check_day, false)
	check(undressed_risk > 0.0, "Post-combat gunshot wound carries daily wound_infection chance")
	check(game.party_health.dress_wound(0, check_day), "Gunshot wound can be cleaned/dressed with dress_wound()")
	var dressed_risk: float = game.party_health.infection_chance(0, check_day, false)
	check(dressed_risk < undressed_risk, "Dressing a gunshot wound reduces wound_infection chance")


func _test_crime_and_save_validation() -> void:
	var game := Simulation.new(1848, "classic", true)
	game.depart("carpenter", ["SPENCER", "SAM", "JO", "LOU", "PAT"], 5, {"oxen": 4, "food": 400, "clothing": 5, "bullet_boxes": 2, "medicine": 2})
	for i in range(game.characters.profiles.size()):
		game.characters.profiles[i]["morality"] = "ruthless"
	game.route_path = game.route.main_path_to("fort_laramie")
	game.state.merge({"day": 35, "landmark": "fort_laramie", "next_landmark": "fort_laramie", "miles": 640, "leg_length": 0, "leg_miles": 0}, true)
	game._arrive_landmark(true, false)
	game.open_crime()
	game.start_tactical_combat("shoot")
	var s: Dictionary = game.tactical_session
	for u in s.get("units", []):
		if String(u.get("team", "")) == "enemy":
			u["health"] = 0
	s["shots_fired"] = 2
	s["bullets_left"] = 38
	s["resolved"] = true
	s["active"] = false
	s["outcome"] = "victory"
	game.finish_tactical_combat()

	var current: Dictionary = game.crime.incident()
	check(String(current.get("stage", "")) == "loot", "Winning shootout transitions crime incident to loot stage")
	check(game.crime.living_staff("fort_laramie").is_empty(), "Defenders killed in tactical combat are dead in crime.record.actors")
	check(game.crime.local_witnesses(current).is_empty(), "Eliminating all defenders leaves zero local witnesses")
	check(game.crime.valid(game.crime.snapshot(), game), "Crime ledger passes strict save validation after tactical combat")

	var store := SaveStore.new()
	var payload: Dictionary = store.capture(game)
	var restored = store.restore(payload)
	check(restored != null, "SaveStore captures and restores game state after tactical combat")


func _test_roadside_and_wanted_encounters() -> void:
	var game := Simulation.new(184899, "classic", true)
	game.depart("carpenter", ["SPENCER", "SAM", "JO", "LOU", "PAT"], 5, {"oxen": 4, "food": 400, "clothing": 5, "bullet_boxes": 2, "medicine": 2})

	# 1. Roadside bandits ("Defend the wagon")
	var bandit_ev: Dictionary = {}
	for ev in game.trail_events.events:
		if String(ev.get("id", "")) == "bandits":
			bandit_ev = ev
			break
	game._present_trail_event(bandit_ev)
	check(String(game.pending.get("id", "")) == "bandits", "Bandits trail event is presented")
	var bullets_before := int(game.state.bullets)
	check(game.start_tactical_combat("trail:1"), "Bandits 'Defend the wagon' launches tactical combat")
	check(String(game.tactical_session.get("mode_source", "")) == "trail_event", "Session mode_source is trail_event")
	check(String(game.tactical_session.get("venue_kind", "")) == "traders", "Bandits defense uses roadside traders map")
	game.tactical_step({"type": "start_combat"})
	game.tactical_session["bullets_left"] = bullets_before - 3
	for u in game.tactical_session.get("units", []):
		if String(u.get("team", "")) == "enemy":
			u["health"] = 0
	game.tactical._check_resolution(game.tactical_session)
	check(game.finish_tactical_combat(), "Bandits tactical combat settles cleanly")
	check(int(game.state.bullets) == bullets_before - 3, "Actual bullets fired are deducted after roadside skirmish")
	check(game.combat.victories() == 1, "Bandits tactical victory is recorded in combat.history")

	# 2. Roadside riders ("Circle and guard")
	var riders_ev: Dictionary = {}
	for ev in game.trail_events.events:
		if String(ev.get("id", "")) == "riders":
			riders_ev = ev
			break
	game._present_trail_event(riders_ev)
	game.pending["friendly"] = false
	check(game.start_tactical_combat("trail:3"), "Hostile riders 'Circle and guard' launches tactical combat")
	check(String(game.tactical_session.get("venue_kind", "")) == "emigrants", "Circle tactic uses wagon-circle emigrants map")
	game.tactical_step({"type": "retreat_all"})
	check(game.finish_tactical_combat(), "Riders circle skirmish settles cleanly")
	check(game.combat.history.size() == 2, "Riders circle skirmish is recorded in combat.history")

	# 3. Horse thieves pursuit ("Ride after the thieves")
	game.state["horses"] = 3
	var thieves_ev: Dictionary = {}
	for ev in game.trail_events.events:
		if String(ev.get("id", "")) == "horse_thieves":
			thieves_ev = ev
			break
	game._present_trail_event(thieves_ev)
	var horses_after_theft := int(game.state.get("horses", 0))
	check(horses_after_theft == 1, "Horse thieves onset steals 2 horses")
	check(game.start_tactical_combat("trail:0"), "Riding after horse thieves launches tactical combat")
	for u in game.tactical_session.get("units", []):
		if String(u.get("team", "")) == "enemy":
			u["health"] = 0
	game.tactical._check_resolution(game.tactical_session)
	check(game.finish_tactical_combat(), "Horse thieves skirmish settles cleanly")
	check(int(game.state.get("horses", 0)) == 3, "Winning horse thieves tactical skirmish recovers stolen horses")

	# 4. SaveStore validation after roadside encounters
	var store := SaveStore.new()
	var payload: Dictionary = store.capture(game)
	var restored = store.restore(payload)
	check(restored != null, "SaveStore captures and restores game state after roadside tactical encounters: " + store.error)


func _test_bug_regressions() -> void:
	# Regression 1: A surrendering targeted defender with 30 health stays at 30 health (not 0),
	# preserves surrender status, and does not record a killing when combat ends in victory.
	var game1 := Simulation.new(184805, "classic", true)
	game1.depart("carpenter", ["SPENCER", "SAM", "JO", "LOU", "PAT"], 5, {"oxen": 4, "food": 400, "clothing": 5, "bullet_boxes": 2, "medicine": 2})
	game1.route_path = game1.route.main_path_to("fort_bridger")
	game1.state.merge({"day": 45, "landmark": "fort_bridger", "next_landmark": "fort_bridger", "miles": 989, "leg_length": 0, "leg_miles": 0}, true)
	game1._arrive_landmark(true, false)
	var targets1: Array = game1.crime.local_targets(game1)
	var target_uid := String(targets1[0].uid)
	check(game1.open_local_attack(target_uid), "Open local attack menu for defender at Fort Bridger")
	check(game1.start_tactical_combat("shoot"), "Start tactical shoot targeting defender")
	var s1: Dictionary = game1.tactical_session
	for u in s1.get("units", []):
		if String(u.get("team", "")) == "enemy":
			u["health"] = 30
			u["yielded"] = true
			u["surrendered"] = true
	game1.tactical._check_resolution(s1)
	check(String(s1.get("outcome", "")) == "victory", "All defenders yielding resolves fight as victory")
	check(game1.finish_tactical_combat(), "Finish tactical combat with surrendering targeted defender")
	var def_actor: Dictionary = game1.crime.actor("fort_bridger", target_uid)
	check(int(def_actor.get("health", 0)) == 30, "Surrendering targeted defender keeps 30 health instead of becoming 0")
	var def_unit: Dictionary = game1.tactical.get_unit(game1.last_tactical, target_uid)
	check(bool(def_unit.get("yielded", false)) and bool(def_unit.get("surrendered", false)), "Defender surrender status is preserved in finished tactical record")
	var inc1: Dictionary = game1.crime.incident()
	check(String(inc1.get("attempt", "")) == "wounded", "Surrendering defender with 30 health records attempt as 'wounded', not 'killed'")
	check(not inc1.get("kills", []).has(target_uid), "Surrendering defender is not added to incident kills")
	var ev1: Dictionary = game1.crime.Wanted.incident_evidence(game1.crime, game1, inc1, true)
	check(int(ev1.get("severity", 0)) == 3, "No killing is recorded in evidence when targeted defender surrendered alive")
	check(game1.crime.valid(game1.crime.snapshot(), game1), "Crime ledger passes strict save validation when targeted defender surrenders")

	# Regression 2: Companions who refuse murder do not join an initiated attack even if willing to defend,
	# while defensive willingness is used for attacks against the party, and joining records match the squad.
	var game2 := Simulation.new(184806, "classic", true)
	game2.depart("carpenter", ["SPENCER", "SAM", "JO", "LOU", "PAT"], 5, {"oxen": 4, "food": 400, "clothing": 5, "bullet_boxes": 2, "medicine": 2})
	# Configure companion 1 (SAM): forbids murder, willing to defend.
	game2.characters.profiles[1].boundaries.forbidden = ["murder"]
	game2.characters.profiles[1].trust = 50
	# Configure companion 2 (JO): willing to murder and defend.
	game2.characters.profiles[2].boundaries.forbidden = []
	game2.characters.profiles[2].trust = 50
	check(not game2.characters.willing(1, "murder"), "Companion 1 explicitly refuses murder")
	check(game2.characters.willing(1, "defend"), "Companion 1 is willing to defend the party")

	game2.route_path = game2.route.main_path_to("fort_bridger")
	game2.state.merge({"day": 45, "landmark": "fort_bridger", "next_landmark": "fort_bridger", "miles": 989, "leg_length": 0, "leg_miles": 0}, true)
	game2._arrive_landmark(true, false)
	game2.open_crime()
	check(game2.start_tactical_combat("shoot"), "Initiate tactical attack at Fort Bridger")
	var squad_ids_attack: Array = []
	for u in game2.tactical_session.get("units", []):
		if String(u.get("team", "")) == "player":
			squad_ids_attack.append(int(str(u.get("id", "-1"))))
	check(1 not in squad_ids_attack, "Companion who refuses murder is excluded from initiated tactical attack squad")
	check(2 in squad_ids_attack, "Companion willing to commit murder joins initiated tactical attack squad")
	var inc2: Dictionary = game2.crime.incident()
	check(inc2.get("joining", []) == squad_ids_attack, "Incident joining record matches actual attacking squad")
	game2.tactical_step({"type": "retreat_all"})
	game2.finish_tactical_combat()
	game2.crime.choose(game2, "finish")

	# Now test a defensive encounter against the party (Wanted regulators catching up).
	game2.state.day = 55
	check(game2.crime.Wanted.start(game2.crime, game2, "regulators"), "Regulators catch up with the party")
	check(game2.start_tactical_combat("breakout"), "Start defensive tactical combat against regulators")
	var squad_ids_defend: Array = []
	for u in game2.tactical_session.get("units", []):
		if String(u.get("team", "")) == "player":
			squad_ids_defend.append(int(str(u.get("id", "-1"))))
	check(1 in squad_ids_defend, "Companion who refused murder joins defensive fight against regulators")
	var inc2_def: Dictionary = game2.crime.incident()
	check(inc2_def.get("joining", []) == squad_ids_defend, "Defensive incident joining record matches actual defending squad")
	game2.tactical_step({"type": "retreat_all"})
	game2.finish_tactical_combat()
	check(game2.crime.valid(game2.crime.snapshot(), game2), "Crime ledger passes strict validation after defensive tactical fight")

	# Regression 3: Getting shot during retreat at 1 health never increases health (never heals from 1 to 8).
	var tc := TacticalCombat.new()
	var hit_observed := false
	for attempt_seed in range(1, 60):
		var s3 := tc.start_session({
			"seed": attempt_seed,
			"venue_kind": "store",
			"place_name": "Test Store",
			"bullets": 5,
			"squad": [
				{"id": "0", "name": "SPENCER", "health": 1},
			],
			"enemies": [
				{"uid": "keeper:test", "name": "Keeper", "role": "owner", "health": 100},
			],
		})
		var p0 := tc.get_unit(s3, "0")
		p0["x"] = 5
		p0["y"] = 5
		p0["health"] = 1
		tc.rng.seed = attempt_seed
		tc.step(s3, {"type": "retreat_all"})
		var hp_after := int(p0.get("health", 0))
		check(hp_after <= 1, "Parting shot during retreat never increases traveler health above 1 (got %d)" % hp_after)
		if int(p0.get("wounds_taken", 0)) > 0:
			hit_observed = true
			check(hp_after == 1, "Traveler at 1 HP hit by nonfatal parting shot stays at 1 HP instead of healing to 8")
			break
	check(hit_observed, "Regression test observed a parting shot hit on a 1-HP retreating traveler")

	# Regression 4: Killing someone during a resisted robbery records the death in kills,
	# does not hide the killing behind 'complied', preserves surviving witnesses, and carries homicide severity (4).
	var game4 := Simulation.new(184807, "classic", true)
	game4.depart("carpenter", ["SPENCER", "SAM", "JO", "LOU", "PAT"], 5, {"oxen": 4, "food": 400, "clothing": 5, "bullet_boxes": 2, "medicine": 2})
	for i in range(game4.characters.profiles.size()):
		game4.characters.profiles[i]["morality"] = "ruthless"
	game4.route_path = game4.route.main_path_to("fort_bridger")
	game4.state.merge({"day": 45, "landmark": "fort_bridger", "next_landmark": "fort_bridger", "miles": 989, "leg_length": 0, "leg_miles": 0}, true)
	game4._arrive_landmark(true, false)
	game4.open_crime()
	# Start a robbery that resists.
	game4.crime.rng.seed = 999999
	check(game4.crime.choose(game4, "robbery"), "Initiate robbery at Fort Bridger")
	var inc4: Dictionary = game4.crime.incident()
	inc4["attempt"] = "resisted"
	inc4["stage"] = "escape"
	check(game4.start_tactical_combat("resisted"), "Start tactical combat on resisted robbery")
	var s4: Dictionary = game4.tactical_session
	var keeper_uid := String(game4.crime.owner_id("fort_bridger"))
	var witness_uid := ""
	for u in s4.get("units", []):
		if String(u.get("team", "")) != "enemy":
			continue
		var uid := String(u.get("uid", u.get("id", "")))
		if uid == keeper_uid:
			u["health"] = 0
		else:
			witness_uid = uid
			u["health"] = 35
			u["yielded"] = true
			u["surrendered"] = true
	game4.tactical._check_resolution(s4)
	check(String(s4.get("outcome", "")) == "victory", "Robbery fight resolves in victory")
	check(game4.finish_tactical_combat(), "Settle resisted robbery where shopkeeper died and witness survived")
	check(String(inc4.get("attempt", "")) == "killed", "Resisted robbery where shopkeeper died records attempt as 'killed', not 'complied'")
	check(inc4.get("kills", []).has(keeper_uid), "Dead shopkeeper is included in incident kills list")
	check(not witness_uid.is_empty() and not inc4.get("kills", []).has(witness_uid), "Surviving witness is not in incident kills list")
	var witnesses4: Array = game4.crime.local_witnesses(inc4)
	check(witness_uid in witnesses4 and keeper_uid not in witnesses4, "Surviving staff member remains a witness while dead shopkeeper does not")
	var ev4: Dictionary = game4.crime.Wanted.incident_evidence(game4.crime, game4, inc4, true)
	check(int(ev4.get("severity", 0)) == 4, "Robbery with a killing carries homicide severity (4), not robbery severity (2)")
	check(game4.crime.valid(game4.crime.snapshot(), game4), "Crime ledger passes strict save validation after fatal robbery")
	# Complete the getaway and verify the surviving witness reports the homicide.
	game4.crime.rng.seed = 12345
	check(game4.crime.choose(game4, "flee"), "Escape after fatal robbery with surviving witness")
	check(game4.crime.record.reports.size() == 1, "Surviving witness generates a crime report")
	var charges4: Array = game4.crime.Wanted.charges(game4.crime, game4, "fort_bridger")
	check(charges4.size() == 1 and int(charges4[0].get("severity", 0)) == 4, "Surviving witness report produces a homicide-severity (4) charge")
	check(game4.crime.valid(game4.crime.snapshot(), game4), "Crime ledger passes strict save validation after witness report")

	# Regression 5: Travelers who already withdrew cannot be shot during retreat_all,
	# and parting fire requires range and clear line of sight.
	var already_withdrawn_hit := false
	var exposed_in_los_hit := false
	for attempt_seed in range(1, 50):
		var s5 := tc.start_session({
			"seed": attempt_seed,
			"venue_kind": "store",
			"place_name": "Test Store",
			"bullets": 5,
			"squad": [
				{"id": "0", "name": "SPENCER", "health": 100},
				{"id": "1", "name": "SAM", "health": 100},
			],
			"enemies": [
				{"uid": "keeper:test", "name": "Keeper", "role": "owner", "health": 100},
			],
		})
		var u0_5 := tc.get_unit(s5, "0")
		var u1_5 := tc.get_unit(s5, "1")
		var e0_5 := tc.get_unit(s5, "keeper:test")
		var ret_tiles: Array = s5.get("retreat_tiles", [[0, 9]])
		var rt: Array = ret_tiles[0]
		u0_5["x"] = int(rt[0])
		u0_5["y"] = int(rt[1])
		# Unit 0 withdraws individually first.
		var withdrew0 := tc._exec_retreat_unit(s5, "0")
		if attempt_seed == 1:
			check(withdrew0, "Unit 0 withdraws from retreat tile")
		# Unit 1 is exposed in clear LoS and range of the enemy.
		u1_5["x"] = 5
		u1_5["y"] = 5
		e0_5["x"] = 5
		e0_5["y"] = 4
		tc.rng.seed = attempt_seed
		tc.step(s5, {"type": "retreat_all"})
		if int(u0_5.get("health", 100)) < 100 or int(u0_5.get("wounds_taken", 0)) > 0:
			already_withdrawn_hit = true
		if int(u1_5.get("health", 100)) < 100:
			exposed_in_los_hit = true
	check(not already_withdrawn_hit, "Traveler who already withdrew never takes parting-shot damage on subsequent retreat_all")
	check(exposed_in_los_hit, "Exposed traveler in range and clear LoS remains eligible for parting fire")

	# Verify that an exposed traveler with blocked LoS (or out of range) cannot be shot on retreat_all.
	var s5_blocked := tc.start_session({
		"seed": 7,
		"venue_kind": "store",
		"place_name": "Test Store",
		"bullets": 5,
		"squad": [
			{"id": "0", "name": "SPENCER", "health": 100},
		],
		"enemies": [
			{"uid": "keeper:test", "name": "Keeper", "role": "owner", "health": 100},
		],
	})
	var u0_blk := tc.get_unit(s5_blocked, "0")
	var e0_blk := tc.get_unit(s5_blocked, "keeper:test")
	# Place full-cover wall prop between enemy at (5, 1) and player at (5, 6), and check LoS is blocked.
	s5_blocked["props"].append({"x": 5, "y": 4, "cover": 2, "kind": "wall", "label": "Cabin Wall"})
	u0_blk["x"] = 5
	u0_blk["y"] = 6
	e0_blk["x"] = 5
	e0_blk["y"] = 1
	check(not bool(tc.line_of_sight(s5_blocked, 5, 1, 5, 6).get("clear", true)), "Wall prop blocks LoS between enemy and retreating traveler")
	tc.step(s5_blocked, {"type": "retreat_all"})
	check(int(u0_blk.get("health", 0)) == 100 and bool(e0_blk.get("loaded", false)), "Enemy does not fire a parting shot when LoS is blocked")

	# Regression 6: Wanted standoffs (posse/regulators/bounty_hunters) include all 3 pursuers
	# (including owner_id(place)) in tactical combat rather than stripping the lead pursuer.
	var game6 = null
	var wanted_type := ""
	for seed6 in range(184809, 184849):
		var g6 := Simulation.new(seed6, "classic", true)
		g6.depart("carpenter", ["SPENCER", "SAM", "JO", "LOU", "PAT"], 5, {"oxen": 4, "food": 400, "clothing": 5, "bullet_boxes": 2, "medicine": 2})
		for i in range(g6.characters.profiles.size()):
			g6.characters.profiles[i]["morality"] = "ruthless"
		g6.route_path = g6.route.main_path_to("fort_bridger")
		g6.state.merge({"day": 40, "landmark": "fort_bridger", "next_landmark": "fort_bridger", "miles": 989, "leg_length": 0, "leg_miles": 0}, true)
		g6._arrive_landmark(true, false)
		g6.open_crime()
		g6.crime.choose(g6, "shoot")
		if g6.state.status != "traveling" or g6.crime.incident().is_empty():
			continue
		g6.crime.choose(g6, "flee")
		if g6.state.status != "traveling" or String(g6.crime.incident().get("resolution", "")) != "escaped":
			continue
		g6.crime.choose(g6, "finish")
		g6.state.day = int(g6.state.day) + 30
		var types6: Array = g6.crime.Wanted.eligible(g6.crime, g6)
		if types6.is_empty():
			continue
		wanted_type = String(types6[0])
		game6 = g6
		break
	check(game6 != null, "Found a seed where the party escapes a shooting and becomes wanted")
	if game6 == null:
		return
	check(game6.crime.Wanted.start(game6.crime, game6, wanted_type), "Wanted %s standoff starts" % wanted_type)
	var wanted_place := String(game6.crime.incident().get("place", ""))
	check(game6.start_tactical_combat("breakout"), "Wanted posse breakout starts tactical combat")
	var wanted_enemies: Array = game6.tactical_session.get("units", []).filter(func(u): return String(u.get("team", "")) == "enemy")
	check(wanted_enemies.size() == game6.crime.staff_ids(wanted_place).size(), "All wanted pursuers spawn in tactical combat (lead rider not dropped)")
	for eu in wanted_enemies:
		eu["health"] = 0
	game6.tactical_session["shots_fired"] = 3
	game6.tactical_session["bullets_left"] = int(game6.state.bullets) - 3
	game6.tactical._check_resolution(game6.tactical_session)
	check(game6.finish_tactical_combat(), "Wanted posse tactical combat finishes")
	check(game6.crime.living_staff(wanted_place).is_empty(), "All 3 wanted posse pursuers are dead in crime.record.actors after victory")
	check(game6.crime.valid(game6.crime.snapshot(), game6), "Wanted posse tactical victory passes crime.valid()")

	# Regression 7: Killing all 4 defenders at Fort Kearny (where staff == 4 > breakout_shots == 3)
	# does not invert clampi bounds or violate crime.valid() save validation.
	var game7 := Simulation.new(184810, "classic", true)
	game7.depart("carpenter", ["SPENCER", "SAM", "JO", "LOU", "PAT"], 5, {"oxen": 4, "food": 400, "clothing": 5, "bullet_boxes": 2, "medicine": 2})
	for i in range(game7.characters.profiles.size()):
		game7.characters.profiles[i]["morality"] = "ruthless"
	game7.route_path = game7.route.main_path_to("fort_kearny")
	game7.state.merge({"day": 75, "landmark": "fort_kearny", "next_landmark": "fort_kearny", "miles": 319, "leg_length": 0, "leg_miles": 0}, true)
	game7._arrive_landmark(true, false)
	game7.open_crime()
	check(game7.start_tactical_combat("shoot"), "Fort Kearny tactical shootout starts")
	var kearny_enemies: Array = game7.tactical_session.get("units", []).filter(func(u): return String(u.get("team", "")) == "enemy")
	check(kearny_enemies.size() == 4, "Fort Kearny spawns all 4 garrison defenders")
	for eu in kearny_enemies:
		eu["health"] = 0
	game7.tactical_session["shots_fired"] = 4
	game7.tactical_session["bullets_left"] = int(game7.state.bullets) - 4
	game7.tactical._check_resolution(game7.tactical_session)
	check(game7.finish_tactical_combat(), "Fort Kearny 4-kill tactical shootout settles cleanly")
	var inc7: Dictionary = game7.crime.incident()
	check(inc7.get("kills", []).size() == 4, "All 4 Fort Kearny defenders recorded in kills")
	check(game7.crime.valid(game7.crime.snapshot(), game7), "Fort Kearny 4-kill shootout passes strict crime.valid() check")

	# Coverage 8: Surrendering to roadside bandits mid-fight pays the randomized BanditDemand
	# (cash/goods, or the whole wagon) exactly as surrendering from the event menu would.
	var saw_goods := false
	var saw_wagon := false
	for seed8 in range(184811, 184871):
		if saw_goods and saw_wagon:
			break
		var g8 := Simulation.new(seed8, "classic", true)
		g8.depart("carpenter", ["SPENCER", "SAM", "JO", "LOU", "PAT"], 5, {"oxen": 4, "food": 400, "clothing": 5, "bullet_boxes": 2, "medicine": 2})
		# Once a cash/goods demand is covered, force the rarer whole-wagon demand.
		g8.combat.data.bandit_demands["wagon_chance"] = 1.0 if saw_goods else 0.0
		var ev8: Dictionary = {}
		for ev in g8.trail_events.events:
			if String(ev.get("id", "")) == "bandits":
				ev8 = ev
				break
		g8._present_trail_event(ev8)
		var ch8: Array = g8.pending.get("choices", [])
		if ch8.size() < 2 or not bool(ch8[0].get("bandit_payment", false)):
			continue
		var wagon8 := bool(ch8[0].get("bandit_wagon", false))
		if (wagon8 and saw_wagon) or (not wagon8 and saw_goods):
			continue
		var req8: Dictionary = ch8[0].get("requires", {}).duplicate(true)
		var combat_idx := -1
		for i in range(ch8.size()):
			if ch8[i].has("combat"):
				combat_idx = i
				break
		if combat_idx < 0 or not g8.start_tactical_combat("trail:%d" % combat_idx):
			continue
		var before8: Dictionary = g8.state.duplicate(true)
		g8.tactical_step({"type": "surrender"})
		g8.finish_tactical_combat()
		var paid_all := true
		for item in req8:
			if item == "money":
				paid_all = paid_all and is_equal_approx(float(g8.state.money), maxf(0.0, float(before8.money) - float(req8.money)))
			else:
				paid_all = paid_all and int(g8.state.get(item, 0)) == maxi(0, int(before8.get(item, 0)) - int(req8[item]))
		if wagon8:
			saw_wagon = true
			check(paid_all and String(g8.state.vehicle) == "foot", "Surrendering mid-fight to a wagon demand loses the wagon, team and cargo")
		else:
			saw_goods = true
			check(paid_all and String(g8.state.vehicle) == "wagon", "Surrendering mid-fight pays the randomized cash/goods demand and keeps the wagon")
	check(saw_goods, "Found a bandit cash/goods demand to test")
	check(saw_wagon, "Found a bandit whole-wagon demand to test")

	# Regression 9: Once combat has started, non-active player units cannot act out of turn.
	var s9 := tc.start_session({
		"seed": 99,
		"venue_kind": "store",
		"place_name": "Test Turn Order",
		"bullets": 5,
		"squad": [
			{"id": "0", "name": "SPENCER", "health": 100},
			{"id": "1", "name": "SAM", "health": 100},
		],
		"enemies": [
			{"uid": "keeper:test", "name": "Keeper", "role": "owner", "health": 100},
		],
	})
	tc.step(s9, {"type": "start_combat"})
	while String(s9.get("turn", "")) != "player":
		tc.step(s9, {"type": "end_turn"})
	var active9 := String(s9.get("active_unit_id", ""))
	var inactive9 := "1" if active9 == "0" else "0"
	var u_inact := tc.get_unit(s9, inactive9)
	u_inact["loaded"] = false
	tc.step(s9, {"type": "reload", "unit_id": inactive9})
	check(not bool(u_inact.get("loaded", true)), "Non-active player unit cannot reload out of turn once combat has started")





func _test_ui_integration() -> void:
	var screen: Control = Main.instantiate()
	root.add_child(screen)
	await process_frame
	var game = screen.game
	game.depart("carpenter", ["SPENCER", "SAM", "JO", "LOU", "PAT"], 5, {"oxen": 4, "food": 400, "clothing": 5, "bullet_boxes": 2, "medicine": 2})
	for i in range(game.characters.profiles.size()):
		game.characters.profiles[i]["morality"] = "ruthless"
	screen.departure_view.hide()
	game.route_path = game.route.main_path_to("fort_bridger")
	game.state.merge({"day": 58, "landmark": "fort_bridger", "next_landmark": "fort_bridger", "miles": 989, "leg_length": 0, "leg_miles": 0}, true)
	game._arrive_landmark(true, false)
	game.open_crime()

	check(screen._open_tactical_combat("shoot"), "Main screen opens tactical combat window")
	await process_frame
	check(screen.tactical_window.visible, "TacticalView is visible when opened")
	check(screen.tactical_window.size.x <= 800.0 and screen.tactical_window.size.y <= 360.0, "TacticalView fits strictly inside 800x360 viewport")
	check(screen.tactical_window.snap_button.get_global_rect().end.y <= 360.0, "Bottom tactical control bar sits inside 800x360 viewport")
	var enemy_id := ""
	for u in game.tactical_session.get("units", []):
		if String(u.get("team", "")) == "enemy":
			enemy_id = String(u.get("id", ""))
			break
	check(not enemy_id.is_empty(), "Enemy unit exists in tactical session")
	var sprev: Dictionary = game.tactical.shot_preview_at(
		game.tactical_session,
		String(game.tactical_session.get("selected_id", "")),
		2,
		6,
		enemy_id,
		"snap",
		"torso",
		1
	)
	check(String(sprev.get("breakdown", "")).contains("BASE"), "shot_preview_at provides hit math breakdown")
	check(sprev.has("los_clear"), "shot_preview_at reports line of sight status from candidate tile")
	screen.tactical_window._set_fire_mode("called")
	screen.tactical_window._on_unit_clicked(enemy_id)
	check(screen.tactical_window.called_modal.visible, "Clicking enemy in Called Shot mode opens body-part targeting modal")

	screen.tactical_window._on_retreat_all_pressed()
	check(bool(game.tactical_session.get("resolved", false)), "Fall Back All resolves the skirmish")
	screen.tactical_window._on_finish_pressed()
	check(not screen.tactical_window.visible, "Finishing closes TacticalView and returns to crime/trail flow")
	screen.queue_free()
	await process_frame
