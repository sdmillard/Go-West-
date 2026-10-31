extends SceneTree
## Jailbreak: the free companions fight the guards to free the prisoners, who have no arms.
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Detention=preload("res://simulation/detention.gd")
const Armory=preload("res://simulation/armory.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit(seed_value: int=57,extra: Dictionary={}):
	var game=Simulation.new(seed_value,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	cart.merge(extra,true)
	game.depart("banker",["A","B","C","D","E"],5,cart)
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	for profile in game.characters.profiles.slice(1):
		profile.boundaries={"approved":[],"disapproved":[],"forbidden":[]}
		profile.trust=80
	return game
func at(game,place: String):
	game.state.next_landmark=place
	game._arrive_landmark()
	game.state.miles=int(game.route.node_miles()[place])
	return game
func pick(game,command: String) -> bool:
	for index in range(game.pending.get("choices",[]).size()):
		if game.pending.choices[index].get("crime_command","")==command:return game.choose(index)
	return false
func offers(game,command: String) -> bool:
	return game.pending.get("choices",[]).any(func(choice):return choice.get("crime_command","")==command)
func roundtrip(game,label: String) -> void:
	var store=Store.new()
	var snapshot: Dictionary=store.capture(game)
	var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(copy!=null,label+" restores: "+store.error)
	if copy!=null:check(store.capture(copy)==snapshot,label+" restores exactly")
## The leader alone caught stealing at the Independence store and held for the county court.
func jailed(seed_value: int=57,extra: Dictionary={}):
	var game=at(outfit(seed_value,extra),"independence")
	# The companions would not steal, so only the leader is held.
	for profile in game.characters.profiles.slice(1):
		profile.boundaries={"approved":[],"disapproved":[],"forbidden":["robbery"]}
		profile.thresholds.loyalty=101
	game.open_crime("independence")
	game.crime.scenes.independence.theft_success=0
	pick(game,"theft")
	pick(game,"surrender")
	for profile in game.characters.profiles.slice(1):
		profile.boundaries={"approved":[],"disapproved":[],"forbidden":[]}
		profile.thresholds.loyalty=80
	game.pending=game.crime.menu(game)
	return game
func run() -> void:
	var game=jailed(57,{"revolvers":1})
	var custody: Dictionary=game.crime.incident()
	check(custody.stage=="custody" and int(custody.custody.arms.get("revolvers",0))==1,"The leader is held and has given up the Colt")
	check(offers(game,"jailbreak"),"Free, armed companions can try to break the leader out")
	roundtrip(game,"Custody with a jailbreak offer")
	# Nobody willing, or no gun: no jailbreak.
	var timid=jailed()
	for profile in timid.characters.profiles.slice(1):
		profile.boundaries={"approved":[],"disapproved":[],"forbidden":["murder"]}
		profile.thresholds.loyalty=101
	timid.pending=timid.crime.menu(timid)
	check(not offers(timid,"jailbreak"),"Companions who would never kill won't storm a jail")
	var unarmed=jailed()
	unarmed.state.bullets=0
	unarmed.pending=unarmed.crime.menu(unarmed)
	check(not offers(unarmed,"jailbreak"),"Without a loaded gun there is no jailbreak")
	# Breaking custody ends it as an escape and opens a standoff with the county's guards.
	check(pick(game,"jailbreak"),"The party tries a jailbreak")
	var attack: Dictionary=game.crime.incident()
	check(custody.stage=="done" and custody.resolution=="escaped" and custody.custody.get("broken",false),"The broken custody is closed as an escape")
	check(attack.action=="assault" and attack.stage=="standoff" and attack.place==("jail_county:%d" % int(custody.id)),"The jailbreak is an assault on the county's guards")
	check(game.crime.rules(attack.place).kind=="jail" and game.crime.living_staff(attack.place).size()==3,"The jailer and two deputies guard the cells")
	check(Detention.jailbreak_incident(game.crime,attack) and Detention.prisoners(game.crime,attack)==[0],"The fight knows who the prisoners are")
	check(offers(game,"breakout") and offers(game,"surrender") and "prisoners have no arms" in game.pending.text,"The standoff offers the fight or surrender")
	check(game.crime.record.reports.any(func(report):return int(report.incident)==int(custody.id)),"The original crime is now reported as an escape")
	roundtrip(game,"Jailbreak standoff")
	# The tactical fight: prisoners fight bare-handed; the rescuers carry the party's arms; every guard fights.
	check(game.crime.build_tactical_config(game,"breakout").venue_kind=="jail_county","The county jailbreak is fought in the Jackson County jail")
	check(Armory.icon("hatchets").region==Rect2(80,0,16,16) and Armory.icon("food")==null,"Each arm has its icon")
	check(game.start_tactical_combat("breakout"),"The jailbreak opens the tactical fight")
	var session: Dictionary=game.tactical_session
	var leader: Dictionary=game.tactical.get_unit(session,"0")
	check(leader.weapon=="" and leader.blade=="" and game.tactical.melee(leader).label=="Fists","The prisoner fights with bare hands")
	check(game.tactical.get_unit(session,"1").weapon=="rifles","A rescuer carries a rifle")
	check(session.units.filter(func(unit):return unit.team=="enemy").size()==3,"All three guards stand against the jailbreak")
	# Win: everyone gets away and the prisoners take back their arms.
	for unit in session.units:
		if unit.team=="enemy":
			unit.health=0
	session.resolved=true
	session.outcome="victory"
	session.reason="breakout"
	check(game.finish_tactical_combat(),"The fight resolves")
	check(attack.resolution=="escaped" and attack.attempt=="killed" and not attack.get("kills",[]).is_empty(),"The jailbreak killed the jailer and is an escape: "+str(attack.attempt))
	check(Armory.count(game.state,"revolvers")==1,"The leader takes back the Colt")
	check(game.state.status=="traveling","The journey goes on")
	roundtrip(game,"After a jailbreak")
	# Lose: the rescuers join the prisoners before the same court, for the jailbreak and the original crime.
	var failed=jailed(58)
	odds_zero(failed)
	check(pick(failed,"jailbreak") and pick(failed,"breakout"),"A headless jailbreak is fought by the odds")
	var retaken: Dictionary=failed.crime.incident()
	check(retaken.action=="assault" and retaken.stage=="custody" and retaken.custody.authority=="county","Retaken, the party is held by the county for the jailbreak")
	check(retaken.custody.accused.size()>1,"The rescuers are held with the leader: "+str(retaken.custody.accused))
	check(failed.crime.Wanted.trial_charges(failed.crime,failed,retaken).size()>=2,"The court hears the jailbreak and the original crime")
	roundtrip(failed,"Retaken after a jailbreak")
	# A household's kin guard their own prisoners.
	check(Detention.jail_place(game.crime,{"id":1,"place":"native:platte","custody":{"authority":"council"}})=="native:platte","A household's kin are the guards of its council")
	print("Jailbreak: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
func odds_zero(game) -> void:
	for key in ["jail_county","jail_army","jail_company"]:game.crime.scenes[key].breakout=0.0
	game.crime.modifiers.floor=0.0
