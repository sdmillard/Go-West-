extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(value: bool, message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func run():
	var game=Simulation.new(57,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	var quote: Dictionary=game.outfitter.quote("farmer",cart)
	check(quote.total_cents==39260 and quote.remaining_cents==20740,"Revised six-ox outfit leaves $207.40 from $600")
	check(game.depart("farmer",["A","B","C","D","E"],5,cart),"Suggested historical-price outfit is affordable and fits")
	var profile: Dictionary=game.characters.profiles[1]
	profile.skill="Hunting"
	profile.traits=["Cautious","Compassionate"]
	profile.specials=["Mercenary"]
	check(game.characters.wage_quote(profile).daily_cents*30==1050,"Lowest ordinary hire costs $10.50 per thirty days plus food")
	profile.skill="Carpentry"
	profile.traits=["Bold","Pragmatic"]
	profile.specials=["Mercenary","Loyal","Veteran"]
	check(game.characters.wage_quote(profile).daily_cents*30==3750,"Experienced loyal carpenter tops out at $37.50 per thirty days")
	var rules: Dictionary=game.characters.benefits.duplicate(true)
	for background in game.characters.SKILLS:
		profile.skill=background
		for values in ["Compassionate","Pragmatic"]:
			profile.traits=["Cautious",values]
			for extras in [[],["Loyal"],["Veteran"],["Loyal","Veteran"]]:
				profile.specials=["Mercenary"]+extras
				var daily: int=game.characters.wage_quote(profile).daily_cents
				for days in [1,5,7]:
					check(game.characters.acceptable_terms(daily*days,days,profile) and not game.characters.acceptable_terms(daily*days-1,days,profile),"Exact minimum enforced for all backgrounds, values, premiums and intervals")
	for field in ["wage_bases","wage_modifiers"]:
		for malformed in [null,{}, {"Hunting":40}]:
			var bad: Dictionary=rules.duplicate(true)
			bad[field]=malformed
			check(not game.characters.load_benefits(bad) and game.characters.benefits==rules,"Malformed wage table cannot replace valid rules")
	var bad: Dictionary=rules.duplicate(true)
	bad.wage_bases.Hunting=40.5
	check(not game.characters.load_benefits(bad),"Fractional cents are rejected")
	check(game.characters.load_benefits(rules),"Valid wage rules reload")
	var store=Store.new()
	var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-historical-wages-save-v1.json"))
	var restored=store.restore(previous)
	check(restored!=null,"Authentic previous economy save migrates")
	if restored!=null:
		check(restored.characters.profiles[1].contract.wage_cents==1000 and restored.characters.profiles[1].contract==store.normalize(previous.characters[1].contract),"Existing higher wage agreement is honored without repricing")
		check(store.normalize(restored.state)==store.normalize(previous.state) and str(restored.rng.state)==previous.random and restored.pending==store.normalize(previous.pending),"Migration preserves cash, supplies, time, RNG and pending choices")
		check(store.restore(store.capture(restored))!=null,"Migrated save can be saved again")
	print("Historical economy: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

