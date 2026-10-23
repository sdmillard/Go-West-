extends Control
## Trailside memorial: a headstone picture with the inscription drawn over its plain face.
const PRAIRIE = preload("res://art/pixels/prairie.png")
const HEADSTONE = preload("res://art/pixels/gravestone_frame.png")
const FONT = preload("res://art/pixels/trail_font.fnt")
var record: Dictionary = {}
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
func center_text(text: String, y: int) -> void:
	# A light lower edge makes each line read as cut into the stone.
	draw_string(FONT,Vector2(122,y + 1),text,HORIZONTAL_ALIGNMENT_CENTER,188,8,Color("f6e7bc"))
	draw_string(FONT,Vector2(122,y),text,HORIZONTAL_ALIGNMENT_CENTER,188,8,Color("45372f"))
func _draw() -> void:
	if record.is_empty():
		draw_texture(PRAIRIE,Vector2.ZERO)
		return
	draw_texture(HEADSTONE,Vector2.ZERO)
	var companion: bool = record.get("kind","party") == "companion"
	center_text("HERE LIES" if companion else "HERE REST THE PARTY OF",38)
	center_text(str(record.name).to_upper(),50)
	center_text(("DIED " if companion else "") + str(record.date),63)
	center_text("GUIDE MILE %d" % record.miles,75)
	draw_rect(Rect2(140,81,152,1),Color("908a72"))
	draw_rect(Rect2(140,82,152,1),Color("f6e7bc"))
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
