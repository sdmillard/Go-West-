extends Window
## THE OVERLAND GUIDE: a period survival book (data/guide.json) with chapters in an 1840s guide's
## voice, shown as an open book: calf binding, two parchment pages, a thumb tab for each chapter
## and pages that turn. Each chapter's plain game rules stay hidden until the reader asks for
## them; they then appear after the period text in pencil, like a reader's own notes. The outfit
## chapter prices the guide's recommended outfit at the Independence counter.
signal plain_rules_toggled(shown: bool)

const FONT=preload("res://art/pixels/trail_font.fnt")
const ART=preload("res://art/pixels/guide_book.png")
## Geometry of art/aseprite/scenes/guide_book.lua (608 x 320).
const BOOK_SIZE:=Vector2i(608,320)
const LEFT_PAGE:=Rect2(12,10,268,276)
const RIGHT_PAGE:=Rect2(284,10,268,276)
const SPINE_X:=282.0
const TEXT_MARGIN:=16.0
const TEXT_TOP:=34.0
const LINE_H:=10
const LINES_PER_PAGE:=23
const TEXT_W:=236.0
const INK:="45372f"
const RUBRIC:="9e3f33"
const PENCIL:="555d68"
const FADED:="76503c"
const TURN_TIME:=0.22
## Thumb-tab labels where a chapter title would not fit.
const TAB_NAMES:={"provisions":"GAME","preface":"PREFACE"}

var data: Dictionary={}
var game
var plain_toggle: CheckBox
var close_button: Button
var left_page: RichTextLabel
var right_page: RichTextLabel
var left_folio: Label
var right_folio: Label
var left_head: Label
var right_head: Label
var back_button: Button
var next_button: Button
var tabs: Array=[]
var chapter_index:=0
var spread:=0
var _pages: Dictionary={} # chapter id -> Array of pages, each an Array of [text, kind]
var _turn: Control
var _turn_t:=1.0
var _turn_dir:=1

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
	borderless=true
	transparent=true
	transparent_bg=true
	unresizable=true
	exclusive=true
	transient=true
	visible=false
	wrap_controls=false
	size=BOOK_SIZE
	min_size=BOOK_SIZE
	close_requested.connect(hide)
	window_input.connect(_on_input)
	var art:=TextureRect.new()
	art.texture=ART
	art.position=Vector2.ZERO
	art.size=Vector2(BOOK_SIZE)
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(art)
	left_head=_label(Rect2(LEFT_PAGE.position.x+TEXT_MARGIN,15,TEXT_W,10),FADED,HORIZONTAL_ALIGNMENT_CENTER)
	right_head=_label(Rect2(RIGHT_PAGE.position.x+TEXT_MARGIN,15,TEXT_W,10),FADED,HORIZONTAL_ALIGNMENT_CENTER)
	left_page=_page(LEFT_PAGE)
	right_page=_page(RIGHT_PAGE)
	var folio_y: float=LEFT_PAGE.end.y-16
	left_folio=_label(Rect2(LEFT_PAGE.position.x+TEXT_MARGIN,folio_y,TEXT_W,10),FADED,HORIZONTAL_ALIGNMENT_CENTER)
	right_folio=_label(Rect2(RIGHT_PAGE.position.x+TEXT_MARGIN,folio_y,TEXT_W,10),FADED,HORIZONTAL_ALIGNMENT_CENTER)
	back_button=_ink_button("< BACK",Rect2(LEFT_PAGE.position.x+TEXT_MARGIN-4,folio_y-2,52,13),"Turn back a page (left arrow).")
	back_button.pressed.connect(func():turn(-1))
	next_button=_ink_button("ON >",Rect2(RIGHT_PAGE.end.x-TEXT_MARGIN-40,folio_y-2,44,13),"Turn the page (right arrow).")
	next_button.alignment=HORIZONTAL_ALIGNMENT_RIGHT
	next_button.pressed.connect(func():turn(1))
	var chapters: Array=data.get("chapters",[])
	for index in range(chapters.size()):
		var tab:=Button.new()
		tab.text=tab_name(chapters[index])
		tab.tooltip_text=str(chapters[index].title)
		tab.focus_mode=Control.FOCUS_NONE
		tab.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		tab.alignment=HORIZONTAL_ALIGNMENT_RIGHT
		tab.position=Vector2(RIGHT_PAGE.end.x-4,14+index*27)
		tab.size=Vector2(56,25)
		tab.pressed.connect(func():_go(index,0,1 if index>chapter_index else -1))
		add_child(tab)
		tabs.append(tab)
	close_button=_gilt_button("CLOSE THE BOOK",Rect2(18,296,100,12))
	close_button.tooltip_text="Close the guide (Esc)."
	close_button.pressed.connect(hide)
	plain_toggle=CheckBox.new()
	plain_toggle.text="PLAIN RULES IN PENCIL"
	plain_toggle.tooltip_text="Write each chapter's plain game rules after the period text, like notes in the margin."
	plain_toggle.focus_mode=Control.FOCUS_NONE
	for state in ["normal","hover","pressed","hover_pressed","focus"]:plain_toggle.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for key in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:plain_toggle.add_theme_color_override(key,Color("ddb461"))
	plain_toggle.add_theme_font_size_override("font_size",8)
	plain_toggle.position=Vector2(404,295)
	plain_toggle.size=Vector2(150,14)
	plain_toggle.toggled.connect(func(shown):_pages.clear();_show_spread();plain_rules_toggled.emit(shown))
	add_child(plain_toggle)
	_turn=Control.new()
	_turn.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_turn.size=Vector2(BOOK_SIZE)
	_turn.draw.connect(_draw_turn)
	add_child(_turn)
	_show_spread()

func _process(delta: float) -> void:
	if _turn_t>=1.0:return
	_turn_t=minf(1.0,_turn_t+delta/TURN_TIME)
	_turn.queue_redraw()

func set_game(simulation) -> void:
	game=simulation
	_pages.clear()
	_show_spread()

func set_plain_rules(shown: bool) -> void:
	plain_toggle.set_pressed_no_signal(shown)
	_pages.clear()
	_show_spread()

func open_chapter(id: String) -> void:
	var chapters: Array=data.get("chapters",[])
	for index in range(chapters.size()):
		if chapters[index].id==id:chapter_index=index;spread=0
	_show_spread()

func current_id() -> String:
	var chapters: Array=data.get("chapters",[])
	return str(chapters[chapter_index].id) if chapter_index<chapters.size() else ""

## Turns one spread forward (1) or back (-1), running on into the next or previous chapter.
func turn(direction: int) -> void:
	var chapters: Array=data.get("chapters",[])
	if chapters.is_empty():return
	if direction>0:
		if spread+1<spreads(current_id()):_go(chapter_index,spread+1,1)
		elif chapter_index+1<chapters.size():_go(chapter_index+1,0,1)
	else:
		if spread>0:_go(chapter_index,spread-1,-1)
		elif chapter_index>0:_go(chapter_index-1,spreads(str(chapters[chapter_index-1].id))-1,-1)

func spreads(id: String) -> int:
	return int(ceil(pages(id).size()/2.0))

## The chapter laid out in lines of the pixel font, cut into pages of LINES_PER_PAGE.
func pages(id: String) -> Array:
	if _pages.has(id):return _pages[id]
	var lines: Array=chapter_lines(id,plain_toggle.button_pressed)
	var result: Array=[]
	var page: Array=[]
	for line in lines:
		if page.is_empty() and line[1]=="blank":continue
		page.append(line)
		if page.size()==LINES_PER_PAGE:result.append(page);page=[]
	if not page.is_empty() or result.is_empty():result.append(page)
	_pages[id]=result
	return result

## Book page number of a chapter's first page: every chapter opens on a left-hand page.
func first_folio(id: String) -> int:
	var folio:=1
	for chapter in data.get("chapters",[]):
		if chapter.id==id:return folio
		folio+=spreads(str(chapter.id))*2
	return folio

func chapter_lines(id: String,plain: bool) -> Array:
	var lines: Array=[]
	for chapter in data.get("chapters",[]):
		if chapter.id!=id:continue
		lines.append([str(chapter.title).to_upper(),"title"])
		if id==str(data.chapters[0].id):
			lines.append(["","blank"])
			for row in _wrap(str(data.subtitle)):lines.append([row,"subtitle"])
		lines.append(["~ * ~","ornament"])
		lines.append(["","blank"])
		_add_text(lines,str(chapter.period),"body")
		if chapter.get("outfit",false) and game!=null:
			lines.append(["","blank"])
			for row in outfit_rows():lines.append(row)
		if plain:
			lines.append(["","blank"])
			lines.append(["PLAIN RULES","plain_head"])
			_add_text(lines,str(chapter.plain),"plain")
		lines.append(["","blank"])
		lines.append(["*","ornament"])
	return lines

## The whole chapter as plain text, as the reader would see it across its pages.
func page_text(id: String,plain: bool) -> String:
	return "\n".join(chapter_lines(id,plain).map(func(line):return line[0]))

## The words on the two open pages.
func spread_text() -> String:
	return left_page.get_parsed_text()+"\n"+right_page.get_parsed_text()

## The guide's outfit for a party of five, priced at the Independence counter, with dotted leaders.
func outfit_rows() -> Array:
	if game==null:return []
	var rows: Array=[]
	for line in _wrap("THE GUIDE'S OUTFIT FOR FIVE, AT INDEPENDENCE PRICES"):rows.append([line,"table_head"])
	var cart: Dictionary={}
	var cents:=0
	for good in game.outfitter.goods:
		var amount: int=int(data.outfit.get(good.id,0))
		if amount<=0:continue
		cart[good.id]=amount
		var cost: int=amount*int(good.price_cents)
		cents+=cost
		rows.append([_leader("%s, %s" % [_good_name(str(good.id)),_amount(str(good.id),amount)],"$%.2f" % (cost/100.0)),"table"])
	var quote: Dictionary=game.outfitter.quote("banker",cart)
	rows.append([_leader("Total","$%.2f" % (cents/100.0)),"table_head"])
	rows.append(["About %d lb of cargo of 2,500." % int(quote.get("cargo_lb",0)),"table"])
	for line in _wrap("Buy it whole, or trim it to your purse; keep money back for the posts."):rows.append([line,"body"])
	return rows

func outfit_table() -> String:
	return "\n".join(outfit_rows().map(func(line):return line[0]))

static func tab_name(chapter: Dictionary) -> String:
	if TAB_NAMES.has(chapter.id):return TAB_NAMES[chapter.id]
	var name: String=str(chapter.title).to_upper()
	for prefix in ["TO THE ","OF THE ","OF "]:
		if name.begins_with(prefix):return name.trim_prefix(prefix)
	return name

func _go(index: int,to_spread: int,direction: int) -> void:
	if index==chapter_index and to_spread==spread:return
	chapter_index=index
	spread=to_spread
	_turn_dir=direction
	_turn_t=0.0
	_show_spread()

func _show_spread() -> void:
	if left_page==null:return
	var id:=current_id()
	var book_pages: Array=pages(id)
	spread=clampi(spread,0,maxi(0,spreads(id)-1))
	var left: Array=book_pages[spread*2] if spread*2<book_pages.size() else []
	var right: Array=book_pages[spread*2+1] if spread*2+1<book_pages.size() else []
	left_page.text=_render(left)
	right_page.text=_render(right)
	var folio: int=first_folio(id)+spread*2
	left_folio.text="- %d -" % folio
	right_folio.text="- %d -" % (folio+1)
	left_head.text=str(data.get("title","THE OVERLAND GUIDE"))
	right_head.text=str(data.chapters[chapter_index].title).to_upper() if not data.get("chapters",[]).is_empty() else ""
	var last: int=data.get("chapters",[]).size()-1
	back_button.visible=chapter_index>0 or spread>0
	next_button.visible=chapter_index<last or spread+1<spreads(id)
	for index in range(tabs.size()):
		var picked: bool=index==chapter_index
		var tab: Button=tabs[index]
		var colour: String=["76503c","6e3a2c","52423a"][index%3]
		for state in ["normal","hover","pressed","focus","disabled"]:
			var box:=StyleBoxFlat.new()
			box.bg_color=Color("f6e7bc" if picked else ("a16b43" if state=="hover" else colour))
			box.border_color=Color("c18d4d" if picked else "302b2c")
			box.set_border_width_all(1)
			box.border_width_left=0
			box.content_margin_right=6
			box.content_margin_left=8
			box.corner_radius_top_right=3
			box.corner_radius_bottom_right=3
			tab.add_theme_stylebox_override(state,box)
		for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			tab.add_theme_color_override(key,Color(INK if picked else "f6e7bc"))
		tab.position.x=RIGHT_PAGE.end.x-(8 if picked else 4)
		tab.size.x=60 if picked else 56
	_turn.queue_redraw()

func _render(lines: Array) -> String:
	var out: Array=[]
	for line in lines:
		var words: String=str(line[0]).replace("[","[lb]")
		match line[1]:
			"title":out.append("[center][color=#%s]%s[/color][/center]" % [RUBRIC,words])
			"subtitle":out.append("[center][color=#%s]%s[/color][/center]" % [FADED,words])
			"ornament":out.append("[center][color=#%s]%s[/color][/center]" % [RUBRIC,words])
			"plain_head":out.append("[color=#%s]%s[/color]" % [PENCIL,words])
			"plain":out.append("[color=#%s]%s[/color]" % [PENCIL,words])
			"table_head":out.append("[color=#%s]%s[/color]" % [RUBRIC,words])
			_:out.append(words)
	return "\n".join(out)

func _add_text(lines: Array,text: String,kind: String) -> void:
	var first:=true
	for paragraph in text.split("\n"):
		if paragraph.strip_edges().is_empty():continue
		if not first:lines.append(["","blank"])
		first=false
		for row in _wrap(paragraph.strip_edges()):lines.append([row,kind])

func _wrap(text: String) -> Array:
	var rows: Array=[]
	var line:=""
	for word in text.split(" ",false):
		var trial: String=word if line.is_empty() else line+" "+word
		if not line.is_empty() and FONT.get_string_size(trial.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x>TEXT_W:
			rows.append(line)
			line=word
		else:line=trial
	if not line.is_empty():rows.append(line)
	return rows

func _leader(left: String,right: String) -> String:
	var line: String=left+" "
	while FONT.get_string_size((line+". "+right).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x<=TEXT_W:line+="."
	return line+" "+right

func _page(bounds: Rect2) -> RichTextLabel:
	var label:=RichTextLabel.new()
	label.bbcode_enabled=true
	label.scroll_active=false
	label.autowrap_mode=TextServer.AUTOWRAP_OFF
	label.clip_contents=true
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.position=Vector2(bounds.position.x+TEXT_MARGIN,TEXT_TOP)
	label.size=Vector2(TEXT_W+4,LINES_PER_PAGE*LINE_H+2)
	label.add_theme_color_override("default_color",Color(INK))
	label.add_theme_constant_override("line_separation",LINE_H-9)
	for key in ["normal_font_size","bold_font_size","italics_font_size"]:label.add_theme_font_size_override(key,8)
	add_child(label)
	return label

func _label(bounds: Rect2,colour: String,align: HorizontalAlignment) -> Label:
	var label:=Label.new()
	label.position=bounds.position
	label.size=bounds.size
	label.horizontal_alignment=align
	label.add_theme_color_override("font_color",Color(colour))
	label.add_theme_font_size_override("font_size",8)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _ink_button(text: String,bounds: Rect2,tip: String) -> Button:
	var button:=_flat_button(text,bounds,FADED,RUBRIC)
	button.tooltip_text=tip
	return button

func _gilt_button(text: String,bounds: Rect2) -> Button:
	return _flat_button(text,bounds,"ddb461","fff4d4")

func _flat_button(text: String,bounds: Rect2,colour: String,hover: String) -> Button:
	var button:=Button.new()
	button.text=text
	button.flat=true
	button.focus_mode=Control.FOCUS_NONE
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	for state in ["normal","hover","pressed","focus","disabled"]:button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	button.add_theme_color_override("font_color",Color(colour))
	button.add_theme_color_override("font_focus_color",Color(colour))
	button.add_theme_color_override("font_hover_color",Color(hover))
	button.add_theme_color_override("font_pressed_color",Color(hover))
	button.add_theme_font_size_override("font_size",8)
	button.position=bounds.position
	button.size=bounds.size
	add_child(button)
	return button

func _on_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():return
	if event.is_action("ui_cancel"):hide()
	elif event.is_action("ui_right") or (event is InputEventKey and event.keycode==KEY_PAGEDOWN):turn(1)
	elif event.is_action("ui_left") or (event is InputEventKey and event.keycode==KEY_PAGEUP):turn(-1)

## A blank leaf swinging over the spine: it lifts off one page, stands on edge and lands on the other.
func _draw_turn() -> void:
	if _turn_t>=1.0:return
	var t: float=_turn_t
	var width: float=RIGHT_PAGE.size.x*absf(cos(t*PI))
	var forward: bool=_turn_dir>0
	var on_right: bool=(t<0.5)==forward
	var x: float=SPINE_X+2 if on_right else SPINE_X-2-width
	var rise: float=6.0*sin(t*PI)
	var top: float=RIGHT_PAGE.position.y-rise
	var rect:=Rect2(floor(x),floor(top),floor(width),RIGHT_PAGE.size.y+floor(rise))
	if rect.size.x<1:return
	# the leaf darkens as it stands upright, showing its edge to the light
	_turn.draw_rect(rect,Color("f6e7bc" if width>RIGHT_PAGE.size.x*0.5 else "ecd097"))
	var edge_x: float=rect.end.x-1 if on_right else rect.position.x
	_turn.draw_rect(Rect2(edge_x,rect.position.y,1,rect.size.y),Color("c18d4d"))
	_turn.draw_rect(Rect2(rect.position.x,rect.end.y,rect.size.x,1),Color("cfb98e"))

func _good_name(id: String) -> String:
	return {"wagon":"Wagon","oxen":"Oxen","food":"Provisions","clothing":"Clothing","bullet_boxes":"Ammunition","wheels":"Spare wheel","axles":"Spare axle","tongues":"Spare tongue","medicine":"Care kits","salt":"Salt","dried_produce":"Dried fruit"}.get(id,id.capitalize())

func _amount(id: String,amount: int) -> String:
	if id=="food":return "%d lb" % amount
	if id=="salt":return "%d lb" % amount
	if id=="bullet_boxes":return "%d boxes of 20" % amount
	if id=="dried_produce":return "%d baskets" % amount
	if id=="clothing":return "%d sets" % amount
	return str(amount)
