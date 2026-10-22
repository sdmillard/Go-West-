extends RefCounted
## Local player-authored memorials, separate from the journey save slot.
const Writer = preload("res://simulation/save_store.gd")
const DEFAULT_PATH := "user://gravestones.json"
## A party stone marks a journey lost; a companion stone marks one grave dug on the trail. Older books have only party stones.
const KINDS := ["party", "companion"]
var path := DEFAULT_PATH
var records: Array[Dictionary] = []
var error := ""
var writer = Writer.new()

func read_records() -> bool:
	records.clear()
	error = ""
	if not FileAccess.file_exists(path):
		return true
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 2097152:
		error = "Could not read the memorial book."
		return false
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		error = "The memorial book is damaged. It has been preserved."
		return false
	var value: Variant = parser.data
	if not value is Dictionary or value.get("format") != "westward-memorials" or value.get("version") != 1 or not value.get("graves") is Array or value.graves.size() > 100:
		error = "The memorial book is damaged or incompatible. It has been preserved."
		return false
	var ids: Array = []
	for record in value.graves:
		if not record is Dictionary:
			error = "Invalid memorial record."
			return false
		for key in ["id", "name", "date", "epitaph"]:
			if not record.get(key) is String or record[key].length() > 120:
				error = "Invalid memorial inscription."
				return false
		if record.id in ids or not writer.integer(record.get("miles"),0,100000) or not writer.integer(record.get("day"),0,100000) or record.get("kind","party") not in KINDS:
			error = "Invalid memorial location."
			return false
		ids.append(record.id)
		records.append(writer.normalize(record))
	return true

func memorial_id(game, grave: Dictionary = {}) -> String:
	if not grave.is_empty():
		return (str(game.state.seed) + ":grave:" + str(int(grave.id)) + ":" + str(grave.name) + ":" + str(int(grave.day)) + ":" + ",".join(game.state.party)).sha256_text()
	return (str(game.state.seed) + ":" + str(game.state.day) + ":" + str(game.state.miles) + ":" + ",".join(game.state.party)).sha256_text()

func date_of(game, day: int) -> String:
	var start := "1848-%02d-01T00:00:00" % game.state.departure_month
	var date := Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_datetime_string(start)) + day * 86400)
	return "%04d-%02d-%02d" % [date.year,date.month,date.day]

## A party stone once the journey is lost, or, given a remains entry the party buried, a stone over that grave.
func make_record(game, inscription: String, grave: Dictionary = {}) -> Dictionary:
	if grave.is_empty() and game.state.status != "lost":
		return {}
	if not grave.is_empty() and grave.get("state","") != "buried":
		return {}
	var text := inscription.strip_edges().replace("\n", " ").replace("\r", " ").replace("\t", " ")
	if text.is_empty():
		text = "They followed the western road." if grave.is_empty() else "Rest easy by the western road."
	if not grave.is_empty():
		return {"id": memorial_id(game,grave), "kind":"companion", "name": str(grave.name).substr(0,40), "date": date_of(game,int(grave.day)),
			"miles":int(grave.mile), "day":int(grave.day), "epitaph":text.substr(0,90)}
	return {"id": memorial_id(game), "kind":"party", "name": game.state.party[0], "date": date_of(game,int(game.state.day)),
		"miles":game.state.miles, "day":game.state.day, "epitaph":text.substr(0,90)}

func leave_memorial(game, inscription: String, grave: Dictionary = {}) -> bool:
	var record := make_record(game,inscription,grave)
	if record.is_empty():
		error = "A memorial can be left after a journey ends in loss, or over a grave the party dug."
		return false
	if not read_records():
		return false
	var found := false
	for index in range(records.size()):
		if records[index].id == record.id:
			records[index] = record
			found = true
	if not found:
		if records.size() >= 100:
			error = "The memorial book is full. Existing stones have been preserved."
			return false
		records.append(record)
	if not writer.write_document({"format":"westward-memorials","version":1,"graves":records},path):
		error = writer.error
		return false
	error = ""
	return true

func along_route(before: int, after: int, visited: Array) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record in records:
		if record.id not in visited and int(record.miles) >= before and int(record.miles) <= after:
			found.append(record.duplicate(true))
	return found
