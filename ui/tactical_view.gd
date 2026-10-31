extends PanelContainer

signal finished

const TacticalScene = preload("res://ui/tactical_scene.gd")

var game = null
var title_label := Label.new()
var status_label := Label.new()
var ammo_label := Label.new()
var zoom_out_btn := Button.new()
var zoom_in_btn := Button.new()
var center_btn := Button.new()

# Baldur's Gate 3-style horizontal Initiative Tracker running across the top
var init_strip_panel := PanelContainer.new()
var init_row := HBoxContainer.new()

var scene := TacticalScene.new()

var squad_box := VBoxContainer.new()
var inspector_label := Label.new()
var weapon_label := Label.new()
var snap_button := Button.new()
var called_button := Button.new()
var club_button := Button.new()
var part_row := HBoxContainer.new()
var part_buttons: Dictionary = {}

var reload_button := Button.new()
var retreat_unit_button := Button.new()
var start_combat_button := Button.new()
var end_turn_button := Button.new()
var retreat_all_button := Button.new()
var surrender_button := Button.new()
var finish_button := Button.new()

var log_label := RichTextLabel.new()

# Fallout-style Called Shot modal overlay when clicking a target in Called Shot mode
var called_modal := PanelContainer.new()
var called_modal_title := Label.new()
var called_modal_rows := VBoxContainer.new()
var called_target_id := ""


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var root_style := StyleBoxFlat.new()
	root_style.bg_color = Color("16120e")
	root_style.border_color = Color("8c6f46")
	root_style.set_border_width_all(1)
	root_style.set_content_margin_all(5)
	add_theme_stylebox_override("panel", root_style)

	var main_col := VBoxContainer.new()
	main_col.add_theme_constant_override("separation", 3)
	add_child(main_col)

	# 1. Top Header Bar + Camera Controls
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	main_col.add_child(header)

	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.add_theme_color_override("font_color", Color("f4e4c1"))
	header.add_child(title_label)

	status_label.add_theme_color_override("font_color", Color("e2b25b"))
	header.add_child(status_label)

	ammo_label.add_theme_color_override("font_color", Color("d8c7a8"))
	header.add_child(ammo_label)

	zoom_out_btn.text = "Z-"
	_apply_chip_style(zoom_out_btn, Color("241d16"), Color("786042"), 1)
	zoom_out_btn.pressed.connect(func(): scene.adjust_zoom(-0.25))
	header.add_child(zoom_out_btn)

	zoom_in_btn.text = "Z+"
	_apply_chip_style(zoom_in_btn, Color("241d16"), Color("786042"), 1)
	zoom_in_btn.pressed.connect(func(): scene.adjust_zoom(0.25))
	header.add_child(zoom_in_btn)

	center_btn.text = "CTR"
	_apply_chip_style(center_btn, Color("241d16"), Color("786042"), 1)
	center_btn.pressed.connect(func():
		if game != null and not game.tactical_session.is_empty():
			scene.center_on_unit(String(game.tactical_session.get("selected_id", "")))
	)
	header.add_child(center_btn)

	# 2. Horizontal BG3-Style Initiative Order Bar Across the Top
	var init_style := StyleBoxFlat.new()
	init_style.bg_color = Color("1f1913")
	init_style.border_color = Color("6b5438")
	init_style.set_border_width_all(1)
	init_style.set_content_margin_all(3)
	init_strip_panel.add_theme_stylebox_override("panel", init_style)
	main_col.add_child(init_strip_panel)

	var init_outer := HBoxContainer.new()
	init_outer.add_theme_constant_override("separation", 6)
	init_strip_panel.add_child(init_outer)

	var init_title := Label.new()
	init_title.text = "INIT:"
	init_title.add_theme_color_override("font_color", Color("d8b878"))
	init_outer.add_child(init_title)

	init_row.add_theme_constant_override("separation", 3)
	init_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	init_outer.add_child(init_row)

	# 3. Middle Split: Isometric Battlefield (Left) + Active Unit & Telemetry Sidebar (Right)
	var mid_row := HBoxContainer.new()
	mid_row.add_theme_constant_override("separation", 6)
	mid_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_col.add_child(mid_row)

	var stage_wrap := Control.new()
	stage_wrap.custom_minimum_size = Vector2(532, 180)
	stage_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_row.add_child(stage_wrap)

	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.tile_clicked.connect(_on_tile_clicked)
	scene.unit_clicked.connect(_on_unit_clicked)
	scene.hover_changed.connect(func(_cell: Vector2i): _update_inspector())
	stage_wrap.add_child(scene)

	_build_called_modal(stage_wrap)

	var right_col := VBoxContainer.new()
	right_col.custom_minimum_size = Vector2(250, 180)
	right_col.add_theme_constant_override("separation", 4)
	mid_row.add_child(right_col)

	var squad_panel := _make_subpanel("CURRENT COMBATANT & SQUAD")
	squad_panel.custom_minimum_size = Vector2(250, 88)
	right_col.add_child(squad_panel)
	inspector_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector_label.add_theme_color_override("font_color", Color("e8dcc4"))
	squad_panel.get_child(0).add_child(inspector_label)

	var squad_scroll := ScrollContainer.new()
	squad_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	squad_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	squad_panel.get_child(0).add_child(squad_scroll)
	squad_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	squad_box.add_theme_constant_override("separation", 2)
	squad_scroll.add_child(squad_box)

	var log_panel := _make_subpanel("SKIRMISH TELEMETRY")
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_child(log_panel)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.bbcode_enabled = false
	log_label.scroll_following = true
	log_label.add_theme_color_override("default_color", Color("e6dac3"))
	log_panel.get_child(0).add_child(log_label)

	# 4. Bottom Fallout-Style Control Deck
	var action_panel := _make_subpanel("1848 CAPLOCK RIFLE & TURN ORDERS")
	action_panel.custom_minimum_size = Vector2(0, 52)
	main_col.add_child(action_panel)
	var action_col: VBoxContainer = action_panel.get_child(0)
	action_col.add_theme_constant_override("separation", 3)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)
	action_col.add_child(top_bar)

	weapon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_label.clip_text = true
	weapon_label.add_theme_color_override("font_color", Color("f0c259"))
	top_bar.add_child(weapon_label)

	part_row.add_theme_constant_override("separation", 3)
	top_bar.add_child(part_row)
	var part_lbl := Label.new()
	part_lbl.text = "AIM:"
	part_lbl.add_theme_color_override("font_color", Color("cbb999"))
	part_row.add_child(part_lbl)
	for p in ["head", "torso", "arms", "legs"]:
		var b := Button.new()
		b.text = p.to_upper()
		b.pressed.connect(func(): _set_called_part(p))
		part_row.add_child(b)
		part_buttons[p] = b

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 4)
	action_col.add_child(btn_row)

	start_combat_button.text = "> START COMBAT (SPACE)"
	start_combat_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_combat_button.pressed.connect(_on_start_combat_pressed)
	btn_row.add_child(start_combat_button)

	snap_button.text = "SNAP 4AP"
	snap_button.pressed.connect(func(): _set_fire_mode("snap"))
	btn_row.add_child(snap_button)

	called_button.text = "CALLED 6AP"
	called_button.pressed.connect(func(): _set_fire_mode("called"))
	btn_row.add_child(called_button)

	club_button.text = "CLUB 3AP"
	club_button.pressed.connect(func(): _set_fire_mode("club"))
	btn_row.add_child(club_button)

	reload_button.text = "RELOAD 5AP"
	reload_button.pressed.connect(_on_reload_pressed)
	btn_row.add_child(reload_button)

	retreat_unit_button.text = "WITHDRAW 1AP"
	retreat_unit_button.pressed.connect(_on_retreat_unit_pressed)
	btn_row.add_child(retreat_unit_button)

	end_turn_button.text = "END TURN / NEXT (SPACE)"
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	btn_row.add_child(end_turn_button)

	retreat_all_button.text = "FALL BACK"
	retreat_all_button.pressed.connect(_on_retreat_all_pressed)
	btn_row.add_child(retreat_all_button)

	surrender_button.text = "SURRENDER"
	surrender_button.pressed.connect(_on_surrender_pressed)
	btn_row.add_child(surrender_button)

	finish_button.text = "CONTINUE - SETTLE WOUNDS & OUTCOME"
	finish_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish_button.visible = false
	finish_button.pressed.connect(_on_finish_pressed)
	btn_row.add_child(finish_button)


func init_Scroll_setup(sc: ScrollContainer) -> void:
	sc.custom_minimum_size = Vector2(0, 22)


func _make_subpanel(heading: String) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color("211b15")
	st.border_color = Color("634e34")
	st.set_border_width_all(1)
	st.set_content_margin_all(4)
	p.add_theme_stylebox_override("panel", st)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	p.add_child(col)
	var lbl := Label.new()
	lbl.text = heading
	lbl.add_theme_color_override("font_color", Color("b89f74"))
	col.add_child(lbl)
	return p


func _build_called_modal(parent: Control) -> void:
	called_modal.visible = false
	called_modal.custom_minimum_size = Vector2(360, 150)
	called_modal.position = Vector2(86, 32)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.10, 0.08, 0.06, 0.96)
	st.border_color = Color("e2b25b")
	st.set_border_width_all(1)
	st.set_content_margin_all(6)
	called_modal.add_theme_stylebox_override("panel", st)
	parent.add_child(called_modal)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	called_modal.add_child(col)

	called_modal_title.text = "CALLED SHOT TARGETING (6 AP)"
	called_modal_title.add_theme_color_override("font_color", Color("f4e4c1"))
	col.add_child(called_modal_title)

	called_modal_rows.add_theme_constant_override("separation", 2)
	col.add_child(called_modal_rows)

	var cancel_btn := Button.new()
	cancel_btn.text = "CANCEL AIM"
	cancel_btn.pressed.connect(func(): called_modal.visible = false)
	col.add_child(cancel_btn)


func open(sim_game) -> void:
	game = sim_game
	if get_parent() is Control and get_parent().theme != null:
		theme = get_parent().theme
	called_modal.visible = false
	visible = true
	scene.bind(game.tactical, game.tactical_session)
	_refresh_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or game == null or game.tactical_session.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and called_modal.visible:
			called_modal.visible = false
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE:
			if bool(game.tactical_session.get("resolved", false)):
				_on_finish_pressed()
			elif not bool(game.tactical_session.get("started", false)):
				_on_start_combat_pressed()
			else:
				_on_end_turn_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R and bool(game.tactical_session.get("started", false)) and not bool(game.tactical_session.get("resolved", false)):
			_on_reload_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_EQUAL, KEY_KP_ADD]:
			scene.adjust_zoom(0.25)
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			scene.adjust_zoom(-0.25)
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_A, KEY_LEFT]:
			scene.cam_pan.x += 24.0
			scene._clamp_pan()
			scene.queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_D, KEY_RIGHT]:
			scene.cam_pan.x -= 24.0
			scene._clamp_pan()
			scene.queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_W, KEY_UP]:
			scene.cam_pan.y += 20.0
			scene._clamp_pan()
			scene.queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_S, KEY_DOWN]:
			scene.cam_pan.y -= 20.0
			scene._clamp_pan()
			scene.queue_redraw()
			get_viewport().set_input_as_handled()


func _on_tile_clicked(grid_pos: Vector2i) -> void:
	if game == null or game.tactical_session.is_empty() or bool(game.tactical_session.get("resolved", false)):
		return
	called_modal.visible = false
	var sel_id := String(game.tactical_session.get("selected_id", ""))
	if sel_id.is_empty():
		return
	if not bool(game.tactical_session.get("started", false)):
		game.tactical_step({
			"type": "place",
			"unit_id": sel_id,
			"x": grid_pos.x,
			"y": grid_pos.y,
		})
	else:
		game.tactical_step({
			"type": "move",
			"unit_id": sel_id,
			"x": grid_pos.x,
			"y": grid_pos.y,
		})
	_after_step()


func _on_unit_clicked(unit_id: String) -> void:
	if game == null or game.tactical_session.is_empty() or bool(game.tactical_session.get("resolved", false)):
		return
	var u: Dictionary = game.tactical.get_unit(game.tactical_session, unit_id)
	if u.is_empty() or int(u.get("health", 0)) <= 0:
		return
	var started := bool(game.tactical_session.get("started", false))
	if String(u.get("team", "")) == "player":
		called_modal.visible = false
		if not started:
			game.tactical_step({"type": "select", "unit_id": unit_id})
			_after_step()
		else:
			scene.center_on_unit(unit_id)
		return

	if not started:
		# If player clicks an enemy before hitting Start Combat, center on them or open Called Shot preview if in called mode
		var sel_id_pre := String(game.tactical_session.get("selected_id", ""))
		if String(game.tactical_session.get("fire_mode", "snap")) == "called" and not sel_id_pre.is_empty():
			game.tactical_step({"type": "start_combat"})
			_after_step()
			var active_now := String(game.tactical_session.get("selected_id", ""))
			var tgt_now: Dictionary = game.tactical.get_unit(game.tactical_session, unit_id)
			if not bool(game.tactical_session.get("resolved", false)) and not active_now.is_empty() and int(tgt_now.get("health", 0)) > 0:
				_open_called_shot_modal(active_now, unit_id)
		else:
			scene.center_on_unit(unit_id)
		return

	var sel_id := String(game.tactical_session.get("selected_id", ""))
	if sel_id.is_empty():
		return
	var mode := String(game.tactical_session.get("fire_mode", "snap"))
	if mode == "called":
		_open_called_shot_modal(sel_id, unit_id)
	else:
		game.tactical_step({
			"type": "shoot",
			"unit_id": sel_id,
			"target_id": unit_id,
			"mode": mode,
			"body_part": "torso",
		})
		_after_step()


func _open_called_shot_modal(attacker_id: String, target_id: String) -> void:
	called_target_id = target_id
	var target: Dictionary = game.tactical.get_unit(game.tactical_session, target_id)
	called_modal_title.text = "CALLED SHOT · %s (6 AP)" % String(target.get("name", "Defender")).to_upper()
	for child in called_modal_rows.get_children():
		child.queue_free()

	var previews: Dictionary = game.tactical.all_called_shot_previews(game.tactical_session, attacker_id, target_id)
	var effect_tags := {
		"head": "FATAL HEADSHOT",
		"torso": "CENTER MASS WOUND",
		"arms": "-22% AIM & +1AP RELOAD",
		"legs": "+1AP STEP & BLEED",
	}
	for part in ["head", "torso", "arms", "legs"]:
		var prev: Dictionary = previews.get(part, {})
		var btn := Button.new()
		var pct := int(round(float(prev.get("hit_chance", 0.0)) * 100.0))
		var dmin := int(prev.get("damage_min", 25))
		var dmax := int(prev.get("damage_max", 40))
		btn.text = "%s - %d%% HIT - %d-%d DMG - %s" % [part.to_upper(), pct, dmin, dmax, effect_tags.get(part, "")]
		btn.disabled = not bool(prev.get("can_shoot", false))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func():
			called_modal.visible = false
			game.tactical_step({
				"type": "shoot",
				"unit_id": attacker_id,
				"target_id": target_id,
				"mode": "called",
				"body_part": part,
			})
			_after_step()
		)
		called_modal_rows.add_child(btn)

	called_modal.visible = true


func _on_start_combat_pressed() -> void:
	if game == null or game.tactical_session.is_empty():
		return
	called_modal.visible = false
	game.tactical_step({"type": "start_combat"})
	_after_step()
	var active_id := String(game.tactical_session.get("selected_id", ""))
	if not active_id.is_empty():
		scene.center_on_unit(active_id)


func _set_fire_mode(mode: String) -> void:
	if game == null or game.tactical_session.is_empty():
		return
	called_modal.visible = false
	game.tactical_step({"type": "set_mode", "mode": mode})
	_refresh_ui()
	scene.refresh()


func _set_called_part(part: String) -> void:
	if game == null or game.tactical_session.is_empty():
		return
	game.tactical_step({"type": "set_mode", "mode": "called", "body_part": part})
	_refresh_ui()
	scene.refresh()


func _on_reload_pressed() -> void:
	if game == null or game.tactical_session.is_empty():
		return
	called_modal.visible = false
	game.tactical_step({"type": "reload"})
	_after_step()


func _on_retreat_unit_pressed() -> void:
	if game == null or game.tactical_session.is_empty():
		return
	called_modal.visible = false
	game.tactical_step({"type": "retreat_unit"})
	_after_step()


func _on_retreat_all_pressed() -> void:
	if game == null or game.tactical_session.is_empty():
		return
	called_modal.visible = false
	game.tactical_step({"type": "retreat_all"})
	_after_step()


func _on_surrender_pressed() -> void:
	if game == null or game.tactical_session.is_empty():
		return
	called_modal.visible = false
	game.tactical_step({"type": "surrender"})
	_after_step()


func _on_end_turn_pressed() -> void:
	if game == null or game.tactical_session.is_empty():
		return
	called_modal.visible = false
	game.tactical_step({"type": "end_turn"})
	_after_step()
	var active_id := String(game.tactical_session.get("selected_id", ""))
	if not active_id.is_empty():
		scene.center_on_unit(active_id)


func _on_finish_pressed() -> void:
	if game == null:
		return
	visible = false
	finished.emit()


func _after_step() -> void:
	if game == null or game.tactical_session.is_empty():
		return
	var q: Array = game.tactical_session.get("fx_queue", [])
	if not q.is_empty():
		scene.play_fx_queue(q)
	elif not game.tactical_session.get("last_fx", {}).is_empty():
		scene.trigger_fx(game.tactical_session.get("last_fx", {}))
	scene.refresh()
	_refresh_ui()


func _apply_chip_style(btn: Button, bg: Color, border: Color, bw: int = 1) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(bw)
	st.content_margin_left = 4
	st.content_margin_right = 4
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(state_name, st)


func _refresh_ui() -> void:
	if game == null or game.tactical_session.is_empty():
		return
	var s: Dictionary = game.tactical_session
	var resolved := bool(s.get("resolved", false))
	var started := bool(s.get("started", false))
	var sel_id := String(s.get("selected_id", ""))
	var active_id := String(s.get("active_unit_id", sel_id))
	var sel_unit: Dictionary = game.tactical.get_unit(s, sel_id)

	title_label.text = "%s - %s" % [String(s.get("place_name", "Frontier")).to_upper(), String(s.get("title", "Skirmish")).to_upper()]
	if resolved:
		status_label.text = "RESOLVED: %s" % String(s.get("outcome", "")).to_upper()
	elif not started:
		status_label.text = "DEPLOYMENT PHASE"
	else:
		status_label.text = "RND %d - TURN %d/%d" % [
			int(s.get("round", 1)),
			int(s.get("turn_index", 0)) + 1,
			maxi(1, s.get("initiative_order", []).size()),
		]

	var reserve: int = game.tactical.available_reload_balls(s)
	ammo_label.text = "BALLS: %d (POUCH: %d)" % [int(s.get("bullets_left", 0)), reserve]

	# Rebuild Baldur's Gate 3-style Horizontal Initiative Tracker across the top
	for child in init_row.get_children():
		child.queue_free()
	var order: Array = s.get("initiative_order", [])
	for idx in range(order.size()):
		var uid := String(order[idx])
		var u: Dictionary = game.tactical.get_unit(s, uid)
		if u.is_empty():
			continue
		var is_player := String(u.get("team", "")) == "player"
		var hp := int(u.get("health", 0))
		var retreated := bool(u.get("retreated", false))
		var yielded := bool(u.get("yielded", false))
		var init_val := int(u.get("initiative", 10))
		var short_name := String(u.get("name", "Unit")).get_slice("·", 0).strip_edges().to_upper()
		if short_name.length() > 4:
			short_name = short_name.substr(0, 4)

		var chip := Button.new()
		var state_txt := "%d" % init_val
		if hp <= 0:
			state_txt = "XX"
		elif retreated:
			state_txt = "<<"
		elif yielded:
			state_txt = "--"
		elif started and uid == active_id:
			state_txt = "%dA" % int(u.get("ap", 0))

		var is_now := (started and uid == active_id) or (not started and uid == sel_id)
		var prefix := ">" if is_now else "%d:" % (idx + 1)
		chip.text = "%s%s.%s" % [prefix, short_name, state_txt]
		chip.tooltip_text = "%s (Initiative %d - %d HP)" % [String(u.get("name", "Unit")), init_val, hp]

		if hp <= 0 or retreated or yielded:
			_apply_chip_style(chip, Color("1a1612"), Color("4a4035"), 1)
			chip.add_theme_color_override("font_color", Color("706454"))
		elif is_now:
			var hi_border := Color("7bf28c") if started else Color("67b6d6")
			var hi_bg := Color("243b27") if started else Color("1d333d")
			_apply_chip_style(chip, hi_bg, hi_border, 2)
			chip.add_theme_color_override("font_color", Color("f7e479"))
		elif is_player:
			_apply_chip_style(chip, Color("1c2922"), Color("4d7a5c"), 1)
			chip.add_theme_color_override("font_color", Color("d4ecd9"))
		else:
			_apply_chip_style(chip, Color("2e1816"), Color("a84438"), 1)
			chip.add_theme_color_override("font_color", Color("f2c6c2"))

		chip.mouse_entered.connect(func():
			scene.highlight_unit_id = uid
			scene.queue_redraw()
			_update_inspector(uid)
		)
		chip.mouse_exited.connect(func():
			if scene.highlight_unit_id == uid:
				scene.highlight_unit_id = ""
				scene.queue_redraw()
			_update_inspector()
		)
		chip.pressed.connect(func():
			if not started and is_player and hp > 0 and not retreated:
				game.tactical_step({"type": "select", "unit_id": uid})
				_after_step()
			scene.center_on_unit(uid)
		)
		init_row.add_child(chip)

	# Active Combatant Inspector & Squad Summary on Right Sidebar
	_update_inspector()

	for child in squad_box.get_children():
		child.queue_free()
	for u in s.get("units", []):
		if String(u.get("team", "")) != "player":
			continue
		var uid := String(u.get("id", ""))
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var hp := int(u.get("health", 0))
		var ap := int(u.get("ap", 0))
		var load_tag := _arms_tag(u)
		var state_tag := "%dHP %dAP %s" % [hp, ap, load_tag]
		if hp <= 0:
			state_tag = "DEAD"
		elif bool(u.get("stunned", false)):
			state_tag = "STUNNED %dHP" % hp
		elif bool(u.get("retreated", false)):
			state_tag = "OUT (%dHP)" % hp
		var prefix := ">" if uid == sel_id else " "
		var uname := String(u.get("name", "Traveler")).to_upper()
		if uname.length() > 8:
			uname = uname.substr(0, 8)
		btn.text = "%s%s [%s]" % [prefix, uname, state_tag]
		_apply_chip_style(btn, Color("243627") if uid == sel_id else Color("1d1813"), Color("6bc27c") if uid == sel_id else Color("54432e"), 1)
		btn.disabled = resolved or hp <= 0 or bool(u.get("retreated", false)) or bool(u.get("stunned", false))
		btn.mouse_entered.connect(func():
			scene.highlight_unit_id = uid
			scene.queue_redraw()
		)
		btn.mouse_exited.connect(func():
			if scene.highlight_unit_id == uid:
				scene.highlight_unit_id = ""
				scene.queue_redraw()
		)
		btn.pressed.connect(func():
			if not started:
				game.tactical_step({"type": "select", "unit_id": uid})
				_after_step()
			scene.center_on_unit(uid)
		)
		squad_box.add_child(btn)

	# Bottom Deck Weapon & Action Buttons
	var mode := String(s.get("fire_mode", "snap"))
	var cpart := String(s.get("called_part", "torso"))
	if resolved:
		weapon_label.text = String(s.get("outcome_summary", "")).to_upper()
	elif not started:
		var first_uid := String(order[0]) if not order.is_empty() else ""
		var first_u: Dictionary = game.tactical.get_unit(s, first_uid)
		weapon_label.text = "PLACE SQUAD IN BLUE ZONE - FIRST IN INITIATIVE: %s (INIT %d)" % [
			String(first_u.get("name", "Combatant")).to_upper(),
			int(first_u.get("initiative", 10)),
		]
	elif not sel_unit.is_empty():
		var ap_now := int(sel_unit.get("ap", 0))
		var ap_max := int(sel_unit.get("max_ap", 8))
		var r_state := _arms_state(sel_unit)
		weapon_label.text = "%s'S TURN - %d/%d AP - %s - HIT 'END TURN' FOR NEXT IN INITIATIVE" % [
			String(sel_unit.get("name", "Traveler")).to_upper(),
			ap_now,
			ap_max,
			r_state,
		]

	start_combat_button.visible = (not started) and (not resolved)
	# Costs follow the selected traveler's own arms.
	var snap_txt := "SNAP %dAP" % game.tactical.shot_ap_cost("snap", sel_unit)
	var called_txt := "CALLED %dAP" % game.tactical.shot_ap_cost("called", sel_unit)
	var melee_name := String(game.tactical.melee(sel_unit).get("label", "Club")).to_upper() if not sel_unit.is_empty() else "CLUB"
	var club_txt := "%s %dAP" % [melee_name, game.tactical.shot_ap_cost("club", sel_unit)]
	snap_button.text = "[%s]" % snap_txt if mode == "snap" else snap_txt
	called_button.text = "[%s]" % called_txt if mode == "called" else called_txt
	club_button.text = "[%s]" % club_txt if mode == "club" else club_txt
	snap_button.visible = started and not resolved
	called_button.visible = started and not resolved
	club_button.visible = started and not resolved

	part_row.visible = started and (mode == "called") and not resolved
	for p in part_buttons.keys():
		var b: Button = part_buttons[p]
		b.text = "[%s]" % p.to_upper() if p == cpart else p.to_upper()

	var r_cost: int = game.tactical.reload_ap_cost(sel_unit) if not sel_unit.is_empty() else 5
	reload_button.text = "RELOAD %dAP" % r_cost
	reload_button.visible = started and not resolved
	reload_button.disabled = (not started) or resolved or sel_unit.is_empty() or game.tactical.capacity(sel_unit) == 0 or int(sel_unit.get("rounds", 0)) >= game.tactical.capacity(sel_unit) or int(sel_unit.get("ap", 0)) < r_cost or reserve <= 0

	var on_retreat: bool = not sel_unit.is_empty() and bool(game.tactical.is_retreat_tile(s, int(sel_unit.get("x", -1)), int(sel_unit.get("y", -1))))
	retreat_unit_button.visible = started and not resolved
	retreat_unit_button.disabled = (not started) or resolved or not on_retreat or int(sel_unit.get("ap", 0)) < 1
	end_turn_button.visible = started and not resolved
	retreat_all_button.visible = not resolved
	surrender_button.visible = not resolved
	finish_button.visible = resolved

	var lines: Array = s.get("log", [])
	var tail: Array = lines.slice(maxi(0, lines.size() - 5), lines.size())
	log_label.text = "\n".join(tail)


## "RIFLE LD", "COLT 3/5", "KNIFE": what a traveler holds and how much is loaded.
func _arms_tag(u: Dictionary) -> String:
	var arm: Dictionary = game.tactical.gun(u)
	if arm.is_empty():
		return String(game.tactical.melee(u).get("label", "Fists")).to_upper()
	if int(arm.capacity) > 1:
		return "%s %d/%d" % [String(arm.label).to_upper(), int(u.get("rounds", 0)), int(arm.capacity)]
	return "%s %s" % [String(arm.label).to_upper(), "LD" if bool(u.get("loaded", false)) else "--"]


func _arms_state(u: Dictionary) -> String:
	var arm: Dictionary = game.tactical.gun(u)
	if arm.is_empty():
		return "NO FIREARM - %s" % String(game.tactical.melee(u).get("label", "Fists")).to_upper()
	if bool(u.get("loaded", false)):
		return "%s LOADED%s" % [String(arm.label).to_upper(), " (%d/%d)" % [int(u.get("rounds", 0)), int(arm.capacity)] if int(arm.capacity) > 1 else ""]
	return "%s UNLOADED (RELOAD %dAP)" % [String(arm.label).to_upper(), game.tactical.reload_ap_cost(u)]


func _update_inspector(focus_uid: String = "") -> void:
	if game == null or game.tactical_session.is_empty():
		return
	var s: Dictionary = game.tactical_session
	if bool(s.get("resolved", false)):
		inspector_label.text = "COMBAT RESOLVED"
		return
	var started := bool(s.get("started", false))
	var sel_id := String(s.get("selected_id", ""))
	var sel_unit: Dictionary = game.tactical.get_unit(s, sel_id)

	var target_unit: Dictionary = {}
	if not focus_uid.is_empty():
		target_unit = game.tactical.get_unit(s, focus_uid)
	elif scene._in_bounds(scene.hover_cell):
		target_unit = game.tactical.unit_at(s, scene.hover_cell.x, scene.hover_cell.y)

	if not target_unit.is_empty() and String(target_unit.get("team", "")) == "enemy":
		var tid := String(target_unit.get("id", ""))
		var prev: Dictionary = game.tactical.shot_preview(
			s,
			sel_id,
			tid,
			String(s.get("fire_mode", "snap")),
			String(s.get("called_part", "torso"))
		)
		var math_str := String(prev.get("breakdown", "")).replace("  ", " ")
		inspector_label.text = "TARGET: %s (%d HP - INIT %d)\n%s" % [
			String(target_unit.get("name", "Enemy")).to_upper(),
			int(target_unit.get("health", 100)),
			int(target_unit.get("initiative", 10)),
			math_str,
		]
		return

	if not sel_unit.is_empty():
		var cov: Dictionary = game.tactical.unit_adjacent_cover(s, sel_unit)
		var cov_txt := String(cov.get("label", "Open ground")).to_upper() if not cov.is_empty() else "OPEN GROUND"
		var load_txt := _arms_state(sel_unit)
		var mode_header := "DEPLOYING" if not started else "NOW ACTING"
		inspector_label.text = "%s: %s (INIT %d - SAVE %d)\n%d HP - %d/%d AP - %s - %s" % [
			mode_header,
			String(sel_unit.get("name", "Traveler")).to_upper(),
			int(sel_unit.get("initiative", 10)),
			game.tactical.body_save(sel_unit) - game.tactical.wound_penalty(sel_unit),
			int(sel_unit.get("health", 100)),
			int(sel_unit.get("ap", 0)),
			int(sel_unit.get("max_ap", 8)),
			load_txt,
			cov_txt,
		]
