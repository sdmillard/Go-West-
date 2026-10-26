extends AcceptDialog
## Review a single local work day or request permission for personal property.
var game
var body:=VBoxContainer.new()
var panel_kind: String="work"
var result_text: String=""
func _ready():
 title="SETTLEMENT WORK";min_size=Vector2i(490,240)
 var scroll:=ScrollContainer.new();scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);scroll.offset_left=10;scroll.offset_top=8;scroll.offset_right=-10;scroll.offset_bottom=-8;add_child(scroll)
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
func open(current,kind: String) -> void:
 game=current;panel_kind=kind;result_text="";refresh();popup_centered(Vector2i(490,250))
func text_line(message: String) -> void:
 var line:=Label.new();line.text=message;line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;line.custom_minimum_size.x=450;body.add_child(line)
func refresh() -> void:
 for child in body.get_children():body.remove_child(child);child.queue_free()
 title="SETTLEMENT WORK" if panel_kind=="work" else "PERSONAL KEEPSAKES"
 text_line(result_text)
 if panel_kind=="work":
  text_line("One worker, one day. Party meals and contracted wages still apply; no employer board. Camp orders continue for everyone else.")
  var offers: Array=game.income.offers(game)
  if offers.is_empty():text_line("No local employment here now.")
  if not offers.is_empty():text_line("%d paid day(s) left at this stop; all jobs share this limit." % offers[0].left)
  for person in game.party_health.members:
   if not game.party_health.is_active(person):continue
   var row:=HBoxContainer.new();body.add_child(row)
   var name_tag:=Label.new();name_tag.text=person.name;name_tag.custom_minimum_size.x=85;row.add_child(name_tag)
   var choice:=OptionButton.new();choice.custom_minimum_size.x=245;row.add_child(choice)
   var choose:=Button.new();choose.text="WORK 1 DAY";row.add_child(choose)
   for offer in offers:
    var q: Dictionary=game.income.quote(game,int(person.id),offer.id)
    choice.add_item("%s · $%.2f" % [offer.label,offer.cents/100.0]);choice.set_item_disabled(choice.item_count-1,not q.valid)
    choice.get_popup().set_item_tooltip(choice.item_count-1,q.message)
   choose.disabled=offers.is_empty() or not game.income.quote(game,int(person.id),offers[0].id).valid
   choice.item_selected.connect(func(selected):
    var q: Dictionary=game.income.quote(game,int(person.id),offers[selected].id)
    choose.disabled=not q.valid;choose.tooltip_text=q.message)
   choose.pressed.connect(func():
    var q: Dictionary=game.income.quote(game,int(person.id),offers[choice.selected].id)
    if q.valid and game.income.work(game,int(person.id),offers[choice.selected].id):result_text="Paid $%.2f. See the journal for the day's events." % (q.cents/100.0)
    refresh())
  text_line("DAY COST: %d party food units at current rations; normal wage bills, spoilage and weather. No travel miles." % (int(game.provisions.data.rations_lb[game.state.rations])*int(game.state.party_size)))
 else:
  text_line("Small family keepsakes: 0.25 lb each; estimated post resale $2. Bringing each one to Oregon earns 100 keepsake points. Companion consent is required to sell.")
  if game.income.record.keepsakes.is_empty():text_line("No personal keepsakes were brought on this journey.")
  for owner in game.income.record.keepsakes:
   var index: int=int(owner);var held: bool=int(game.state.get(game.income.key(index),0))>0
   text_line("%s · %s" % [game.income.label_for(game,game.income.key(index)),"CARRIED" if held else "Not with the party (sold, cached, away or lost)"])
   if not game.party_health.members[index].alive:
    text_line("Deceased owner: may be sold as estate goods, or retained as a memorial.")
    continue
   var allow: bool=not game.income.record.keepsakes[owner].consent
   var ask:=Button.new();ask.text="ASK PERMISSION TO SELL" if allow else "WITHDRAW SALE PERMISSION"
   ask.disabled=not held or not game.can_service() or (allow and not game.income.can_consent(game,index))
   ask.tooltip_text="Owners must be present and trust you (50 or more). Granting permission takes no day; sell through an available trading counter."
   ask.pressed.connect(func():
    if game.income.consent(game,index,allow):result_text="Sale permission updated."
    refresh())
   body.add_child(ask)
