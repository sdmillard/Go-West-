extends RefCounted
## Derived, deduplicated evidence; daily encounters and persistent frontier sentences.
const PREFIXES={"posse":"wanted_posse:","regulators":"wanted_regulators:","bounty_hunters":"wanted_hunters:"}
const POSTS=["fort_laramie","fort_bridger","fort_hall","fort_boise"]
const SENTENCES=["restitution","robbery","assault","hanged"]
const RIDE_LABEL="Cut loose and ride · leave the wagon, grab what you can, 1 day"
const CHOOSE_LABEL="Cut loose and ride · too few horses: choose who rides, the rest stay with the wagon"
static func valid_rules(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=18 or not value.get("note") is String:return false
	for key in ["posse_max_mile","decay_days","cooldown_days","army_max_days","bounty_min_cents","bounty_max_cents","bounty_step_cents","robbery_reward_cents","flogging_damage","left_behind_trust"]:
		if not whole(value.get(key),1,100000):return false
	for key in ["daily_base","daily_cap","seizure_chance","helper_banish_chance","mounted_flight_bonus","left_behind_taken"]:
		if not number(value.get(key)) or value[key]<0 or value[key]>1:return false
	return number(value.get("payoff_factor")) and value.payoff_factor>=1 and value.payoff_factor<=2 and value.bounty_max_cents>=value.bounty_min_cents
## How the party would run: in the saddle (two to a horse if need be), behind the oxen, or on foot.
static func flight_plan(game) -> Dictionary:
	var inventory: Dictionary=game.state.duplicate()
	inventory["double_up"]=true
	return game.Mounts.plan(game.provisions.data.mounts,inventory)
static func flight_speed(game) -> float:
	if game.Mounts.mounted(flight_plan(game)):return float(game.Mounts.condition(game.state))/100.0
	return float(game.state.ox_health)/100.0 if game.state.vehicle!="foot" and int(game.state.oxen)>0 else 0.25
## Riders outrun most pursuit, though the riders after them are mounted too: a bonus, never a certainty.
static func flight_bonus(crime,game) -> float:
	return float(crime.wanted_data.mounted_flight_bonus) if game.Mounts.mounted(flight_plan(game)) else 0.0
static func flight_chance(crime,game,scene: Dictionary) -> float:
	return clampf(1.0-float(scene.escape_capture)+(flight_speed(game)-0.5)*0.2+int(game.state.pace)*0.04+flight_bonus(crime,game),0.05,0.85)
## A hard ride wears the animals: one hard-pace day, at the doubled-up rate when two share a saddle.
static func ride_hard(game) -> void:
	var plan: Dictionary=flight_plan(game)
	if not game.Mounts.mounted(plan):return
	if plan.mode=="doubled" and not game.state.get("double_up",false):game.state["double_up"]=true
	var wear: int=game.Mounts.wear(game.provisions.data.mounts,plan,game.context.region_id(game),0,2)
	game.state["horse_health"]=maxi(0,game.Mounts.condition(game.state)-wear)
	if game.state.horse_health==0:game.Mounts.breakdown(game)
## A wagon party can cut loose: as many as the saddled animals carry two to a saddle, the wagon left where it stands.
static func can_ride_off(game) -> bool:
	if game.state.vehicle!="wagon" or not game.wagon_cache.is_empty():return false
	if game.state.next_landmark==game.state.landmark and game.travelled_path().size()<2:return false
	return seats(game)>0
## Riders the saddled animals can carry in a getaway, two to a saddle.
static func seats(game) -> int:
	return 2*mini(game.Mounts.count(game.state,"saddles"),game.Mounts.count(game.state,"horses")+game.Mounts.count(game.state,"mules"))
## Whether the whole party fits on the animals, doubled if need be.
static func everyone_rides(game,left: Array=[]) -> bool:
	var inventory: Dictionary=game.state.duplicate()
	inventory["vehicle"]="foot"
	inventory["double_up"]=true
	inventory["party_size"]=int(game.state.party_size)-left.size()
	return game.Mounts.mounted(game.Mounts.plan(game.provisions.data.mounts,inventory))
static func ride_label(game) -> String:
	return RIDE_LABEL if everyone_rides(game) else CHOOSE_LABEL
## Who stays with the wagon: active companions not picked to ride. The leader always rides.
static func left_behind(game,riding: Array) -> Array:
	return game.party_health.members.filter(func(member):return int(member.id)>0 and game.party_health.is_active(member) and int(member.id) not in riding).map(func(member):return int(member.id))
## The first pick: the leader, then companions in party order until the saddles are full.
static func default_riders(game) -> Array:
	var riding: Array=[0]
	for member in game.party_health.members:
		if riding.size()>=seats(game):break
		if int(member.id)>0 and game.party_health.is_active(member):riding.append(int(member.id))
	return riding
static func valid_riders(game,riding: Variant) -> bool:
	if not riding is Array or riding.is_empty() or riding.size()>seats(game) or not can_ride_off(game):return false
	var seen: Array=[]
	for id in riding:
		if not whole(id,0,game.party_health.members.size()-1) or int(id) in seen or not game.party_health.is_active(game.party_health.members[int(id)]):return false
		seen.append(int(id))
	return 0 in seen
## The picker: each companion can be taken or left; the leader rides. Choices carry rider_member: an id to toggle, -1 to ride, -2 to go back.
static func riders_menu(game,riding: Array) -> Dictionary:
	var names:=func(ids):return ", ".join(ids.map(func(id):return game.party_health.members[int(id)].name)) if not ids.is_empty() else "nobody"
	var left:=left_behind(game,riding)
	var text: String="Saddles for %d, two to a horse. Riding: %s. Staying with the wagon: %s.\nThose left behind guard the wagon and its goods until you come back for them, if the pursuers don't take them in first." % [seats(game),names.call(riding),names.call(left)]
	var choices: Array=[]
	for member in game.party_health.members:
		var id: int=int(member.id)
		if id==0 or not game.party_health.is_active(member):continue
		choices.append({"label":("Leave %s with the wagon" if id in riding else "Take %s along") % member.name,"rider_member":id,"effects":{},"result":""})
	choices.append({"label":"Ride off · %d riding, %d staying, 1 day" % [riding.size(),left.size()],"rider_member":-1,"effects":{},"result":""})
	choices.append({"label":"Back","rider_member":-2,"effects":{},"result":""})
	return {"id":"riders","riders_menu":true,"service_menu":true,"title":"Who rides?","text":text,"riding":riding.duplicate(),"choices":choices}
static func can_choose_rider(game,index: int) -> bool:
	if not game.pending.get("riders_menu",false) or index<0 or index>=game.pending.choices.size():return false
	var riding: Array=game.pending.riding
	var id: int=int(game.pending.choices[index].rider_member)
	if id==-2:return true
	if id==-1:return valid_riders(game,riding)
	return id in riding or riding.size()<seats(game)
static func choose_rider(game,index: int) -> bool:
	if not can_choose_rider(game,index):return false
	var riding: Array=game.pending.riding.duplicate()
	var id: int=int(game.pending.choices[index].rider_member)
	if id==-2:
		game.pending=game.crime.menu(game)
		return true
	if id==-1:
		game.pending=game.crime.menu(game)
		return game.crime.choose(game,"ride",left_behind(game,riding))
	if id in riding:riding.erase(id)
	else:riding.append(id)
	riding.sort()
	game.pending=riders_menu(game,riding)
	return true
## Temperaments that never wait at an abandoned wagon: too frightened, or looking out for themselves.
const SCATTER=["Nervous","Self-serving"]
## Whether a companion left at the wagon slips away as the riders go. Broken trust always does;
## the fearful and the self-serving do unless Loyal; the Loyal stay; others go more often the lower their trust.
static func slips_away(crime,game,id: int) -> bool:
	var profile: Dictionary=game.characters.profiles[id]
	var trust: float=float(profile.trust)
	if trust<=float(profile.get("thresholds",{}).get("breaking",20)):return true
	if "Loyal" in profile.get("specials",[]):return false
	if profile.traits.any(func(name):return name in SCATTER):return true
	return crime.rng.randf()<clampf((float(crime.wanted_data.left_behind_trust)-trust)/100.0,0.0,1.0)
## What becomes of those left with the wagon: some slip away at once, and pursuers coming on the wagon may take in the rest.
## The party learns it when it comes back.
static func left_at_wagon(crime,game,pursued: bool) -> void:
	var cache: Dictionary=game.wagon_cache
	if not cache.has("guards"):return
	var food=game.Guards.Food.new()
	food.data=game.provisions.data.duplicate(true)
	food.fresh.assign(cache.fresh.duplicate(true))
	var day: int=int(game.state.day)
	for member in cache.guards:
		if not member.alive or member.get("departed",false):continue
		if slips_away(crime,game,int(member.id)):
			game.Guards._leave(game,cache,member,food,day,"slipped away as the riders left")
		elif pursued and crime.rng.randf()<float(crime.wanted_data.left_behind_taken):
			member["departed"]=true
			member["guard_departure"]=true
			member["departure_day"]=day
			member["departure_place"]=cache.location.from
			member["departure_supplies"]={"food":0,"clothing":0,"gear_lb":int(game.provisions.data.walking.personal_gear_lb_per_person)}
			member.history.append("Day %d · Taken in by the pursuers at the abandoned wagon." % day)
			cache.household_gear_lb=maxf(0.0,float(cache.household_gear_lb)-float(game.provisions.data.walking.personal_gear_lb_per_person))
			game.Guards._log(cache,day,"%s was taken in by the pursuers who came on the wagon." % member.name)
	cache.fresh=food.fresh.duplicate(true)
## Nobody planned this: whatever comes to hand goes into the saddlebags and packs, in no sensible order,
## and the rest stays with the wagon. Spare wagon parts stay behind.
static func cut_loose(crime,game,left: Array=[]) -> bool:
	if not can_ride_off(game) or not everyone_rides(game,left) or not (left.is_empty() or game.Guards.valid_selection(game,left)):return false
	game.state["double_up"]=game.state.get("double_up",false) or game.Mounts.plan(game.provisions.data.mounts,game.state.merged({"vehicle":"foot","party_size":int(game.state.party_size)-left.size()})).mode!="mounted"
	var items: Array=["food","bullets","clothing","medicine","salt"]
	var stock: Dictionary=game.CacheSupport.available(game)
	var cart: Dictionary={}
	for key in stock:cart[key]=0
	var capacity: float=float(game.CacheSupport.quote(game,cart,false,left,false,true).get("capacity_lb",0.0))
	var weights: Dictionary=game.provisions.data.weights_lb
	var room: float=capacity-float(game.provisions.data.walking.personal_gear_lb_per_person)*(int(game.state.party_size)-left.size())
	# Shuffle with the crime's own generator so a saved game replays the same scramble.
	for i in range(items.size()-1,0,-1):
		var j: int=crime.rng.randi_range(0,i)
		var swap=items[i]
		items[i]=items[j]
		items[j]=swap
	for key in items:
		var grab: int=floori(int(stock.get(key,0))*crime.rng.randf_range(0.3,1.0))
		var each: float=float(weights.get(key,1.0))
		grab=mini(grab,floori(maxf(0.0,room)/each)) if each>0 else grab
		cart[key]=maxi(0,grab)
		room-=grab*each
	var offer: Dictionary=game.CacheSupport.quote(game,cart,false,left,false,true)
	# Fresh meat weighs more than the pound guess: shed food until the load fits.
	while not offer.valid and int(cart.food)>0:
		cart.food=maxi(0,int(cart.food)-maxi(1,int(cart.food)/10))
		offer=game.CacheSupport.quote(game,cart,false,left,false,true)
	if not offer.valid:return false
	var names: Array=left.map(func(id):return game.party_health.members[int(id)].name)
	game.CacheSupport.pack(game,cart,false,left,true)
	game.journal.append("Day %d · Cut loose from the wagon and rode for it. Grabbed in a hurry: %s. Everything else stays with the wagon%s." % [game.state.day,game.RobberyDemand.describe(cart)," and "+", ".join(names) if not names.is_empty() else ""])
	return true
static func number(value: Variant) -> bool:return (value is int or value is float) and is_finite(value)
static func whole(value: Variant,low: int,high: int) -> bool:return number(value) and value==floor(value) and value>=low and value<=high
static func is_wanted(place: String) -> bool:return PREFIXES.values().any(func(prefix):return place.begins_with(prefix))
static func here(game,place: Variant) -> int:
	return int(place) if number(place) else (int(game.state.miles) if str(place).is_empty() else game.crime.mile(game,str(place)))
static func arrived(crime,game,source: Dictionary,place: Variant,day: int=-1) -> bool:
	if day<0:day=int(game.state.day)
	if (place is String and place==source.origin) or here(game,place)==crime.mile(game,str(source.origin)):return int(source.day)<=day
	return int(source.day)+int(crime.news_rules.delay_days)+ceili(absi(here(game,place)-crime.mile(game,str(source.origin)))/float(crime.news_rules.miles_per_day))<=day
static func value_of(game,item: Dictionary) -> int:
	# Food restitution uses the documented opening staple price, in cents.
	return int(item.cash_cents)+int(item.food)*int(game.outfitter.goods[1].price_cents)+roundi(game.RobberyDemand.value(game,item.get("taken_goods",{})))
static func incident_evidence(crime,game,item: Dictionary,identified: bool) -> Dictionary:
	var action: String=item.action
	var military: bool=crime.rules(item.place).kind=="fort"
	var weight: float=5.0 if military else ({"theft":1.0,"robbery":2.0,"raid":2.0,"shoot":4.0,"assault":4.0,"pursuit":5.0,"wanted":4.0}.get(action,0.0))
	var severity: int=1 if action=="theft" else (2 if action in ["robbery","raid"] else 3)
	if item.attempt=="killed" or not item.get("kills",[]).is_empty():severity=4
	if action in ["wanted","pursuit"] and int(item.shots)==0:weight=0
	return {"id":"incident:%d" % int(item.id),"weight":weight if identified else weight*0.5,"severity":severity,"value":value_of(game,item),"day":int(item.day),"identified":identified,"origin":item.place,"joining":item.get("joining",[])}
## Merge reports and tales about the same act, taking the strongest identification, never double-counting.
static func evidence(crime,game,place: Variant="",local: Dictionary={},day: int=-1) -> Array:
	var known: Dictionary={}
	for report in crime.record.reports:
		if arrived(crime,game,report,place,day):merge(known,incident_evidence(crime,game,crime.record.incidents[int(report.incident)-1],report.identified))
	for told in crime.tales(game):
		if not arrived(crime,game,told,place,day):continue
		for id in told.incidents:merge(known,incident_evidence(crime,game,crime.record.incidents[int(id)-1],true))
		for id in told.attacks:
			var attack: Dictionary=crime.record.attacks[int(id)-1]
			merge(known,{"id":"attack:%d" % int(id),"weight":4.0,"severity":4 if attack.attempt=="killed" else 3,"value":0,"day":int(attack.day),"identified":true,"origin":told.origin,"joining":attack.joining})
		for id in told.remains:
			merge(known,{"id":"remains:%d" % int(id),"weight":3.0,"severity":2,"value":0,"day":int(told.day),"identified":true,"origin":told.origin,"joining":[]})
	if not local.is_empty() and local.action!="wanted" and (local.action!="pursuit" or int(local.shots)>0):merge(known,incident_evidence(crime,game,local,true))
	return known.values().filter(func(item):return float(item.weight)>0)
static func merge(known: Dictionary,item: Dictionary) -> void:
	if not known.has(item.id) or float(known[item.id].weight)<float(item.weight):known[item.id]=item
static func notoriety(crime,game,place: Variant="",day: int=-1) -> float:
	var total:=0.0
	for item in evidence(crime,game,place,{},day):total+=float(item.weight)
	return total
static func settled(crime) -> Array:
	var ids: Array=[]
	for item in crime.record.incidents:
		if item.has("sentence"):ids.append_array(item.sentence.charges)
	return ids
static func charges(crime,game,place: Variant,local: Dictionary={}) -> Array:
	var answered:=settled(crime)
	return evidence(crime,game,place,local).filter(func(item):return item.id not in answered)
static func pursuit_days(crime,game,place: String) -> int:
	return mini(int(crime.wanted_data.army_max_days),int(crime.rules(place).pursuit.days)+floori(notoriety(crime,game,place)/4.0))
static func post_bounties(crime,game) -> void:
	var posted: Array=[]
	for bounty in crime.record.bounties:posted.append_array(bounty.incidents)
	var answered:=settled(crime)
	for post in POSTS:
		var ids: Array=[]
		for report in crime.heard(game,post):
			var id: int=int(report.incident)
			if not report.identified or id in posted or "incident:%d" % id in answered:continue
			var item: Dictionary=crime.record.incidents[id-1]
			if item.action in ["shoot","assault","pursuit"] or (item.action=="wanted" and int(item.shots)>0) or item.attempt=="killed" or not item.get("kills",[]).is_empty() or (item.action in ["robbery","raid"] and value_of(game,item)>=int(crime.wanted_data.robbery_reward_cents)):ids.append(id)
		if ids.is_empty():continue
		var cents: int=clampi(roundi(notoriety(crime,game,post)*float(crime.wanted_data.bounty_step_cents)),int(crime.wanted_data.bounty_min_cents),int(crime.wanted_data.bounty_max_cents))
		crime.record.bounties.append({"id":crime.record.bounties.size()+1,"day":int(game.state.day),"post":post,"cents":cents,"incidents":ids,"cleared_day":-1})
		posted.append_array(ids)
		game.journal.append("Day %d · Word from %s: $%.2f offered for the party's capture." % [game.state.day,game.route.nodes[post].name,cents/100.0])
static func live_bounties(crime,game) -> Array:
	# Hunters need time to bring a posting from its post to this stretch of road.
	return crime.record.bounties.filter(func(item):return int(item.cleared_day)<0 and arrived(crime,game,{"day":item.day,"origin":item.post},int(game.state.miles)))
static func eligible(crime,game) -> Array:
	var known:=charges(crime,game,int(game.state.miles))
	if known.is_empty():return []
	var types: Array=[]
	if int(game.state.miles)<=int(crime.wanted_data.posse_max_mile) and known.any(func(item):return crime.mile(game,item.origin)<=int(crime.wanted_data.posse_max_mile)):types.append("posse")
	if known.any(func(item):return int(item.severity)>=3):types.append("regulators")
	if not live_bounties(crime,game).is_empty():types.append("bounty_hunters")
	return types
static func check_wanted(crime,game) -> bool:
	if game.state.status!="traveling" or not crime.record.active.is_empty() or crime.record.incidents.size()>=10000:return false
	post_bounties(crime,game)
	var types:=eligible(crime,game)
	if types.is_empty():return false
	var day: int=int(game.state.day)
	for item in crime.record.incidents:
		if item.action in ["wanted","pursuit"] and day-int(item.get("ended_day",item.get("sentence",{}).get("day",item.day)))<int(crime.wanted_data.cooldown_days):return false
	var known:=charges(crime,game,int(game.state.miles))
	if crime.rng.randf()>=daily_chance(crime,game,known):return false
	return start(crime,game,types[crime.rng.randi_range(0,types.size()-1)])
static func daily_chance(crime,game,known: Array) -> float:
	if known.is_empty():return 0.0
	var latest:=0
	for item in known:latest=maxi(latest,int(item.day))
	return minf(float(crime.wanted_data.daily_cap),float(crime.wanted_data.daily_base)*notoriety(crime,game,int(game.state.miles)))*pow(0.5,float(maxi(0,int(game.state.day)-latest))/float(crime.wanted_data.decay_days))
static func start(crime,game,type: String) -> bool:
	if type not in eligible(crime,game) or not crime.record.active.is_empty():return false
	var id: int=crime.record.incidents.size()+1
	var place: String=PREFIXES[type]+str(id)
	crime.add_transient(game,place)
	crime.service(place).alarmed=true
	var bounty: int=int(live_bounties(crime,game)[0].id) if type=="bounty_hunters" else 0
	var current: Dictionary={"id":id,"day":int(game.state.day),"place":place,"target":crime.owner_id(place),"action":"wanted","attempt":"caught","resolution":"","stage":"standoff","food":0,"cash_cents":0,"shots":0,"knowledge":{},"bounty":bounty,"ended_day":-1,"joining":[],"kills":[]}
	crime.record.incidents.append(current)
	crime.record.active={"id":id}
	crime.observe(game,current,"attempt",true)
	game.service_return=game.pending.duplicate(true)
	game.pending=menu(crime,game,current)
	game.journal.append("Day %d · %s caught up with the party." % [game.state.day,crime.rules(place).title])
	game.health_events.append(crime.rules(place).title+" have caught up with the party.")
	return true
static func payoff(crime,current: Dictionary) -> int:
	return ceili(int(crime.record.bounties[int(current.bounty)-1].cents)*float(crime.wanted_data.payoff_factor)) if int(current.bounty)>0 else 0
static func menu(crime,game,current: Dictionary) -> Dictionary:
	var options: Array=[]
	var text: String
	if current.stage=="standoff":
		var known:=charges(crime,game,int(game.state.miles))
		var killing: bool=known.any(func(item):return item.severity==4)
		text="They recognize the party from word along the road. "+("A killing is known: conviction means hanging." if killing else "Surrender brings a trial, restitution or punishment; it does not automatically end the journey.")+"\nFleeing takes a day. A failed escape can leave someone wounded. Fighting spends up to three bullets and risks injury or death."
		options=[crime.option("Surrender for trial","surrender"),crime.option(("Ride for it · 1 day, risk of capture" if game.Mounts.mounted(flight_plan(game)) else "Flee · 1 day, risk of capture"),"flee"),crime.option("Fight · up to 3 bullets, 1 day","breakout")]
		if can_ride_off(game):options.append(crime.option(ride_label(game),"ride"))
		if int(current.bounty)>0:options.append(crime.option("Pay off the reward seekers · $%.2f" % (payoff(crime,current)/100.0),"payoff"))
	else:
		text=current.get("sentence",{}).get("text","The encounter ended: "+str(current.resolution)+". Read the journal for wounds and losses.")
		options=[crime.option("Acknowledge the outcome","finish")]
	options.append(crime.option("Encounter in progress","back"))
	return {"id":"crime","crime_menu":true,"service_menu":true,"title":crime.rules(current.place).title,"text":text,"choices":options}
static func can_choose(crime,game,current: Dictionary,command: String) -> bool:
	if current.stage=="report":return command=="finish"
	if current.stage!="standoff":return false
	if command in ["surrender","flee"]:return true
	if command=="ride":return can_ride_off(game)
	if command=="breakout":return game.state.bullets>0
	return command=="payoff" and int(current.bounty)>0 and int(crime.record.bounties[int(current.bounty)-1].cleared_day)<0 and roundi(float(game.state.money)*100)>=payoff(crime,current)
static func end_encounter(crime,game,current: Dictionary,resolution: String) -> void:
	current.ended_day=int(game.state.day)
	crime.result(game,resolution)
static func choose(crime,game,current: Dictionary,command: String,left: Array=[]) -> bool:
	if not can_choose(crime,game,current,command):return false
	if command=="finish":
		current.stage="done"
		crime.record.active={}
		game.pending=game.service_return.duplicate(true)
		game.service_return={}
		game.refresh_stop_offers()
		return true
	if command=="surrender":trial(crime,game,current,true)
	elif command=="payoff":
		var cents:=payoff(crime,current)
		game._apply({"money":-cents/100.0})
		crime.record.bounties[int(current.bounty)-1].cleared_day=int(game.state.day)
		game.journal.append("Day %d · Paid reward seekers $%.2f. The posting is settled; word of past crimes remains." % [game.state.day,cents/100.0])
		end_encounter(crime,game,current,"paid")
	elif command in ["flee","ride"]:
		if command=="ride":
			if not cut_loose(crime,game,left):return false
			left_at_wagon(crime,game,true)
		if not crime.advance(game):return true
		var scene: Dictionary=crime.rules(current.place)
		var chance: float=flight_chance(crime,game,scene)
		ride_hard(game)
		if crime.rng.randf()<chance:end_encounter(crime,game,current,"escaped")
		else:
			crime.wound(game,int(scene.injury_damage),1)
			if game.state.status=="traveling":trial(crime,game,current,false)
			else:end_encounter(crime,game,current,"party_lost")
	elif command=="breakout":
		var scene: Dictionary=crime.rules(current.place)
		var shots: int=mini(int(game.state.bullets),int(scene.breakout_shots))
		current.joining=game.party_health.members.filter(func(member):return game.party_health.is_active(member) and game.characters.willing(int(member.id),"defend")).map(func(member):return int(member.id))
		game._apply({"bullets":-shots})
		current.shots+=shots
		for shot in range(shots):
			var targets: Array=crime.living_staff(current.place)
			if targets.is_empty() or crime.rng.randf()>=float(scene.shot_hit):continue
			var actor: Dictionary=crime.record.actors[targets[0]]
			actor.health=0 if int(actor.health)<=40 or crime.rng.randf()<float(scene.shot_fatal) else int(actor.health)-40
			if int(actor.health)==0:
				current.kills.append(actor.uid)
				current.knowledge.erase(actor.uid)
		if not crime.advance(game):return true
		crime.wound(game,int(scene.injury_damage),1 if crime.rng.randf()<0.5 else 2)
		if game.state.status!="traveling":end_encounter(crime,game,current,"party_lost")
		elif crime.living_staff(current.place).is_empty() or crime.rng.randf()<clampf(float(scene.breakout)+crime.experience(game)*0.04-(0.15 if crime.party_condition(game)=="poor" else 0),0.05,0.95):
			crime.observe(game,current,"escape",true)
			end_encounter(crime,game,current,"escaped")
		else:trial(crime,game,current,false)
	game.Remains.sync(game)
	if game.state.status=="traveling":game.pending=menu(crime,game,current)
	return true
## A later army detachment can be fled, unlike soldiers already blocking a fort gate.
static func flee_pursuit(crime,game,current: Dictionary,ride: bool=false,left: Array=[]) -> bool:
	if ride:
		if not cut_loose(crime,game,left):return false
		left_at_wagon(crime,game,true)
	if not crime.advance(game):return true
	var scene: Dictionary=crime.rules(current.place)
	var chance: float=flight_chance(crime,game,scene)
	ride_hard(game)
	if crime.rng.randf()<chance:
		crime.observe(game,current,"escape",true)
		crime.result(game,"escaped")
	else:
		crime.wound(game,int(scene.injury_damage),1)
		if game.state.status=="traveling":trial(crime,game,current,false)
		else:crime.result(game,"party_lost")
	game.Remains.sync(game)
	if game.state.status=="traveling":game.pending=crime.menu(game)
	return true
## Captures at an original crime scene and later pursuits use the same sentencing rules.
static func trial(crime,game,current: Dictionary,surrendered: bool) -> void:
	var known:=charges(crime,game,int(game.state.miles),current)
	# A detachment carries its own post's reports, even ahead of the general news.
	# Merely being pursued is not an additional assault.
	if current.action=="pursuit":
		var answered:=settled(crime)
		for report in crime.record.reports:
			if report.origin==current.place and "incident:%d" % int(report.incident) not in answered:
				merge_array(known,incident_evidence(crime,game,crime.record.incidents[int(report.incident)-1],true))
	# A violent fight just witnessed is evidence even if its report has not left yet.
	if current.action=="wanted" and int(current.shots)>0:merge_array(known,incident_evidence(crime,game,current,true))
	var severity:=1
	var value:=0
	var helpers: Array=[]
	for item in known:
		severity=maxi(severity,int(item.severity))
		value+=int(item.value)
		for id in item.joining:
			if int(id)>0 and int(id) not in helpers:helpers.append(int(id))
	var kind: String=SENTENCES[severity-1]
	var paid:=0
	var goods: Dictionary={}
	var banished: Array=[]
	var seizure: String=""
	if severity<4:
		var acting_leader: int=int(game.party_health.members.filter(func(member):return game.party_health.is_active(member))[0].id)
		var due: int=value*(2 if severity==1 else 1)
		paid=mini(due,roundi(float(game.state.money)*100))
		game._apply({"money":-paid/100.0})
		var remaining: int=due-paid
		# Confiscate actual goods at opening outfit prices. Never create money or negative stock.
		for good in game.outfitter.goods:
			var id: String="bullets" if good.id=="bullet_boxes" else str(good.id)
			if id=="oxen" or remaining<=0:continue
			var unit: int=maxi(1,float(good.price_cents)/(20.0 if id=="bullets" else 1.0))
			var amount: int=mini(int(game.state.get(id,0)),ceili(remaining/float(unit)))
			if amount<=0:continue
			goods[id]=amount
			game._apply({id:-amount})
			remaining=maxi(0,remaining-amount*unit)
		if severity>=2 and not surrendered:
			var leaders: Array=game.party_health.members.filter(func(member):return game.party_health.is_active(member))
			var leader: Dictionary=leaders[0]
			var damage: int=game.characters.catalog.health_delta(game.characters.profiles[int(leader.id)],-int(crime.wanted_data.flogging_damage),"frontier punishment",game.party_health.conditions)
			# Punishment is nonfatal even when Frail amplifies the wound. Future illness still matters.
			leader.health=maxi(1,int(leader.health)+damage)
			game.party_health.begin_condition(int(leader.id),"wound",int(game.state.day),1)
		if severity>=2:
			for id in helpers:
				if int(id)!=acting_leader and game.party_health.is_active(game.party_health.members[id]) and (severity>=3 or crime.rng.randf()<float(crime.wanted_data.helper_banish_chance)):banished.append(id)
		if severity==3 and crime.rng.randf()<float(crime.wanted_data.seizure_chance):
			if int(game.state.oxen)>0:
				game._apply({"oxen":-int(game.state.oxen)})
				seizure="oxen"
			elif game.state.vehicle!="foot":
				game.state.vehicle="foot"
				# Seized wagons cannot be recovered; goods must now be carried or dropped.
				game.wagon_cache={}
				seizure="wagon"
		for profile in game.characters.profiles.slice(1):
			if game.party_health.is_active(game.party_health.members[int(profile.id)]):game.characters.remember(game,profile,"action_trial",-3,"Frontier justice caught up with the party.")
	var text: String="Hanged for a known killing. The journey is over." if severity==4 else "Sentence: %s. Taken: $%.2f%s.%s%s%s" % [kind,paid/100.0,(" and "+", ".join(goods.keys().map(func(id):return "%d %s" % [goods[id],id]))) if not goods.is_empty() else ""," You surrendered; no flogging." if surrendered and severity>=2 else (" The leader was flogged and wounded." if severity>=2 else ""),(" Banished: "+", ".join(banished.map(func(id):return game.party_health.members[id].name))+".") if not banished.is_empty() else "",(" Seized: "+seizure+".") if not seizure.is_empty() else ""]
	current["sentence"]={"kind":kind,"day":int(game.state.day),"surrendered":surrendered,"charges":known.map(func(item):return item.id),"cents":paid,"goods":goods,"banished":banished,"seizure":seizure,"text":text}
	current.resolution="tried"
	current.stage="report"
	if current.action=="wanted":current.ended_day=int(game.state.day)
	for bounty in crime.record.bounties:
		if int(bounty.cleared_day)<0 and bounty.incidents.all(func(id):return "incident:%d" % int(id) in current.sentence.charges):bounty.cleared_day=int(game.state.day)
	# Write the sentence before flight so validators can account for each departure.
	game.flee(banished,"when banished at a frontier trial")
	game._collect_health_events()
	game.state.health=game.party_health.average_health()
	game.state.party_size=game.party_health.living_count()
	game.journal.append("Day %d · %s" % [game.state.day,text])
	if severity==4:
		current.stage="done"
		crime.record.active={}
		game.state.status="lost"
		game.state.loss_reason="The party's leader was hanged for murder."
		game.pending={}
		game.service_return={}
static func merge_array(items: Array,item: Dictionary) -> void:
	for old in items:
		if old.id==item.id:return
	items.append(item)
static func valid_bounties(crime,r: Dictionary,game) -> bool:
	if not r.get("bounties") is Array or r.bounties.size()>10000:return false
	if r.bounties.is_empty():return true
	var shadow=crime.get_script().new()
	shadow.record=r
	shadow.miles=crime.miles
	var posted: Array=[]
	for index in range(r.bounties.size()):
		var b: Variant=r.bounties[index]
		if not b is Dictionary or b.size()!=6 or b.get("id")!=index+1 or not whole(b.get("day"),0,int(game.state.day)) or b.get("post") not in POSTS or not whole(b.get("cents"),int(crime.wanted_data.bounty_min_cents),int(crime.wanted_data.bounty_max_cents)) or not (b.get("cleared_day")==-1 or whole(b.get("cleared_day"),int(b.day),int(game.state.day))) or not b.get("incidents") is Array or b.incidents.is_empty():return false
		var expected_cents: int=clampi(roundi(notoriety(shadow,game,b.post,int(b.day))*float(crime.wanted_data.bounty_step_cents)),int(crime.wanted_data.bounty_min_cents),int(crime.wanted_data.bounty_max_cents))
		if int(b.cents)!=expected_cents:return false
		for id in b.incidents:
			if not whole(id,1,r.incidents.size()) or id in posted:return false
			posted.append(id)
			var item: Dictionary=r.incidents[int(id)-1]
			if not (item.action in ["shoot","assault","pursuit"] or (item.action=="wanted" and int(item.shots)>0) or item.attempt=="killed" or not item.get("kills",[]).is_empty() or (item.action in ["robbery","raid"] and value_of(game,item)>=int(crime.wanted_data.robbery_reward_cents))):return false
			if not r.reports.any(func(report):return report.incident==id and report.identified and shadow.arrival(game,report,b.post)<=int(b.day)):return false
		if int(b.cleared_day)>=0 and not r.incidents.any(func(item):return (item.action=="wanted" and int(item.get("bounty",0))==int(b.id) and item.resolution=="paid" and int(item.ended_day)==int(b.cleared_day)) or (item.has("sentence") and int(item.sentence.day)==int(b.cleared_day) and b.incidents.all(func(id):return "incident:%d" % int(id) in item.sentence.charges))):return false
	return true
static func valid_extras(crime,r: Dictionary,current: Dictionary,game) -> bool:
	if current.has("joining"):
		if not current.joining is Array:return false
		for id in current.joining:
			if not whole(id,0,game.party_health.members.size()-1) or current.joining.count(id)!=1:return false
	if current.has("kills"):
		if not current.kills is Array:return false
		for uid in current.kills:
			if uid not in crime.staff_ids(current.place) or current.kills.count(uid)!=1 or r.actors[uid].health!=0:return false
	if not current.has("sentence"):return current.resolution!="tried"
	var s: Variant=current.sentence
	if not s is Dictionary or s.size()!=9 or s.get("kind") not in SENTENCES or current.resolution!="tried" or current.stage not in ["report","done"] or not whole(s.get("day"),int(current.day),int(game.state.day)) or not s.get("surrendered") is bool or not s.get("text") is String or not whole(s.get("cents"),0,100000000) or not s.get("charges") is Array or not s.get("goods") is Dictionary or not s.get("banished") is Array or s.get("seizure") not in ["","oxen","wagon"]:return false
	var severity:=1
	for id in s.charges:
		if not id is String or id.count(":")!=1 or not id.get_slice(":",1).is_valid_int() or not {"incident":r.incidents,"attack":r.attacks,"remains":r.remains}.has(id.get_slice(":",0)):return false
		var entries: Array={"incident":r.incidents,"attack":r.attacks,"remains":r.remains}[id.get_slice(":",0)]
		if not whole(int(id.get_slice(":",1)),1,entries.size()) or s.charges.count(id)!=1 or int(entries[int(id.get_slice(":",1))-1].day)>int(s.day):return false
		var entry: Dictionary=entries[int(id.get_slice(":",1))-1]
		var level: int
		match id.get_slice(":",0):
			"incident":level=int(incident_evidence(crime,game,entry,true).severity)
			"attack":level=4 if entry.attempt=="killed" else 3
			_:level=2
		severity=maxi(severity,level)
	if s.kind!=SENTENCES[severity-1]:return false
	if s.kind=="hanged" and (game.state.status!="lost" or game.state.loss_reason!="The party's leader was hanged for murder."):return false
	if s.kind=="restitution" and (not s.banished.is_empty() or s.seizure!=""):return false
	for id in s.goods:
		if id not in ["food","bullets","clothing","wheels","axles","tongues","medicine","salt"] or not whole(s.goods[id],1,100000):return false
	for id in s.banished:
		if not whole(id,1,game.party_health.members.size()-1) or s.banished.count(id)!=1:return false
		var member: Dictionary=game.party_health.members[int(id)]
		if not member.get("fled",false) or int(member.departure_day)!=int(s.day):return false
	return true
static func valid_incident(crime,r: Dictionary,current: Dictionary,game,index: int,previous_day: int) -> bool:
	if not current.get("joining") is Array or not current.get("kills") is Array:return false
	if current.size()!=16+int(current.has("sentence")) or not is_wanted(current.place) or current.place.get_slice(":",1)!=str(index+1) or current.attempt!="caught" or current.stage not in ["standoff","report","done"] or current.resolution not in ["","escaped","paid","tried","party_lost"] or int(current.day)<previous_day:return false
	if not whole(current.get("bounty"),0,r.bounties.size()) or not whole(current.get("ended_day"),-1,int(game.state.day)) or current.target!=crime.owner_id(current.place):return false
	if (current.stage=="standoff")!=(current.resolution=="") or (current.stage=="standoff")!=(int(current.ended_day)==-1):return false
	if int(current.ended_day)>=0 and int(current.ended_day)<int(current.day):return false
	if current.place.begins_with("wanted_hunters:")!=(int(current.bounty)>0) or (current.resolution=="paid" and int(current.bounty)==0):return false
	for key in ["food","cash_cents"]:
		if current.get(key)!=0:return false
	if not whole(current.get("shots"),0,int(crime.rules(current.place).breakout_shots)) or not current.get("knowledge") is Dictionary:return false
	if int(current.bounty)>0 and not r.bounties[int(current.bounty)-1] is Dictionary:return false
	if current.kills.size()>int(current.shots) or (current.resolution=="paid" and r.bounties[int(current.bounty)-1].cleared_day!=current.ended_day):return false
	if current.stage!="done" and r.active.get("id",0)!=current.id:return false
	for uid in crime.staff_ids(current.place):
		if r.actors[uid].health>0 and "attempt" not in current.knowledge.get(uid,[]):return false
	for uid in current.knowledge:
		if not r.people.has(uid) and uid not in crime.staff_ids(current.place):return false
		if not current.knowledge[uid] is Array or current.knowledge[uid].is_empty():return false
		for fact in current.knowledge[uid]:
			if fact not in ["attempt","escape"] or current.knowledge[uid].count(fact)!=1:return false
	return true
