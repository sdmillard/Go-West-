extends Control
## Original code-drawn memorial, deliberately separate from historical site art.
const PRAIRIE = preload("res://art/pixels/prairie.png")
const FONT = preload("res://art/pixels/trail_font.fnt")
var record: Dictionary = {}
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
func center_text(text: String, y: int) -> void:
	draw_string(FONT,Vector2(122,y),text,HORIZONTAL_ALIGNMENT_CENTER,188,8,Color("45372f"))
func _draw() -> void:
	draw_texture(PRAIRIE,Vector2.ZERO)
	if record.is_empty():
		return
	draw_rect(Rect2(109,140,218,5),Color("76503c"))
	draw_colored_polygon(PackedVector2Array([Vector2(116,140),Vector2(116,28),Vector2(128,16),Vector2(304,16),Vector2(316,28),Vector2(316,140)]),Color("aaa58b"))
	draw_rect(Rect2(120,30,192,108),Color("c6bea0"))
	draw_rect(Rect2(128,21,176,10),Color("c6bea0"))
	center_text("HERE REST THE PARTY OF",38)
	center_text(str(record.name).to_upper(),50)
	center_text(str(record.date),63)
	center_text("GUIDE MILE %d" % record.miles,75)
	draw_rect(Rect2(140,81,152,1),Color("85816c"))
	var words: PackedStringArray = str(record.epitaph).to_upper().split(" ",false)
	var lines: Array[String] = []
	var line := ""
	for word in words:
		while word.length() > 29:
			if not line.is_empty():
				lines.append(line)
			lines.append(word.substr(0,29))
			word = word.substr(29)
			line = ""
		if line.length() + word.length() + 1 > 29:
			lines.append(line)
			line = ""
		line += (" " if not line.is_empty() else "") + word
	if not line.is_empty():
		lines.append(line)
	for index in range(mini(4,lines.size())):
		center_text(lines[index],94 + index * 10)
	for x in [104,111,321,327]:
		draw_rect(Rect2(x,136,2,9),Color("596442"))
