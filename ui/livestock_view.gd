extends AcceptDialog
signal changed
## Oxen, horses and mules are butchered through main.gd's confirmation (it knows team speed and cargo).
signal slaughter_requested(by_hand: bool,kind: String)
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
 note("GRAIN %.2f LB · DAIRY FODDER %.2f LB\nCARE %.1f / %.1f HOURS AVAILABLE" % [game.livestock.Feeding.available(game,"poultry_feed"),game.livestock.Feeding.available(game,"livestock_fodder"),o.hours,o.budget])
 note("TRAVEL FEED ESTIMATE: scratch %.2f lb equiv. · shared portions %.2f lb · grain %.2f lb · fodder %.2f lb" % [o.feeding.scratch_lb,o.feeding.scraps_lb,o.feeding.grain_lb,o.feeding.fodder_lb])
 for kind in game.livestock.ANIMALS:
  if game.livestock.count(game.state,kind)>0:
   var feeding: Dictionary=o.feeding.animals[kind]
   if kind=="hens":note("HEN FEED COVERAGE: %d%%" % roundi(float(feeding.intake)*100))
   else:note("%s: upkeep %d%% · milk potential %d%%" % [game.livestock.data.animals[kind].label.to_upper(),roundi(float(feeding.maintenance_coverage)*100),roundi(float(feeding.production)*100)])
 if o.waterless:note("WATERLESS ROAD: adequate feed does not prevent thirst.")
 note("GRAZING SEASON %d%% · LAYING DAYLIGHT %d%%" % [roundi(float(o.season)*100),roundi(float(game.livestock.data.feeding.laying_months[int(game.calendar().month)-1])*100)])
 var sharing:=CheckBox.new();sharing.text="Feed edible food portions to hens";sharing.button_pressed=game.livestock.record.get("share_scraps",true);sharing.disabled=not game.can_service()
 sharing.tooltip_text="Optional: gives hens food people could eat, before using poultry grain. Starts off on new journeys. The current human ration and vitamin-bearing fruit portions are protected. Scratching and grain feeding continue while this is off."
 sharing.toggled.connect(func(on):game.livestock.set_scraps(game,on);refresh();changed.emit());rows.add_child(sharing)
 var grain_row:=HBoxContainer.new();rows.add_child(grain_row)
 var amount:=SpinBox.new();amount.min_value=0;amount.max_value=game.livestock.count(game.state,"poultry_feed");amount.step=1;amount.value=mini(4,int(amount.max_value));grain_row.add_child(amount)
 var discard:=Button.new();discard.text="DROP GRAIN (QUARTER LB UNITS)";discard.disabled=not game.can_service()
 discard.pressed.connect(func():
  game.livestock.drop_grain(game,int(amount.value));refresh();changed.emit())
 grain_row.add_child(discard)
 if not game.livestock.record.products.is_empty():
  var drop_food:=Button.new();drop_food.text="DISCARD TABLE FOOD / PARTIAL PORTIONS";drop_food.disabled=not game.can_service()
  drop_food.pressed.connect(func():game.livestock.discard_products(game);refresh();changed.emit());rows.add_child(drop_food)
 note("TABLE FOOD: %.2f UNITS · %.2f LB (includes partial portions)" % [game.livestock.available_kcal()/1000.0,float(game.state.get("livestock_products_lb",0))])
 var fodder_row:=HBoxContainer.new();rows.add_child(fodder_row)
 var fodder:=SpinBox.new();fodder.min_value=0;fodder.max_value=game.livestock.count(game.state,"livestock_fodder");fodder.step=1;fodder.value=mini(25,int(fodder.max_value));fodder_row.add_child(fodder)
 var drop_fodder:=Button.new();drop_fodder.text="DROP DAIRY FODDER (LB)";drop_fodder.disabled=not game.can_service()
 drop_fodder.pressed.connect(func():game.livestock.drop_feed(game,"livestock_fodder",int(fodder.value));refresh();changed.emit());fodder_row.add_child(drop_fodder)
 if game.livestock.FEED_REMAINDERS.any(func(key):return float(game.state.get(key,0))>0):
  var partial_feed:=Button.new();partial_feed.text="DISCARD PARTIAL FEED SERVINGS";partial_feed.disabled=not game.can_service()
  partial_feed.pressed.connect(func():game.livestock.discard_feed_remainders(game);refresh();changed.emit());rows.add_child(partial_feed)
 var care:=CheckBox.new();care.text="Daily milking / feeding chores";care.button_pressed=game.livestock.record.care;care.disabled=not game.can_service()
 care.tooltip_text="Uses available healthy household members and adds fatigue. Nursing patients and companions doing other work today cannot also tend stock. Idle travel-day camp orders do not reserve workers. Hens still use grain as needed."
 care.toggled.connect(func(on):game.livestock.set_care(game,on);refresh();changed.emit());rows.add_child(care)
 if not game.livestock.last.is_empty():
  var last: Dictionary=game.livestock.last
  note("LAST DAY: %.2f LB MILK · %d EGGS · %.2f FOOD UNITS" % [last.milk_lb,last.eggs,last.food])
 note("Milk and eggs keep their actual food value, including small servings. Partial portions keep their weight and expiry. Milk and eggs do not replace fruit and greens.")
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
 if game.wagon_count()>1:note("Assign separate wagon teams through SUPPLIES > WAGONS & TEAMS.")
 note("WORKING OXEN: %d / %d · CHOOSE UP TO SIX\nSpare oxen are led and do not pull the wagon. Uncheck a tired ox, then check its replacement." % [teams.working.size(),teams.oxen.size()])
 var fittest:=Button.new();fittest.text="HITCH UP TO SIX FITTEST OXEN";fittest.disabled=not game.can_service() or game.wagon_count()>1
 fittest.pressed.connect(func():
  var selection: Array=range(game.team_conditions.record.oxen.size())
  selection.sort_custom(func(a,b):return int(game.team_conditions.record.oxen[a])>int(game.team_conditions.record.oxen[b]))
  selection=selection.filter(func(i):return int(game.team_conditions.record.oxen[i])>0).slice(0,6)
  game.team_conditions.select(game,selection);refresh();changed.emit())
 rows.add_child(fittest)
 for i in range(teams.oxen.size()):
  var pick:=CheckBox.new();pick.text="OX %d · %s (%d)" % [i+1,game.PartyHealth.condition_label(int(teams.oxen[i])),teams.oxen[i]];pick.button_pressed=i in teams.working;pick.disabled=not game.can_service() or game.wagon_count()>1
  pick.toggled.connect(func(on):
   var selection: Array=game.team_conditions.record.working.duplicate()
   if on:selection.append(i)
   else:selection.erase(i)
   game.team_conditions.select(game,selection);refresh();changed.emit())
  rows.add_child(pick)
 for kind in ["horses","mules"]:
  for i in range(teams[kind].size()):note("%s %d · %s (%d)" % [kind.trim_suffix("s").to_upper(),i+1,game.PartyHealth.condition_label(int(teams[kind][i])),teams[kind][i]])
 # Emergency meat from the team itself, once lived under SUPPLIES; one place only.
 var team_offers: Array=[]
 var ox_offer: Dictionary=game.ox_slaughter_offer()
 if not ox_offer.is_empty():team_offers.append(["SHOOT / BUTCHER 1 OX · %d LB · 1 BULLET · 1 DAY" % ox_offer.meat,false,"oxen","Smaller teams pull less cargo and travel slowly. No oxen means no wagon movement. Meat may spoil."])
 var hand_offer: Dictionary=game.ox_slaughter_offer(true)
 if not hand_offer.is_empty():team_offers.append(["BUTCHER 1 OX BY HAND · NO AMMO · %d%% INJURY RISK · 1 DAY" % roundi(hand_offer.injury_chance*100),true,"oxen","Smaller teams pull less cargo and travel slowly. No oxen means no wagon movement. Meat may spoil."])
 for kind in game.Mounts.ANIMALS:
  var stock_offer: Dictionary=game.mount_slaughter_offer(kind,game.state.bullets<1)
  if stock_offer.is_empty():continue
  var animal: String={"horses":"HORSE","mules":"MULE"}[kind]
  team_offers.append([("BUTCHER 1 %s · %d LB · " % [animal,stock_offer.meat])+("1 BULLET · 1 DAY" if not stock_offer.by_hand else "BY HAND · %d%% INJURY RISK · 1 DAY" % roundi(stock_offer.injury_chance*100)),stock_offer.by_hand,kind,"Fewer animals means fewer riders and smaller loads. Meat may spoil."])
 if not team_offers.is_empty():
  note("SLAUGHTER FOR MEAT")
  for offer in team_offers:
   var kill:=Button.new();kill.text=offer[0];kill.tooltip_text=offer[3];kill.name="Slaughter"+str(offer[2]).capitalize()+("ByHand" if offer[1] else "")
   kill.pressed.connect(func():slaughter_requested.emit(offer[1],offer[2]))
   rows.add_child(kill)
func confirm_butcher(kind: String,hand: bool) -> void:
 var offer: Dictionary=game.livestock.butcher_offer(game,kind,hand)
 if offer.is_empty():return
 confirmation.dialog_text="Butcher one %s?\n%.1f lb edible meat before cargo limits.\nOne day; %d bullet(s); %d%% hand injury risk.\nThis permanently removes the animal and its future production." % [game.livestock.data.animals[kind].label.to_lower(),offer.meat,offer.bullets,roundi(float(offer.injury_chance)*100)]
 for callback in confirmation.confirmed.get_connections():confirmation.confirmed.disconnect(callback.callable)
 confirmation.confirmed.connect(func():game.livestock.butcher(game,kind,hand);refresh();changed.emit(),CONNECT_ONE_SHOT)
 confirmation.popup_centered()
