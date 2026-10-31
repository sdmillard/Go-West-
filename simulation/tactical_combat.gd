extends RefCounted

var rules: Dictionary = {}
var rng := RandomNumberGenerator.new()
const Armory = preload("res://simulation/armory.gd")

const BODY_PARTS := ["head", "torso", "arms", "legs"]
const DIRS := [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]


func _init() -> void:
	var file := FileAccess.open("res://data/tactical_combat.json", FileAccess.READ)
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			rules = parsed


func start_session(config: Dictionary) -> Dictionary:
	var seed_val := int(config.get("seed", 184801))
	rng.seed = seed_val
	var venue_kind := String(config.get("venue_kind", "store"))
	var venues: Dictionary = rules.get("venues", {})
	var venue: Dictionary = venues.get(venue_kind, venues.get("store", {})).duplicate(true)
	var grid_cfg: Dictionary = rules.get("grid", {})
	var width := int(grid_cfg.get("width", 12))
	var height := int(grid_cfg.get("height", 10))

	var base_tile := int(venue.get("base_tile", 0))
	var floor_rect: Array = venue.get("floor_rect", [2, 1, 9, 5])
	var floor_tile := int(venue.get("floor_tile", 2))
	var retreat_list: Array = venue.get("retreat_tiles", [[0, 7], [0, 8], [0, 9], [1, 9], [2, 9]])

	var tiles: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			var t := base_tile
			if floor_rect.size() == 4:
				if x >= int(floor_rect[0]) and x <= int(floor_rect[2]) and y >= int(floor_rect[1]) and y <= int(floor_rect[3]):
					t = floor_tile
			if _coord_in_list(x, y, retreat_list):
				t = 4
			row.append(t)
		tiles.append(row)

	var props: Array = []
	for raw_prop in venue.get("props", []):
		var p: Dictionary = raw_prop.duplicate(true)
		props.append(p)

	var bullets_left := maxi(0, int(config.get("bullets", 12)))
	var units: Array = []
	var player_spawns: Array = venue.get("player_spawns", [[2, 8], [3, 8], [1, 7], [4, 8], [2, 7]])
	var raw_squad: Array = config.get("squad", [])
	var loaded_assigned := 0
	for i in range(raw_squad.size()):
		var m: Dictionary = raw_squad[i]
		var spawn: Vector2i = _pick_open_spawn(player_spawns, i, Vector2i(2, 8), width, height, props, units)
		# Each traveler fights with the arms handed out from the party's stock; a config without them means a rifle.
		var weapon := String(m.get("weapon", "rifles"))
		if not Armory.data.firearms.has(weapon):
			weapon = ""
		var rounds := 0
		if not weapon.is_empty():
			rounds = mini(int(Armory.data.firearms[weapon].capacity), maxi(0, bullets_left - loaded_assigned))
		loaded_assigned += rounds
		var starts_loaded := rounds > 0
		var hp := clampi(int(m.get("health", 100)), 1, 100)
		var broken_leg := bool(m.get("broken_leg", false))
		var broken_arm := bool(m.get("broken_arm", false))
		var has_wound := bool(m.get("wound", false))
		var max_ap := max_ap_for_health(hp)
		var role_str := String(m.get("role", "member"))
		var init_score: int = 10 + int(hp / 25) - (3 if broken_leg else 0) - (1 if has_wound else 0) + rng.randi_range(1, 20)
		units.append({
			"id": String(m.get("id", "p_%d" % i)),
			"name": String(m.get("name", "Traveler %d" % (i + 1))),
			"role": role_str,
			"team": "player",
			"soldier": false,
			"initiative": init_score,
			"x": spawn.x,
			"y": spawn.y,
			"facing": "ne",
			"pose": "ready",
			"health": hp,
			"start_health": hp,
			"max_ap": max_ap,
			"ap": max_ap,
			"loaded": starts_loaded,
			"weapon": weapon,
			"blade": String(m.get("blade", "")) if Armory.data.blades.has(String(m.get("blade", ""))) else "",
			"rounds": rounds,
			"broken_leg": broken_leg,
			"broken_arm": broken_arm,
			"wound": has_wound,
			"wound_severity": int(m.get("wound_severity", 1 if has_wound else 0)),
			"wounds_taken": 0,
			"new_broken_leg": false,
			"new_broken_arm": false,
			"last_hit_part": "",
			"retreated": false,
			"yielded": false,
			"profile": m.get("profile", {}).duplicate(true) if m.get("profile") is Dictionary else {},
			"body_bonus": _body_bonus(m, int(config.get("combat_wins", 0)), bool(config.get("leader_veteran", false))),
			"trained_aim": _trained_aim(m, String(config.get("leader_background", ""))),
		})

	var enemy_spawns: Array = venue.get("enemy_spawns", [[8, 2], [6, 2], [9, 3], [5, 2], [8, 4]])
	var raw_enemies: Array = config.get("enemies", [])
	for i in range(raw_enemies.size()):
		var e: Dictionary = raw_enemies[i]
		var spawn: Vector2i = _pick_open_spawn(enemy_spawns, i, Vector2i(8, 2), width, height, props, units)
		var hp := clampi(int(e.get("health", 100)), 1, 100)
		var is_soldier := bool(e.get("soldier", venue_kind == "fort"))
		var max_ap := max_ap_for_health(hp)
		var role_str := String(e.get("role", "clerk"))
		var enemy_init: int = 10 + int(hp / 25) + (2 if is_soldier else 0) + (1 if role_str == "owner" else 0) + rng.randi_range(1, 20)
		units.append({
			"id": String(e.get("uid", e.get("id", "e_%d" % i))),
			"uid": String(e.get("uid", e.get("id", "e_%d" % i))),
			"name": String(e.get("name", "Defender %d" % (i + 1))),
			"role": role_str,
			"team": "enemy",
			"soldier": is_soldier,
			"initiative": enemy_init,
			"x": spawn.x,
			"y": spawn.y,
			"facing": "sw",
			"pose": "ready",
			"health": hp,
			"start_health": hp,
			"max_ap": max_ap,
			"ap": max_ap,
			"loaded": true,
			"weapon": "rifles",
			"blade": "",
			"rounds": 1,
			"broken_leg": false,
			"broken_arm": false,
			"wound": false,
			"wound_severity": 0,
			"wounds_taken": 0,
			"new_broken_leg": false,
			"new_broken_arm": false,
			"last_hit_part": "",
			"retreated": false,
			"yielded": bool(e.get("yielded", e.get("surrendered", false))),
			"surrendered": bool(e.get("surrendered", e.get("yielded", false))),
			"profile": e.get("profile", {}).duplicate(true) if e.get("profile") is Dictionary else {},
		})

	var sorted_units: Array = units.duplicate()
	sorted_units.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ia := int(a.get("initiative", 10))
		var ib := int(b.get("initiative", 10))
		if ia != ib:
			return ia > ib
		return String(a.get("id", "")) < String(b.get("id", ""))
	)
	var initiative_order: Array = []
	for u in sorted_units:
		initiative_order.append(String(u.get("id", "")))

	var first_id := _first_ready_player_id(sorted_units)
	var place_name := String(config.get("place_name", venue.get("title", "Frontier Post")))
	var custom_title := String(config.get("title", ""))
	var custom_subtitle := String(config.get("subtitle", ""))
	var reason := String(config.get("reason", "resisted"))
	var opening_line := _opening_banner(place_name, reason, venue)
	var session := {
		"active": true,
		"started": false,
		"resolved": false,
		"outcome": "",
		"outcome_summary": "",
		"seed": seed_val,
		"venue_kind": venue_kind,
		"place_name": place_name,
		"title": custom_title if not custom_title.is_empty() else String(venue.get("title", place_name)),
		"subtitle": custom_subtitle if not custom_subtitle.is_empty() else String(venue.get("subtitle", "")),
		"reason": reason,
		"command": String(config.get("command", "")),
		"mode_source": String(config.get("mode_source", "crime")),
		"event_id": String(config.get("event_id", "")),
		"choice_index": int(config.get("choice_index", -1)),
		"tactic": String(config.get("tactic", "defend")),
		"width": width,
		"height": height,
		"tiles": tiles,
		"props": props,
		"retreat_tiles": retreat_list.duplicate(true),
		"units": units,
		"initiative_order": initiative_order,
		"turn_index": -1,
		"active_unit_id": String(initiative_order[0]) if not initiative_order.is_empty() else first_id,
		"bullets_start": bullets_left,
		"bullets_left": bullets_left,
		"shots_fired": 0,
		"round": 1,
		"turn": "pre_combat",
		"selected_id": first_id,
		"fire_mode": "snap",
		"called_part": "torso",
		"log": [opening_line, "Initiative rolled — press START COMBAT to begin the turn order."],
		"last_fx": {},
		"fx_queue": [],
	}
	_refresh_unit_stances(session)
	_check_resolution(session)
	return session


func _opening_banner(place_name: String, reason: String, venue: Dictionary) -> String:
	match reason:
		"resisted":
			return "Rifles come up across %s! Defenders duck behind cover with caplock pieces cocked." % place_name
		"breakout":
			return "Garrison rifles level across %s! Cut your way to the retreat edge or drop the patrol." % place_name
		"shoot":
			return "Your party levels rifles at %s. Single-shot muzzleloaders—make every ball count." % place_name
		"bandits":
			return "Armed highwaymen block %s! Take cover behind the wagons and drive them off." % place_name
		"riders":
			return "Hostile riders close in along %s! Hold the wagons and make every shot count." % place_name
		"cayuse_riders":
			return "Cayuse riders level their rifles along %s! Hold your ground or pull back." % place_name
		"horse_thieves":
			return "You catch the horse thieves in broken country near %s! Drive them off to recover the stock." % place_name
		_:
			return String(venue.get("subtitle", "Skirmish at %s." % place_name))


func max_ap_for_health(hp: int) -> int:
	var ap_cfg: Dictionary = rules.get("ap", {})
	if hp >= 70:
		return int(ap_cfg.get("healthy", 8))
	if hp >= 40:
		return int(ap_cfg.get("worn", 6))
	return int(ap_cfg.get("critical", 5))


func move_cost_per_tile(unit: Dictionary) -> int:
	var ap_cfg: Dictionary = rules.get("ap", {})
	if bool(unit.get("broken_leg", false)):
		return int(ap_cfg.get("move_cost_broken_leg", 2))
	return int(ap_cfg.get("move_cost", 1))


## The firearm a unit carries, or {} when it has none. Units from older sessions carried rifles.
func gun(unit: Dictionary) -> Dictionary:
	return Armory.data.firearms.get(String(unit.get("weapon", "rifles")), {})


## What a unit swings at close quarters: its blade, a clubbed long gun, or bare fists.
func melee(unit: Dictionary) -> Dictionary:
	var blade := String(unit.get("blade", ""))
	if Armory.data.blades.has(blade):
		return Armory.data.blades[blade]
	if bool(gun(unit).get("long_gun", false)):
		var club_cfg: Dictionary = rules.get("club", {})
		return {"label": "Clubbed stock", "hit": float(club_cfg.get("hit_chance", 0.82)), "damage_min": int(club_cfg.get("damage_min", 16)), "damage_max": int(club_cfg.get("damage_max", 24)), "cost": int(rules.get("ap", {}).get("club_cost", 3))}
	return Armory.data.fists


func capacity(unit: Dictionary) -> int:
	return int(gun(unit).get("capacity", 0))


func reload_ap_cost(unit: Dictionary) -> int:
	var ap_cfg: Dictionary = rules.get("ap", {})
	var base := int(gun(unit).get("reload_cost", ap_cfg.get("reload_cost", 5)))
	if bool(unit.get("broken_arm", false)):
		return base + int(ap_cfg.get("reload_cost_broken_arm", 6)) - int(ap_cfg.get("reload_cost", 5))
	return base


func shot_ap_cost(mode: String, unit: Dictionary = {}) -> int:
	var ap_cfg: Dictionary = rules.get("ap", {})
	if mode == "club":
		return int(melee(unit).get("cost", ap_cfg.get("club_cost", 3))) if not unit.is_empty() else int(ap_cfg.get("club_cost", 3))
	var arm: Dictionary = gun(unit) if not unit.is_empty() else {}
	if mode == "called":
		return int(arm.get("called_cost", ap_cfg.get("called_shot_cost", 6)))
	return int(arm.get("snap_cost", ap_cfg.get("snap_shot_cost", 4)))


func retreat_ap_cost() -> int:
	var ap_cfg: Dictionary = rules.get("ap", {})
	return int(ap_cfg.get("retreat_cost", 1))


func available_reload_balls(session: Dictionary) -> int:
	var loaded_players := 0
	for u in session.get("units", []):
		if String(u.get("team", "")) == "player" and _unit_active(u) and bool(u.get("loaded", false)):
			loaded_players += maxi(1, int(u.get("rounds", 1)))
	return maxi(0, int(session.get("bullets_left", 0)) - loaded_players)


func get_unit(session: Dictionary, unit_id: String) -> Dictionary:
	for u in session.get("units", []):
		if String(u.get("id", "")) == unit_id:
			return u
	return {}


func unit_at(session: Dictionary, x: int, y: int) -> Dictionary:
	for u in session.get("units", []):
		if _unit_active(u) and int(u.get("x", -1)) == x and int(u.get("y", -1)) == y:
			return u
	return {}


func prop_at(session: Dictionary, x: int, y: int) -> Dictionary:
	for p in session.get("props", []):
		var px := int(p.get("x", -1))
		var py := int(p.get("y", -1))
		var pw := maxi(1, int(p.get("w", 1)))
		var ph := maxi(1, int(p.get("h", 1)))
		if x >= px and x < px + pw and y >= py and y < py + ph:
			return p
	return {}


func is_retreat_tile(session: Dictionary, x: int, y: int) -> bool:
	return _coord_in_list(x, y, session.get("retreat_tiles", []))


func is_deployment_tile(session: Dictionary, x: int, y: int) -> bool:
	var w := int(session.get("width", 12))
	var h := int(session.get("height", 10))
	if x < 0 or y < 0 or x >= w or y >= h:
		return false
	if not prop_at(session, x, y).is_empty():
		return false
	var occ := unit_at(session, x, y)
	if not occ.is_empty() and String(occ.get("team", "")) == "enemy":
		return false
	# Player deployment zone: SW approach side of the battlefield (rows y >= 6, columns x <= 9)
	return y >= 6 and x <= 9


func deployment_tiles(session: Dictionary) -> Dictionary:
	var out := {}
	if bool(session.get("started", false)):
		return out
	var w := int(session.get("width", 12))
	var h := int(session.get("height", 10))
	for y in range(h):
		for x in range(w):
			if is_deployment_tile(session, x, y):
				out[Vector2i(x, y)] = {"ap_cost": 0}
	return out


func is_walkable(session: Dictionary, x: int, y: int, ignore_unit_id: String = "") -> bool:
	var w := int(session.get("width", 12))
	var h := int(session.get("height", 10))
	if x < 0 or y < 0 or x >= w or y >= h:
		return false
	if not prop_at(session, x, y).is_empty():
		return false
	var occ := unit_at(session, x, y)
	if not occ.is_empty() and String(occ.get("id", "")) != ignore_unit_id:
		return false
	return true


func reachable_tiles(session: Dictionary, unit_id: String) -> Dictionary:
	var unit := get_unit(session, unit_id)
	if unit.is_empty() or not _unit_active(unit):
		return {}
	var step_cost := move_cost_per_tile(unit)
	var max_steps := int(unit.get("ap", 0)) / maxi(1, step_cost)
	var start := Vector2i(int(unit.get("x", 0)), int(unit.get("y", 0)))
	var dist := {start: 0}
	var parent := {}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		var d := int(dist[cur])
		if d >= max_steps:
			continue
		for dir in DIRS:
			var nxt: Vector2i = cur + dir
			if dist.has(nxt):
				continue
			if not is_walkable(session, nxt.x, nxt.y, unit_id):
				continue
			dist[nxt] = d + 1
			parent[nxt] = cur
			queue.append(nxt)

	var out := {}
	for cell in dist.keys():
		if cell == start:
			continue
		var steps := int(dist[cell])
		var path: Array[Vector2i] = []
		var cur: Vector2i = cell
		while cur != start:
			path.push_front(cur)
			cur = parent[cur]
		out[cell] = {
			"steps": steps,
			"ap_cost": steps * step_cost,
			"path": path,
		}
	return out


func path_to(session: Dictionary, unit_id: String, dest_x: int, dest_y: int) -> Dictionary:
	var reach := reachable_tiles(session, unit_id)
	var target := Vector2i(dest_x, dest_y)
	return reach.get(target, {})


func line_of_sight(session: Dictionary, x0: int, y0: int, x1: int, y1: int) -> Dictionary:
	var cells := _bresenham(x0, y0, x1, y1)
	for i in range(1, cells.size() - 1):
		var c: Vector2i = cells[i]
		var p := prop_at(session, c.x, c.y)
		if int(p.get("cover", 0)) >= 2:
			# Allow leaning around an immediately adjacent full-cover corner.
			var adj_to_shooter := maxi(absi(c.x - x0), absi(c.y - y0)) <= 1
			if not adj_to_shooter:
				return {
					"clear": false,
					"blocker": c,
					"blocker_label": String(p.get("label", "Wall")),
					"cells": cells,
				}
	return {
		"clear": true,
		"blocker": Vector2i(-1, -1),
		"blocker_label": "",
		"cells": cells,
	}


func target_cover_from(session: Dictionary, shooter_x: int, shooter_y: int, target_x: int, target_y: int) -> Dictionary:
	var dx := shooter_x - target_x
	var dy := shooter_y - target_y
	if dx == 0 and dy == 0:
		return {"in_cover": false, "cover": 0, "label": ""}
	var step_x := signi(dx)
	var step_y := signi(dy)
	var candidates: Array[Vector2i] = []
	if step_x != 0 and step_y != 0:
		if absi(dx) >= absi(dy):
			candidates.append(Vector2i(target_x + step_x, target_y))
			candidates.append(Vector2i(target_x, target_y + step_y))
		else:
			candidates.append(Vector2i(target_x, target_y + step_y))
			candidates.append(Vector2i(target_x + step_x, target_y))
		candidates.append(Vector2i(target_x + step_x, target_y + step_y))
	elif step_x != 0:
		candidates.append(Vector2i(target_x + step_x, target_y))
	elif step_y != 0:
		candidates.append(Vector2i(target_x, target_y + step_y))

	var best_cover := 0
	var best_label := ""
	for c in candidates:
		var p := prop_at(session, c.x, c.y)
		var cov := int(p.get("cover", 0))
		if cov > best_cover:
			best_cover = cov
			best_label = String(p.get("label", "Cover"))
	return {
		"in_cover": best_cover > 0,
		"cover": best_cover,
		"label": best_label,
	}


func unit_adjacent_cover(session: Dictionary, unit: Dictionary) -> Dictionary:
	var ux := int(unit.get("x", 0))
	var uy := int(unit.get("y", 0))
	var best := {}
	for dir in DIRS:
		var p := prop_at(session, ux + dir.x, uy + dir.y)
		if int(p.get("cover", 0)) > int(best.get("cover", 0)):
			best = p
	return best


func shot_preview(session: Dictionary, attacker_id: String, target_id: String, mode: String = "", body_part: String = "torso") -> Dictionary:
	var attacker := get_unit(session, attacker_id)
	if attacker.is_empty():
		return {"can_shoot": false, "reason": "Invalid shooter."}
	return shot_preview_at(session, attacker_id, int(attacker.get("x", 0)), int(attacker.get("y", 0)), target_id, mode, body_part, 0)


func shot_preview_at(session: Dictionary, attacker_id: String, ax: int, ay: int, target_id: String, mode: String = "", body_part: String = "torso", move_ap_spent: int = 0) -> Dictionary:
	var attacker := get_unit(session, attacker_id)
	var target := get_unit(session, target_id)
	if attacker.is_empty() or target.is_empty() or not _unit_active(attacker) or not _unit_active(target):
		return {"can_shoot": false, "reason": "Invalid target."}
	if String(attacker.get("team", "")) == String(target.get("team", "")):
		return {"can_shoot": false, "reason": "Friendly traveler."}

	var use_mode := mode if not mode.is_empty() else String(session.get("fire_mode", "snap"))
	var use_part := body_part if use_mode == "called" else "torso"
	if not BODY_PARTS.has(use_part):
		use_part = "torso"

	var tx := int(target.get("x", 0))
	var ty := int(target.get("y", 0))
	var dist := absi(ax - tx) + absi(ay - ty)
	var ap_cost := shot_ap_cost(use_mode, attacker)
	var ap_avail := maxi(0, int(attacker.get("ap", 0)) - move_ap_spent)

	if use_mode == "club":
		var club_cfg: Dictionary = melee(attacker)
		var club_hit := float(club_cfg.get("hit", 0.82))
		var terms: Array[String] = ["BASE %d%%" % int(round(club_hit * 100.0))]
		if bool(attacker.get("broken_arm", false)):
			club_hit -= 0.20
			terms.append("ARM -20%")
		var final_club := clampf(club_hit, 0.15, 0.95)
		terms.append("= %d%%" % int(round(final_club * 100.0)))
		var can_club := dist == 1 and ap_avail >= ap_cost
		var club_reason := ""
		if dist != 1:
			club_reason = "Must stand on an adjacent tile to strike with %s." % String(club_cfg.get("label", "a blade")).to_lower()
		elif ap_avail < ap_cost:
			club_reason = "Needs %d AP." % ap_cost
		return {
			"can_shoot": can_club,
			"reason": club_reason,
			"mode": "club",
			"body_part": "torso",
			"part_label": String(club_cfg.get("label", "Clubbed stock")),
			"ap_cost": ap_cost,
			"hit_chance": final_club,
			"breakdown": "  ".join(terms),
			"distance": dist,
			"in_cover": false,
			"cover_label": "",
			"damage_min": int(club_cfg.get("damage_min", 16)),
			"damage_max": int(club_cfg.get("damage_max", 24)),
			"condition": "",
			"wound_severity": 0,
			"summary": "%s at close quarters. Uses no powder or ball." % String(club_cfg.get("label", "A blow")),
			"los_cells": [Vector2i(ax, ay), Vector2i(tx, ty)],
		}

	var acc_cfg: Dictionary = rules.get("accuracy", {})
	var arm: Dictionary = gun(attacker)
	var max_range := int(arm.get("max_range", acc_cfg.get("max_range", 11)))
	var los := line_of_sight(session, ax, ay, tx, ty)
	var cov := target_cover_from(session, ax, ay, tx, ty)
	var called_cfg: Dictionary = rules.get("called_shots", {}).get(use_part, {})

	var base_val := float(acc_cfg.get("base_hit", 0.78)) + float(arm.get("hit_mod", 0.0))
	var hit := base_val
	var b_terms: Array[String] = ["BASE %d%%" % int(round(base_val * 100.0))]
	var trained := String(attacker.get("trained_aim", ""))
	if bool(attacker.get("soldier", false)) or trained == "soldier":
		var sb := float(acc_cfg.get("soldier_bonus", 0.08))
		hit += sb
		b_terms.append("SOLDIER +%d%%" % int(round(sb * 100.0)))
	elif trained == "hunter":
		var hb := float(acc_cfg.get("hunter_bonus", 0.04))
		hit += hb
		b_terms.append("HUNTER +%d%%" % int(round(hb * 100.0)))
	var opt_range := int(arm.get("optimal_range", acc_cfg.get("optimal_range", 4)))
	if dist <= 2:
		var pb := float(acc_cfg.get("point_blank_bonus", 0.07))
		hit += pb
		b_terms.append("PT-BLANK +%d%%" % int(round(pb * 100.0)))
	elif dist > opt_range:
		var rf := float(dist - opt_range) * float(arm.get("range_falloff", acc_cfg.get("range_falloff", 0.055)))
		hit -= rf
		b_terms.append("RNG(%d) -%d%%" % [dist, int(round(rf * 100.0))])

	if bool(cov.get("in_cover", false)):
		var cp := float(acc_cfg.get("half_cover_penalty", 0.28))
		hit -= cp
		b_terms.append("COVER -%d%%" % int(round(cp * 100.0)))
	if bool(attacker.get("broken_arm", false)):
		var ap_pen := float(acc_cfg.get("broken_arm_penalty", 0.22))
		hit -= ap_pen
		b_terms.append("ARM -%d%%" % int(round(ap_pen * 100.0)))
	if bool(attacker.get("wound", false)):
		var wp := float(acc_cfg.get("wound_penalty", 0.07))
		hit -= wp
		b_terms.append("WOUND -%d%%" % int(round(wp * 100.0)))

	if use_mode == "called":
		var cm := float(called_cfg.get("hit_mod", 0.0))
		hit += cm
		if absf(cm) > 0.001:
			var sign_s := "+" if cm > 0 else ""
			b_terms.append("%s %s%d%%" % [use_part.to_upper(), sign_s, int(round(cm * 100.0))])
	else:
		hit += float(called_cfg.get("snap_hit_mod", 0.0))

	hit = clampf(hit, float(acc_cfg.get("min_hit", 0.08)), float(acc_cfg.get("max_hit", 0.95)))
	if not bool(los.get("clear", false)) or dist > max_range:
		hit = 0.0
		b_terms.append("= BLOCKED")
	else:
		b_terms.append("= %d%%" % int(round(hit * 100.0)))

	var can_fire := true
	var reason := ""
	if arm.is_empty():
		can_fire = false
		reason = "No firearm. Close in and use %s." % String(melee(attacker).get("label", "a blade")).to_lower()
	elif not bool(attacker.get("loaded", false)):
		can_fire = false
		reason = "%s unloaded (Reload costs %d AP)." % [String(arm.get("label", "Rifle")), reload_ap_cost(attacker)]
	elif not bool(los.get("clear", false)):
		can_fire = false
		reason = "Blocked by %s." % String(los.get("blocker_label", "cover"))
	elif dist > max_range:
		can_fire = false
		reason = "Out of effective %s range (%d tiles)." % [String(arm.get("label", "rifle")).to_lower(), dist]
	elif ap_avail < ap_cost:
		can_fire = false
		reason = "Needs %d AP (%d AP left)." % [ap_cost, ap_avail]

	return {
		"can_shoot": can_fire,
		"los_clear": bool(los.get("clear", false)) and dist <= max_range,
		"reason": reason,
		"mode": use_mode,
		"body_part": use_part,
		"part_label": String(called_cfg.get("label", "Torso")),
		"ap_cost": ap_cost,
		"hit_chance": hit,
		"breakdown": "  ".join(b_terms),
		"distance": dist,
		"in_cover": bool(cov.get("in_cover", false)),
		"cover_label": String(cov.get("label", "")),
		"damage_min": roundi(int(called_cfg.get("damage_min", 36)) * float(arm.get("damage_factor", 1.0))),
		"damage_max": roundi(int(called_cfg.get("damage_max", 48)) * float(arm.get("damage_factor", 1.0))),
		"condition": String(called_cfg.get("condition", "wound")),
		"wound_severity": int(called_cfg.get("wound_severity", 2)),
		"summary": String(called_cfg.get("summary", "")),
		"los_cells": los.get("cells", []),
		"blocker": los.get("blocker", Vector2i(-1, -1)),
	}


func all_called_shot_previews(session: Dictionary, attacker_id: String, target_id: String) -> Dictionary:
	var out := {}
	for part in BODY_PARTS:
		out[part] = shot_preview(session, attacker_id, target_id, "called", part)
	return out


func step(session: Dictionary, action: Dictionary) -> Dictionary:
	if bool(session.get("resolved", false)):
		return session
	session["last_fx"] = {}
	session["fx_queue"] = []
	var started := bool(session.get("started", false))
	var active_id := String(session.get("active_unit_id", session.get("selected_id", "")))
	var kind := String(action.get("type", ""))
	match kind:
		"start_combat":
			if not started:
				session["started"] = true
				session["turn_index"] = -1
				_append_log(session, "Combat begins! Initiative order engaged.")
				_advance_to_next_turn(session, true)
		"place":
			if not started:
				var uid := String(action.get("unit_id", session.get("selected_id", "")))
				_exec_place_unit(session, uid, int(action.get("x", -1)), int(action.get("y", -1)))
		"select":
			var uid := String(action.get("unit_id", ""))
			var u := get_unit(session, uid)
			if not started:
				if not u.is_empty() and String(u.get("team", "")) == "player" and _unit_active(u):
					session["selected_id"] = uid
			else:
				# Once initiative order starts, only the active combatant acts on their turn.
				if uid == active_id:
					session["selected_id"] = active_id
		"set_mode":
			var m := String(action.get("mode", "snap"))
			if m in ["snap", "called", "club"]:
				session["fire_mode"] = m
			if action.has("body_part"):
				var bp := String(action.get("body_part", "torso"))
				if bp in BODY_PARTS:
					session["called_part"] = bp
		"move":
			var tx := int(action.get("x", -1))
			var ty := int(action.get("y", -1))
			if not started and is_deployment_tile(session, tx, ty):
				var uid := String(action.get("unit_id", session.get("selected_id", "")))
				_exec_place_unit(session, uid, tx, ty)
			else:
				if not started:
					_ensure_started_for_unit(session, String(action.get("unit_id", session.get("selected_id", ""))))
					active_id = String(session.get("active_unit_id", ""))
				var uid := String(action.get("unit_id", active_id))
				if uid == active_id:
					_exec_move(session, uid, tx, ty)
		"shoot":
			if not started:
				_ensure_started_for_unit(session, String(action.get("unit_id", session.get("selected_id", ""))))
				active_id = String(session.get("active_unit_id", ""))
			var uid := String(action.get("unit_id", active_id))
			if uid == active_id:
				var tid := String(action.get("target_id", ""))
				var mode := String(action.get("mode", session.get("fire_mode", "snap")))
				var part := String(action.get("body_part", session.get("called_part", "torso")))
				_exec_attack(session, uid, tid, mode, part)
		"reload":
			if not started:
				_ensure_started_for_unit(session, String(action.get("unit_id", session.get("selected_id", ""))))
				active_id = String(session.get("active_unit_id", ""))
			var uid := String(action.get("unit_id", active_id))
			if uid == active_id:
				_exec_reload(session, uid)
		"retreat_unit":
			if not started:
				_ensure_started_for_unit(session, String(action.get("unit_id", session.get("selected_id", ""))))
				active_id = String(session.get("active_unit_id", ""))
			var uid := String(action.get("unit_id", active_id))
			if uid == active_id and _exec_retreat_unit(session, uid):
				_check_resolution(session)
				if not bool(session.get("resolved", false)):
					_advance_to_next_turn(session, false)
		"retreat_all":
			_exec_retreat_all(session)
		"surrender":
			_exec_surrender(session)
		"end_turn":
			if not started:
				session["started"] = true
				session["turn_index"] = -1
				_advance_to_next_turn(session, true)
			else:
				_exec_end_turn(session)

	_refresh_unit_stances(session)
	_check_resolution(session)
	return session


func _ensure_started_for_unit(session: Dictionary, uid: String) -> void:
	session["started"] = true
	session["turn"] = "player"
	var order: Array = session.get("initiative_order", [])
	var idx := order.find(uid)
	session["turn_index"] = maxi(0, idx)
	session["active_unit_id"] = uid
	session["selected_id"] = uid


func _exec_place_unit(session: Dictionary, unit_id: String, dest_x: int, dest_y: int) -> bool:
	var unit := get_unit(session, unit_id)
	if unit.is_empty() or not _unit_active(unit) or String(unit.get("team", "")) != "player":
		return false
	if not is_deployment_tile(session, dest_x, dest_y):
		_append_log(session, "Place %s inside the highlighted SW deployment zone." % String(unit.get("name", "Traveler")))
		return false
	var old_x := int(unit.get("x", 0))
	var old_y := int(unit.get("y", 0))
	if old_x == dest_x and old_y == dest_y:
		return false
	var occ := unit_at(session, dest_x, dest_y)
	if not occ.is_empty() and String(occ.get("id", "")) != unit_id:
		if String(occ.get("team", "")) != "player":
			return false
		occ["x"] = old_x
		occ["y"] = old_y
		unit["x"] = dest_x
		unit["y"] = dest_y
		_append_log(session, "%s swaps positions with %s." % [String(unit.get("name", "Traveler")), String(occ.get("name", "Traveler"))])
	else:
		unit["x"] = dest_x
		unit["y"] = dest_y
		var cov := unit_adjacent_cover(session, unit)
		if not cov.is_empty():
			_append_log(session, "%s deploys behind %s." % [String(unit.get("name", "Traveler")), String(cov.get("label", "cover"))])
		else:
			_append_log(session, "%s deploys at (%d, %d)." % [String(unit.get("name", "Traveler")), dest_x, dest_y])
	return true


func _exec_move(session: Dictionary, unit_id: String, dest_x: int, dest_y: int) -> bool:
	var unit := get_unit(session, unit_id)
	if unit.is_empty() or not _unit_active(unit):
		return false
	var path_info := path_to(session, unit_id, dest_x, dest_y)
	if path_info.is_empty():
		return false
	var ap_cost := int(path_info.get("ap_cost", 99))
	if int(unit.get("ap", 0)) < ap_cost:
		return false
	var old_x := int(unit.get("x", 0))
	var old_y := int(unit.get("y", 0))
	unit["x"] = dest_x
	unit["y"] = dest_y
	unit["ap"] = int(unit.get("ap", 0)) - ap_cost
	if (dest_x - old_x) - (dest_y - old_y) > 0:
		unit["facing"] = "ne"
	elif (dest_x - old_x) - (dest_y - old_y) < 0:
		unit["facing"] = "sw"
	var cov := unit_adjacent_cover(session, unit)
	if not cov.is_empty():
		_append_log(session, "%s moves behind %s (%d AP)." % [String(unit.get("name", "Traveler")), String(cov.get("label", "cover")), ap_cost])
	else:
		_append_log(session, "%s advances (%d AP)." % [String(unit.get("name", "Traveler")), ap_cost])
	var path_pts: Array = [Vector2i(old_x, old_y)]
	for step_pt in path_info.get("path", []):
		path_pts.append(step_pt)
	var fx := {
		"type": "move",
		"unit_id": unit_id,
		"from": Vector2i(old_x, old_y),
		"to": Vector2i(dest_x, dest_y),
		"path": path_pts,
		"banner": String(session.get("log", [""]).back()),
	}
	session["last_fx"] = fx
	session["fx_queue"].append(fx)
	return true


func _exec_reload(session: Dictionary, unit_id: String) -> bool:
	var unit := get_unit(session, unit_id)
	if unit.is_empty() or not _unit_active(unit):
		return false
	var arm: Dictionary = gun(unit)
	if arm.is_empty():
		_append_log(session, "%s has no firearm to load." % String(unit.get("name", "Traveler")))
		return false
	var rounds := int(unit.get("rounds", 1 if bool(unit.get("loaded", false)) else 0))
	if rounds >= int(arm.capacity):
		_append_log(session, "%s's %s is already loaded." % [String(unit.get("name", "Traveler")), String(arm.label).to_lower()])
		return false
	var cost := reload_ap_cost(unit)
	if int(unit.get("ap", 0)) < cost:
		_append_log(session, "%s needs %d AP to ram home powder and ball." % [String(unit.get("name", "Traveler")), cost])
		return false
	if String(unit.get("team", "")) == "player" and available_reload_balls(session) <= 0:
		_append_log(session, "Out of lead balls! No ammunition left in the pouch.")
		return false
	unit["ap"] = int(unit.get("ap", 0)) - cost
	var fill := int(arm.capacity) - rounds
	if String(unit.get("team", "")) == "player":
		fill = mini(fill, available_reload_balls(session))
	unit["rounds"] = rounds + fill
	unit["loaded"] = true
	unit["pose"] = "reload"
	_append_log(session, "%s pours powder, rams a patched ball, and seats a percussion cap (%d AP)." % [String(unit.get("name", "Traveler")), cost])
	var fx := {
		"type": "reload",
		"unit_id": unit_id,
		"pos": Vector2i(int(unit.get("x", 0)), int(unit.get("y", 0))),
		"banner": String(session.get("log", [""]).back()),
	}
	session["last_fx"] = fx
	session["fx_queue"].append(fx)
	return true


func _exec_attack(session: Dictionary, attacker_id: String, target_id: String, mode: String, body_part: String) -> bool:
	var preview := shot_preview(session, attacker_id, target_id, mode, body_part)
	if not bool(preview.get("can_shoot", false)):
		var why := String(preview.get("reason", "Cannot fire."))
		if not why.is_empty() and String(session.get("turn", "")) == "player":
			_append_log(session, why)
		return false

	var attacker := get_unit(session, attacker_id)
	var target := get_unit(session, target_id)
	var ap_cost := int(preview.get("ap_cost", 4))
	attacker["ap"] = int(attacker.get("ap", 0)) - ap_cost
	var ax := int(attacker.get("x", 0))
	var ay := int(attacker.get("y", 0))
	var tx := int(target.get("x", 0))
	var ty := int(target.get("y", 0))
	attacker["facing"] = "ne" if (tx - ax) >= (ty - ay) else "sw"
	attacker["pose"] = "fire"

	var use_mode := String(preview.get("mode", "snap"))
	var use_part := String(preview.get("body_part", "torso"))
	var part_label := String(preview.get("part_label", "Torso")).to_lower()
	if use_mode != "club":
		attacker["rounds"] = maxi(0, int(attacker.get("rounds", 1)) - 1)
		attacker["loaded"] = int(attacker.rounds) > 0
		if String(attacker.get("team", "")) == "player":
			session["bullets_left"] = maxi(0, int(session.get("bullets_left", 0)) - 1)
			session["shots_fired"] = int(session.get("shots_fired", 0)) + 1

	var hit_chance := float(preview.get("hit_chance", 0.5))
	var roll := rng.randf()
	var did_hit := roll <= hit_chance
	var dmg := 0
	var status_note := ""

	if did_hit:
		dmg = rng.randi_range(int(preview.get("damage_min", 30)), int(preview.get("damage_max", 44)))
		target["health"] = maxi(0, int(target.get("health", 100)) - dmg)
		if use_mode != "club":
			target["wound"] = true
			target["wound_severity"] = maxi(int(target.get("wound_severity", 0)), int(preview.get("wound_severity", 2)))
			target["wounds_taken"] = int(target.get("wounds_taken", 0)) + 1
			target["last_hit_part"] = use_part
			if use_part == "legs" and not bool(target.get("broken_leg", false)):
				target["broken_leg"] = true
				target["new_broken_leg"] = true
				status_note = " (shattered leg!)"
			elif use_part == "arms" and not bool(target.get("broken_arm", false)):
				target["broken_arm"] = true
				target["new_broken_arm"] = true
				status_note = " (shattered arm!)"
			elif use_part == "head":
				if int(target.get("health", 0)) <= 15:
					target["health"] = 0
				status_note = " (headshot!)"
			else:
				status_note = " (open gunshot wound)"

		var stunned_now := int(target.get("health", 0)) > 0 and not _stun_save(session, target)
		if stunned_now:
			status_note += " — knocked senseless"
		if int(target.get("health", 0)) <= 0:
			target["pose"] = "down"
			_append_log(session, "%s hits %s in the %s for %d dmg%s — %s drops!" % [
				String(attacker.get("name", "Shooter")),
				String(target.get("name", "Target")),
				part_label,
				dmg,
				status_note,
				String(target.get("name", "Target")),
			])
		else:
			_append_log(session, "%s hits %s in the %s for %d dmg%s (%d HP left)." % [
				String(attacker.get("name", "Shooter")),
				String(target.get("name", "Target")),
				part_label,
				dmg,
				status_note,
				int(target.get("health", 0)),
			])
	else:
		var cov_label := String(preview.get("cover_label", ""))
		if not cov_label.is_empty():
			_append_log(session, "%s fires at %s (%d%%) — lead ball splinters into the %s!" % [
				String(attacker.get("name", "Shooter")),
				String(target.get("name", "Target")),
				int(round(hit_chance * 100.0)),
				cov_label.to_lower(),
			])
		else:
			_append_log(session, "%s fires at %s (%d%%) — ball whistles wide through the smoke!" % [
				String(attacker.get("name", "Shooter")),
				String(target.get("name", "Target")),
				int(round(hit_chance * 100.0)),
			])

	var fx := {
		"type": "shot" if use_mode != "club" else "club",
		"attacker_id": attacker_id,
		"target_id": target_id,
		"from": Vector2i(ax, ay),
		"to": Vector2i(tx, ty),
		"hit": did_hit,
		"damage": dmg,
		"body_part": use_part,
		"status_note": status_note.strip_edges(),
		"hit_chance": hit_chance,
		"banner": String(session.get("log", [""]).back()),
	}
	session["last_fx"] = fx
	session["fx_queue"].append(fx)
	return true


func _exec_retreat_unit(session: Dictionary, unit_id: String) -> bool:
	var unit := get_unit(session, unit_id)
	if unit.is_empty() or not _unit_active(unit) or String(unit.get("team", "")) != "player":
		return false
	var ux := int(unit.get("x", 0))
	var uy := int(unit.get("y", 0))
	var cost := retreat_ap_cost()
	if not is_retreat_tile(session, ux, uy):
		_append_log(session, "Move %s onto a gold retreat chevron tile at the SW edge to withdraw." % String(unit.get("name", "Traveler")))
		return false
	if int(unit.get("ap", 0)) < cost:
		_append_log(session, "%s needs %d AP to withdraw." % [String(unit.get("name", "Traveler")), cost])
		return false
	unit["ap"] = 0
	unit["retreated"] = true
	_append_log(session, "%s slips back to the wagons and withdraws from the firefight." % String(unit.get("name", "Traveler")))
	var next_id := _first_ready_player_id(session.get("units", []))
	if not next_id.is_empty():
		session["selected_id"] = next_id
	return true


func _exec_retreat_all(session: Dictionary) -> void:
	# Collect exposed, still-present player units BEFORE marking the remaining party as retreated.
	var units: Array = session.get("units", [])
	var retiring: Array = []
	var exposed: Array = []
	for u in units:
		# Companions drag senseless travelers back with them, exposed to the same parting fire.
		var senseless := bool(u.get("stunned", false)) and int(u.get("health", 0)) > 0 and not bool(u.get("retreated", false))
		if String(u.get("team", "")) == "player" and (_unit_active(u) or senseless):
			retiring.append(u)
			if not is_retreat_tile(session, int(u.get("x", 0)), int(u.get("y", 0))):
				exposed.append(u)
	if not exposed.is_empty():
		_append_log(session, "Your party scrambles back toward the teams under parting fire!")
		_parting_fire_on_retreat(session, exposed)
	else:
		_append_log(session, "Your party withdraws cleanly from the retreat edge.")
	for u in retiring:
		u["retreated"] = true
		u["ap"] = 0


func _parting_fire_on_retreat(session: Dictionary, candidates: Array = []) -> void:
	var pool: Array = candidates
	if pool.is_empty():
		for u in session.get("units", []):
			if String(u.get("team", "")) == "player" and _unit_active(u) and not is_retreat_tile(session, int(u.get("x", 0)), int(u.get("y", 0))):
				pool.append(u)
	if pool.is_empty():
		return
	var acc_cfg: Dictionary = rules.get("accuracy", {})
	var max_range := int(acc_cfg.get("max_range", 11))
	for e in session.get("units", []):
		if String(e.get("team", "")) == "enemy" and _unit_active(e) and bool(e.get("loaded", false)):
			var ex := int(e.get("x", 0))
			var ey := int(e.get("y", 0))
			var valid_targets: Array = []
			for u in pool:
				if int(u.get("health", 0)) <= 0 or bool(u.get("retreated", false)):
					continue
				var ux := int(u.get("x", 0))
				var uy := int(u.get("y", 0))
				var dist := absi(ux - ex) + absi(uy - ey)
				if dist <= max_range and bool(line_of_sight(session, ex, ey, ux, uy).get("clear", false)):
					valid_targets.append(u)
			if valid_targets.is_empty():
				continue
			var target: Dictionary = valid_targets[rng.randi() % valid_targets.size()]
			if rng.randf() < 0.28:
				var cur_hp := int(target.get("health", 100))
				var raw_dmg := rng.randi_range(16, 28)
				var dmg := mini(raw_dmg, maxi(0, cur_hp - 1))
				target["health"] = cur_hp - dmg
				target["wound"] = true
				target["wound_severity"] = maxi(int(target.get("wound_severity", 0)), 1)
				target["wounds_taken"] = int(target.get("wounds_taken", 0)) + 1
				_append_log(session, "A parting rifle ball grazes %s (%d dmg, open wound) during the retreat!" % [
					String(target.get("name", "Traveler")),
					dmg,
				])
			e["loaded"] = false
			e["rounds"] = 0
			break


func _exec_surrender(session: Dictionary) -> void:
	_append_log(session, "Your party grounded their rifles and surrendered.")
	session["resolved"] = true
	session["active"] = false
	session["outcome"] = "surrendered"
	session["outcome_summary"] = "Your party grounded their rifles and submitted to judgment."


func _exec_end_turn(session: Dictionary) -> void:
	if bool(session.get("resolved", false)):
		return
	_advance_to_next_turn(session, false)


func _advance_to_next_turn(session: Dictionary, is_opening: bool) -> void:
	var order: Array = session.get("initiative_order", [])
	if order.is_empty():
		return
	var max_steps := order.size() * 2 + 2
	var steps := 0
	while steps < max_steps:
		steps += 1
		_check_resolution(session)
		if bool(session.get("resolved", false)):
			return
		var next_idx: int = int(session.get("turn_index", -1)) + 1
		if next_idx >= order.size():
			next_idx = 0
			if not is_opening:
				session["round"] = int(session.get("round", 1)) + 1
				_append_log(session, "Round %d begins." % int(session.get("round", 1)))
		is_opening = false
		session["turn_index"] = next_idx
		var uid := String(order[next_idx])
		var u := get_unit(session, uid)
		if not u.is_empty() and not _turn_start_saves(session, u):
			continue
		if u.is_empty() or not _unit_active(u):
			continue
		u["max_ap"] = max_ap_for_health(int(u.get("health", 100)))
		u["ap"] = int(u.get("max_ap", 8))
		u["pose"] = "ready"
		session["active_unit_id"] = uid
		if String(u.get("team", "")) == "enemy":
			session["turn"] = "enemy"
			_run_single_enemy_turn(session, u)
			_check_resolution(session)
			if bool(session.get("resolved", false)):
				return
			continue
		else:
			session["turn"] = "player"
			session["selected_id"] = uid
			_append_log(session, "%s's turn (INIT %d · %d AP)." % [
				String(u.get("name", "Traveler")),
				int(u.get("initiative", 10)),
				int(u.get("ap", 8)),
			])
			var turn_fx := {
				"type": "turn",
				"unit_id": uid,
				"pos": Vector2i(int(u.get("x", 0)), int(u.get("y", 0))),
				"banner": "NOW ACTING: %s (%d AP)" % [String(u.get("name", "Traveler")).to_upper(), int(u.get("ap", 8))],
			}
			session["last_fx"] = turn_fx
			session["fx_queue"].append(turn_fx)
			return


func _run_single_enemy_turn(session: Dictionary, e: Dictionary) -> void:
	if not _unit_active(e):
		return
	var owner_alive := false
	for u in session.get("units", []):
		if String(u.get("team", "")) == "enemy" and _unit_active(u) and String(u.get("role", "")) == "owner":
			owner_alive = true
			break

	# Morale check for wounded civilian staff when the post owner is down.
	if not bool(e.get("soldier", false)) and String(e.get("role", "")) != "owner":
		if int(e.get("health", 100)) <= 40 and (not owner_alive or int(e.get("wounds_taken", 0)) >= 1):
			if rng.randf() < 0.50:
				e["yielded"] = true
				e["surrendered"] = true
				e["ap"] = 0
				_append_log(session, "%s drops their rifle and throws up both hands!" % String(e.get("name", "Clerk")))
				return

	var guard := 0
	while int(e.get("ap", 0)) > 0 and _unit_active(e) and guard < 6:
		guard += 1
		if _living_player_units(session).is_empty():
			break
		var eid := String(e.get("id", ""))
		if bool(e.get("loaded", false)):
			var best_shot := _best_enemy_shot(session, eid)
			# If standing in the open with enough AP to step into cover and still fire, do so.
			if unit_adjacent_cover(session, e).is_empty() and int(e.get("ap", 0)) >= shot_ap_cost("snap") + move_cost_per_tile(e):
				var cover_step := _best_enemy_cover_tile(session, eid, true)
				if cover_step != Vector2i(-1, -1):
					_exec_move(session, eid, cover_step.x, cover_step.y)
					best_shot = _best_enemy_shot(session, eid)

			if not best_shot.is_empty() and int(e.get("ap", 0)) >= shot_ap_cost("snap"):
				var tid := String(best_shot.get("target_id", ""))
				var mode := "snap"
				var part := "torso"
				if int(e.get("ap", 0)) >= shot_ap_cost("called") and float(best_shot.get("hit_chance", 0.0)) >= 0.72 and rng.randf() < 0.35:
					mode = "called"
					part = "legs" if rng.randf() < 0.5 else "torso"
				_exec_attack(session, eid, tid, mode, part)
				continue

			# Move toward a tile that has LoS on a player unit.
			var advance := _best_enemy_advance_tile(session, eid)
			if advance != Vector2i(-1, -1):
				_exec_move(session, eid, advance.x, advance.y)
				continue
			break
		else:
			var r_cost := reload_ap_cost(e)
			if unit_adjacent_cover(session, e).is_empty() and int(e.get("ap", 0)) >= r_cost + move_cost_per_tile(e):
				var cov_tile := _best_enemy_cover_tile(session, eid, false)
				if cov_tile != Vector2i(-1, -1):
					_exec_move(session, eid, cov_tile.x, cov_tile.y)
			if int(e.get("ap", 0)) >= r_cost:
				_exec_reload(session, eid)
				continue
			var fallback := _best_enemy_cover_tile(session, eid, false)
			if fallback != Vector2i(-1, -1):
				_exec_move(session, eid, fallback.x, fallback.y)
			break


func _best_enemy_shot(session: Dictionary, enemy_id: String) -> Dictionary:
	var best := {}
	var best_score := -1.0
	for p in _living_player_units(session):
		var pid := String(p.get("id", ""))
		var prev := shot_preview(session, enemy_id, pid, "snap", "torso")
		if not bool(prev.get("can_shoot", false)):
			continue
		var hit := float(prev.get("hit_chance", 0.0))
		if hit < 0.20:
			continue
		var finish_bonus := 0.18 if int(p.get("health", 100)) <= 42 else 0.0
		var score := hit + finish_bonus
		if score > best_score:
			best_score = score
			best = prev.duplicate(true)
			best["target_id"] = pid
	return best


func _best_enemy_cover_tile(session: Dictionary, enemy_id: String, require_los: bool) -> Vector2i:
	var reach := reachable_tiles(session, enemy_id)
	var enemy := get_unit(session, enemy_id)
	var r_cost := shot_ap_cost("snap") if require_los else reload_ap_cost(enemy)
	var best_cell := Vector2i(-1, -1)
	var best_score := -999.0
	var players := _living_player_units(session)
	if players.is_empty():
		return best_cell

	for cell in reach.keys():
		var info: Dictionary = reach[cell]
		var ap_left := int(enemy.get("ap", 0)) - int(info.get("ap_cost", 99))
		if ap_left < r_cost:
			continue
		var cov_score := 0.0
		for p in players:
			var px := int(p.get("x", 0))
			var py := int(p.get("y", 0))
			var cov := target_cover_from(session, px, py, cell.x, cell.y)
			if bool(cov.get("in_cover", false)):
				cov_score += 2.0
			if require_los:
				var los := line_of_sight(session, cell.x, cell.y, px, py)
				if bool(los.get("clear", false)):
					cov_score += 1.5
		if cov_score > best_score and cov_score > 0.0:
			best_score = cov_score
			best_cell = cell
	return best_cell


func _best_enemy_advance_tile(session: Dictionary, enemy_id: String) -> Vector2i:
	var reach := reachable_tiles(session, enemy_id)
	var players := _living_player_units(session)
	if reach.is_empty() or players.is_empty():
		return Vector2i(-1, -1)
	var best_cell := Vector2i(-1, -1)
	var best_score := -999.0
	for cell in reach.keys():
		var score := 0.0
		for p in players:
			var px := int(p.get("x", 0))
			var py := int(p.get("y", 0))
			var d := absi(cell.x - px) + absi(cell.y - py)
			score -= float(absi(d - 5)) * 0.6
			var los := line_of_sight(session, cell.x, cell.y, px, py)
			if bool(los.get("clear", false)):
				score += 4.0
			var cov := target_cover_from(session, px, py, cell.x, cell.y)
			if bool(cov.get("in_cover", false)):
				score += 2.2
		if score > best_score:
			best_score = score
			best_cell = cell
	return best_cell


func _refresh_unit_stances(session: Dictionary) -> void:
	for u in session.get("units", []):
		if int(u.get("health", 0)) <= 0:
			u["pose"] = "down"
			continue
		if not _unit_active(u):
			continue
		if not unit_adjacent_cover(session, u).is_empty():
			u["pose"] = "crouch"
		else:
			u["pose"] = "ready"


func _check_resolution(session: Dictionary) -> void:
	if bool(session.get("resolved", false)):
		return
	var active_enemies := 0
	var active_players := 0
	var retreated_players := 0
	var living_players := 0
	for u in session.get("units", []):
		var team := String(u.get("team", ""))
		if team == "enemy" and _unit_active(u):
			active_enemies += 1
		elif team == "player":
			if int(u.get("health", 0)) > 0:
				living_players += 1
			if bool(u.get("retreated", false)):
				retreated_players += 1
			elif _unit_active(u):
				active_players += 1

	if active_enemies == 0:
		session["resolved"] = true
		session["active"] = false
		session["outcome"] = "victory"
		session["outcome_summary"] = "The defenders are down or yielded. The ground is yours."
		_append_log(session, session["outcome_summary"])
	elif active_players == 0:
		session["resolved"] = true
		session["active"] = false
		if retreated_players > 0 and living_players > 0:
			session["outcome"] = "retreated"
			session["outcome_summary"] = "Your party broke contact and fell back to the trail."
			_append_log(session, session["outcome_summary"])
		else:
			session["outcome"] = "defeat"
			session["outcome_summary"] = "Your gun hands are down in the smoke."
			_append_log(session, session["outcome_summary"])


## Wound band from current health: 0 light, 1 serious, 2 critical, 3+ mortal (one more per mortal step).
func wound_penalty(unit: Dictionary) -> int:
	var cfg: Dictionary = rules.get("saves", {})
	var hp := int(unit.get("health", 100))
	var start := int(unit.get("start_health", 100))
	if hp >= start:
		return 0
	var mortal_below := int(cfg.get("mortal_below", 25))
	if hp < mortal_below:
		var step := maxi(1, int(cfg.get("mortal_step", 5)))
		return 3 + (mortal_below - 1 - hp) / step
	if hp < int(cfg.get("critical_below", 50)):
		return 2
	if hp < int(cfg.get("serious_below", 75)):
		return 1
	return 0


func body_save(unit: Dictionary) -> int:
	var cfg: Dictionary = rules.get("saves", {})
	return int(unit.get("body", cfg.get("soldier_body", 7) if bool(unit.get("soldier", false)) else cfg.get("body", 6))) + int(unit.get("body_bonus", 0))


## Combat experience steadies a traveler: the party's won fights by step, and a Veteran's own service.
func _body_bonus(member: Dictionary, wins: int, leader_veteran: bool = false) -> int:
	var cfg: Dictionary = rules.get("saves", {})
	var bonus := 0
	for step in cfg.get("experience_steps", []):
		if wins >= int(step):
			bonus += 1
	var profile = member.get("profile", {})
	# A Soldier leader's service counts like a Veteran companion's (party slot 0 is the leader).
	if (profile is Dictionary and ("Veteran" in profile.get("specials", []) or profile.get("skill", "") == "Soldiering")) or (leader_veteran and int(member.get("slot", -1)) == 0):
		bonus += int(cfg.get("veteran_bonus", 0))
	return bonus


## Trained shots aim better: a Soldiering traveler like a soldier, a Hunting one (or a
## Sharpshooter) about half as much. Slot 0 is the leader, whose profession gives the background.
func _trained_aim(member: Dictionary, leader_background: String = "") -> String:
	var profile = member.get("profile", {})
	var skill := leader_background if int(member.get("slot", -1)) == 0 else (String(profile.get("skill", "")) if profile is Dictionary else "")
	if skill == "Soldiering":
		return "soldier"
	if skill == "Hunting" or (profile is Dictionary and "Sharpshooter" in profile.get("specials", [])):
		return "hunter"
	return ""


func is_mortal(unit: Dictionary) -> bool:
	return int(unit.get("health", 0)) > 0 and int(unit.get("health", 0)) < int(rules.get("saves", {}).get("mortal_below", 25))


## Stun/shock save after a hit: d10 at or under Body minus the wound penalty keeps a fighter on their feet.
func _stun_save(session: Dictionary, unit: Dictionary) -> bool:
	var need := body_save(unit) - wound_penalty(unit)
	var roll := rng.randi_range(1, 10)
	if roll <= need:
		return true
	unit["stunned"] = true
	unit["pose"] = "down"
	unit["ap"] = 0
	unit["times_stunned"] = int(unit.get("times_stunned", 0)) + 1
	_append_log(session, "%s fails a stun save (rolled %d, needed %d or less) and goes down senseless!" % [String(unit.get("name", "Fighter")), roll, need])
	return false


## At the start of a fighter's turn: a mortal wound demands a death save, and a stunned fighter tries to come round.
## Returns false when the fighter cannot act this turn.
func _turn_start_saves(session: Dictionary, unit: Dictionary) -> bool:
	if int(unit.get("health", 0)) <= 0 or bool(unit.get("retreated", false)) or bool(unit.get("yielded", false)) or bool(unit.get("surrendered", false)):
		return true
	if is_mortal(unit):
		var mortal_level := wound_penalty(unit) - 3
		var need := body_save(unit) - mortal_level
		var roll := rng.randi_range(1, 10)
		if roll > need:
			unit["health"] = 0
			unit["stunned"] = false
			unit["pose"] = "down"
			unit["died_of_wounds"] = true
			_append_log(session, "%s fails a death save (rolled %d, needed %d or less) and dies of their wounds." % [String(unit.get("name", "Fighter")), roll, need])
			return false
		_append_log(session, "%s holds on through a mortal wound (death save %d, needed %d or less)." % [String(unit.get("name", "Fighter")), roll, need])
	if bool(unit.get("stunned", false)):
		var need := body_save(unit) - wound_penalty(unit)
		var roll := rng.randi_range(1, 10)
		if roll <= need:
			unit["stunned"] = false
			unit["pose"] = "crouch"
			_append_log(session, "%s comes round (rolled %d) but spends the turn getting up." % [String(unit.get("name", "Fighter")), roll])
		else:
			_append_log(session, "%s is still senseless." % String(unit.get("name", "Fighter")))
		return false
	return true


func _living_player_units(session: Dictionary) -> Array:
	var out: Array = []
	for u in session.get("units", []):
		if String(u.get("team", "")) == "player" and _unit_active(u):
			out.append(u)
	return out


func _first_ready_player_id(units: Array) -> String:
	for u in units:
		if String(u.get("team", "")) == "player" and _unit_active(u) and int(u.get("ap", 0)) > 0:
			return String(u.get("id", ""))
	for u in units:
		if String(u.get("team", "")) == "player" and _unit_active(u):
			return String(u.get("id", ""))
	return ""


func _unit_active(u: Dictionary) -> bool:
	return int(u.get("health", 0)) > 0 and not bool(u.get("stunned", false)) and not bool(u.get("retreated", false)) and not bool(u.get("yielded", false)) and not bool(u.get("surrendered", false))


func _append_log(session: Dictionary, line: String) -> void:
	if line.is_empty():
		return
	var log_arr: Array = session.get("log", [])
	log_arr.append(line)
	while log_arr.size() > 24:
		log_arr.pop_front()
	session["log"] = log_arr


func _pick_open_spawn(spawns: Array, idx: int, fallback: Vector2i, width: int, height: int, props: Array, units: Array) -> Vector2i:
	if idx < spawns.size() and spawns[idx] is Array and spawns[idx].size() >= 2:
		var cand := Vector2i(int(spawns[idx][0]), int(spawns[idx][1]))
		if _spawn_free(cand, width, height, props, units):
			return cand
	for raw in spawns:
		if raw is Array and raw.size() >= 2:
			var cand := Vector2i(int(raw[0]), int(raw[1]))
			if _spawn_free(cand, width, height, props, units):
				return cand
	for r in range(1, 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var cand := Vector2i(fallback.x + dx, fallback.y + dy)
				if _spawn_free(cand, width, height, props, units):
					return cand
	return fallback


func _spawn_free(c: Vector2i, width: int, height: int, props: Array, units: Array) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= width or c.y >= height:
		return false
	for p in props:
		var px := int(p.get("x", -1))
		var py := int(p.get("y", -1))
		var pw := maxi(1, int(p.get("w", 1)))
		var ph := maxi(1, int(p.get("h", 1)))
		if c.x >= px and c.x < px + pw and c.y >= py and c.y < py + ph:
			return false
	for u in units:
		if int(u.get("x", -1)) == c.x and int(u.get("y", -1)) == c.y:
			return false
	return true


func _coord_in_list(x: int, y: int, coords: Array) -> bool:
	for c in coords:
		if c is Array and c.size() >= 2 and int(c[0]) == x and int(c[1]) == y:
			return true
		elif c is Vector2i and c.x == x and c.y == y:
			return true
	return false


func _bresenham(x0: int, y0: int, x1: int, y1: int) -> Array[Vector2i]:
	var pts: Array[Vector2i] = []
	var dx := absi(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy := -absi(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var cx := x0
	var cy := y0
	while true:
		pts.append(Vector2i(cx, cy))
		if cx == x1 and cy == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			cx += sx
		if e2 <= dx:
			err += dx
			cy += sy
	return pts
