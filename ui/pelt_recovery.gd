extends VBoxContainer
## Optional physical skins from the current player hunt; no resource mutation.
var game
var quantities: Dictionary={}
var detail:=Label.new()
var updating:=false
func _init():
 var heading:=Label.new();heading.text="OPTIONAL TRADE SKINS - EXTRA CAMP DAY";add_child(heading)
 var choices:=HBoxContainer.new();add_child(choices)
 for pair in [["bison_hide","BISON"],["deer_hide","DEER"],["rabbit_pelt","RABBIT"]]:
  var name:=Label.new();name.text=pair[1];choices.add_child(name)
  var count:=SpinBox.new();count.min_value=0;count.max_value=0;count.step=1;count.custom_minimum_size.x=66
  choices.add_child(count);quantities[pair[0]]=count
  count.value_changed.connect(func(_v):if not updating:refresh())
 detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.custom_minimum_size=Vector2(432,34);add_child(detail)
func reset(current):
 game=current;updating=true
 for box in quantities.values():box.value=0
 updating=false;refresh()
func cart() -> Dictionary:
 var result: Dictionary={}
 for item in quantities:
  if quantities[item].value>0:result[item]=int(quantities[item].value)
 return result
func clear():
 updating=true
 for box in quantities.values():box.value=0
 updating=false;refresh()
func refresh():
 if game==null or updating or game.hunt.is_empty():return
 updating=true
 var available: Dictionary=game.pelt_quote({}).get("available",{})
 for item in quantities:
  quantities[item].max_value=int(available.get(item,0))
  var rule: Dictionary=game.provisions.data.pelts.goods[item]
  quantities[item].tooltip_text="%s: %.1f lb raw, %.1f lb prepared; base post offer $%.2f. Preparing selected skins costs an extra camp day and meals." % [rule.label,rule.raw_lb,rule.weight_lb,rule.sell_cents/100.0]
 var q: Dictionary=game.pelt_quote(cart());detail.text=q.message
 detail.modulate=Color.WHITE if q.valid else Color("a03020")
 updating=false
