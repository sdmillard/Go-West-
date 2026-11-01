extends RefCounted
## Cosmetic identity data never participates in personality, wages or survival calculations.
const PATH = "res://data/appearance.json"
static func catalog() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH))
static func default_for(id: int) -> Dictionary:
	return {"skin":"Light","hair":"Brown","clothing":"Blue" if id%2==0 else "Red","outfit":id%2,"heritage":"Not specified"}
static func generate(seed_value: int, index: int) -> Dictionary:
	var data := catalog()
	var random := RandomNumberGenerator.new()
	random.seed=seed_value ^ (index*104729) ^ 0x41505045
	var result := default_for(index)
	for key in ["skin","hair","clothing"]:
		var choices: Array=data[key].keys()
		result[key]=choices[random.randi_range(0,choices.size()-1)]
	result.outfit=random.randi_range(0,data.outfits.size()-1)
	result.heritage=data.heritage[random.randi_range(0,data.heritage.size()-1)]
	return result
## Generated names follow the outfit: a dress and bonnet draws from women's given names.
static func wears_dress(value: Dictionary) -> bool:
	var outfits: Array=catalog().outfits
	var index:=int(value.get("outfit",0))
	return index>=0 and index<outfits.size() and str(outfits[index]).begins_with("Dress")
static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=5:return false
	var data := catalog()
	for key in ["skin","hair","clothing"]:
		if not value.get(key) is String or not data[key].has(value[key]):return false
	return (value.get("outfit") is int or value.get("outfit") is float) and is_finite(value.outfit) and value.outfit==floor(value.outfit) and value.outfit>=0 and value.outfit<data.outfits.size() and value.get("heritage") is String and value.heritage.length()<=64 and not "\n" in value.heritage and not "\r" in value.heritage
