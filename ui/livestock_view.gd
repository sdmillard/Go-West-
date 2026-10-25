extends AcceptDialog
signal changed
var game
var rows:=VBoxContainer.new()
var confirmation:=ConfirmationDialog.new()
func _ready() -> void:
 title="LIVESTOCK & WORKING TEAM"
 get_ok_button().text="CLOSE"
 var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(460,250)
 add_child(scroll);scroll.add_child(rows);rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 add_child(confirmation);confirmation.title="BUTCHER AN ANIMAL?"
 confirmation.get_ok_button().text="BUTCHER"
func note(text: String) -> void:
 var line:=Label.new();line.text=text;line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;line.custom_minimum_size.x=440;rows.add_child(line)
func open(value) -> void:
 game=value;refresh();reset_size();popup_centered()
func refresh() -> void:
 for child in rows.get_children():rows.remove_child(child);child.queue_free()
 var o: Dictionary=game.livestock.outlook(game)
 note("GRAIN %.2f LB · HENS NEED %.2f LB / DAY\nCARE %.1f / %.1f HOURS AVAILABLE · SEASON %d%%" % [game.livestock.count(game.state,"poultry_feed")*0.25,int(o.feed_needed)*0.25,o.hours,o.budget,roundi(float(o.season)*100)])
 var grain_row:=HBoxContainer.new();rows.add_child(grain_row)
 var amount:=SpinBox.new();amount.min_value=0;amount.max_value=game.livestock.count(game.state,"poultry_feed");amount.step=1;amount.value=mini(4,int(amount.max_value));grain_row.add_child(amount)
 var discard:=Button.new();discard.text="DROP GRAIN (QUARTER LB UNITS)";discard.disabled=not game.can_service()
 discard.pressed.connect(func():
  game.livestock.drop_grain(game,int(amount.value));refresh();changed.emit())
 grain_row.add_child(discard)
 if not game.livestock.record.products.is_empty():
  var drop_food:=Button.new();drop_food.text="DISCARD UNCONVERTED MILK / EGGS";drop_food.disabled=not game.can_service()
  drop_food.pressed.connect(func():game.livestock.discard_products(game);refresh();changed.emit());rows.add_child(drop_food)
 var care:=CheckBox.new();care.text="Daily milking / feeding chores";care.button_pressed=game.livestock.record.care;care.disabled=not game.can_service()
 care.tooltip_text="Uses available healthy household members and adds fatigue. Nursing patients and companions on assigned work cannot also tend stock. Hens still consume their grain."
 care.toggled.connect(func(on):game.livestock.set_care(game,on);refresh();changed.emit());rows.add_child(care)
 if not game.livestock.last.is_empty():
  var last: Dictionary=game.livestock.last
  note("LAST DAY: %.2f LB MILK · %d EGGS · %d FOOD UNITS" % [last.milk_lb,last.eggs,last.food])
 note("Milk and eggs spoil. Small egg lots accumulate before rounding to food units. These foods do not replace fruit and greens.")
 for kind in game.livestock.ANIMALS:
  var group:=HBoxContainer.new();rows.add_child(group)
  var icon:=TextureRect.new();icon.texture=load("res://art/pixels/livestock_icons.png");icon.texture=AtlasTexture.new();icon.texture.atlas=load("res://art/pixels/livestock_icons.png");icon.texture.region=Rect2(game.livestock.ANIMALS.find(kind)*16,0,16,16);icon.custom_minimum_size=Vector2(24,24);group.add_child(icon)
  var title_line:=Label.new();title_line.text="%s: %d" % [game.livestock.data.animals[kind].label.to_upper(),game.livestock.count(game.state,kind)];group.add_child(title_line)
  for a in game.livestock.record.animals:
   if a.kind==kind:note("  #%d · %s%s" % [int(a.id)+1,game.PartyHealth.condition_label(int(a.condition))," · %d milk days left" % int(a.remaining) if kind!="hens" else ""])
  if game.livestock.count(game.state,kind)>0:
   for hand in ([false,true] if kind!="hens" else [true]):
    var offer: Dictionary=game.livestock.butcher_offer(game,kind,hand)
    var pick:=Button.new();pick.text="BUTCHER %s · %s" % [game.livestock.data.animals[kind].label.to_upper(),"BY HAND" if hand else "1 BULLET"];pick.disabled=offer.is_empty()
    pick.pressed.connect(confirm_butcher.bind(kind,hand));rows.add_child(pick)
 var teams: Dictionary=game.team_conditions.snapshot(game)
 note("WORKING OXEN: %d / %d · CHOOSE UP TO SIX\nSpare oxen are led and do not pull the wagon. Uncheck a tired ox, then check its replacement." % [teams.working.size(),teams.oxen.size()])
 var fittest:=Button.new();fittest.text="HITCH UP TO SIX FITTEST OXEN";fittest.disabled=not game.can_service()
 fittest.pressed.connect(func():
  var selection: Array=range(game.team_conditions.record.oxen.size())
  selection.sort_custom(func(a,b):return int(game.team_conditions.record.oxen[a])>int(game.team_conditions.record.oxen[b]))
  selection=selection.filter(func(i):return int(game.team_conditions.record.oxen[i])>0).slice(0,6)
  game.team_conditions.select(game,selection);refresh();changed.emit())
 rows.add_child(fittest)
 for i in range(teams.oxen.size()):
  var pick:=CheckBox.new();pick.text="OX %d · %s (%d)" % [i+1,game.PartyHealth.condition_label(int(teams.oxen[i])),teams.oxen[i]];pick.button_pressed=i in teams.working;pick.disabled=not game.can_service()
  pick.toggled.connect(func(on):
   var selection: Array=game.team_conditions.record.working.duplicate()
   if on:selection.append(i)
   else:selection.erase(i)
   game.team_conditions.select(game,selection);refresh();changed.emit())
  rows.add_child(pick)
 for kind in ["horses","mules"]:
  for i in range(teams[kind].size()):note("%s %d · %s (%d)" % [kind.trim_suffix("s").to_upper(),i+1,game.PartyHealth.condition_label(int(teams[kind][i])),teams[kind][i]])
func confirm_butcher(kind: String,hand: bool) -> void:
 var offer: Dictionary=game.livestock.butcher_offer(game,kind,hand)
 if offer.is_empty():return
 confirmation.dialog_text="Butcher one %s?\n%.1f lb edible meat before cargo limits.\nOne day; %d bullet(s); %d%% hand injury risk.\nThis permanently removes the animal and its future production." % [game.livestock.data.animals[kind].label.to_lower(),offer.meat,offer.bullets,roundi(float(offer.injury_chance)*100)]
 for callback in confirmation.confirmed.get_connections():confirmation.confirmed.disconnect(callback.callable)
 confirmation.confirmed.connect(func():game.livestock.butcher(game,kind,hand);refresh();changed.emit(),CONNECT_ONE_SHOT)
 confirmation.popup_centered()
