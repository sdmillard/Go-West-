extends AcceptDialog
var game
var rows:=VBoxContainer.new()
var summary:=Label.new()
var automatic:=Button.new()
var roster_scroll:=ScrollContainer.new()
var confirmation:=ConfirmationDialog.new()
var discard_index: int=-1
signal changed
func _ready() -> void:
 title="WAGONS & TEAMS";min_size=Vector2i(560,0);hide()
 var box:=VBoxContainer.new();add_child(box)
 summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;summary.custom_minimum_size=Vector2(530,42);box.add_child(summary)
 automatic.text="ASSIGN AVAILABLE DRIVERS & BALANCE OX TEAMS";box.add_child(automatic)
 automatic.pressed.connect(func():if game.Train.auto_assign(game):refresh();changed.emit())
 roster_scroll.custom_minimum_size=Vector2(530,52);box.add_child(roster_scroll)
 rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;roster_scroll.add_child(rows)
 add_child(confirmation);confirmation.title="LEAVE AN EMPTY WAGON";confirmation.get_ok_button().text="LEAVE IT BEHIND"
 confirmation.confirmed.connect(func():
  if game.Train.discard(game,discard_index):refresh();reset_size();changed.emit())
func open(value) -> void:
 game=value
 if get_parent() is Control:theme=get_parent().theme
 game.Train.ensure(game,game.state)
 refresh();reset_size();popup_centered()
func refresh() -> void:
 for child in rows.get_children():rows.remove_child(child);child.queue_free()
 roster_scroll.custom_minimum_size.y=clampf(game.wagon_count()*26,36,160)
 automatic.disabled=not game.can_service()
 update_summary()
 if game.wagon_count()==0:
  var label:=Label.new();label.text="Traveling with packs. Buy a wagon at a stocked settlement.";rows.add_child(label)
 for index in range(game.state.wagon_train.size()):
  var wagon: Dictionary=game.state.wagon_train[index]
  var row:=HBoxContainer.new();rows.add_child(row)
  var name_label:=Label.new();name_label.text="WAGON %d
%s" % [int(wagon.id)+1,"BROKEN" if wagon.condition<=0 else "SOUND"];name_label.custom_minimum_size.x=70;row.add_child(name_label)
  var driver:=OptionButton.new();driver.custom_minimum_size.x=135;row.add_child(driver)
  driver.add_item("UNASSIGNED",-1)
  var people: Array=game.Train.drivers(game)
  for id in people:
   driver.add_item(game.party_health.members[id].name,id)
   for other in game.state.wagon_train:
    if other!=wagon and other.driver==id:driver.set_item_disabled(driver.item_count-1,true)
  driver.select(people.find(int(wagon.driver))+1 if int(wagon.driver) in people else 0)
  driver.disabled=not game.can_service()
  driver.item_selected.connect(func(choice):
   if game.Train.assign(game,index,-1 if choice==0 else driver.get_item_id(choice),wagon.team):refresh();changed.emit())
  var team:=MenuButton.new();team.flat=false;team.text="%d OXEN · CONDITION %d%%" % [wagon.team.size(),game.Train.condition(game,wagon)];team.custom_minimum_size.x=210;row.add_child(team)
  for style in ["normal","hover","pressed","disabled"]:team.add_theme_stylebox_override(style,get_theme_stylebox(style,"Button"))
  team.disabled=not game.can_service()
  var leave:=Button.new();leave.text="LEAVE >";leave.custom_minimum_size.x=88;row.add_child(leave)
  leave.disabled=not game.can_service() or game.wagon_count()<2
  leave.pressed.connect(func():
   var offer: Dictionary=game.Train.discard_quote(game,index)
   if offer.is_empty():return
   discard_index=index
   confirmation.dialog_text="Leave empty wagon %d behind permanently? People, animals and supplies stay with you.\nRemaining cargo: %.1f / %.0f lb. Reassign freed oxen if needed.\nTo cache supplies and return later, use Abandon train / Choose packs instead." % [int(offer.wagon)+1,offer.cargo,offer.capacity]
   confirmation.popup_centered())
  var menu:=team.get_popup();menu.hide_on_checkable_item_selection=false
  for animal in range(game.team_conditions.record.oxen.size()):
   menu.add_check_item("Ox %d · %d%%" % [animal+1,game.team_conditions.record.oxen[animal]],animal)
   menu.set_item_checked(animal,animal in wagon.team)
   for other in game.state.wagon_train:
    if other!=wagon and animal in other.team:menu.set_item_disabled(animal,true)
  menu.about_to_popup.connect(func():
   for animal in range(menu.item_count):
    menu.set_item_checked(animal,animal in wagon.team)
    var used:=false
    for other in game.state.wagon_train:
     if other!=wagon and animal in other.team:used=true
    menu.set_item_disabled(animal,used))
  menu.id_pressed.connect(func(animal):
   var selected: Array=wagon.team.duplicate()
   if animal in selected:selected.erase(animal)
   else:selected.append(animal)
   if game.Train.assign(game,index,int(wagon.driver),selected):
    menu.set_item_checked(animal,animal in selected)
    team.text="%d OXEN · CONDITION %d%%" % [wagon.team.size(),game.Train.condition(game,wagon)]
    update_summary();changed.emit())

func update_summary() -> void:
 var reason: String=game.Train.ready(game)
 summary.text="%d WAGONS · %d TRAVELERS · %.0f / %.0f LB
%s" % [game.wagon_count(),game.state.party_size,game.provisions.cargo(game.state),game.provisions.capacity(game.state),reason if not reason.is_empty() else "One driver and a separate team per wagon. Supplies are shared across the train."]
