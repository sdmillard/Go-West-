extends RefCounted
## Winter cabins and settling short of Oregon (Spencer, October 31). A party builds a log cabin at a stop with
## timber over several work days; a finished cabin keeps out the cold but not hunger. A party may settle anywhere,
## any time: Missouri and the Willamette edge are open, a post takes it unless it refuses the party over crimes,
## and in Native country the people there decide. Staying where they refuse ends with the party run off.
## state.cabins = {stop: work units}; two units per worker-day, three with Carpentry.
## state.settled = {"place", "kind", "people"} once the journey has ended by settling.
const KINDS=["open","post","cabin","native","run_off"]
static var data: Dictionary=load_rules()

static func load_rules() -> Dictionary:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/cabins.json"))
	return parsed if valid_rules(parsed) else {}

static func number(v: Variant) -> bool:return (v is int or v is float) and is_finite(float(v))
static func whole(v: Variant,low: int,high: int) -> bool:return number(v) and v==floor(v) and v>=low and v<=high

static func valid_rules(v: Variant,route=null) -> bool:
	if not v is Dictionary or not v.get("note") is String or not whole(v.get("worker_days"),1,200) or not whole(v.get("minimum_health"),0,100):return false
	if not number(v.get("carpentry_factor")) or v.carpentry_factor<1 or v.carpentry_factor>3 or not number(v.get("winter_illness_factor")) or v.winter_illness_factor<0 or v.winter_illness_factor>1:return false
	if not v.get("timber") is Array or not v.timber.all(func(id):return id is String):return false
	var s: Variant=v.get("settle")
	if not s is Dictionary or not s.get("note") is String or not number(s.get("consent_chance")) or s.consent_chance<0 or s.consent_chance>1:return false
	for key in ["open","posts"]:
		if not s.get(key) is Array or not s[key].all(func(id):return id is String):return false
	if not s.get("peoples") is Dictionary or not s.peoples.values().all(func(name):return name is String and not name.is_empty()):return false
	if route!=null:
		# Every stop but the destination is open, a post, or somebody's country, and only one of these.
		for id in route.nodes:
			if route.nodes[id].kind=="destination":continue
			if [id in s.open,id in s.posts,s.peoples.has(id)].count(true)!=1:return false
		if not v.timber.all(func(id):return route.nodes.has(id)):return false
	return true

static func units_needed() -> int:return int(data.worker_days)*2
## Physically at a stop: its menu is open, or the party has not yet left it.
static func at_stop(game) -> bool:
	return game.state.extended_route and (game.pending.get("landmark","")==game.state.landmark or (int(game.state.leg_miles)==0 and game.Direction.heading(game)=="west"))
static func progress(game,place: String) -> int:return int(game.state.get("cabins",{}).get(place,0))
static func done(game,place: String) -> bool:return progress(game,place)>=units_needed()
## Sheltered tonight: camped at a stop with a finished cabin.
static func sheltered(game) -> bool:return at_stop(game) and done(game,str(game.state.landmark))
static func timber(game) -> bool:return str(game.state.landmark) in data.timber

## Fit, willing hands and what each gives in a day.
static func workers(game) -> Array:
	var hands: Array=[]
	for member in game.party_health.members:
		var id: int=int(member.id)
		if not game.party_health.is_active(member) or int(member.health)<int(data.minimum_health) or not game.characters.willing(id,"repair"):continue
		hands.append({"id":id,"units":roundi(2*float(data.carpentry_factor)) if game.camp_tasks.specialist(game,id,"Carpentry") else 2})
	return hands

static func reason(game) -> String:
	if not game.can_service():return "Finish the current event first."
	if not at_stop(game):return "A cabin goes up at a stop, not on the open road."
	var place: String=str(game.state.landmark)
	if not timber(game):return "There is no timber for a cabin at %s." % game.route.nodes[place].name
	if done(game,place):return "Your cabin here is finished."
	if int(game.state.get("hatchets",0))<1:return "Felling and notching logs needs a hatchet."
	if workers(game).is_empty():return "Nobody is fit and willing to build."
	return ""

static func days_left(game) -> int:
	var units: int=workers(game).reduce(func(sum,hand):return sum+int(hand.units),0)
	return 0 if units<=0 else ceili(float(units_needed()-progress(game,str(game.state.landmark)))/units)

## One building day: the party works instead of resting, then the logs go up.
static func build(game) -> bool:
	if not reason(game).is_empty():return false
	var place: String=str(game.state.landmark)
	var hands: Array=workers(game)
	game._tick_day(false,false)
	if game.state.status!="traveling":return true
	var gained: int=hands.filter(func(hand):return game.party_health.is_active(game.party_health.members[int(hand.id)])).reduce(func(sum,hand):return sum+int(hand.units),0)
	if not game.state.has("cabins"):game.state["cabins"]={}
	game.state.cabins[place]=mini(units_needed(),progress(game,place)+gained)
	if done(game,place):game.journal.append("Day %d · The cabin at %s is finished: four log walls, a roof and a fire. It will keep out the cold, if not the hunger." % [game.state.day,game.route.nodes[place].name])
	else:game.journal.append("Day %d · Cabin building at %s: %d of %d worker-days done." % [game.state.day,game.route.nodes[place].name,progress(game,place)/2,int(data.worker_days)])
	if game.state.status=="traveling" and game.pending.is_empty():game._schedule_event(false)
	return true

## Who decides whether the party may stay here, and whether they agree.
static func settle_kind(game) -> String:
	var place: String=str(game.state.landmark)
	if place in data.settle.open:return "open"
	if place in data.settle.posts:return "post"
	return "native"
static func people(game) -> String:
	var site: Dictionary=game.native_encounters.data.sites.get(str(game.state.landmark),{})
	return str(site.get("people",data.settle.peoples.get(str(game.state.landmark),"")))
## The people of this country decide once per party and place, apart from the game's dice; anything they have
## heard against the party, or a household that will not deal with it, is a refusal.
static func consents(game) -> bool:
	var place: String=str(game.state.landmark)
	if game.crime.refuses(game,place) or not game.crime.household_refusal(game,place).is_empty() or game.crime.driven_out(game,place):return false
	var dice:=RandomNumberGenerator.new()
	dice.seed=("%d|settle|%s" % [int(game.state.seed),place]).hash()
	return dice.randf()<float(data.settle.consent_chance)
static func welcome(game) -> bool:
	match settle_kind(game):
		"open":return true
		"post":return not game.crime.refuses(game,str(game.state.landmark)) and not game.crime.closed(str(game.state.landmark))
	return consents(game)
static func settle_reason(game) -> String:
	if not game.can_service():return "Finish the current event first."
	if not at_stop(game):return "Settle at a stop, where there is water and wood."
	if game.route.nodes[str(game.state.landmark)].kind=="destination":return "You have reached Oregon."
	if not game.party_health.is_active(game.party_health.members[0]):return "The leader must be alive to settle."
	return ""
## What staying here means, before the player commits.
static func settle_text(game) -> String:
	var name: String=game.route.nodes[str(game.state.landmark)].name
	var cabin: String=" Your cabin here is ready." if done(game,str(game.state.landmark)) else (" You have no cabin here yet." if timber(game) else " There is no timber here for a cabin.")
	match settle_kind(game):
		"open":return "Settle at %s for good and end the journey short of Oregon.%s" % [name,cabin]
		"post":
			if welcome(game):return "The people at %s will take you on as hands or let you squat nearby. Settling ends the journey short of Oregon.%s" % [name,cabin]
			return "%s will have nothing to do with your party. If you stay anyway you will be run off, and the journey ends there.%s" % [name,cabin]
	var folk: String=people(game)
	if welcome(game):return "The %s people here are willing to let your party stay. Settling ends the journey short of Oregon.%s" % [folk,cabin]
	return "This is %s country, and they will not have your party stay. If you stay anyway they will run you off, and the journey ends there.%s" % [folk,cabin]

## End the journey here: settled, or run off where nobody would have the party.
static func settle(game) -> bool:
	if not settle_reason(game).is_empty():return false
	var place: String=str(game.state.landmark)
	var kind: String=settle_kind(game)
	if kind=="native" or kind=="post":kind=("cabin" if done(game,place) and kind=="native" else kind) if welcome(game) else "run_off"
	elif done(game,place):kind="cabin"
	game.state["settled"]={"place":place,"kind":kind,"people":people(game) if settle_kind(game)=="native" else ""}
	game.state.status="settled"
	game.pending={}
	game.service_return={}
	game.journal.append("Day %d · %s" % [game.state.day,ending_title(game)])
	return true

static func ending_title(game) -> String:
	var s: Dictionary=game.state.get("settled",{})
	var name: String=game.route.nodes[str(s.get("place",game.state.landmark))].name
	return "Run off from %s" % name if s.get("kind","")=="run_off" else "Settled at %s" % name
static func ending_text(game) -> String:
	var s: Dictionary=game.state.get("settled",{})
	var name: String=game.route.nodes[str(s.place)].name
	var text: String={
		"open":"Your party went no farther than %s and made a home there, short of Oregon." % name,
		"post":"Your party stayed on at %s, working for the post and living beside it, short of Oregon." % name,
		"cabin":"Your party wintered in its own cabin at %s and stayed for good, short of Oregon%s." % [name,", with the leave of the %s people" % s.people if not str(s.people).is_empty() else ""],
		"run_off":"Your party tried to stay at %s against the wishes of %s. Within weeks they ran you off with what you could carry, and the journey ended there." % [name,"the post" if str(s.people).is_empty() else "the %s people" % s.people]}[s.kind]
	return text+"\n\n"+game.journey_summary()

static func valid_state(s: Dictionary,route) -> bool:
	if s.has("cabins"):
		if not s.cabins is Dictionary or s.cabins.size()>data.timber.size():return false
		for place in s.cabins:
			if place not in data.timber or not whole(s.cabins[place],1,units_needed()):return false
	if s.get("status")=="settled"!=s.has("settled"):return false
	if s.has("settled"):
		var v: Variant=s.settled
		if not v is Dictionary or v.size()!=3 or not route.nodes.has(v.get("place")) or v.get("kind") not in KINDS or not v.get("people") is String or v.place!=s.get("landmark"):return false
	return true
