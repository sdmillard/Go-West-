extends "res://tests/full_trail_balance.gd"
## Full-route journeys that use every crime system through its public actions, beside a lawful control.
## An integration check for stuck encounters, impossible services and save errors, not the balance campaign.
const Remains=preload("res://simulation/remains.gd")
const STRATEGIES=["lawful","road_robber","kearny","open_cannibal","killer"]
func _initialize():call_deferred("run")
func command(game,key: String,value: String,member: int=-1) -> int:
	for index in range(game.pending.choices.size()):
		var choice: Dictionary=game.pending.choices[index]
		if choice.get(key,"")==value and (member<0 or int(choice.get("member",-1))==member) and game.can_choose(index):return index
	return -1
func pick(game,key: String,value: String,member: int=-1) -> bool:
	var index:=command(game,key,value,member)
	return index>=0 and game.choose(index)
## Settles an open crime panel the way a desperate party would: take what it can, run, shoot out of a standoff.
func settle_crime(game) -> bool:
	var stage: String=game.crime.incident().get("stage","")
	if stage=="loot":return pick(game,"crime_command","take") or pick(game,"crime_command","flee")
	if stage=="escape":return pick(game,"crime_command","flee")
	if stage=="standoff":return pick(game,"crime_command","breakout") or pick(game,"crime_command","surrender")
	if stage=="report":return pick(game,"crime_command","finish")
	return pick(game,"crime_command","back")
## Butchers any body within reach, then feeds the leader and the willing; deceives the rest when asked to.
func eat_the_dead(game,deceive: bool) -> bool:
	if not game.open_remains():return false
	for item in Remains.here(game):
		if item.state in ["lying","carried"]:
			pick(game,"remains_command","butcher_open" if not deceive else "butcher_secret")
			break
	if game.state.status!="traveling" or not game.pending.get("remains_menu",false):return true
	for member in game.party_health.members:
		var slot: int=int(member.id)
		if not game.party_health.is_active(member):continue
		if slot==0:pick(game,"remains_command","eat",0)
		elif Remains.willing(game,slot):pick(game,"remains_command","offer",slot)
		elif deceive:pick(game,"remains_command","deceive",slot)
	if game.pending.get("remains_menu",false):pick(game,"remains_command","back")
	return true
## Visits a camp the lawful way: trade for food when bullets allow, have the first traveler in need nursed, and swap news.
func visit_camp(game) -> bool:
	if not game.open_camp():return false
	for key in ["barter_food","care","news"]:
		if not game.pending.get("service_menu",false) and not game.open_camp():return true
		for index in range(game.pending.choices.size()):
			if str(game.pending.choices[index].get("market_key","")).ends_with("|"+key) and game.can_choose(index):
				game.choose(index)
				break
	if game.pending.get("service_menu",false):game.choose(game.pending.choices.size()-1)
	return true
func run():
	adaptive=true
	hunting_study=true
	var rows: Array=[]
	var errors: Array=[]
	var store=Store.new()
	var policy: Dictionary={"id":"outlaw","pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":45,"adaptive_rations":true,"preserve":"salt","slaughter":true}
	for strategy in STRATEGIES:
		for seed_value in range(4):
			var game=Simulation.new(seed_value,"classic",true)
			var cart: Dictionary={}
			for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
			game.depart("banker",["A","B","C","D","E"],[6,5,8,7][seed_value],cart)
			var aim:=RandomNumberGenerator.new()
			aim.seed=seed_value ^ 0x4f55544c
			var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
			var acts: Dictionary={"robberies":0,"kearny":false,"attacked":false}
			var outcome: String="limit"
			var progress: Dictionary={}
			var label: String="%s seed %d" % [strategy,seed_value]
			for step in range(3000):
				progress[int(game.state.day)]=int(game.state.miles)
				if game.state.status!="traveling":
					outcome=game.state.status
					break
				if game.state.day>=365:break
				var okay:=true
				var idle: bool=game.pending.is_empty() or game.pending.has("landmark")
				if game.pending.get("crime_menu",false):okay=settle_crime(game)
				elif game.pending.get("remains_menu",false) or game.pending.get("attack_menu",false):okay=game.choose(game.pending.choices.size()-1)
				elif idle and strategy=="lawful" and not game.crime.camp(game).is_empty() and game.crime.camp(game) not in acts.visited:
					acts.visited.append(game.crime.camp(game))
					okay=visit_camp(game)
				elif idle and strategy=="road_robber" and acts.robberies<3 and game.crime.eligible(game) and game.crime.transient(game.crime.target(game)):
					acts.robberies+=1
					okay=game.open_crime() and pick(game,"crime_command","robbery")
				elif idle and strategy=="kearny" and not acts.kearny and game.pending.get("landmark","")=="fort_kearny" and game.crime.eligible(game):
					acts.kearny=true
					okay=game.open_crime() and pick(game,"crime_command","robbery")
				elif idle and strategy in ["open_cannibal","killer"] and not acts.attacked and game.state.day>=20 and game.state.party_size>=3 and game.state.bullets>0:
					acts.attacked=true
					var target: int=game.party_health.members.filter(func(member):return member.id>0 and game.party_health.is_active(member)).back().id
					okay=game.open_attack(target) and game.choose(0)
				elif idle and strategy in ["open_cannibal","killer"] and Remains.here(game).any(func(item):return item.state in ["lying","carried"]):
					okay=eat_the_dead(game,strategy=="killer")
				else:okay=act(game,policy,aim,count)
				if not okay:
					outcome="policy_blocked"
					errors.append({"run":label,"day":game.state.day,"error":"blocked policy","pending":game.pending.get("id","")})
					break
				if game.state.food<0 or game.state.money<0 or game.state.party_size!=game.party_health.living_count() or game.state.health!=game.party_health.average_health() or int(game.state.get("remains_lb",0))!=Remains.weight(game):
					errors.append({"run":label,"day":game.state.day,"error":"state invariant"})
				if step%40==0 or game.pending.get("crime_menu",false) or game.pending.get("remains_menu",false):
					var snapshot: Dictionary=store.capture(game)
					if not snapshot.is_empty() and store.restore(JSON.parse_string(JSON.stringify(snapshot)))==null:errors.append({"run":label,"day":game.state.day,"error":"save round trip","pending":game.pending.get("id","")})
			# Running out of time is an outcome; making no progress for two months is a stuck journey.
			if outcome=="limit":
				var earlier: int=int(progress.get(int(game.state.day)-60,-1))
				if earlier<0 or earlier>=int(game.state.miles):errors.append({"run":label,"error":"journey stuck"})
				else:outcome="out_of_time"
			if store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append({"run":label,"error":"final save"})
			var record: Dictionary=game.crime.record
			rows.append({"strategy":strategy,"seed":seed_value,"outcome":outcome,"days":game.state.day,"miles":game.state.miles,"survivors":game.state.party_size,
				"deaths":game.party_health.members.filter(func(member):return not member.alive).size(),"departures":game.party_health.members.filter(func(member):return member.get("departed",false)).size(),
				"incidents":record.incidents.map(func(current):return "%s:%s:%s" % [current.action,current.attempt,current.resolution]),"attacks":record.attacks.map(func(attack):return attack.attempt),
				"remains":record.remains.map(func(item):return item.state),"camps_visited":acts.visited.size(),"tales":game.crime.tales(game).size(),"betrayals":record.betrayals.map(func(item):return "%s:%s" % [item.act,item.attempt])})
			print("%s: %s on day %d at mile %d, %d with the party" % [label,outcome,game.state.day,game.state.miles,game.state.party_size])
	var file=FileAccess.open("res://docs/outlaw-journeys.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"rules_signature":store.fingerprint(),"runs":rows,"errors":errors,"policy":"20 full-route journeys: 5 strategies x 4 seeds (banker suggested outfit; June, May, August, July). Lawful control that visits each emigrant camp peacefully (trading bullets for food, nursing, news); robbing up to three roadside parties; robbing the Fort Kearny commissary; shooting a companion on day 20, then butchering any accessible dead openly and offering the meat, or in secret and serving it without telling. Otherwise the cautious salted-hunt survival policy. An integration check, not balance evidence."},"\t"))
	file.close()
	for error in errors:printerr("ERROR: %s" % JSON.stringify(error))
	print("Outlaw journeys: %d runs, %d errors" % [rows.size(),errors.size()])
	quit(0 if rows.size()==20 and errors.is_empty() else 1)
