extends AcceptDialog
## Uses existing river scenery; controls and timing come from the simulation.
signal start_requested(kit: String)
signal returned
var game
var info:=Label.new()
var report:=Label.new()
var choices:=VBoxContainer.new()
var action:=Button.new()
var timer_bar:=ProgressBar.new()
var scenery:=TextureRect.new()
var active:=false
func _ready() -> void:
 title="FISHING"
 get_ok_button().text="CLOSE"
 confirmed.connect(_return)
 canceled.connect(_return)
 var rows:=VBoxContainer.new()
 rows.custom_minimum_size=Vector2(432,0)
 add_child(rows)
 info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 info.custom_minimum_size.x=432
 rows.add_child(info)
 scenery.texture=load("res://ui/location_scenes.gd").new().texture_for("wakarusa")
 scenery.custom_minimum_size=Vector2(432,150)
 scenery.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 scenery.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 scenery.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 rows.add_child(scenery)
 rows.add_child(choices)
 report.custom_minimum_size=Vector2(432,42)
 report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 rows.add_child(report)
 timer_bar.show_percentage=false
 timer_bar.max_value=1.0
 rows.add_child(timer_bar)
 action.custom_minimum_size.y=32
 action.pressed.connect(func():game.fishing_click();refresh())
 rows.add_child(action)
func open(value) -> void:
 game=value;active=false
 for child in choices.get_children():choices.remove_child(child);child.queue_free()
 var access: Dictionary=game.fishing_offer()
 info.text="%s · %.0f ROAD MILES TO WATER\nOne day including travel, fishing and meals." % [str(access.name).to_upper(),access.distance]
 for kit in ["foot","ride_horse_light"]:
  var quote: Dictionary=game.fishing_quote(kit)
  var pick:=Button.new()
  pick.text="WALK" if kit=="foot" else "TAKE A SADDLED HORSE"
  pick.disabled=not quote.get("valid",false)
  pick.tooltip_text=("%.1f hours at water · up to %d casts · %.0f lb catch allowance. Basic line/hooks included in household gear." % [quote.fishing_hours,quote.casts,quote.catch_lb]) if quote.get("valid",false) else str(quote.message)
  pick.custom_minimum_size.y=30
  pick.pressed.connect(func():start_requested.emit(kit))
  choices.add_child(pick)
 choices.show();action.hide();timer_bar.hide()
 report.text="A horse is required at this distance." if not access.walk else "Choose how to reach the riverbank."
 get_ok_button().text="CLOSE"
 reset_size();popup_centered()
func show_activity() -> void:
 active=true;choices.hide();action.show();timer_bar.show()
 get_ok_button().text="RETURN TO CAMP"
 refresh();reset_size()
func _process(delta: float) -> void:
 if visible and active:
  game.advance_fishing(delta)
  refresh()
func refresh() -> void:
 if game.hunt.get("activity","")!="fish":return
 var outing: Dictionary=game.hunt
 info.text="%s · %d LB EDIBLE FISH\nCASTS %d / %d · %d SECONDS LEFT" % [str(outing.field.site_name).to_upper(),outing.meat,outing.shots,outing.casts.size(),maxi(0,ceili(float(game.fishing.data.duration)-float(outing.elapsed)))]
 report.text=outing.message
 action.disabled=outing.ended
 action.text={"ready":"CAST","waiting":"WAIT...","bite":"BITE! STRIKE!"}.get(outing.phase,"CAST")
 timer_bar.value=maxf(0,1.0-float(outing.phase_time)/float(game.fishing.data.bite_seconds)) if outing.phase=="bite" else 0.0
func _return() -> void:
 hide()
 if active:active=false;returned.emit()
