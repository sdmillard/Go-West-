extends ConfirmationDialog
signal committed
var game
var quantities: Dictionary={}
var quote_label: Label
var goods_box: VBoxContainer
var last_offer: Dictionary={}
func _ready() -> void:
 title="MAKE A ROBBERY DEMAND"
 get_ok_button().text="MAKE DEMAND"
 var layout:=VBoxContainer.new()
 layout.custom_minimum_size=Vector2(500,0)
 add_child(layout)
 var intro:=Label.new()
 intro.text="Choose what to demand. A larger share makes resistance likelier.\nAn available wagon can be seized while you are on foot.\nCommitting spends one day; witnesses and escape risks still apply."
 layout.add_child(intro)
 var scroll:=ScrollContainer.new()
 scroll.custom_minimum_size=Vector2(500,140)
 layout.add_child(scroll)
 goods_box=VBoxContainer.new()
 goods_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(goods_box)
 quote_label=Label.new()
 quote_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 quote_label.custom_minimum_size=Vector2(500,55)
 layout.add_child(quote_label)
 confirmed.connect(func():
  hide()
  if game.demand_robbery(basket()):committed.emit())
func basket() -> Dictionary:
 var result: Dictionary={}
 for item in quantities:
  var n:=roundi(quantities[item].value*(100.0 if item=="cash_cents" else 1.0))
  if n>0:result[item]=n
 return result
func refresh_quote() -> void:
 last_offer=game.robbery_quote(basket())
 get_ok_button().disabled=not last_offer.valid
 quote_label.text=str(last_offer.message)
 if last_offer.has("compliance"):
  quote_label.text="DEMAND VALUE $%.2f · COMPLIANCE %d%%\nLOAD %.1f / %.1f LB\n%s" % [int(last_offer.value_cents)/100.0,roundi(last_offer.compliance*100),last_offer.cargo_lb,last_offer.capacity_lb,last_offer.message]
func open(model) -> void:
 game=model
 quantities={}
 for child in goods_box.get_children():goods_box.remove_child(child);child.queue_free()
 var stock: Dictionary=game.RobberyDemand.stock(game,game.crime.target(game))
 for item in stock:
  var available: int=stock[item]
  if available<=0:continue
  if item=="wagon" and game.state.vehicle!="foot":continue
  var row:=HBoxContainer.new()
  goods_box.add_child(row)
  var caption:=Label.new()
  caption.text=("CASH · AVAILABLE $%.2f" % (available/100.0)) if item=="cash_cents" else "%s · AVAILABLE %d" % [{"food":"FOOD UNITS","medicine":"CARE KITS","clothing":"CLOTHING SETS"}.get(item,item.to_upper()),available]
  caption.custom_minimum_size.x=350
  row.add_child(caption)
  var quantity:=SpinBox.new()
  quantity.min_value=0
  quantity.max_value=available/100.0 if item=="cash_cents" else available
  quantity.step=0.01 if item=="cash_cents" else 1.0
  quantity.custom_minimum_size=Vector2(125,20)
  row.add_child(quantity)
  quantities[item]=quantity
  quantity.value_changed.connect(func(_value):refresh_quote())
 if quantities.has("cash_cents"):quantities.cash_cents.value=minf(5.0,float(quantities.cash_cents.max_value))
 refresh_quote()
 popup_centered()
