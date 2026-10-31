extends RefCounted
## Custody between capture and sentence. Who holds the accused decides where and how they are heard:
## Jackson County (Missouri), the army at Fort Kearny, a Native household's council for wrongs done to that household,
## or an emigrant jury anywhere else.
## Authored game rules from docs/FRONTIER_DETENTION_RESEARCH.md, not a historical sentencing table.
const AUTHORITIES=["county","army","company","council"]
const COMMANDS=["wait","bail","vouch"]
const VERDICTS=["convicted","discharged","bailed"]
## Sentence kind by worst severity (theft, robbery, assault, killing) for each authority.
const KINDS={"company":["restitution","robbery","assault","hanged"],"county":["fine","penitentiary","penitentiary","hanged"],"army":["restitution","sent_east","sent_east","sent_east"],"council":["returned","driven_out","driven_out","price"]}
## A council's answer to a killing is the family's: "price" above, or "life".
const COUNCIL_KILLING=["price","life"]
const TITLES={"county":"Jackson County jail","army":"Under guard at Fort Kearny","company":"Held by an emigrant company","council":"Held by the household's kin"}
const LOSS={"penitentiary":"The party's leader was sent to the Missouri penitentiary.","sent_east":"The party's leader was sent east under military escort to stand trial.","life":"The family of the dead took the party leader's life for the killing."}
static func number(value: Variant) -> bool:return (value is int or value is float) and is_finite(value)
static func whole(value: Variant,low: int,high: int) -> bool:return number(value) and value==floor(value) and value>=low and value<=high
static func valid_rules(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=12 or not value.get("note") is String:return false
	var council: Variant=value.get("council")
	if not council is Dictionary or council.size()!=9 or not council.get("note") is String:return false
	for key in ["theft_factor","violent_factor"]:
		if not whole(council.get(key),1,5):return false
	for key in ["theft_min_cents","violent_min_cents","price_cents"]:
		if not whole(council.get(key),0,100000):return false
	for key in ["life_chance","unpaid_life_step","surrender_step"]:
		if not number(council.get(key)) or council[key]<0 or council[key]>1:return false
	for group in ["hearing_days","conviction"]:
		if not value.get(group) is Dictionary or value[group].size()!=AUTHORITIES.size():return false
		for authority in AUTHORITIES:
			if group=="hearing_days" and not whole(value[group].get(authority),1,5):return false
			if group=="conviction" and (not number(value[group].get(authority)) or value[group][authority]<0.05 or value[group][authority]>0.95):return false
	for key in ["unidentified_factor","vouch_bonus","abandon_daily"]:
		if not number(value.get(key)) or value[key]<0 or value[key]>1:return false
	if not value.get("bail_cents") is Array or value.bail_cents.size()!=3 or not value.bail_cents.all(func(cents):return whole(cents,100,100000)):return false
	return whole(value.get("fine_min_cents"),0,100000) and whole(value.get("bail_value_factor"),1,5) and whole(value.get("jail_day_cents"),1,10000) and whole(value.get("max_jail_days"),1,120)
static func rules(crime) -> Dictionary:return crime.detention_data
## Soldiers hold their own post's offenders; Missouri holds what happened in Missouri; everyone else answers to emigrants.
static func authority(crime,game,current: Dictionary) -> String:
	# A household's kin bring those who wronged it before their own council.
	if crime.household(current.place):return "council"
	if current.action=="pursuit" or crime.rules(current.place).kind=="fort":return "army"
	if current.place.begins_with("wanted_posse:"):return "county"
	if current.action!="wanted" and not crime.transient(current.place) and crime.mile(game,current.place)<=int(crime.wanted_data.posse_max_mile):return "county"
	return "company"
static func acting_leader(game) -> int:
	var active: Array=game.party_health.members.filter(func(member):return game.party_health.is_active(member))
	return int(active[0].id) if not active.is_empty() else -1
## The acting leader answers for the party; companions are held only for acts they took part in.
static func accused(crime,game,known: Array) -> Array:
	var ids: Array=[acting_leader(game)]
	for item in known:
		for id in item.joining:
			if int(id)>0 and int(id) not in ids and game.party_health.is_active(game.party_health.members[int(id)]):ids.append(int(id))
	return ids
static func severity(known: Array) -> int:
	var worst:=1
	for item in known:worst=maxi(worst,int(item.severity))
	return worst
static func value(known: Array) -> int:
	var total:=0
	for item in known:total+=int(item.value)
	return total
static func arrest(crime,game,current: Dictionary,surrendered: bool) -> void:
	var known: Array=crime.Wanted.trial_charges(crime,game,current)
	var who: String=authority(crime,game,current)
	current["custody"]={"authority":who,"day":int(game.state.day),"hearing_day":int(game.state.day)+int(rules(crime).hearing_days[who]),"surrendered":surrendered,"accused":accused(crime,game,known),"vouched":-1,"abandoned":[]}
	current.custody["arms"]=take_arms(game,current.custody.accused.size())
	current.stage="custody"
	var names: String=", ".join(current.custody.accused.map(func(id):return game.party_health.members[int(id)].name))
	game.journal.append("Day %d · %s %s. Held: %s. Hearing on day %d.%s" % [game.state.day,"Surrendered to" if surrendered else "Taken by",{"county":"the Jackson County sheriff","army":"the soldiers","company":"an emigrant company","council":"kin of the household"}[who],names,current.custody.hearing_day,(" Their arms are held: %s." % arms_text(current.custody.arms)) if not current.custody.arms.is_empty() else ""])
## The accused give up the arms they carry, the first in the party's loadout as the leader is held first.
static func take_arms(game,held: int) -> Dictionary:
	var arms: Dictionary={}
	for kit in preload("res://simulation/armory.gd").loadout(game.state,held):
		for key in [kit.weapon,kit.blade]:
			if key!="":arms[key]=int(arms.get(key,0))+1
	for key in arms:game.state[key]=int(game.state[key])-int(arms[key])
	return arms
## Arms held in custody come back to whoever walks free.
static func return_arms(game,current: Dictionary) -> void:
	var arms: Dictionary=current.get("custody",{}).get("arms",{})
	for key in arms:game.state[key]=int(game.state.get(key,0))+int(arms[key])
	if not arms.is_empty():game.journal.append("Day %d · The party's arms were handed back: %s." % [game.state.day,arms_text(arms)])
static func arms_text(arms: Dictionary) -> String:return preload("res://simulation/armory.gd").describe(arms)
static func charges_text(known: Array) -> String:
	return ["theft","robbery","assault","a killing"][severity(known)-1]
static func bail_cents(crime,known: Array) -> int:
	var level:=severity(known)
	if level>=4:return 0
	return maxi(int(rules(crime).bail_cents[level-1]),value(known)*int(rules(crime).bail_value_factor))
static func can_bail(crime,game,current: Dictionary) -> bool:
	if current.custody.authority!="county":return false
	var cents:=bail_cents(crime,crime.Wanted.trial_charges(crime,game,current))
	return cents>0 and roundi(float(game.state.money)*100)>=cents
## A companion who was not part of it and does not object to such acts can speak for the accused, once.
static func voucher(game,current: Dictionary,known: Array) -> int:
	if int(current.custody.vouched)>=0:return -1
	var act: String="murder" if severity(known)>=3 else "robbery"
	for member in game.party_health.members:
		var id: int=int(member.id)
		if id==0 or id in current.custody.accused or not game.party_health.is_active(member):continue
		if game.characters.willing(id,act) and game.characters.response(id,act) not in ["reluctant","disapproved"]:return id
	return -1
static func conviction_chance(crime,current: Dictionary,known: Array) -> float:
	var chance: float=float(rules(crime).conviction[current.custody.authority])
	if not known.any(func(item):return item.identified):chance*=float(rules(crime).unidentified_factor)
	if int(current.custody.vouched)>=0:chance-=float(rules(crime).vouch_bonus)
	return clampf(chance,0.0,1.0)
static func menu(crime,game,current: Dictionary) -> Dictionary:
	var known: Array=crime.Wanted.trial_charges(crime,game,current)
	var who: String=current.custody.authority
	var days: int=maxi(0,int(current.custody.hearing_day)-int(game.state.day))
	var names: String=", ".join(current.custody.accused.map(func(id):return game.party_health.members[int(id)].name))
	var text: String="Held: %s. Charge: %s. " % [names,charges_text(known)]
	text+={"county":"The county keeps them in the brick jail at Independence until court sits. Theft brings a fine, worked off in jail if you cannot pay. Robbery or assault means the state penitentiary; a killing can mean hanging.",
		"army":"The soldiers keep them under guard. Petty theft is paid back; anything violent and they are sent east under escort to a civil court.",
		"company":"An emigrant company holds them for a hearing by its own jury. It can order restitution, a whipping, banishment or, for a killing, hanging.",
		"council":council_terms(crime,game,current,known)}[who]
	text+="\nHearing in %d day(s). The rest of the party camps nearby and eats as usual. Thin evidence can mean release; it is never certain." % days
	if known.all(func(item):return not item.identified):text+=" Nobody has named the party for certain."
	if 0 in current.custody.accused and game.party_health.living_count()>current.custody.accused.size():text+="\nWhile you sit in jail, a companion with little faith in you may give up and leave."
	var options: Array=[crime.option("Wait for the hearing · %d day(s)" % days if days>0 else "Face the hearing","wait")]
	var helper:=voucher(game,current,known)
	if helper>=0:options.append(crime.option("Ask %s to speak for the accused" % game.party_health.members[helper].name,"vouch"))
	elif int(current.custody.vouched)>=0:text+="\n%s has spoken for the accused." % game.party_health.members[int(current.custody.vouched)].name
	if who=="county" and severity(known)<4:
		var cents:=bail_cents(crime,known)
		options.append(crime.option("Post bail and leave Missouri · $%.2f, forfeited" % (cents/100.0),"bail"))
		text+="\nBail is security for appearing in court. Leaving forfeits it and the case stays on the books as answered by forfeit."
	# The panel's last row is its way back; custody has none.
	options.append(crime.option("Held in custody","back"))
	return {"id":"crime","crime_menu":true,"service_menu":true,"title":TITLES[who],"text":text,"choices":options}
## What the household's council will weigh. Invented game rules; no source gives these communities' 1848 penalties.
static func council_terms(crime,game,current: Dictionary,known: Array) -> String:
	var level:=severity(known)
	if level==1:return "The household's council meets tomorrow. For a theft they want the goods' worth twice over, taken in cash and then goods."
	if level<4:return "The household's council meets tomorrow. For robbery or an attack they want three times the loss, at least $%.2f, and will drive the party out of this country: no household here will deal with you again." % (int(council(crime).violent_min_cents)/100.0)
	return "The household's council meets tomorrow. For a killing, the family of the dead chooses: a heavy price of $%.2f, taken in cash and then goods, or the killer's life. The chance they want a life: about %d in 10%s." % [price_cents(crime,known)/100.0,roundi(life_chance(crime,game,current,known)*10)," (you could not cover the price)" if not can_cover(crime,game,price_cents(crime,known)) else ""]
static func council(crime) -> Dictionary:return rules(crime).council
static func council_due(crime,known: Array) -> int:
	var level:=severity(known)
	if level==1:return maxi(value(known)*int(council(crime).theft_factor),int(council(crime).theft_min_cents))
	if level<4:return maxi(value(known)*int(council(crime).violent_factor),int(council(crime).violent_min_cents))
	return price_cents(crime,known)
static func price_cents(crime,known: Array) -> int:return int(council(crime).price_cents)+value(known)
## Cash plus the goods a council can take, at opening outfit prices.
static func can_cover(crime,game,cents: int) -> bool:
	return roundi(float(game.state.money)*100)+crime.Wanted.goods_value(game)>=cents
static func life_chance(crime,game,current: Dictionary,known: Array) -> float:
	var chance: float=float(council(crime).life_chance)
	if not can_cover(crime,game,price_cents(crime,known)):chance+=float(council(crime).unpaid_life_step)
	if bool(current.custody.surrendered):chance-=float(council(crime).surrender_step)
	return clampf(chance,0.0,1.0)
static func can_choose(crime,game,current: Dictionary,command: String) -> bool:
	if command=="wait":return true
	if command=="vouch":return voucher(game,current,crime.Wanted.trial_charges(crime,game,current))>=0
	return command=="bail" and can_bail(crime,game,current)
static func choose(crime,game,current: Dictionary,command: String) -> bool:
	if not can_choose(crime,game,current,command):return false
	if command=="vouch":
		var id:=voucher(game,current,crime.Wanted.trial_charges(crime,game,current))
		current.custody.vouched=id
		game.journal.append("Day %d · %s spoke for the accused." % [game.state.day,game.party_health.members[id].name])
	elif command=="bail":
		var cents:=bail_cents(crime,crime.Wanted.trial_charges(crime,game,current))
		game._apply({"money":-cents/100.0})
		crime.Wanted.trial(crime,game,current,bool(current.custody.surrendered),"county","bailed",cents)
	else:
		# Waiting is ordinary camp time: meals, illness and weather continue.
		while int(game.state.day)<int(current.custody.hearing_day):
			held_day(crime,game,current)
			if game.state.status!="traveling":
				crime.result(game,"party_lost")
				return true
		var known: Array=crime.Wanted.trial_charges(crime,game,current)
		var verdict: String="convicted" if crime.rng.randf()<conviction_chance(crime,current,known) else "discharged"
		crime.Wanted.trial(crime,game,current,bool(current.custody.surrendered),current.custody.authority,verdict)
	game.Remains.sync(game)
	if game.state.status=="traveling":game.pending=crime.menu(game)
	return true
## Days in the county jail for a fine the party cannot pay. The party camps and eats while it waits.
static func serve(crime,game,current: Dictionary,days: int) -> void:
	for day in range(days):
		if game.state.status!="traveling":return
		held_day(crime,game,current)
## One day with the accused locked up. While the leader sits in jail, a companion may give up on the party:
## more likely the lower their trust; Loyal companions never do.
static func held_day(crime,game,current: Dictionary) -> void:
	game._tick_day(true,false,"rest")
	game._check_health()
	if game.state.status!="traveling" or acting_leader(game)!=0 or 0 not in current.custody.accused:return
	var leaving: Array=[]
	for profile in game.characters.profiles.slice(1):
		var id: int=int(profile.id)
		if id in current.custody.accused or not game.party_health.is_active(game.party_health.members[id]) or "Loyal" in profile.get("specials",[]):continue
		if crime.rng.randf()<abandon_chance(crime,profile):leaving.append(id)
	if leaving.is_empty():return
	current.custody.abandoned.append_array(leaving)
	game.flee(leaving,"while the leader sat in jail")
static func abandon_chance(crime,profile: Dictionary) -> float:
	return clampf(float(rules(crime).abandon_daily)*(100.0-float(profile.trust))/50.0,0.0,1.0)
static func valid_arms(arms: Variant) -> bool:
	return arms is Dictionary and arms.keys().all(func(key):return key in preload("res://simulation/armory.gd").KEYS and whole(arms[key],1,100))
static func valid_custody(crime,r: Dictionary,current: Dictionary,game) -> bool:
	if not current.has("custody"):return current.stage!="custody"
	var c: Variant=current.custody
	if not c is Dictionary or c.size()!=(8 if c.has("arms") else 7) or (c.has("arms") and not valid_arms(c.arms)) or not c.get("abandoned") is Array or c.get("authority") not in AUTHORITIES or not whole(c.get("day"),int(current.day),int(game.state.day)) or not c.get("surrendered") is bool:return false
	if c.hearing_day!=int(c.day)+int(rules(crime).hearing_days[c.authority]) or not c.get("accused") is Array or c.accused.is_empty():return false
	for id in c.accused:
		if not whole(id,0,game.party_health.members.size()-1) or c.accused.count(id)!=1:return false
	for id in c.abandoned:
		if not whole(id,1,game.party_health.members.size()-1) or c.abandoned.count(id)!=1 or id in c.accused or not game.party_health.members[int(id)].get("fled",false):return false
	if not whole(c.get("vouched"),-1,game.party_health.members.size()-1) or int(c.vouched)==0 or int(c.vouched) in c.accused:return false
	if current.stage=="custody":return current.resolution=="" and not current.has("sentence") and int(game.state.day)<=int(c.hearing_day)
	return current.has("sentence") and current.sentence.get("authority")==c.authority
