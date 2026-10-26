extends AcceptDialog
## Review a single local work day or request permission for personal property.
var game
var body:=VBoxContainer.new()
var panel_kind: String="work"
var result_text: String=""
var crew: Dictionary={}
var worker_choices: Dictionary={}
var commit_button: Button
var crew_summary: Label
func _ready():
 title="SETTLEMENT WORK";min_size=Vector2i(490,240)
 var scroll:=ScrollContainer.new();scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);scroll.offset_left=10;scroll.offset_top=8;scroll.offset_right=-10;scroll.offset_bottom=-8;add_child(scroll)
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
func open(current,kind: String) -> void:
 game=current;panel_kind=kind;result_text="";crew={};refresh();popup_centered(Vector2i(490,280 if kind=="work" else 250))
func text_line(message: String) -> void:
 var line:=Label.new();line.text=message;line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;line.custom_minimum_size.x=450;body.add_child(line)
func refresh() -> void:
 for child in body.get_children():body.remove_child(child);child.queue_free()
 title="SETTLEMENT WORK" if panel_kind=="work" else "PERSONAL KEEPSAKES"
 text_line(result_text)
 if panel_kind=="work":
  worker_choices={}
  text_line("Choose the crew for ONE paid day. Jobs have limited openings. Unselected travelers follow camp orders; party meals and contract wages still apply.")
  for id in crew.keys():
   if int(id)>=game.party_health.members.size() or not game.party_health.is_active(game.party_health.members[int(id)]):crew.erase(id)
  var offers: Array=game.income.offers(game)
  if offers.is_empty():crew.clear()
  if offers.is_empty():text_line("No local employment here now.")
  else:text_line("%d worker-days left here; up to %d workers today." % [offers[0].left,int(game.income.data.sites[str(game.state.landmark)].workers_per_day)])
  for person in game.party_health.members:
   if not game.party_health.is_active(person):continue
   var row:=HBoxContainer.new();body.add_child(row)
   var name_tag:=Label.new();name_tag.text=person.name;name_tag.custom_minimum_size.x=85;row.add_child(name_tag)
   var choice:=OptionButton.new();choice.custom_minimum_size.x=340;row.add_child(choice);worker_choices[int(person.id)]=choice
   choice.add_item("Camp orders / rest");choice.set_item_metadata(0,"")
   for offer in offers:
    var q: Dictionary=game.income.quote(game,int(person.id),offer.id)
    choice.add_item("%s · $%.2f [%d slots]" % [offer.label,float(q.get("cents",offer.cents) if q.valid else offer.cents)/100.0,offer.openings]);choice.set_item_metadata(choice.item_count-1,offer.id)
    choice.set_item_disabled(choice.item_count-1,not q.valid)
    choice.get_popup().set_item_tooltip(choice.item_count-1,q.message+"\nPay uses the job rate or this traveler's mercenary market quote, whichever is higher. Private contract amounts do not raise local offers.")
    if crew.get(str(person.id),"")==offer.id:choice.select(choice.item_count-1)
   choice.item_selected.connect(func(selected):
    var job: String=choice.get_item_metadata(selected)
    if job.is_empty():crew.erase(str(person.id))
    else:crew[str(person.id)]=job
    refresh_crew())
  crew_summary=Label.new();crew_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;crew_summary.custom_minimum_size.x=450;body.add_child(crew_summary)
  commit_button=Button.new();commit_button.text="WORK SELECTED CREW · 1 DAY";body.add_child(commit_button)
  commit_button.pressed.connect(func():
   var q: Dictionary=game.income.crew_quote(game,crew)
   if q.valid and game.income.work_crew(game,crew):result_text="Crew earned $%.2f. One day passed; see the journal." % (q.cents/100.0)
   refresh())
  refresh_crew()
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

func refresh_crew() -> void:
 var q: Dictionary=game.income.crew_quote(game,crew)
 crew_summary.text=q.message
 commit_button.disabled=not q.valid
 commit_button.tooltip_text=q.message
