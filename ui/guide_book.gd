extends AcceptDialog
## THE OVERLAND GUIDE: a period survival book (data/guide.json) with chapters in an 1840s guide's
## voice. Each chapter's plain game rules stay hidden until the reader asks for them; the
## outfit chapter prices the guide's recommended outfit at the Independence counter.
signal plain_rules_toggled(shown: bool)
var data: Dictionary={}
var game
var chapters: ItemList
var page: RichTextLabel
var plain_toggle: CheckBox

static func load_data() -> Dictionary:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/guide.json"))
	return parsed if valid(parsed) else {}

static func valid(value: Variant) -> bool:
	if not value is Dictionary or not value.get("title") is String or not value.get("subtitle") is String or not value.get("chapters") is Array or value.chapters.is_empty():return false
	var seen: Array=[]
	for chapter in value.chapters:
		if not chapter is Dictionary or chapter.get("id") in seen:return false
		for key in ["id","title","period","plain"]:
			if not chapter.get(key) is String or str(chapter[key]).strip_edges().is_empty():return false
		seen.append(chapter.id)
	if not value.get("outfit") is Dictionary or value.outfit.is_empty():return false
	for good in value.outfit:
		var amount: Variant=value.outfit[good]
		if not good is String or not (amount is int or amount is float) or amount!=floor(amount) or amount<1:return false
	return true

func _init(simulation=null) -> void:
	game=simulation
	data=load_data()
	title=str(data.get("title","THE OVERLAND GUIDE"))
	min_size=Vector2i(560,262)
	var row:=HBoxContainer.new()
	row.custom_minimum_size=Vector2(540,236)
	add_child(row)
	chapters=ItemList.new()
	chapters.custom_minimum_size=Vector2(150,236)
	chapters.add_theme_font_size_override("font_size",8)
	for chapter in data.get("chapters",[]):chapters.add_item(str(chapter.title))
	chapters.item_selected.connect(func(_index):_show_page())
	row.add_child(chapters)
	var column:=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(column)
	page=RichTextLabel.new()
	page.bbcode_enabled=true
	page.scroll_active=true
	page.size_flags_vertical=Control.SIZE_EXPAND_FILL
	page.custom_minimum_size=Vector2(380,212)
	page.add_theme_font_size_override("normal_font_size",8)
	page.add_theme_font_size_override("bold_font_size",8)
	page.add_theme_font_size_override("italics_font_size",8)
	column.add_child(page)
	plain_toggle=CheckBox.new()
	plain_toggle.text="SHOW PLAIN RULES"
	plain_toggle.tooltip_text="Add each chapter's plain game rules under the period text."
	plain_toggle.add_theme_font_size_override("font_size",8)
	plain_toggle.toggled.connect(func(shown):_show_page();plain_rules_toggled.emit(shown))
	column.add_child(plain_toggle)
	if chapters.item_count>0:chapters.select(0)
	_show_page()

func set_game(simulation) -> void:
	game=simulation
	_show_page()

func set_plain_rules(shown: bool) -> void:
	plain_toggle.set_pressed_no_signal(shown)
	_show_page()

func open_chapter(id: String) -> void:
	for index in range(data.get("chapters",[]).size()):
		if data.chapters[index].id==id:chapters.select(index)
	_show_page()

func current_id() -> String:
	var picked: PackedInt32Array=chapters.get_selected_items()
	return str(data.chapters[picked[0]].id) if not picked.is_empty() else ""

func _show_page() -> void:
	if page==null:return
	page.text=page_text(current_id(),plain_toggle.button_pressed)
	page.scroll_to_line(0)

func page_text(id: String,plain: bool) -> String:
	for chapter in data.get("chapters",[]):
		if chapter.id!=id:continue
		var text: String="[b]%s[/b]\n\n" % str(chapter.title).to_upper()
		if id==str(data.chapters[0].id):text+="[i]%s[/i]\n\n" % data.subtitle
		text+=_escape(str(chapter.period))
		if chapter.get("outfit",false):text+="\n\n"+outfit_table()
		if plain:text+="\n\n[b]PLAIN RULES[/b]\n"+_escape(str(chapter.plain))
		return text
	return ""

## The guide's outfit for a party of five, priced at the Independence counter.
func outfit_table() -> String:
	if game==null:return ""
	var lines: Array=["[b]THE GUIDE'S OUTFIT FOR FIVE, AT INDEPENDENCE PRICES[/b]"]
	var cart: Dictionary={}
	var cents:=0
	for good in game.outfitter.goods:
		var amount: int=int(data.outfit.get(good.id,0))
		if amount<=0:continue
		cart[good.id]=amount
		var cost: int=amount*int(good.price_cents)
		cents+=cost
		lines.append("%s, %s .... $%.2f" % [_good_name(str(good.id)),_amount(str(good.id),amount),cost/100.0])
	var quote: Dictionary=game.outfitter.quote("banker",cart)
	lines.append("[b]Total $%.2f, about %d lb of cargo of 2,500[/b]" % [cents/100.0,int(quote.get("cargo_lb",0))])
	lines.append("Buy it whole, or trim it to your purse; keep money back for the posts.")
	return "\n".join(lines)

func _good_name(id: String) -> String:
	return {"wagon":"Wagon","oxen":"Oxen","food":"Provisions","clothing":"Clothing","bullet_boxes":"Ammunition","wheels":"Spare wheel","axles":"Spare axle","tongues":"Spare tongue","medicine":"Care kits","salt":"Salt","dried_produce":"Dried fruit"}.get(id,id.capitalize())

func _amount(id: String,amount: int) -> String:
	if id=="food":return "%d lb" % amount
	if id=="salt":return "%d lb" % amount
	if id=="bullet_boxes":return "%d boxes of 20" % amount
	if id=="dried_produce":return "%d baskets" % amount
	if id=="clothing":return "%d sets" % amount
	return str(amount)

func _escape(value: String) -> String:return value.replace("[","[lb]")
