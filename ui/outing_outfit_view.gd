extends ConfirmationDialog
signal launch_requested(actor: int,config: Dictionary)
var game
var actor:=OptionButton.new()
var kit:=OptionButton.new()
var return_load:=OptionButton.new()
var duration:=SpinBox.new()
var ammo:=SpinBox.new()
var helpers:=GridContainer.new()
var summary:=Label.new()
var helper_checks: Dictionary={}
var loading:=false
const KIT_LABELS=["On foot","Ride horse + saddlebags","Lead pack horse","Ride mule + saddlebags","Lead pack mule","Ride horse + lead pack mule","Ride horse · no bags","Ride mule · no bags","Bring wagon · everyone"]
func _init():
 title="OUTFIT A HUNTING TRIP"
 get_ok_button().text="SET OUT"
 dialog_hide_on_ok=false
 var rows:=VBoxContainer.new()
 rows.custom_minimum_size=Vector2(500,0)
 add_child(rows)
 var grid:=GridContainer.new();grid.columns=2
 rows.add_child(grid)
 for pair in [["HUNTER",actor],["ANIMALS / TACK",kit],["RETURN LOAD",return_load],["DAYS AWAY",duration],["BULLETS TO TAKE",ammo]]:
  var text:=Label.new();text.text=pair[0];text.custom_minimum_size.x=130
  grid.add_child(text);pair[1].size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(pair[1])
 for text in KIT_LABELS:kit.add_item(text)
 for text in ["Normal load","Heavy load · slower / extra wear","Lead home · walking pace","Lead home heavily loaded"]:return_load.add_item(text)
 helpers.columns=2
 duration.min_value=1;duration.max_value=3;duration.step=1
 ammo.min_value=1;ammo.max_value=30;ammo.step=1
 rows.add_child(helpers)
 summary.tooltip_text="Good / Fair: full human carrying. Poor: gradually reduced to half. Very Poor: falls toward zero. Broken legs prevent hauling. The outbound pack uses part of this capacity; allocated tack and animals add only their own cargo."
 summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 summary.custom_minimum_size=Vector2(500,0)
 rows.add_child(summary)
 actor.item_selected.connect(func(_i):load_preference())
 kit.item_selected.connect(func(_i):refresh())
 return_load.item_selected.connect(func(_i):refresh())
 duration.value_changed.connect(func(_v):refresh())
 ammo.value_changed.connect(func(_v):refresh())
 confirmed.connect(func():
  duration.apply();ammo.apply()
  var q: Dictionary=quote()
  if q.get("valid",false):launch_requested.emit(actor_id(),config()))
func open(current,member: int=-1):
 game=current;loading=true
 actor.clear();actor.add_item("Leader · play the hunt",-1)
 for person in game.party_health.members:
  if int(person.id)!=game.camp_tasks.leader_id(game) and game.party_health.is_active(person):actor.add_item(person.name,int(person.id))
 actor.select(0 if member<0 else maxi(0,actor.get_item_index(member)))
 loading=false
 load_preference()
 reset_size();popup_centered(Vector2i(530,0))
func load_preference():
 if loading:return
 loading=true
 for child in helpers.get_children():helpers.remove_child(child);child.queue_free()
 helper_checks={}
 var id: int=actor_id()
 if id<0:
  for person in game.party_health.members:
   if int(person.id)==game.camp_tasks.leader_id(game) or not game.party_health.is_active(person):continue
   var check:=CheckBox.new()
   check.text=person.name
   check.disabled=game.camp_tasks.enabled() and game.camp_tasks.job(int(person.id)).job!="hunt_help"
   check.button_pressed=not check.disabled
   check.tooltip_text="Assign Help leader hunt in the camp roster to make a companion available. Patients cannot join."
   check.toggled.connect(func(_v):refresh())
   helpers.add_child(check);helper_checks[int(person.id)]=check
 var key: String="leader" if id<0 else str(id)
 var pref: Dictionary=game.field_outings.record.preferences.get(key,{"kit":"foot","days":1,"bullets":5})
 kit.set_item_disabled(game.field_outings.Outfit.KITS.find("wagon"),id>=0)
 kit.select(maxi(0,game.field_outings.Outfit.KITS.find(pref.kit)))
 return_load.select(maxi(0,game.field_outings.Outfit.RETURN_MODES.find(pref.get("return_mode","ride"))))
 duration.value=1 if id<0 else int(pref.days)
 duration.editable=id>=0
 ammo.value=int(pref.bullets)
 loading=false;refresh()
func config() -> Dictionary:
 var members: Array=[]
 if actor_id()<0:
  for person in game.party_health.members:
   if game.party_health.is_active(person):members.append(int(person.id));break
  for id in helper_checks:
   if helper_checks[id].button_pressed and int(id) not in members:members.append(int(id))
 if actor_id()<0 and game.field_outings.Outfit.KITS[kit.selected]=="wagon":members=game.party_health.members.filter(func(p):return game.party_health.is_active(p)).map(func(p):return int(p.id))
 return {"return_mode":game.field_outings.Outfit.RETURN_MODES[return_load.selected],"members":members,"kit":game.field_outings.Outfit.KITS[kit.selected],"days":int(duration.value),"bullets":int(ammo.value)}
func quote() -> Dictionary:
 var c: Dictionary=config()
 var id: int=actor_id()
 if id<0:return game.hunt_outfit_quote(c.members,c.kit,c.bullets,c.return_mode)
 var q: Dictionary=game.field_outings.Outfit.quote(game,[id],c.kit,c.days,c.bullets,c.return_mode)
 if q.get("valid",false) and c.days>1 and not q.mounted:return {"valid":false,"message":"Foot hunts are same-day trips. Longer outings need a riding animal."}
 return q
func refresh():
 if loading or game==null:return
 summary.tooltip_text="Good and Fair retain full human carrying. More time reserved for a slower loaded return means fewer chances to find game."
 var selected: String=game.field_outings.Outfit.KITS[kit.selected]
 var wagon: bool=selected=="wagon"
 helpers.visible=actor_id()<0 and not wagon
 return_load.disabled=selected in ["foot","wagon"]
 ammo.editable=not wagon
 for control in [return_load,duration,ammo]:
  var shown: bool=not wagon and (control!=duration or actor_id()>=0)
  control.visible=shown
  control.get_parent().get_child(control.get_index()-1).visible=shown
 var q: Dictionary=quote()
 get_ok_button().disabled=not q.get("valid",false)
 if not q.get("valid",false):summary.text=q.get("message","Cannot set out.");return
 var c: Dictionary=config()
 if wagon:
  summary.text="EVERYONE COMES · UP TO %d LB FREE CARGO\nUses wagon supplies; works the ox team for one day.\nNoise can scare game away. No camp chores today." % q.catch_lb
 else:
  summary.text="PACK %.1f LB · WORKING %.0f / ALLOWED %.0f LB\nUP TO %d LB CATCH · RIDER %.0f + TACK %.0f LB ON ANIMALS\n%d FOOD, %d CLOTHING, %d BULLETS · %s\n%s" % [q.pack_lb,q.working_lb,q.capacity_lb,q.catch_lb,q.rider_lb,q.tack_lb,q.inventory.food,q.inventory.clothing,q.inventory.bullets,"SHORT SUPPLIES: catch not guaranteed" if q.get("short_provisions",false) else "reserve included","One shared day; other camp jobs continue." if actor_id()<0 else "Riders can follow. Loaded returns are slower; crossings and bandits can kill."]
 if not wagon and float(q.get("search_factor",1.0))<1.0:
  summary.text+="\nSLOWER RETURN: %.0f%% SEARCH TIME · %.1f H RETURN BUFFER" % [q.search_factor*100,q.return_hours]
  summary.tooltip_text="Same one-day outing. More time reserved for the loaded return means fewer chances to find game. Hours are planning estimates; aim time and meat yield are unchanged."
 reset_size()


func actor_id() -> int:return -1 if actor.selected==0 else actor.get_selected_id()
