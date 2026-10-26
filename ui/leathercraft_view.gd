extends AcceptDialog
var game
var body:=VBoxContainer.new()
func _ready():
 title="LEATHERWORK";min_size=Vector2i(480,240)
 var scroll:=ScrollContainer.new();scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);scroll.offset_left=10;scroll.offset_top=8;scroll.offset_right=-10;scroll.offset_bottom=-8;add_child(scroll)
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
func line(message: String):
 var node:=Label.new();node.text=message;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.custom_minimum_size.x=450;body.add_child(node)
func open(current):game=current;refresh();popup_centered(Vector2i(480,270))
func refresh():
 for child in body.get_children():body.remove_child(child);child.queue_free()
 line("Leatherworking background required. Each click spends ONE camp day on one stage. Other companions follow camp orders. Meals and contract wages still apply.")
 line("Rough deer hide > scraped > softened > buckskin (3 worker-days); buckskin > glove pieces > 4 pairs of gloves (2 more). Tools and dressing supplies are assumed in your household kit.")
 var stock: Array[String]=[]
 for item in ["deer_hide"]+game.leathercraft.items():stock.append("%s: %d" % [game.leathercraft.label_for(item),int(game.state.get(item,0))])
 line(" · ".join(stock))
 var artisans:=0
 for person in game.party_health.members:
  if not game.party_health.is_active(person) or not game.leathercraft.qualified(game,int(person.id)):continue
  artisans+=1;line(person.name)
  for job in game.leathercraft.data.recipes:
   var q: Dictionary=game.leathercraft.quote(game,int(person.id),job)
   var button:=Button.new();button.text=game.leathercraft.data.recipes[job].label.to_upper()+" · 1 DAY";button.disabled=not q.valid;button.tooltip_text=q.message
   button.pressed.connect(func():
    game.leathercraft.work(game,int(person.id),job);refresh())
   body.add_child(button)
 if artisans==0:line("No leatherworker is currently with the party. Choose Leatherworking as a background at creation, or recruit someone with that background.")
 line("For work during already-needed camp days, assign Dress deer hides or Make buckskin gloves in Companion Tasks. Finished goods sell through the normal trading counters.")
