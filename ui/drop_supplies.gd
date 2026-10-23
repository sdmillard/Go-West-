extends ConfirmationDialog
signal discarded
signal inventory_requested
const Plan=preload("res://simulation/discard_plan.gd")
var game
var quantities: Dictionary={}
var table: GridContainer
var preview: Label
func words(text: String) -> Label:
 var item:=Label.new()
 item.text=text
 return item
func _init():
 title="DROP SUPPLIES"
 dialog_hide_on_ok=false
 get_ok_button().text="DROP SELECTED"
 confirmed.connect(_confirm)
 var content:=VBoxContainer.new()
 content.custom_minimum_size=Vector2(570,245)
 content.add_theme_constant_override("separation",7)
 add_child(content)
 table=GridContainer.new()
 table.columns=5
 table.add_theme_constant_override("h_separation",12)
 table.add_theme_constant_override("v_separation",3)
 content.add_child(table)
 preview=words("")
 preview.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 preview.custom_minimum_size=Vector2(550,34)
 preview.size=Vector2(550,34)
 content.add_child(preview)
 var back:=Button.new()
 back.text="< SUPPLIES"
 back.pressed.connect(func():hide();inventory_requested.emit())
 content.add_child(back)
func open(current_game) -> void:
 game=current_game
 quantities={}
 for child in table.get_children():table.remove_child(child);child.queue_free()
 for heading in ["SUPPLY","HAVE","TOTAL LB","LB / UNIT","DROP"]:table.add_child(words(heading))
 for row in Plan.stock(game):
  var title_label:=words(row.label)
  title_label.custom_minimum_size.x=110
  table.add_child(title_label)
  table.add_child(words(str(row.amount)))
  table.add_child(words("%.1f" % row.mass_lb))
  table.add_child(words("%.2f%s" % [row.unit_lb," avg" if row.average else ""]))
  var input:=SpinBox.new()
  input.min_value=0
  input.max_value=row.amount
  input.step=1
  input.rounded=true
  input.update_on_text_changed=true
  input.editable=row.amount>0
  input.custom_minimum_size=Vector2(94,19)
  input.value_changed.connect(func(_value):update_quote())
  quantities[row.id]=input
  table.add_child(input)
 update_quote()
 _fit_open.call_deferred()
func cart() -> Dictionary:
 var result: Dictionary={}
 for item in quantities:result[item]=int(quantities[item].value)
 return result
func update_quote() -> void:
 var plan: Dictionary=Plan.quote(game,cart())
 get_ok_button().disabled=not plan.valid
 preview.text="DROP %.1f LB · LOAD AFTER %.1f / %.0f LB%s\n%s" % [plan.dropped_lb,plan.after_lb,plan.capacity_lb," · STILL OVERLOADED" if plan.after_lb>plan.capacity_lb else "",plan.message]
 preview.tooltip_text="Food's unit weight is an average across fresh, dried and staple food. The drop preview uses the actual batches removed."
func _confirm() -> void:
 # Apply any text still being edited before the confirmation button receives focus.
 for input in quantities.values():input.apply()
 if game.discard_supplies(cart()):
  hide()
  discarded.emit()
 else:update_quote()

func _fit_open() -> void:
 # Grid minimums settle after controls inherit the pixel theme; avoid an oversized first popup.
 await get_tree().process_frame
 await get_tree().process_frame
 reset_size()
 size=Vector2i(get_contents_minimum_size())
 popup_centered(size)
