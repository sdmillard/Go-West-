extends SceneTree
## UI bug hunt (November 2026): runs the real main screen under a display (xvfb), departs, then mixes
## random presses of visible enabled buttons with engine progress. After each step it checks for
## controls spilling out of their panel or the window, dialogs larger than the screen, script errors
## and screens with nothing to press. Saves one PNG per new screen signature to .tools/ui-monkey/.
## Usage (Linux): xvfb-run -a godot --path . --rendering-driver opengl3 --script tests/ui_monkey.gd -- [--seed=1] [--steps=1500] [--shots]
const Main=preload("res://ui/main.tscn")
const BLOCK=["NEW JOURNEY","TURN EAST","SETTLE HERE","GO BACK EAST","QUIT","LOAD","SAVE","FULLSCREEN","OPTIONS"]
var rng:=RandomNumberGenerator.new()
var problems: Dictionary={}
var signatures: Dictionary={}
var shots: bool=false
var out_dir: String="res://.tools/ui-monkey"
var screen
func _initialize():call_deferred("run")
func note(kind: String,detail: String) -> void:
	var key: String=kind+"|"+detail
	if problems.has(key):problems[key]+=1;return
	problems[key]=1
	printerr("UI PROBLEM %s: %s (day %d, %s, pending %s)" % [kind,detail,int(screen.game.state.get("day",0)),str(screen.game.state.get("landmark","")),str(screen.game.pending.get("id",""))])
func path_of(node: Node) -> String:
	var bits: Array=[]
	var n: Node=node
	while n!=null and n!=screen and bits.size()<6:
		var text: String=""
		if n is Button and n.text!="":text="["+n.text.left(18)+"]"
		elif n is Label and n.text!="":text="["+n.text.left(18)+"]"
		elif n is Window:text="{"+n.title+"}"
		bits.push_front(n.get_class()+text)
		n=n.get_parent()
	return "/".join(bits)
func visible_windows() -> Array:
	var out: Array=[]
	for w in _all(screen).filter(func(n):return n is Window and n.visible):out.append(w)
	return out
func _all(node: Node) -> Array:
	var out: Array=[node]
	for child in node.get_children():out.append_array(_all(child))
	return out
## A visible control should sit inside its panel (or window), unless a scroll container holds it.
func audit_layout() -> void:
	var view: Rect2=Rect2(Vector2.ZERO,Vector2(root.get_visible_rect().size))
	for w in visible_windows():
		if w.size.x>view.size.x*2.01 or w.size.y>view.size.y*2.01:note("dialog_too_big","%s %s" % [w.title,str(w.size)])
	for node in _all(screen):
		if not node is Control or not node.is_visible_in_tree() or node.size==Vector2.ZERO:continue
		var c: Control=node
		var p: Node=c.get_parent()
		var scrolled: bool=false
		var a: Node=p
		while a!=null and a!=screen:
			if a is ScrollContainer:scrolled=true;break
			if a is Window:break
			a=a.get_parent()
		if scrolled:continue
		if p is Control and (p is Panel or p is PanelContainer or p is Container) and p.size!=Vector2.ZERO:
			var parent_rect: Rect2=Rect2(Vector2.ZERO,p.size).grow(1.5)
			var rect: Rect2=Rect2(c.position,c.size)
			if not parent_rect.encloses(rect) and c.get_global_rect().size.x>2:note("spills_parent","%s rect %s in %s" % [path_of(c),str(rect),str(p.size)])
		if c is Label and c.autowrap_mode==TextServer.AUTOWRAP_OFF and not c.clip_text and c.text!="" and c.text_overrun_behavior==TextServer.OVERRUN_NO_TRIMMING:
			var font: Font=c.get_theme_font("font")
			var fs: int=c.get_theme_font_size("font_size")
			var w: float=0.0
			for line in c.text.split("\n"):w=maxf(w,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x)
			if w>c.size.x+2:note("label_wider_than_box","%s needs %d has %d" % [path_of(c),w,c.size.x])
func pressables() -> Array:
	var windows: Array=visible_windows().filter(func(w):return w.exclusive or w is AcceptDialog)
	var scope: Array=_all(windows[-1]) if not windows.is_empty() else _all(screen)
	return scope.filter(func(n):return (n is BaseButton) and n.is_visible_in_tree() and not n.disabled and not BLOCK.any(func(b):return n is Button and n.text.to_upper().contains(b)))
func signature() -> String:
	var g=screen.game
	var titles: Array=visible_windows().map(func(w):return w.title)
	return "%s|%s|%s|%s" % [g.state.status,",".join(titles),str(g.pending.get("id","")),"crime" if g.pending.get("crime_menu",false) else ""]
func capture(tag: String) -> void:
	if not shots:return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%03d-%s.png" % [out_dir,signatures.size(),tag.validate_filename().left(60)])
func depart(seed_value: int) -> void:
	var g=screen.game
	var cart: Dictionary={}
	for good in g.outfitter.goods:cart[good.id]=int(good.suggested)
	var profession: String=["farmer","banker","outlaw","doctor","carpenter"][seed_value%5]
	while not g.outfitter.quote(profession,cart).get("valid",false) and int(cart.get("oxen",0))>2:cart.oxen=int(cart.oxen)-1
	while not g.outfitter.quote(profession,cart).get("valid",false) and int(cart.get("food",0))>50:cart.food=int(cart.food)-50
	screen._depart(profession,["Ada","Ben","Cora","Dell","Eli"],[4,5,6,7][seed_value%4],cart)
	if g.state.status!="traveling":note("depart_failed",str(g.departure_error))
func run():
	var seed_value: int=1
	var steps: int=1500
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):seed_value=int(argument.get_slice("=",1))
		if argument.begins_with("--steps="):steps=int(argument.get_slice("=",1))
		if argument=="--shots":shots=true
	out_dir="res://.tools/ui-monkey/seed-%d" % seed_value
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	rng.seed=seed_value
	screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.seed_input.value=seed_value
	screen._new_journey()
	await process_frame
	await capture("outfitting")
	depart(seed_value)
	await process_frame
	var stuck: int=0
	var last_day: int=-1
	for step in range(steps):
		var g=screen.game
		if g.state.status!="traveling":break
		var sig: String=signature()
		if not signatures.has(sig):
			signatures[sig]=step
			audit_layout()
			await capture(sig)
		var buttons: Array=pressables()
		var roll: float=rng.randf()
		if not g.tactical_session.is_empty() and screen.tactical_window.visible and roll<0.6:
			g.tactical_step({"type":["end_turn","retreat_all","end_turn","surrender"][rng.randi()%4]})
			if bool(g.tactical_session.get("resolved",false)):screen._finish_tactical_combat()
		elif buttons.is_empty() or roll<0.7:
			# Progress: what a player does from the main screen.
			for w in visible_windows():if w is AcceptDialog and w!=screen.tactical_window:w.hide()
			if not g.raft.is_empty():
				while not g.raft.ended:g.advance_rafting(0.05,rng.randf_range(-1,1))
				g.finish_rafting();screen._rafting_returned()
			elif not g.hunt.is_empty():
				g.finish_hunt();screen._refresh()
			elif g.camp_repair.blocked(g):
				if not g.camp_repair.fit_spare(g) and not g.camp_repair.leader_work(g,"patch") and not g.camp_repair.leader_work(g,"wood"):g.rest()
				screen._refresh()
			elif not g.pending.is_empty():
				var options: Array=range(g.pending.choices.size()).filter(func(i):return g.can_choose(i))
				if options.is_empty():note("no_choice","pending %s has nothing choosable" % g.pending.get("id",""));g.pending={}
				else:screen._choose(options[rng.randi()%options.size()])
			elif rng.randf()<0.85:
				if g._can_act():
					screen.traveling=true
					screen._advance_day()
					screen._pause_travel()
				else:screen._refresh()
			else:screen._rest()
		else:
			var b: BaseButton=buttons[rng.randi()%buttons.size()]
			if b is OptionButton:
				if b.item_count>0:b.select(rng.randi()%b.item_count);b.item_selected.emit(b.selected)
			elif b is MenuButton:
				var popup: PopupMenu=b.get_popup()
				if popup.item_count>0:popup.id_pressed.emit(popup.get_item_id(rng.randi()%popup.item_count))
			elif b.toggle_mode:b.button_pressed=not b.button_pressed
			else:b.pressed.emit()
		await process_frame
		if not screen.landscape.crossing.is_empty() and rng.randf()<0.5:
			screen.landscape.cancel_crossing() if screen.landscape.has_method("cancel_crossing") else null
			screen._crossing_finished()
		stuck=stuck+1 if int(g.state.day)==last_day else 0
		last_day=int(g.state.day)
		if stuck>300:note("stuck","no day passed in 300 steps: %s can_act=%s tactical=%s crossing=%s fishing=%s" % [signature(),g._can_act(),not g.tactical_session.is_empty(),not screen.landscape.crossing.is_empty(),screen.fishing_window.visible]);break
	audit_layout()
	await capture("end-"+str(screen.game.state.status))
	print("UI MONKEY seed %d: day %d %s at %s, %d screens, %d problem kinds" % [seed_value,int(screen.game.state.day),str(screen.game.state.status),str(screen.game.state.get("landmark","")),signatures.size(),problems.size()])
	for key in problems:print("  %4d x %s" % [problems[key],key])
	quit(0)
