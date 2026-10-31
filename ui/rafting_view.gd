extends Window
signal returned
var game
var active:=false
var paused:=true
var started:=false
var target: float=0.0
var scene:=preload("res://ui/rafting_scene.gd").new()
var status:=Label.new()
var hull:=ProgressBar.new()
var pause_button:=Button.new()
var finish_button:=Button.new()
func _ready() -> void:
 hide()
 title="CASCADES RAPIDS"
 size=Vector2i(456,314);unresizable=true;exclusive=true;transient=true
 var panel:=PanelContainer.new();add_child(panel);panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var paper:=StyleBoxFlat.new();paper.bg_color=Color("ecd097");paper.border_color=Color("76503c");paper.set_border_width_all(1);panel.add_theme_stylebox_override("panel",paper)
 var margin:=MarginContainer.new();panel.add_child(margin)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,8)
 var rows:=VBoxContainer.new();margin.add_child(rows)
 var instructions:=Label.new();instructions.text="MOVE THE MOUSE ACROSS THE RIVER TO STEER
AVOID ROCKS, DRIFTING LOGS AND THE SHORE";rows.add_child(instructions)
 rows.add_child(scene);scene.steering.connect(func(value: float):target=value)
 hull.max_value=100;hull.show_percentage=false;hull.custom_minimum_size.y=8;rows.add_child(hull)
 status.custom_minimum_size=Vector2(432,38);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;rows.add_child(status)
 var buttons:=HBoxContainer.new();rows.add_child(buttons)
 pause_button.text="START";pause_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;buttons.add_child(pause_button)
 pause_button.pressed.connect(toggle_pause)
 finish_button.text="CONTINUE";finish_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;buttons.add_child(finish_button)
 finish_button.pressed.connect(finish)
 close_requested.connect(func():
  if active and not game.raft.is_empty():paused=true;refresh()
  else:hide())
func open(value) -> void:
 game=value;active=true;paused=true;started=false;target=0
 if get_parent() is Control:theme=get_parent().theme
 scene.session=game.raft;scene.wagon=game.state.vehicle!="foot";scene.profiles=[]
 for member in game.party_health.members:
  if game.party_health.is_active(member):scene.profiles.append(game.characters.profiles[int(member.id)])
 scene.target=0;refresh();popup_centered()
func toggle_pause() -> void:
 if not active or game.raft.is_empty() or game.raft.ended:return
 started=true;paused=not paused;refresh()
func _process(delta: float) -> void:
 if active and visible and not paused and not game.raft.is_empty():
  game.advance_rafting(delta,target);refresh()
func refresh() -> void:
 if not active or game.raft.is_empty():return
 var raft: Dictionary=game.raft
 scene.session=raft;scene.queue_redraw();hull.value=raft.integrity
 pause_button.text="FINISHED" if raft.ended else "START" if not started else "RESUME" if paused else "PAUSE"
 pause_button.disabled=raft.ended;finish_button.disabled=not raft.ended
 if raft.ended:
  var loss: Dictionary=game.rafting.losses(raft)
  status.text="%s
IMPACTS %d · CARGO LOSS UP TO %d FOOD UNITS%s" % ["RAFT WRECKED" if raft.wrecked else "CLEAR OF THE RAPIDS",raft.hits,loss.food," · INJURY / DROWNING RISK" if raft.wrecked else ""]
 else:status.text="%s · HULL %d%% · IMPACTS %d · %ds LEFT
%s" % ["PAUSED" if paused else "RUNNING",raft.integrity,raft.hits,maxi(0,ceili(float(game.rafting.data.duration_seconds)-float(raft.elapsed))),"Press START when ready. One trail day and meals on completion." if not started else str(raft.message)]
func finish() -> void:
 if not active or game.raft.is_empty() or not game.raft.ended:return
 if not game.finish_rafting():return
 active=false;hide();returned.emit()
func reset() -> void:
 active=false;paused=true;hide();scene.session={}
