extends SceneTree
## Generated companion names fit their outfit and heritage.
const Characters=preload("res://simulation/party_character.gd")
const Appearance=preload("res://simulation/traveler_appearance.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		print("FAIL: "+message)
func _initialize():call_deferred("run")
func run():
	var characters=Characters.new()
	var catalog=characters.catalog
	check(catalog.error.is_empty(),"Catalog with name pools loads")
	var data: Dictionary=catalog.data
	check(data.given_names.women.size()>=80 and data.given_names.men.size()>=80 and data.surnames.size()>=100,"General pool is large")
	var names: Dictionary={}
	var mismatched:=0
	var heritage_hits:=0
	var heritage_total:=0
	for index in range(1,1201):
		var offer: Dictionary=characters.generate_candidate(4242,index,"stranger")
		var appearance: Dictionary=offer.profile.appearance
		var given: String=offer.name.get_slice(" ",0)
		var surname: String=offer.name.substr(given.length()+1)
		names[offer.name]=true
		var woman: bool=Appearance.wears_dress(appearance)
		var all_women: Array=data.given_names.women.duplicate()
		var all_men: Array=data.given_names.men.duplicate()
		for pool in data.heritage_names.values():
			all_women.append_array(pool.women)
			all_men.append_array(pool.men)
		if woman and not given in all_women:mismatched+=1
		if not woman and not given in all_men:mismatched+=1
		if data.heritage_names.has(appearance.heritage):
			heritage_total+=1
			if surname in data.heritage_names[appearance.heritage].surnames:heritage_hits+=1
	check(mismatched==0,"Given names follow the outfit (%d mismatched)" % mismatched)
	check(heritage_total>0 and heritage_hits==heritage_total,"Heritage travelers take a surname from their own pool (%d/%d)" % [heritage_hits,heritage_total])
	check(names.size()>=1100,"Repeats are rare: %d unique names in 1200 offers" % names.size())
	check(characters.generate_candidate(4242,7,"stranger").name==characters.generate_candidate(4242,7,"stranger").name,"Names stay seeded")
	var bad: Dictionary=data.duplicate(true)
	bad.heritage_names["Irish American"].surnames=[]
	check(not catalog.load_data(bad) and catalog.load_data(data),"Empty heritage pool rejects and valid catalog reloads")
	bad=data.duplicate(true)
	bad.given_names.women=["x".repeat(30)]
	check(not catalog.load_data(bad) and catalog.load_data(data),"Overlong given name rejects")
	await process_frame
	print("Companion names: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
