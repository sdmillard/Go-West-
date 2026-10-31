extends AcceptDialog
signal changed
var game
var rows:=VBoxContainer.new()
func _ready() -> void:
 title="WORKING DOG"
 get_ok_button().text="CLOSE"
 var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(450,250)
 add_child(scroll);scroll.add_child(rows);rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
func note(text: String) -> void:
 var line:=Label.new();line.text=text;line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;line.custom_minimum_size.x=420;rows.add_child(line)
func open(value) -> void:
 game=value;refresh();reset_size();popup_centered()
func refresh() -> void:
 for child in rows.get_children():rows.remove_child(child);child.queue_free()
 if not game.dogs.alive():
  if not game.dogs.record.dog.is_empty():note("%s has died. Their story remains in the journal." % game.dogs.record.dog.name)
  else:note("No dog travels with the party.")
  note("One working farm shepherd can accompany you. Dogs eat from real provisions and need rest. They do not occupy a traveler slot.")
  var buy:=Button.new();buy.text="BUY WORKING DOG · $%.2f" % (game.dogs.data.price_cents/100.0)
  buy.disabled=not game.dogs.available(game) or game.state.money*100<game.dogs.data.price_cents
  buy.tooltip_text="Available at towns and forts; one offer per post. Price is an authored estimate."
  buy.pressed.connect(func():
   if game.dogs.acquire(game):refresh();changed.emit())
  rows.add_child(buy);return
 var dog: Dictionary=game.dogs.record.dog
 var portrait:=TextureRect.new();var frame:=AtlasTexture.new();frame.atlas=preload("res://art/pixels/dog.png");frame.region=Rect2(0,0,48,44);portrait.texture=frame;portrait.custom_minimum_size=Vector2(96,88);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;rows.add_child(portrait)
 note("%s · %s · FATIGUE %d/100" % [dog.name,game.PartyHealth.condition_label(roundi(dog.condition)),roundi(dog.fatigue)])
 var grid:=GridContainer.new();grid.columns=2;rows.add_child(grid)
 var label:=Label.new();label.text="NAME";grid.add_child(label)
 var name_edit:=LineEdit.new();name_edit.name="DogName";name_edit.text=dog.name;name_edit.max_length=20;name_edit.custom_minimum_size.x=240;name_edit.editable=game.can_service();grid.add_child(name_edit)
 label=Label.new();label.text="JOB";grid.add_child(label)
 var jobs:=OptionButton.new();jobs.name="DogJob"
 var job_keys: Array=["watch","hunt","rest"]
 for item in ["Camp watch","Help hunt","Rest"]:jobs.add_item(item)
 jobs.select(job_keys.find(dog.job));jobs.disabled=not game.can_service();grid.add_child(jobs)
 jobs.tooltip_text="Watch: may warn of visitors and reduce horse-theft encounter weight. Hunt: joins leader hunts, helps locate game and may catch a rabbit. Rest: recovers fatigue. Weak, hungry or exhausted dogs cannot work."
 label=Label.new();label.text="FEEDING";grid.add_child(label)
 var feeding:=OptionButton.new();feeding.name="DogFeeding";var feed_keys: Array=["share","surplus","off"]
 for item in ["Share provisions after people eat","Reserve tomorrow's human meals","Do not share provisions"]:feeding.add_item(item)
 feeding.select(feed_keys.find(dog.feeding));feeding.disabled=not game.can_service();grid.add_child(feeding)
 feeding.tooltip_text="All meals consume actual portions, meat or staples. Fruit and greens are kept for people. No free scraps are generated."
 var save:=Button.new();save.text="APPLY";save.disabled=not game.can_service()
 save.pressed.connect(func():
  if game.dogs.configure(game,name_edit.text,job_keys[jobs.selected],feed_keys[feeding.selected]):refresh();changed.emit())
 rows.add_child(save)
 note("MEALS: 1.2 food units at rest; 1.6 while working or traveling.\nLast meal: %d%% of need. Rest restores fatigue; adequate meals and camp rest improve condition." % roundi(dog.fed*100))
 if float(dog.condition)<50 or float(dog.fatigue)>=75 or float(dog.fed)<0.75:note("NOT FIT FOR WORK: rest and feed the dog before the next assignment.")
