extends ConfirmationDialog
signal launch_requested(actor: int,config: Dictionary)
var game
var actor:=OptionButton.new()
var kit:=OptionButton.new()
var duration:=SpinBox.new()
var ammo:=SpinBox.new()
var helpers:=VBoxContainer.new()
var summary:=Label.new()
var helper_checks: Dictionary={}
var loading:=false
const KIT_LABELS=["On foot","Ride horse + saddlebags","Lead pack horse","Ride mule + saddlebags","Lead pack mule","Ride horse + lead pack mule"]
func _init():
 title="OUTFIT A HUNTING TRIP"
 get_ok_button().text="SET OUT"
 dialog_hide_on_ok=false
 var rows:=VBoxContainer.new()
 rows.custom_minimum_size=Vector2(500,0)
 add_child(rows)
 var grid:=GridContainer.new();grid.columns=2
 rows.add_child(grid)
 for pair in [["HUNTER",actor],["ANIMALS / TACK",kit],["DAYS AWAY",duration],["BULLETS TO TAKE",ammo]]:
  var text:=Label.new();text.text=pair[0];text.custom_minimum_size.x=130
  grid.add_child(text);pair[1].size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(pair[1])
 for text in KIT_LABELS:kit.add_item(text)
 duration.min_value=1;duration.max_value=3;duration.step=1
 ammo.min_value=1;ammo.max_value=30;ammo.step=1
 rows.add_child(helpers)
 summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 summary.custom_minimum_size=Vector2(500,80)
 rows.add_child(summary)
 actor.item_selected.connect(func(_i):load_preference())
 kit.item_selected.connect(func(_i):refresh())
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
  if int(person.id)>0 and game.party_health.is_active(person):actor.add_item(person.name,int(person.id))
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
   if int(person.id)==0 or not game.party_health.is_active(person):continue
   var check:=CheckBox.new()
   check.text=person.name+" · hunt helper"
   check.disabled=game.camp_tasks.enabled() and game.camp_tasks.job(int(person.id)).job!="hunt_help"
   check.button_pressed=not check.disabled
   check.tooltip_text="Assign Help leader hunt in the camp roster to make a companion available. Patients cannot join."
   check.toggled.connect(func(_v):refresh())
   helpers.add_child(check);helper_checks[int(person.id)]=check
 var key: String="leader" if id<0 else str(id)
 var pref: Dictionary=game.field_outings.record.preferences.get(key,{"kit":"foot","days":1,"bullets":5})
 kit.select(game.field_outings.Outfit.KITS.find(pref.kit))
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
 return {"members":members,"kit":game.field_outings.Outfit.KITS[kit.selected],"days":int(duration.value),"bullets":int(ammo.value)}
func quote() -> Dictionary:
 var c: Dictionary=config()
 var id: int=actor_id()
 if id<0:return game.hunt_outfit_quote(c.members,c.kit,c.bullets)
 var q: Dictionary=game.field_outings.Outfit.quote(game,[id],c.kit,c.days,c.bullets)
 if q.get("valid",false) and c.days>1 and not q.mounted:return {"valid":false,"message":"Foot hunts are same-day trips. Longer outings need a riding animal."}
 return q
func refresh():
 if loading or game==null:return
 var q: Dictionary=quote()
 get_ok_button().disabled=not q.get("valid",false)
 if not q.get("valid",false):summary.text=q.get("message","Cannot set out.");return
 var c: Dictionary=config()
 summary.text="OUTBOUND %.1f / %.1f LB · UP TO %d LB CATCH\nPACK: %d FOOD UNITS (includes one reserve day), %d CLOTHING, %d BULLETS\nONLY THESE PEOPLE AND ALLOCATED ANIMALS HELP.\n%s" % [q.pack_lb,q.capacity_lb,q.catch_lb,q.inventory.food,q.inventory.clothing,q.inventory.bullets,"Leader hunt: one shared day. Other camp tasks can continue." if actor_id()<0 else "One trip. Mounted hunters can rejoin the moving train; delays can strand them. Animal and pack supplies leave camp now."]

func actor_id() -> int:return -1 if actor.selected==0 else actor.get_selected_id()
