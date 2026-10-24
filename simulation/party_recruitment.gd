extends RefCounted
## Five occupied/vacant positions; immutable historical traveler ids are never recycled.
var record: Dictionary={"slots":[0,1,2,3,4],"searches":{}}
var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/recruitment.json"))
const COMMANDS=["search","accept","decline","dismiss","back"]
func snapshot() -> Dictionary:return record.duplicate(true)
func restore(value: Dictionary) -> void:record=value.duplicate(true)
func slots(game) -> Array:
	return record.slots.map(func(id):return int(id) if int(id)>=0 and int(id)<game.party_health.members.size() and (game.party_health.is_active(game.party_health.members[int(id)]) or game.party_health.members[int(id)].get("guarding",false) or game.party_health.members[int(id)].get("away",false)) else -1)
func site(game) -> String:
	if game.pending.get("recruit_menu",false):return game.pending.get("recruit_site","")
	if not game.can_service():return ""
	if game.pending.has("landmark"):
		var node: Dictionary=game.route.nodes[game.state.landmark]
		if (node.kind in ["town","fort"] or node.get("trade_bulk",false)) and game.crime.staffed(game,str(node.id)):return "post:"+str(node.id)
	var market: Dictionary=game.context.market(game)
	if market.available and not market.post:return str(market.key)
	return game.crime.camp(game)
func candidate(game) -> Dictionary:
	return record.searches.get(site(game),{}).get("candidate",{})
func open(game) -> bool:
	if not game.can_service():return false
	var place:=site(game)
	game.service_return=game.pending.duplicate(true)
	game.pending={"recruit_menu":true,"recruit_site":place}
	game.pending=menu(game)
	return true
func option(text: String, command: String) -> Dictionary:return {"label":text,"recruit_command":command,"effects":{},"result":""}
func blocked(game,place: String) -> bool:
	var key: String=place.trim_prefix("post:") if place.begins_with("post:") else place
	return not key.is_empty() and (game.crime.closed(key) or game.crime.refuses(game,key))

func menu(game) -> Dictionary:
	var place:=site(game)
	var visit: Dictionary=record.searches.get(place,{})
	var options: Array=[]
	var text: String="Look for someone willing to join at a populated stop or nearby trading or emigrant camp. Searching costs one day and meals. One search per place; returning to this panel does not reroll a candidate."
	if not slots(game).has(-1):text="Your five-person party is full. Departed and dead travelers remain in the history, leaving vacancies when they go."
	elif game.party_health.members.size()>=game.MAX_TRAVELERS:text="This journey's traveler record is full; no further recruits can be added."
	elif place.is_empty():text="No settled stop or trading camp is nearby. Look again at a town, staffed fort or passing-trader/emigrant camp."
	elif blocked(game,place):text="People here will not join after the incidents involving your party."
	elif visit.is_empty() and record.searches.size()>=128:text="No further contacts can be recorded on this journey."
	elif visit.is_empty():options.append(option("Look for a companion · 1 day and meals","search"))
	elif visit.get("hired_id",-1)>=0:text="The traveler found here already joined your party."
	elif visit.get("declined",false):text="You declined this traveler. They have made other plans."
	elif visit.get("candidate",{}).is_empty():text="You found nobody looking to join here. This place has been searched."
	else:
		var person: Dictionary=visit.candidate
		var profile: Dictionary=person.profile
		text="%s is considering your party.\nHeritage / upbringing: %s\nTemperament / values: %s\nBackground: %s\nSpecials: %s\nFlaw: %s\nStarting trust: %d. Health: good.\n" % [person.name,profile.appearance.heritage,", ".join(profile.traits),profile.skill,", ".join(profile.specials) if not profile.specials.is_empty() else "None",", ".join(profile.get("flaws",[])) if not profile.get("flaws",[]).is_empty() else "None",profile.trust]
		text+=("Requires $%.2f every %d days, plus party provisions. First wages fall due after joining." % [person.terms.wage_cents/100.0,person.terms.interval_days]) if not person.terms.is_empty() else "No wage contract; they expect food, safety and fair treatment."
		text+=" They bring one clothing set and personal gear; no free food or ammunition. Inviting them uses no additional day."
		options.append(option("Invite %s to join" % person.name,"accept"))
		options.append(option("Decline this traveler","decline"))
	options.append(option("Back to the trail","back"))
	return {"id":"recruitment","recruit_menu":true,"recruit_site":place,"service_menu":true,"title":"Find a companion","text":text,"choices":options}
func can_choose(game,index: int) -> bool:
	if index<0 or index>=game.pending.get("choices",[]).size():return false
	var command: String=game.pending.choices[index].get("recruit_command","")
	if command=="back":return true
	if game.pending.get("dismiss_menu",false):return command=="dismiss" and eligible_dismiss(game,int(game.pending.get("dismiss_target",-1)),false)
	if not game.pending.get("recruit_menu",false) or not slots(game).has(-1) or game.party_health.members.size()>=game.MAX_TRAVELERS or blocked(game,site(game)):return false
	var visit: Dictionary=record.searches.get(site(game),{})
	return (command=="search" and not site(game).is_empty() and visit.is_empty() and record.searches.size()<128) or (command in ["accept","decline"] and not visit.get("candidate",{}).is_empty() and not visit.get("declined",false) and int(visit.get("hired_id",-1))<0)
func choose(game,index: int) -> bool:
	if not can_choose(game,index):return false
	var command: String=game.pending.choices[index].recruit_command
	if command=="back":
		game.pending=game.service_return.duplicate(true)
		game.service_return={}
		return true
	if command=="dismiss":return dismiss(game,int(game.pending.dismiss_target))
	var place:=site(game)
	if command=="search":
		game._apply({"days":1})
		game._update_river_stage()
		if game.state.status!="traveling":return true
		var random:=RandomNumberGenerator.new()
		random.seed=int(game.state.seed) ^ int(place.hash()) ^ 0x52454352
		var person: Dictionary={}
		if random.randf()<float(rules.find_chance):person=game.characters.generate_candidate(int(game.state.seed),int(place.hash())%1000000,"stranger")
		record.searches[place]={"day":int(game.state.day),"candidate":person,"declined":false,"hired_id":-1}
		game.journal.append("Day %d · Looked for companions: %s." % [game.state.day,"met "+person.name if not person.is_empty() else "nobody seeking a party"])
	elif command=="decline":
		record.searches[place].declined=true
		game.journal.append("Day %d · Declined %s's offer to join." % [game.state.day,candidate(game).name])
	elif command=="accept":hire(game,place)
	if game.state.status=="traveling" and game.pending.get("recruit_menu",false):game.pending=menu(game)
	return true
func hire(game,place: String) -> void:
	var person: Dictionary=record.searches[place].candidate
	var id: int=game.party_health.members.size()
	var profile: Dictionary=person.profile.duplicate(true)
	profile.id=id
	game.characters.profiles.append(profile)
	var name: String=person.name if person.name.length()<=14 else person.name.get_slice(" ",0)+" "+person.name.get_slice(" ",1).left(1)+"."
	game.party_health.members.append({"id":id,"name":name,"health":int(rules.starting_health),"alive":true,"conditions":[],"history":["Day %d · Joined the party." % game.state.day],"death_day":-1,"cause":"","joined_day":int(game.state.day)})
	game.state.party.append(name)
	record.slots[slots(game).find(-1)]=id
	record.searches[place].hired_id=id
	game.state.clothing+=int(rules.clothing)
	game.state["recruited_gear_lb"]=int(game.state.get("recruited_gear_lb",0))+int(rules.personal_gear_lb)
	if game.state.has("household_gear_lb"):game.state.household_gear_lb+=int(rules.personal_gear_lb)
	game.state.party_size=game.party_health.living_count()
	game.state.health=game.party_health.average_health()
	game.crime.bind_party(game)
	game.social.add_member(game,id)
	if not person.terms.is_empty():game.characters.start_contract(game,id,int(person.terms.wage_cents),int(person.terms.interval_days))
	game.journal.append("Day %d · %s joined the party as traveler %d." % [game.state.day,name,id+1])
	game.health_events.append(name+" joined your party.")
func eligible_dismiss(game,target: int, service: bool=true) -> bool:
	return (game.can_service() if service else game.state.status=="traveling") and target>0 and target<game.party_health.members.size() and game.party_health.is_active(game.party_health.members[target])
func open_dismiss(game,target: int) -> bool:
	if not eligible_dismiss(game,target):return false
	game.service_return=game.pending.duplicate(true)
	game.pending=dismiss_menu(game,target)
	return true
func dismiss_menu(game,target: int) -> Dictionary:
	var group: Array=game.social.departure_group(game,[target])
	var plan: Array=game.plan_for(group)
	var lines: Array[String]=["Ask %s to leave camp. This is a nonviolent dismissal, not an attack. No day or ammunition is used. Close companions may lose trust in you; partners leave together. Pay any wages owed before confirming; unpaid debt stays recorded." % game.party_health.members[target].name]
	for item in plan:lines.append("%s leaves with %d food units, %d clothing set(s), %d lb personal gear%s." % [game.party_health.members[int(item.id)].name,item.food,item.clothing,item.gear_lb," · accompanying their partner" if int(item.id)!=target else ""])
	lines.append("Dead or departed travelers keep their histories. Vacancies can be filled by looking for companions where people are gathered.")
	return {"id":"dismiss","dismiss_menu":true,"dismiss_target":target,"service_menu":true,"title":"Ask a companion to leave","text":"\n".join(lines),"choices":[option("Confirm dismissal","dismiss"),option("Keep them in camp","back")]}
func dismiss(game,target: int) -> bool:
	var group: Array=game.social.departure_group(game,[target])
	var names: String=", ".join(group.map(func(id):return game.party_health.members[int(id)].name))
	game.pending=game.service_return.duplicate(true)
	game.service_return={}
	for profile in game.characters.profiles:
		if int(profile.id)==0 or int(profile.id) in group or not game.party_health.is_active(game.party_health.members[int(profile.id)]):continue
		var close: bool=group.any(func(id):return game.crime.bond(int(profile.id),int(id)) in game.crime.CLOSE)
		game.characters.remember(game,profile,"dismissal_%d" % target,int(rules.dismiss_close_trust if close else rules.dismiss_other_trust),"You dismissed "+names+" from camp.")
	for id in group:game.party_health.members[int(id)]["dismissed"]=true
	game._depart(game.plan_for(group),"")
	game.journal.append("Day %d · Dismissed %s from camp." % [game.state.day,names])
	return true
func valid_open_menu(game) -> bool:
	if game.pending.get("dismiss_menu",false):return game.pending.id=="dismiss" and game.crime.whole(game.pending.get("dismiss_target"),1,game.party_health.members.size()-1) and eligible_dismiss(game,int(game.pending.dismiss_target),false)
	if game.pending.get("recruit_menu",false):return game.pending.id=="recruitment" and game.pending.get("recruit_site","") is String and (game.pending.recruit_site.is_empty() or valid_site(game,game.pending.recruit_site))
	return true
func valid_site(game,key: String) -> bool:
	if key.begins_with("post:"):return game.route.nodes.has(key.trim_prefix("post:")) and (game.route.nodes[key.trim_prefix("post:")].kind in ["town","fort"] or game.route.nodes[key.trim_prefix("post:")].get("trade_bulk",false))
	return (key.begins_with("passing:") or key.begins_with("emigrants:")) and key.length()<=64
func valid(value: Variant,game) -> bool:
	if not value is Dictionary or value.size()!=2 or not value.get("slots") is Array or value.slots.size()!=5 or not value.get("searches") is Dictionary or value.searches.size()>128:return false
	var seen: Array=[]
	for id in value.slots:
		if not game.crime.whole(id,-1,game.party_health.members.size()-1) or (int(id)>=0 and int(id) in seen):return false
		seen.append(int(id))
	for member in game.party_health.members:
		if (game.party_health.is_active(member) or member.get("guarding",false) or member.get("away",false)) and int(member.id) not in seen:return false
	var hired: Array=[]
	for key in value.searches:
		var visit: Variant=value.searches[key]
		if not key is String or not valid_site(game,key) or not visit is Dictionary or visit.size()!=4 or not game.crime.whole(visit.get("day"),0,int(game.state.day)) or not visit.get("candidate") is Dictionary or not visit.get("declined") is bool or not game.crime.whole(visit.get("hired_id"),-1,game.party_health.members.size()-1):return false
		if int(visit.hired_id)>=0:
			if int(visit.hired_id)<5 or int(visit.hired_id) in hired or visit.declined:return false
			hired.append(int(visit.hired_id))
		if visit.candidate.is_empty():
			if visit.declined or visit.hired_id>=0:return false
			continue
		var person: Dictionary=visit.candidate
		if person.size()!=4 or not person.get("candidate_id") is String or not person.get("name") is String or person.name.is_empty() or person.name.length()>64 or not person.get("profile") is Dictionary or not person.profile.has("appearance") or not person.get("terms") is Dictionary:return false
		var profiles: Array=game.characters.profiles.duplicate(true)
		var profile: Dictionary=person.profile.duplicate(true)
		profile.id=profiles.size()
		profiles.append(profile)
		if not game.characters.valid(profiles,profiles.size(),int(game.state.day)):return false
		if "Mercenary" in profile.specials:
			if person.terms.size()!=2 or not game.characters.acceptable_terms(person.terms.get("wage_cents"),person.terms.get("interval_days"),profile):return false
		elif not person.terms.is_empty():return false
	if hired.size()!=game.party_health.members.size()-5:return false
	if not game.crime.whole(game.state.get("recruited_gear_lb",0),0,game.MAX_TRAVELERS*int(rules.personal_gear_lb)) or game.state.get("recruited_gear_lb",0)!=hired.size()*int(rules.personal_gear_lb):return false
	return true
