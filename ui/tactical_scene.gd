extends Control

signal tile_clicked(grid_pos: Vector2i)
signal unit_clicked(unit_id: String)
signal hover_changed(grid_pos: Vector2i)

const Palette = preload("res://ui/traveler_palette.gd")
const PIXEL_FONT: Font = preload("res://art/pixels/trail_font.fnt")

const CELL_PX := 32
const HALF_W := 14.0
const HALF_H := 7.0
const ZOOM_MIN := 1.0
const ZOOM_MAX := 2.5
const ZOOM_STEP := 0.25

var tiles_tex: Texture2D = load("res://art/pixels/tactical_tiles.png")
var cover_tex: Texture2D = load("res://art/pixels/tactical_cover.png")
var units_tex: Texture2D = load("res://art/pixels/tactical_units.png")
var wagon_tex: Texture2D = load("res://art/pixels/cross_wagon.png")

var combat = null
var session: Dictionary = {}
var reachable: Dictionary = {}
var hover_cell := Vector2i(-1, -1)

var zoom_level: float = 1.5
var cam_pan: Vector2 = Vector2.ZERO
var is_panning: bool = false

var pulse_time: float = 0.0
var active_fx: Dictionary = {}
var pending_fx: Array = []
var fx_timer: float = 0.0
var fx_duration: float = 0.4
var banner_text: String = ""
var banner_timer: float = 0.0
var float_texts: Array = []
var smoke_puffs: Array = []
var highlight_unit_id: String = ""


func _ready() -> void:
	custom_minimum_size = Vector2(528, 244)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(true)


func bind(combat_ref, session_data: Dictionary) -> void:
	combat = combat_ref
	session = session_data
	pending_fx.clear()
	active_fx = {}
	smoke_puffs.clear()
	highlight_unit_id = ""
	banner_text = ""
	banner_timer = 0.0
	zoom_level = 1.5
	cam_pan = Vector2.ZERO
	_refresh_reachable()
	queue_redraw()


func refresh() -> void:
	_refresh_reachable()
	queue_redraw()


func adjust_zoom(delta_zoom: float, pivot: Vector2 = Vector2(-1, -1)) -> void:
	var old_zoom := zoom_level
	zoom_level = clampf(snappedf(zoom_level + delta_zoom, 0.05), ZOOM_MIN, ZOOM_MAX)
	if absf(zoom_level - old_zoom) < 0.001:
		return
	if pivot.x >= 0.0 and pivot.y >= 0.0:
		var center := size * 0.5
		var rel := pivot - center - cam_pan
		cam_pan -= rel * ((zoom_level / old_zoom) - 1.0)
	_clamp_pan()
	queue_redraw()


func center_on_unit(unit_id: String) -> void:
	if combat == null or session.is_empty():
		return
	var u: Dictionary = combat.get_unit(session, unit_id)
	if u.is_empty():
		return
	var gx := int(u.get("x", 0))
	var gy := int(u.get("y", 0))
	var w := int(session.get("width", 12))
	var h := int(session.get("height", 10))
	var mid_x := (w - 1) * 0.5
	var mid_y := (h - 1) * 0.5
	var dx := (float(gx - gy) - (mid_x - mid_y)) * HALF_W * zoom_level
	var dy := (float(gx + gy) - (mid_x + mid_y)) * HALF_H * zoom_level
	cam_pan = Vector2(-dx * 0.55, -dy * 0.55)
	_clamp_pan()
	queue_redraw()


func reset_camera() -> void:
	zoom_level = 1.5
	cam_pan = Vector2.ZERO
	queue_redraw()


func _clamp_pan() -> void:
	var max_x := 160.0 * zoom_level
	var max_y := 95.0 * zoom_level
	cam_pan.x = clampf(cam_pan.x, -max_x, max_x)
	cam_pan.y = clampf(cam_pan.y, -max_y, max_y)


func play_fx_queue(queue_items: Array) -> void:
	if queue_items.is_empty():
		return
	for item in queue_items:
		if item is Dictionary and not item.is_empty():
			pending_fx.append(item.duplicate(true))
	if active_fx.is_empty() and not pending_fx.is_empty():
		_start_next_fx()


func trigger_fx(fx: Dictionary) -> void:
	if fx.is_empty():
		return
	play_fx_queue([fx])


func _start_next_fx() -> void:
	if pending_fx.is_empty():
		active_fx = {}
		fx_timer = 0.0
		fx_duration = 0.4
		return
	active_fx = pending_fx.pop_front()
	var kind := String(active_fx.get("type", ""))
	if kind == "move":
		var path_pts: Array = active_fx.get("path", [])
		fx_duration = maxf(0.30, float(maxi(1, path_pts.size() - 1)) * 0.16)
	elif kind in ["shot", "club"]:
		fx_duration = 0.72
	elif kind == "reload":
		fx_duration = 0.55
	else:
		fx_duration = 0.38
	fx_timer = fx_duration
	var b := String(active_fx.get("banner", ""))
	if not b.is_empty():
		banner_text = b.to_upper()
		banner_timer = 2.6
	if kind in ["shot", "club"]:
		var from_cell: Vector2i = active_fx.get("from", Vector2i(0, 0))
		var to_cell: Vector2i = active_fx.get("to", Vector2i(0, 0))
		if kind == "shot":
			smoke_puffs.append({
				"grid": from_cell,
				"drift": Vector2(-3.0, -8.0),
				"ttl": 1.6,
				"max_ttl": 1.6,
			})
		var pos := _grid_to_screen(to_cell.x, to_cell.y) + Vector2(-14, -24 * zoom_level)
		var text := "MISS!"
		var col := Color("dfd5c0")
		if bool(active_fx.get("hit", false)):
			var dmg := int(active_fx.get("damage", 0))
			var note := String(active_fx.get("status_note", ""))
			text = "-%d HP %s" % [dmg, note.to_upper()]
			col = Color("ff6b5e")
		float_texts.append({"pos": pos, "text": text.strip_edges(), "color": col, "ttl": 1.45})
	elif kind == "reload":
		var rpos: Vector2i = active_fx.get("pos", Vector2i(0, 0))
		var pos := _grid_to_screen(rpos.x, rpos.y) + Vector2(-14, -24 * zoom_level)
		float_texts.append({"pos": pos, "text": "RELOADED", "color": Color("f0c259"), "ttl": 1.1})
	queue_redraw()


func _process(delta: float) -> void:
	pulse_time += delta * 4.5
	var dirty := visible
	if fx_timer > 0.0:
		fx_timer = maxf(0.0, fx_timer - delta)
		if fx_timer <= 0.0:
			if not pending_fx.is_empty():
				_start_next_fx()
			else:
				active_fx = {}
		dirty = true
	if banner_timer > 0.0:
		banner_timer = maxf(0.0, banner_timer - delta)
		if banner_timer <= 0.0:
			banner_text = ""
		dirty = true
	for i in range(float_texts.size() - 1, -1, -1):
		var item: Dictionary = float_texts[i]
		item["ttl"] = float(item.get("ttl", 0.0)) - delta
		item["pos"] = Vector2(item.get("pos", Vector2.ZERO)) + Vector2(0, -14.0 * delta)
		if float(item["ttl"]) <= 0.0:
			float_texts.remove_at(i)
		dirty = true
	for i in range(smoke_puffs.size() - 1, -1, -1):
		var sp: Dictionary = smoke_puffs[i]
		sp["ttl"] = float(sp.get("ttl", 0.0)) - delta
		sp["drift"] = Vector2(sp.get("drift", Vector2.ZERO)) + Vector2(-4.5 * delta, -9.0 * delta)
		if float(sp["ttl"]) <= 0.0:
			smoke_puffs.remove_at(i)
		dirty = true
	if dirty:
		queue_redraw()


func _unit_anim_state(u: Dictionary) -> Dictionary:
	var uid := String(u.get("id", ""))
	var gx := int(u.get("x", 0))
	var gy := int(u.get("y", 0))
	var sc := _grid_to_screen(gx, gy)
	var depth := float(gx + gy)
	var pose := String(u.get("pose", "ready"))
	var facing := String(u.get("facing", "sw"))
	var tint := Color.WHITE
	var hp := int(u.get("health", 0))

	if not active_fx.is_empty() and fx_duration > 0.0:
		var prog := clampf(1.0 - (fx_timer / fx_duration), 0.0, 1.0)
		var kind := String(active_fx.get("type", ""))
		if kind == "move" and String(active_fx.get("unit_id", "")) == uid:
			var path_pts: Array = active_fx.get("path", [])
			if path_pts.size() >= 2:
				var segs := path_pts.size() - 1
				var scaled := prog * float(segs)
				var idx := mini(int(floor(scaled)), segs - 1)
				var seg_t := scaled - float(idx)
				var c0: Vector2i = path_pts[idx]
				var c1: Vector2i = path_pts[idx + 1]
				var p0 := _grid_to_screen(c0.x, c0.y)
				var p1 := _grid_to_screen(c1.x, c1.y)
				var hop := -absf(sin(seg_t * PI)) * 3.0 * zoom_level
				sc = p0.lerp(p1, seg_t) + Vector2(0, hop)
				depth = lerpf(float(c0.x + c0.y), float(c1.x + c1.y), seg_t)
				facing = "ne" if (c1.x - c0.x) < (c1.y - c0.y) else "sw"
				pose = "aim" if (int(floor(seg_t * 2.0)) + idx) % 2 == 1 else "ready"
			else:
				var c0: Vector2i = active_fx.get("from", Vector2i(gx, gy))
				var c1: Vector2i = active_fx.get("to", Vector2i(gx, gy))
				var p0 := _grid_to_screen(c0.x, c0.y)
				var p1 := _grid_to_screen(c1.x, c1.y)
				var hop := -absf(sin(prog * PI)) * 3.0 * zoom_level
				sc = p0.lerp(p1, prog) + Vector2(0, hop)
				depth = lerpf(float(c0.x + c0.y), float(c1.x + c1.y), prog)
		elif kind in ["shot", "club"]:
			var from_c: Vector2i = active_fx.get("from", Vector2i(gx, gy))
			var to_c: Vector2i = active_fx.get("to", Vector2i(gx, gy))
			var dir_vec := (_grid_to_screen(to_c.x, to_c.y) - _grid_to_screen(from_c.x, from_c.y)).normalized()
			if String(active_fx.get("attacker_id", "")) == uid:
				if prog < 0.28:
					pose = "aim"
					sc += dir_vec * (1.2 * zoom_level * (prog / 0.28))
				else:
					pose = "fire"
					var kick := clampf(1.0 - ((prog - 0.28) / 0.52), 0.0, 1.0)
					sc -= dir_vec * (3.2 * zoom_level * kick)
			elif String(active_fx.get("target_id", "")) == uid and prog >= 0.34:
				var hit_t := clampf((prog - 0.34) / 0.50, 0.0, 1.0)
				if bool(active_fx.get("hit", false)):
					sc += dir_vec * (3.5 * zoom_level * sin(hit_t * PI))
					tint = Color(1.6, 0.72, 0.68, 1.0)
					if hp > 0:
						pose = "crouch"
				elif hp > 0:
					pose = "crouch"
		elif kind == "reload" and String(active_fx.get("unit_id", "")) == uid:
			pose = "reload"
			sc += Vector2(0, sin(prog * PI * 4.0) * 1.5 * zoom_level)
	elif hp > 0 and not bool(u.get("yielded", false)):
		var phase := float(uid.hash() % 13) * 0.5
		sc += Vector2(0, roundf(sin(pulse_time * 0.55 + phase) * 0.5))

	return {
		"screen_pos": sc,
		"depth": depth,
		"pose": pose,
		"facing": facing,
		"tint": tint,
	}


func _refresh_reachable() -> void:
	reachable = {}
	if combat == null or session.is_empty() or bool(session.get("resolved", false)):
		return
	if not bool(session.get("started", false)):
		reachable = combat.deployment_tiles(session)
		return
	if String(session.get("turn", "")) != "player":
		return
	var sel_id := String(session.get("selected_id", ""))
	if not sel_id.is_empty():
		reachable = combat.reachable_tiles(session, sel_id)


func _eff_half_w() -> float:
	return HALF_W * zoom_level


func _eff_half_h() -> float:
	return HALF_H * zoom_level


func _eff_draw_size() -> Vector2:
	return Vector2(CELL_PX * zoom_level, CELL_PX * zoom_level)


func _origin() -> Vector2:
	var w := int(session.get("width", 12))
	var h := int(session.get("height", 10))
	var mid_x := (w - 1) * 0.5
	var mid_y := (h - 1) * 0.5
	var hw := _eff_half_w()
	var hh := _eff_half_h()
	var center_offset_x := (mid_x - mid_y) * hw
	var center_offset_y := (mid_x + mid_y) * hh
	return Vector2(roundf(size.x * 0.5 - center_offset_x + cam_pan.x), roundf(size.y * 0.54 - center_offset_y + cam_pan.y))


func _grid_to_screen(gx: int, gy: int) -> Vector2:
	var o := _origin()
	return Vector2(
		o.x + float(gx - gy) * _eff_half_w(),
		o.y + float(gx + gy) * _eff_half_h()
	)


func _screen_to_grid(p: Vector2) -> Vector2i:
	var rel := p - _origin()
	var a := rel.x / _eff_half_w()
	var b := rel.y / _eff_half_h()
	var gx := roundi(0.5 * (a + b))
	var gy := roundi(0.5 * (b - a))
	return Vector2i(gx, gy)


func _in_bounds(c: Vector2i) -> bool:
	var w := int(session.get("width", 12))
	var h := int(session.get("height", 10))
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h


func _tile_offers_cover(gx: int, gy: int) -> bool:
	if combat == null or session.is_empty():
		return false
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var p: Dictionary = combat.prop_at(session, gx + dir.x, gy + dir.y)
		if int(p.get("cover", 0)) > 0:
			return true
	return false


func _gui_input(event: InputEvent) -> void:
	if session.is_empty():
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			adjust_zoom(ZOOM_STEP, event.position)
			accept_event()
			return
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			adjust_zoom(-ZOOM_STEP, event.position)
			accept_event()
			return
		elif event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			is_panning = event.pressed
			accept_event()
			return
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var cell := _screen_to_grid(event.position)
			if not _in_bounds(cell):
				return
			var occ: Dictionary = combat.unit_at(session, cell.x, cell.y) if combat != null else {}
			if not occ.is_empty():
				unit_clicked.emit(String(occ.get("id", "")))
			else:
				tile_clicked.emit(cell)
	elif event is InputEventMouseMotion:
		if is_panning:
			cam_pan += event.relative
			_clamp_pan()
			queue_redraw()
			return
		var cell := _screen_to_grid(event.position)
		if not _in_bounds(cell):
			cell = Vector2i(-1, -1)
		if cell != hover_cell:
			hover_cell = cell
			hover_changed.emit(hover_cell)
			queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("191410"), true)
	draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color("5c4938"), false, 1.0)
	if session.is_empty() or combat == null:
		return

	var w := int(session.get("width", 12))
	var h := int(session.get("height", 10))
	var tiles: Array = session.get("tiles", [])
	var sel_id := String(session.get("selected_id", ""))

	# 1. Ground diamonds in isometric depth order + cover shield pips on reachable cover tiles.
	for sum_xy in range(w + h - 1):
		for gx in range(w):
			var gy := sum_xy - gx
			if gy < 0 or gy >= h:
				continue
			var t_idx := 0
			if gy < tiles.size() and gx < tiles[gy].size():
				t_idx = clampi(int(tiles[gy][gx]), 0, 4)
			var sc := _grid_to_screen(gx, gy)
			_draw_tile_cell(t_idx, sc, Color.WHITE)

			var cell := Vector2i(gx, gy)
			if reachable.has(cell):
				var started := bool(session.get("started", false))
				var tile_tint := Color(0.95, 0.82, 0.42, 0.42) if started else Color(0.38, 0.78, 0.96, 0.36)
				_draw_tile_cell(5, sc, tile_tint)
				if _tile_offers_cover(gx, gy):
					_draw_shield_pip(sc + Vector2(-2, -2), Color("67b6d6"))

	# 2. Hovered path or LoS line on the ground plane (+ preview sightlines from hovered move/deploy tiles!).
	var hover_unit: Dictionary = combat.unit_at(session, hover_cell.x, hover_cell.y) if _in_bounds(hover_cell) else {}
	var hover_preview: Dictionary = {}
	var tile_sight_count: int = 0
	var tile_best_pct: int = 0
	if not sel_id.is_empty() and _in_bounds(hover_cell):
		if not hover_unit.is_empty() and String(hover_unit.get("team", "")) == "enemy":
			hover_preview = combat.shot_preview(
				session,
				sel_id,
				String(hover_unit.get("id", "")),
				String(session.get("fire_mode", "snap")),
				String(session.get("called_part", "torso"))
			)
			var sel_u_aim: Dictionary = combat.get_unit(session, sel_id)
			var p0 := _grid_to_screen(int(sel_u_aim.get("x", 0)), int(sel_u_aim.get("y", 0)))
			var p1 := _grid_to_screen(hover_cell.x, hover_cell.y)
			var can_shoot_now := bool(hover_preview.get("can_shoot", false))
			var line_col := Color("f0c259") if can_shoot_now else Color("d15446")
			var blocker: Vector2i = hover_preview.get("blocker", Vector2i(-1, -1))
			if blocker.x >= 0 and blocker.y >= 0:
				var b_sc := _grid_to_screen(blocker.x, blocker.y)
				var seg := p1 - p0
				var seg_len_sq := seg.length_squared()
				var stop_pt := b_sc
				if seg_len_sq > 1.0:
					var t_proj := clampf((b_sc - p0).dot(seg) / seg_len_sq, 0.15, 0.85)
					stop_pt = p0 + seg * t_proj
				draw_line(p0, stop_pt, Color("f0c259"), 1.6)
				draw_line(stop_pt, p1, Color(0.82, 0.33, 0.27, 0.55), 1.4)
				draw_line(stop_pt + Vector2(-3, -3), stop_pt + Vector2(3, 3), Color("ff6b5e"), 1.8)
				draw_line(stop_pt + Vector2(-3, 3), stop_pt + Vector2(3, -3), Color("ff6b5e"), 1.8)
			else:
				draw_line(p0, p1, line_col, 1.8)
			_draw_foot_circle(p1, 11.0 * zoom_level, 5.5 * zoom_level, line_col, 2.0, true)
		elif reachable.has(hover_cell):
			var pinfo: Dictionary = reachable[hover_cell]
			var path: Array = pinfo.get("path", [])
			var move_ap := int(pinfo.get("ap_cost", 0))
			var sel_u: Dictionary = combat.get_unit(session, sel_id)
			var prev_pt := _grid_to_screen(int(sel_u.get("x", 0)), int(sel_u.get("y", 0)))
			for step_cell in path:
				var next_pt := _grid_to_screen(step_cell.x, step_cell.y)
				draw_line(prev_pt, next_pt, Color("f0c259"), 1.5)
				draw_rect(Rect2(next_pt - Vector2(1.5, 1.5), Vector2(3, 3)), Color("f6e7c1"), true)
				prev_pt = next_pt
			var h_sc := _grid_to_screen(hover_cell.x, hover_cell.y)
			_draw_foot_circle(h_sc, 9.0 * zoom_level, 4.5 * zoom_level, Color("f6e7c1"), 1.5, false)

			# Draw preview sightlines from this candidate move/deploy tile to all enemies in LoS!
			var mode_str := String(session.get("fire_mode", "snap"))
			var part_str := String(session.get("called_part", "torso"))
			for eu in session.get("units", []):
				if String(eu.get("team", "")) != "enemy" or int(eu.get("health", 0)) <= 0 or bool(eu.get("yielded", false)):
					continue
				var eid := String(eu.get("id", ""))
				var sprev: Dictionary = combat.shot_preview_at(
					session,
					sel_id,
					hover_cell.x,
					hover_cell.y,
					eid,
					mode_str,
					part_str,
					move_ap
				)
				if bool(sprev.get("los_clear", false)):
					tile_sight_count += 1
					var spct := int(round(float(sprev.get("hit_chance", 0.0)) * 100.0))
					if spct > tile_best_pct:
						tile_best_pct = spct
					var e_sc := _grid_to_screen(int(eu.get("x", 0)), int(eu.get("y", 0)))
					var s_col := Color(0.45, 0.88, 1.0, 0.58) if bool(sprev.get("can_shoot", false)) else Color(0.95, 0.78, 0.38, 0.38)
					draw_line(h_sc, e_sc, s_col, 1.2)

	# 3. Foot rings under all living units, with a bright pulsing double circle under the SELECTED / ACTING unit!
	var fx_actor_id := String(active_fx.get("unit_id", active_fx.get("attacker_id", "")))
	for u in session.get("units", []):
		if int(u.get("health", 0)) <= 0 or bool(u.get("retreated", false)):
			continue
		var uid := String(u.get("id", ""))
		var anim: Dictionary = _unit_anim_state(u)
		var usc: Vector2 = Vector2(anim.get("screen_pos", Vector2.ZERO)) + Vector2(0, 1.0 * zoom_level)
		if not highlight_unit_id.is_empty() and uid == highlight_unit_id:
			var rx := 11.5 * zoom_level
			var ry := 5.8 * zoom_level
			_draw_foot_circle(usc, rx, ry, Color(0.45, 0.88, 1.0, 0.30), 1.0, true)
			_draw_foot_circle(usc, rx, ry, Color("7ce8ff"), 2.0, false)
		elif not fx_actor_id.is_empty() and uid == fx_actor_id and String(u.get("team", "")) == "enemy":
			var pulse := 0.5 + 0.5 * sin(pulse_time)
			var rx := (10.5 + pulse * 1.5) * zoom_level
			var ry := (5.2 + pulse * 0.8) * zoom_level
			_draw_foot_circle(usc, rx, ry, Color(0.95, 0.35, 0.25, 0.30), 1.0, true)
			_draw_foot_circle(usc, rx, ry, Color("ff6b5e"), 2.0, false)
			_draw_foot_circle(usc, rx * 0.72, ry * 0.72, Color("f7e479"), 1.2, false)
		elif uid == sel_id:
			var pulse := 0.5 + 0.5 * sin(pulse_time)
			var rx := (10.5 + pulse * 1.5) * zoom_level
			var ry := (5.2 + pulse * 0.8) * zoom_level
			_draw_foot_circle(usc, rx, ry, Color(0.35, 0.95, 0.45, 0.28), 1.0, true)
			_draw_foot_circle(usc, rx, ry, Color("7bf28c"), 2.0, false)
			_draw_foot_circle(usc, rx * 0.72, ry * 0.72, Color("f7e479"), 1.2, false)
		elif String(u.get("team", "")) == "player":
			_draw_foot_circle(usc, 8.0 * zoom_level, 4.0 * zoom_level, Color(0.35, 0.72, 0.62, 0.65), 1.2, false)
		else:
			_draw_foot_circle(usc, 8.5 * zoom_level, 4.2 * zoom_level, Color(0.88, 0.32, 0.26, 0.80), 1.5, false)

	# 4. Downed bodies first so living units and props stand above them.
	for u in session.get("units", []):
		if int(u.get("health", 0)) <= 0:
			_draw_unit(u, sel_id, hover_unit)

	# 5. Depth-sorted cover props and living units (using animated unit depth during movement!).
	var drawables: Array = []
	for p in session.get("props", []):
		var px := int(p.get("x", 0))
		var py := int(p.get("y", 0))
		var pw := maxi(1, int(p.get("w", 1)))
		var ph := maxi(1, int(p.get("h", 1)))
		drawables.append({
			"kind": "prop",
			"depth": float(px + pw - 1 + py + ph - 1) * 10.0 + 4.0,
			"data": p,
		})
	for u in session.get("units", []):
		if int(u.get("health", 0)) > 0 and not bool(u.get("retreated", false)):
			var anim: Dictionary = _unit_anim_state(u)
			drawables.append({
				"kind": "unit",
				"depth": float(anim.get("depth", 0.0)) * 10.0 + 6.0,
				"data": u,
			})
	drawables.sort_custom(func(a, b): return float(a["depth"]) < float(b["depth"]))
	for item in drawables:
		if item["kind"] == "prop":
			_draw_prop(item["data"])
		else:
			_draw_unit(item["data"], sel_id, hover_unit)

	# 6. Active muzzle smoke / shot tracer FX + lingering drifting black-powder smoke puffs.
	if not active_fx.is_empty():
		_draw_fx(active_fx)
	_draw_smoke_puffs()

	# 7. Top Tactical Status / Hover / Action Banner & Bottom Legend Bar.
	_draw_top_banner(hover_unit, hover_preview, tile_sight_count, tile_best_pct)
	_draw_bottom_legend()

	# 8. Floating combat text.
	for ft in float_texts:
		var fpos: Vector2 = ft.get("pos", Vector2.ZERO)
		var ftxt := String(ft.get("text", ""))
		var fcol: Color = ft.get("color", Color.WHITE)
		draw_string(PIXEL_FONT, fpos + Vector2(1, 1), ftxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.BLACK)
		draw_string(PIXEL_FONT, fpos, ftxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, fcol)


func _draw_foot_circle(center: Vector2, rx: float, ry: float, col: Color, width: float = 1.5, filled: bool = false) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps + 1):
		var ang := float(i) * TAU / float(steps)
		pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	if filled:
		draw_colored_polygon(pts.slice(0, steps), col)
	else:
		draw_polyline(pts, col, width)


func _draw_shield_pip(pos: Vector2, col: Color) -> void:
	draw_rect(Rect2(pos, Vector2(5, 5)), Color("14100d"), true)
	draw_rect(Rect2(pos + Vector2(1, 1), Vector2(3, 3)), col, true)


func _draw_tile_cell(col_idx: int, screen_center: Vector2, modulate_col: Color) -> void:
	if tiles_tex == null:
		return
	var dsize := _eff_draw_size()
	var src := Rect2(col_idx * CELL_PX, 0, CELL_PX, CELL_PX)
	var dst := Rect2(screen_center - dsize * 0.5, dsize)
	draw_texture_rect_region(tiles_tex, dst, src, modulate_col)


func _draw_prop(p: Dictionary) -> void:
	if cover_tex == null:
		return
	var dsize := _eff_draw_size()
	var gx := int(p.get("x", 0))
	var gy := int(p.get("y", 0))
	var pw := maxi(1, int(p.get("w", 1)))
	var ph := maxi(1, int(p.get("h", 1)))
	var is_full := int(p.get("cover", 1)) >= 2
	var row := 1 if is_full else 0
	var col := clampi(int(p.get("prop", 0)), 0, 5)
	var src := Rect2(col * CELL_PX, row * CELL_PX, CELL_PX, CELL_PX)

	if pw > 1 or ph > 1:
		var p0 := _grid_to_screen(gx, gy)
		var p1 := _grid_to_screen(gx + pw - 1, gy + ph - 1)
		var mid := (p0 + p1) * 0.5
		var wsize := dsize * 1.45
		var dst := Rect2(mid - Vector2(wsize.x * 0.5, wsize.y * 0.68), wsize)
		draw_texture_rect_region(cover_tex, dst, src, Color.WHITE)
	else:
		var sc := _grid_to_screen(gx, gy)
		var dst := Rect2(sc - Vector2(dsize.x * 0.5, dsize.y * 0.66), dsize)
		draw_texture_rect_region(cover_tex, dst, src, Color.WHITE)


func _draw_unit(u: Dictionary, sel_id: String, hover_unit: Dictionary) -> void:
	if units_tex == null:
		return
	var dsize := _eff_draw_size()
	var anim: Dictionary = _unit_anim_state(u)
	var sc: Vector2 = Vector2(anim.get("screen_pos", Vector2.ZERO))
	var tex: Texture2D = units_tex
	if not bool(u.get("soldier", false)):
		tex = Palette.texture(units_tex, u.get("profile", {}))

	var row := 0
	if bool(u.get("soldier", false)):
		row = 2
	elif String(anim.get("facing", "sw")) == "sw":
		row = 1
	else:
		row = 0

	var pose := String(anim.get("pose", "ready"))
	var col := 0
	if int(u.get("health", 0)) <= 0 or pose == "down":
		col = 5
		row = 0 if String(u.get("team", "")) == "player" else 1
	elif pose == "aim":
		col = 1
	elif pose == "fire":
		col = 2
	elif pose == "reload":
		col = 3
	elif pose == "crouch":
		col = 4
	else:
		col = 0

	var uid := String(u.get("id", ""))
	var is_selected := (uid == sel_id)
	var src := Rect2(col * CELL_PX, row * CELL_PX, CELL_PX, CELL_PX)
	var dst := Rect2(sc - Vector2(dsize.x * 0.5, dsize.y * 0.72), dsize)
	var tint: Color = Color(anim.get("tint", Color.WHITE))
	if bool(u.get("yielded", false)):
		tint = Color(0.75, 0.75, 0.75, 0.75)
	elif is_selected and tint == Color.WHITE:
		tint = Color(1.18, 1.18, 1.06, 1.0)
	draw_texture_rect_region(tex, dst, src, tint)

	if int(u.get("health", 0)) <= 0:
		return

	var is_player := String(u.get("team", "")) == "player"
	var is_hovered := (not hover_unit.is_empty() and String(hover_unit.get("id", "")) == uid) or (uid == highlight_unit_id)
	var cov_dict: Dictionary = combat.unit_adjacent_cover(session, u)
	var in_cov: bool = not cov_dict.is_empty()

	# Overhead HP bar, cover shield icon on left, brass loaded dot on right.
	var bar_w := roundf(18.0 * clampf(zoom_level * 0.8, 1.0, 1.5))
	var bar_h := 3.0
	var bar_pos := (sc + Vector2(-bar_w * 0.5, -20.0 * zoom_level)).round()
	if in_cov:
		_draw_shield_pip(bar_pos + Vector2(-6.0, -1.0), Color("67b6d6"))

	draw_rect(Rect2(bar_pos - Vector2(1, 1), Vector2(bar_w + 2, bar_h + 2)), Color("14100d"), true)
	var hp_ratio := clampf(float(u.get("health", 100)) / 100.0, 0.0, 1.0)
	var team_col := Color("58b86c") if is_player else Color("d15446")
	draw_rect(Rect2(bar_pos, Vector2(roundf(bar_w * hp_ratio), bar_h)), team_col, true)

	var cap_rect := Rect2(bar_pos + Vector2(bar_w + 2.0, 0.0), Vector2(3.0, 3.0))
	if bool(u.get("loaded", false)):
		draw_rect(cap_rect, Color("f0c259"), true)
	else:
		draw_rect(cap_rect, Color("4a4035"), false, 1.0)

	# Selected unit gets a bobbing golden chevron pointer above their head!
	if is_selected:
		var bob := roundf(sin(pulse_time) * 1.5)
		var ac := Vector2(sc.x, bar_pos.y - 12.0 + bob)
		var tri := PackedVector2Array([
			ac + Vector2(-4, -4),
			ac + Vector2(4, -4),
			ac + Vector2(0, 1),
		])
		draw_colored_polygon(tri, Color("f7e479"))

	var short_name := String(u.get("name", "")).get_slice("·", 0).strip_edges().to_upper()
	if short_name.length() > 8:
		short_name = short_name.substr(0, 8)

	if is_player:
		if is_selected or is_hovered:
			var tpos := bar_pos + Vector2(-3, -3)
			var tcol := Color("7bf28c") if is_selected else Color("f2e7d0")
			draw_string(PIXEL_FONT, tpos + Vector2(1, 1), short_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.BLACK)
			draw_string(PIXEL_FONT, tpos, short_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, tcol)
	else:
		var enemy_tag := short_name
		var ecol := Color("f0c259") if is_hovered else Color("f2e7d0")
		if bool(u.get("yielded", false)):
			enemy_tag += " [YIELD]"
		elif not sel_id.is_empty() and not bool(session.get("resolved", false)):
			if reachable.has(hover_cell) and hover_unit.is_empty():
				var move_ap := int(reachable[hover_cell].get("ap_cost", 0))
				var sprev: Dictionary = combat.shot_preview_at(
					session,
					sel_id,
					hover_cell.x,
					hover_cell.y,
					uid,
					String(session.get("fire_mode", "snap")),
					String(session.get("called_part", "torso")),
					move_ap
				)
				if bool(sprev.get("los_clear", false)):
					var spct := int(round(float(sprev.get("hit_chance", 0.0)) * 100.0))
					enemy_tag += " ->%d%%" % spct
					ecol = Color("7ce8ff") if bool(sprev.get("can_shoot", false)) else Color("f0c259")
				else:
					enemy_tag += " [NO LOS]"
					ecol = Color("8a7c68")
			else:
				var prev: Dictionary = combat.shot_preview(
					session,
					sel_id,
					uid,
					String(session.get("fire_mode", "snap")),
					String(session.get("called_part", "torso"))
				)
				if bool(prev.get("can_shoot", false)):
					var pct := int(round(float(prev.get("hit_chance", 0.0)) * 100.0))
					enemy_tag += " %d%%" % pct
		var tpos := bar_pos + Vector2(-4, -3)
		draw_string(PIXEL_FONT, tpos + Vector2(1, 1), enemy_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.BLACK)
		draw_string(PIXEL_FONT, tpos, enemy_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ecol)


func _draw_fx(fx: Dictionary) -> void:
	var dsize := _eff_draw_size()
	var kind := String(fx.get("type", ""))
	var prog := clampf(1.0 - (fx_timer / maxf(0.01, fx_duration)), 0.0, 1.0)
	if kind in ["shot", "club"]:
		var from_c: Vector2i = fx.get("from", Vector2i.ZERO)
		var to_c: Vector2i = fx.get("to", Vector2i.ZERO)
		var p0 := _grid_to_screen(from_c.x, from_c.y) + Vector2(0, -10 * zoom_level)
		var p1 := _grid_to_screen(to_c.x, to_c.y) + Vector2(0, -10 * zoom_level)
		if kind == "shot" and prog >= 0.24:
			var bullet_t := clampf((prog - 0.24) / 0.24, 0.0, 1.0)
			var tail_t := clampf((prog - 0.30) / 0.35, 0.0, 1.0)
			var b_head := p0.lerp(p1, bullet_t)
			var b_tail := p0.lerp(p1, tail_t)
			draw_line(b_tail, b_head, Color(0.98, 0.90, 0.64, 0.92 * (1.0 - tail_t)), 2.0)
			if bullet_t < 1.0:
				draw_rect(Rect2(b_head - Vector2(2, 2), Vector2(4, 4)), Color("fff3c4"), true)
			if units_tex != null and prog < 0.72:
				var smoke_src := Rect2(4 * CELL_PX, 2 * CELL_PX, CELL_PX, CELL_PX)
				var smoke_dst := Rect2(p0 - dsize * 0.5, dsize)
				var alpha := clampf(1.0 - ((prog - 0.24) / 0.48), 0.0, 0.95)
				draw_texture_rect_region(units_tex, smoke_dst, smoke_src, Color(1, 1, 1, alpha))
		if prog >= 0.40 and units_tex != null:
			if bool(fx.get("hit", false)):
				var spark_src := Rect2(5 * CELL_PX, 2 * CELL_PX, CELL_PX, CELL_PX)
				var spark_dst := Rect2(p1 - dsize * 0.5, dsize)
				var s_alpha := clampf(1.0 - ((prog - 0.40) / 0.55), 0.0, 1.0)
				draw_texture_rect_region(units_tex, spark_dst, spark_src, Color(1, 1, 1, s_alpha))
			else:
				# Miss dust / cover ricochet puff
				var dust_src := Rect2(4 * CELL_PX, 2 * CELL_PX, CELL_PX, CELL_PX)
				var dust_dst := Rect2(p1 - dsize * 0.38, dsize * 0.75)
				var d_alpha := clampf(0.75 - ((prog - 0.40) / 0.55), 0.0, 0.75)
				draw_texture_rect_region(units_tex, dust_dst, dust_src, Color(0.85, 0.78, 0.66, d_alpha))
	elif kind == "move":
		var path_pts: Array = fx.get("path", [])
		if path_pts.size() >= 2:
			for i in range(path_pts.size() - 1):
				var p0 := _grid_to_screen(path_pts[i].x, path_pts[i].y)
				var p1 := _grid_to_screen(path_pts[i + 1].x, path_pts[i + 1].y)
				draw_line(p0, p1, Color(0.42, 0.82, 0.49, 0.65), 1.5)


func _draw_smoke_puffs() -> void:
	if units_tex == null:
		return
	var dsize := _eff_draw_size()
	var smoke_src := Rect2(4 * CELL_PX, 2 * CELL_PX, CELL_PX, CELL_PX)
	for sp in smoke_puffs:
		var gc: Vector2i = sp.get("grid", Vector2i.ZERO)
		var drift: Vector2 = sp.get("drift", Vector2.ZERO) * zoom_level
		var ttl := float(sp.get("ttl", 0.0))
		var max_ttl := maxf(0.01, float(sp.get("max_ttl", 1.6)))
		var alpha := clampf((ttl / max_ttl) * 0.65, 0.0, 0.65)
		var scale_f := 1.0 + (1.0 - ttl / max_ttl) * 0.35
		var psize := dsize * scale_f
		var pos := _grid_to_screen(gc.x, gc.y) + drift
		draw_texture_rect_region(units_tex, Rect2(pos - psize * 0.5, psize), smoke_src, Color(0.92, 0.90, 0.86, alpha))


func _draw_top_banner(hover_unit: Dictionary, hover_preview: Dictionary, tile_sight_count: int = 0, tile_best_pct: int = 0) -> void:
	var text := ""
	var sub := ""
	var border_col := Color("a68654")
	var started := bool(session.get("started", false))
	var sel_id := String(session.get("selected_id", ""))
	var sel_u: Dictionary = combat.get_unit(session, sel_id)

	if _in_bounds(hover_cell):
		if not hover_unit.is_empty() and String(hover_unit.get("team", "")) == "enemy":
			var pct := int(round(float(hover_preview.get("hit_chance", 0.0)) * 100.0))
			var mode_lbl := String(hover_preview.get("part_label", "Torso")).to_upper()
			var ap_c := int(hover_preview.get("ap_cost", 4))
			var math_str := String(hover_preview.get("breakdown", ""))
			if not started:
				text = "ENEMY: %s (INIT %d) - PRESS 'START COMBAT' BELOW TO BEGIN" % [String(hover_unit.get("name", "Enemy")).to_upper(), int(hover_unit.get("initiative", 10))]
				sub = "SHOT MATH (%s): %s" % [mode_lbl, math_str]
				border_col = Color("f0c259")
			elif bool(hover_preview.get("can_shoot", false)):
				text = "CLICK TO SHOOT %s - %d%% HIT - %s (%d AP) - %d-%d DMG" % [
					String(hover_unit.get("name", "Enemy")).to_upper(),
					pct,
					mode_lbl,
					ap_c,
					int(hover_preview.get("damage_min", 36)),
					int(hover_preview.get("damage_max", 48)),
				]
				sub = "MATH: %s" % math_str
				border_col = Color("f0c259")
			else:
				text = "CANNOT SHOOT %s (%s)" % [String(hover_unit.get("name", "Enemy")).to_upper(), String(hover_preview.get("reason", "")).to_upper()]
				sub = "MATH IF READY: %s" % math_str
				border_col = Color("d15446")
		elif not hover_unit.is_empty() and String(hover_unit.get("team", "")) == "player":
			if not started:
				text = "CLICK TO SELECT OR SWAP %s (INIT %d - %d HP - %s)" % [
					String(hover_unit.get("name", "Traveler")).to_upper(),
					int(hover_unit.get("initiative", 10)),
					int(hover_unit.get("health", 100)),
					"LOADED" if bool(hover_unit.get("loaded", false)) else "UNLOADED",
				]
			else:
				text = "%s (INIT %d - %d HP - %d/%d AP - %s)" % [
					String(hover_unit.get("name", "Traveler")).to_upper(),
					int(hover_unit.get("initiative", 10)),
					int(hover_unit.get("health", 100)),
					int(hover_unit.get("ap", 0)),
					int(hover_unit.get("max_ap", 8)),
					"LOADED" if bool(hover_unit.get("loaded", false)) else "UNLOADED",
				]
		elif reachable.has(hover_cell):
			var has_cov := _tile_offers_cover(hover_cell.x, hover_cell.y)
			var sight_note := "SIGHTLINES FROM TILE: %d IN LOS (BEST SHOT: %d%% HIT)" % [tile_sight_count, tile_best_pct] if tile_sight_count > 0 else "SIGHTLINES FROM TILE: NO ENEMIES IN LOS (FULL CONCEALMENT)"
			if not started:
				text = "CLICK TO DEPLOY %s HERE (0 AP)%s" % [String(sel_u.get("name", "Traveler")).to_upper(), " - PROVIDES COVER (-28% ENEMY HIT)" if has_cov else ""]
				sub = sight_note
				border_col = Color("67b6d6")
			else:
				var ap_c := int(reachable[hover_cell].get("ap_cost", 1))
				text = "CLICK TO MOVE HERE (%d AP)%s" % [ap_c, " - PROVIDES COVER (-28% ENEMY HIT)" if has_cov else ""]
				if combat.is_retreat_tile(session, hover_cell.x, hover_cell.y):
					sub = "RETREAT EDGE (WITHDRAW 1 AP) - %s" % sight_note
				else:
					sub = sight_note
		else:
			var p: Dictionary = combat.prop_at(session, hover_cell.x, hover_cell.y)
			if not p.is_empty():
				var cov_kind := "FULL COVER (BLOCKS LINE OF SIGHT)" if int(p.get("cover", 1)) >= 2 else "HALF COVER (-28% HIT TO ADJACENT RIFLEMAN)"
				text = "%s - %s" % [String(p.get("label", "Cover")).to_upper(), cov_kind]

	if text.is_empty():
		if not banner_text.is_empty():
			text = banner_text
			border_col = Color("f0c259")
		else:
			if bool(session.get("resolved", false)):
				text = String(session.get("outcome_summary", "COMBAT RESOLVED")).to_upper()
			elif not started:
				var uname := String(sel_u.get("name", "Traveler")).to_upper()
				text = "DEPLOYMENT: CLICK BLUE TILES TO POSITION %s · CLICK OTHER TRAVELERS TO PLACE THEM · PRESS 'START COMBAT'" % uname
				border_col = Color("67b6d6")
			elif not sel_u.is_empty():
				var uname := String(sel_u.get("name", "Traveler")).to_upper()
				if bool(sel_u.get("loaded", false)):
					text = "NOW ACTING: %s (%d AP, LOADED) — MOVE, SHOOT, OR PRESS 'END TURN' FOR NEXT IN INITIATIVE" % [uname, int(sel_u.get("ap", 0))]
				elif int(sel_u.get("ap", 0)) >= combat.reload_ap_cost(sel_u):
					text = "NOW ACTING: %s (RIFLE UNLOADED) — CLICK 'RELOAD 5AP' BELOW OR PRESS 'END TURN'" % uname
				else:
					text = "NOW ACTING: %s (%d AP LEFT) — PRESS 'END TURN (SPACE)' TO ADVANCE INITIATIVE" % [uname, int(sel_u.get("ap", 0))]

	if text.is_empty():
		return
	text = text.replace("·", "-").replace("—", "-")
	sub = sub.replace("·", "-").replace("—", "-")
	var box_h := 24.0 if not sub.is_empty() else 14.0
	var box_rect := Rect2(Vector2(4, 4), Vector2(size.x - 8.0, box_h))
	draw_rect(box_rect, Color(0.08, 0.06, 0.05, 0.92), true)
	draw_rect(box_rect, border_col, false, 1.0)
	draw_string(PIXEL_FONT, Vector2(8, 13), text, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 16), 8, Color("f6e7c1"))
	if not sub.is_empty():
		draw_string(PIXEL_FONT, Vector2(8, 24), sub, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 16), 8, Color("cbb999"))


func _draw_bottom_legend() -> void:
	var y := size.y - 14.0
	var rect := Rect2(Vector2(4, y - 1), Vector2(size.x - 8.0, 11.0))
	draw_rect(rect, Color(0.08, 0.06, 0.05, 0.85), true)
	var legend := "WHEEL/+-: ZOOM (%.1fX)  R-DRAG/WASD: PAN  [GREEN CIRCLE] SELECTED  [RED RING] ENEMY" % zoom_level
	draw_string(PIXEL_FONT, Vector2(8, y + 7), legend, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 16), 8, Color("b89f74"))
