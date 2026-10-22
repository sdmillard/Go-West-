extends RefCounted
## Companion backgrounds, trust, participation and warned settlement departures.
const SKILLS=["Hunting", "Carpentry", "Caregiving", "Trading"]
const KINDS=["rest_sick", "push_sick", "care", "defend"]
const ACTIONS=["robbery", "murder", "cannibalism", "miss_wages", "hunt", "repair", "care", "trade", "defend"]
var RELATIONSHIPS: Dictionary={"self":50}
var SPECIALS: Array=[]
const MAX_CREATION_SPECIALS=2
var FLAWS: Dictionary={}
var catalog=preload("res://simulation/character_catalog.gd").new()
const MAX_PAYMENT_INTERVAL=7
const FRAMEWORK_FIELDS=["specials","relationship","boundaries","thresholds","can_betray","contract","exit_warning"]
var profiles: Array[Dictionary]=[]
var benefits: Dictionary={}
var error: String=""

func _init() -> void:
	if not catalog.error.is_empty():
		error=catalog.error
		return
	SPECIALS=catalog.data.specials.keys()
	for name in catalog.data.flaws:FLAWS[name]=catalog.data.flaws[name].description
	for name in catalog.data.relationships:RELATIONSHIPS[name]=int(catalog.data.relationships[name].trust)
	load_benefits(JSON.parse_string(FileAccess.get_file_as_string("res://data/party_benefits.json")))

func load_benefits(value: Variant) -> bool:
	error="Invalid party benefit rules"
	if not value is Dictionary:return false
	for key in ["minimum_health","carpentry_days_saved","care_health_bonus","care_recovery_bonus","missed_payments_before_departure","departure_notice_days","food_days_on_departure"]:
		if not whole(value.get(key),1,40):return false
	for key in ["hunter_reload_factor","trade_buy_factor","veteran_risk_reduction"]:
		var amount: Variant=value.get(key)
		if not (amount is int or amount is float) or not is_finite(amount) or amount<=0 or amount>=1:return false
	if not value.get("wage_bases") is Dictionary or value.wage_bases.size()!=SKILLS.size():return false
	for background in SKILLS:
		if not whole(value.wage_bases.get(background),30,1000):return false
	if not value.get("wage_modifiers") is Dictionary or value.wage_modifiers.size()!=4:return false
	for modifier in ["Compassionate","Pragmatic","Loyal","Veteran"]:
		if not whole(value.wage_modifiers.get(modifier),-100,1000):return false
	benefits=value.duplicate(true)
	error=""
	return true

func available(game, background: String="", special: String="") -> bool:
	for profile in profiles:
		if profile.id==0 or profile.id>=game.party_health.members.size():continue
		var member: Dictionary=game.party_health.members[int(profile.id)]
		if not game.party_health.is_active(member) or member.health<benefits.minimum_health or member.conditions.any(func(condition):return condition.severity>=3):continue
		var action: String="defend" if special=="Veteran" else {"Hunting":"hunt","Carpentry":"repair","Caregiving":"care","Trading":"trade"}.get(background,"")
		if not willing(int(profile.id),action):continue
		var assists: bool=profile.skill==background
		for ability in profile.specials:
			if catalog.data.specials[ability].get("assists","")==background:assists=true
		if (background.is_empty() or assists) and (special.is_empty() or special in profile.specials):return true
	return false

func benefit_description(index: int) -> String:
	if index<=0 or index>=profiles.size():return ""
	var profile: Dictionary=profiles[index]
	var description: String=background_benefit(profile.skill)
	if "Veteran" in profile.specials:description+=" Veteran: %d percentage points less confrontation injury risk, subject to the normal floor." % roundi(benefits.veteran_risk_reduction*100)
	for special in profile.specials:
		if special not in ["Loyal","Mercenary","Veteran","Cannibal"]:description+=" "+special+": "+catalog.data.specials[special].description
	return description+" Benefits require a living, willing companion with at least %d health and no serious condition; duplicates do not stack." % benefits.minimum_health

func background_benefit(background: String) -> String:
	return {"Hunting":"Reload time reduced by %d%%." % roundi((1-benefits.hunter_reload_factor)*100),"Carpentry":"%d fewer day(s) for patch/wooden wagon repairs (minimum one day)." % benefits.carpentry_days_saved,"Caregiving":"Care restores %d extra health and advances recovery %d extra day(s)." % [benefits.care_health_bonus,benefits.care_recovery_bonus],"Trading":"%d%% off cash purchases; selling prices unchanged." % roundi((1-benefits.trade_buy_factor)*100)}.get(background,"")

func concern(game, decision: String) -> String:
	var names: Array[String]=[]
	var refusals: Array[String]=[]
	for profile in profiles:
		if profile.id==0 or not game.party_health.is_active(game.party_health.members[profile.id]):continue
		if decision=="defend" and not willing(int(profile.id),"defend"):
			refusals.append(game.party_health.members[profile.id].name)
			continue
		if (decision=="defend" and catalog.reaction(profile,"defense",-1)<0) or (decision=="push_sick" and catalog.reaction(profile,"push_sick")<0):
			names.append(game.party_health.members[profile.id].name)
	var text: String="" if names.is_empty() else "Companion concern (%s): %s" % [", ".join(names),"Risking an armed fight may damage trust." if decision=="defend" else "Pushing a grueling pace with sick or injured travelers may damage trust."]
	if not refusals.is_empty():text+="\n"+", ".join(refusals)+" refuse to assist in an armed defense."
	return text

func start(seed_value: int, count: int) -> void:
	profiles.clear()
	var random:=RandomNumberGenerator.new()
	random.seed=seed_value ^ 0x43484152
	var skills:=SKILLS.duplicate()
	for index in range(skills.size()-1,0,-1):
		var other:=random.randi_range(0,index)
		var swap: String=skills[index]
		skills[index]=skills[other]
		skills[other]=swap
	for index in range(count):
		var traits: Array=[]
		if index>0:
			traits=["Cautious" if random.randi_range(0,1)==0 else "Bold", "Compassionate" if random.randi_range(0,1)==0 else "Pragmatic"]
		profiles.append({"id":index,"traits":traits,"skill":"Leadership" if index==0 else skills[(index-1)%skills.size()],"trust":50,"memories":[]})
	upgrade()

func upgrade() -> void:
	# Existing travelers acquire neutral framework fields; never invent family, debt or specials.
	for profile in profiles:
		profile.specials=[]
		profile.relationship="self" if profile.id==0 else "fellow_traveler"
		profile.boundaries={"approved":[],"disapproved":[],"forbidden":[] if profile.id==0 else (["robbery","murder","cannibalism"] if "Compassionate" in profile.traits else ["murder"])}
		profile.thresholds={"loyalty":80,"breaking":20,"betrayal":10}
		profile.can_betray=false
		profile.contract={}
		profile.exit_warning={}

func breaking_point(profile: Dictionary) -> int:
	return maxi(0,int(profile.thresholds.breaking)-attachment(profile))

func attachment(profile: Dictionary) -> int:
	return int(catalog.data.relationships.get(profile.relationship,{}).get("attachment",0))

func willing(index: int, action: String) -> bool:
	if index==0 or index>=profiles.size():return true
	var profile: Dictionary=profiles[index]
	return response(index,action)!="forbidden" and profile.trust>breaking_point(profile)

func exit_reason(profile: Dictionary) -> String:
	if profile.trust<=breaking_point(profile):return "lost trust"
	if not profile.contract.is_empty() and profile.contract.arrears_cents>0 and profile.contract.misses>=benefits.missed_payments_before_departure:return "repeated unpaid wages"
	return ""

func review_exit(game, profile: Dictionary) -> void:
	if profile.id==0 or not game.party_health.is_active(game.party_health.members[profile.id]):return
	var reason:=exit_reason(profile)
	if reason.is_empty():
		if not profile.exit_warning.is_empty():
			var message: String="%s is staying: the immediate reason for leaving has been resolved." % game.party_health.members[profile.id].name
			game.journal.append("Day %d · %s" % [game.state.day,message])
			game.health_events.append(message)
		profile.exit_warning={}
	elif profile.exit_warning.is_empty():
		profile.exit_warning={"day":int(game.state.day),"reason":reason}
		var message: String="%s warns: I intend to leave at a settlement because of %s. Resolve this before continuing from a settlement." % [game.party_health.members[profile.id].name,reason]
		game.journal.append("Day %d · %s" % [game.state.day,message])
		game.health_events.append(message)

func departure_candidates(game) -> Array[int]:
	var result: Array[int]=[]
	if not game.pending.has("landmark") or game.route.nodes[game.pending.landmark].kind not in ["town","fort"]:return result
	if game.pending.landmark=="fort_kearny" and game.calendar().year==1848 and game.calendar().month<6:return result
	for profile in profiles:
		review_exit(game,profile)
		if profile.id>0 and game.party_health.is_active(game.party_health.members[profile.id]) and not profile.exit_warning.is_empty() and not exit_reason(profile).is_empty() and game.state.day-profile.exit_warning.day>=benefits.departure_notice_days:result.append(int(profile.id))
	return result

func set_relationship(game, index: int, relationship: String) -> bool:
	if index<=0 or index>=profiles.size() or relationship not in RELATIONSHIPS or relationship=="self" or game.state.day!=0:return false
	var profile: Dictionary=profiles[index]
	if not profile.memories.is_empty() or not profile.contract.is_empty() or not profile.exit_warning.is_empty():return false
	profile.relationship=relationship
	profile.trust=RELATIONSHIPS[relationship]
	return true

func response(index: int, action: String) -> String:
	if index<=0 or index>=profiles.size() or action not in ACTIONS:return "neutral"
	var profile: Dictionary=profiles[index]
	if action=="cannibalism" and "Cannibal" in profile.specials:return "neutral"
	if action in profile.boundaries.forbidden:
		return "reluctant" if profile.trust>=profile.thresholds.loyalty else "forbidden"
	if action in profile.boundaries.disapproved:return "disapproved"
	if action in profile.boundaries.approved:return "approved"
	return "neutral"

func effective_forbidden(profile: Dictionary) -> Array:
	var result: Array=profile.boundaries.forbidden.duplicate()
	if "Cannibal" in profile.specials:result.erase("cannibalism")
	return result

func react_to_action(game, action: String) -> void:
	# Call only after an action actually happens; inspecting response() is pure.
	for profile in profiles:
		if profile.id==0 or not game.party_health.is_active(game.party_health.members[profile.id]):continue
		var reaction:=response(profile.id,action)
		if reaction=="neutral":continue
		var forbidden: bool=reaction in ["forbidden","reluctant"]
		remember(game,profile,"action_"+action, -12 if forbidden else (2 if reaction=="approved" else -2),"Your decision: %s. Response: %s." % [action.replace("_"," "),reaction],forbidden)

func react_to_incident(game,action: String,incident_id: int) -> void:
	for profile in profiles:
		if profile.id==0 or not game.party_health.is_active(game.party_health.members[profile.id]):continue
		var reaction:=response(int(profile.id),action)
		if reaction=="neutral":continue
		var forbidden: bool=reaction in ["forbidden","reluctant"]
		remember(game,profile,"action_"+action,-12 if forbidden else (2 if reaction=="approved" else -2),"You attempted %s%s. Response: %s." % [action," "+game.crime.where(game,game.crime.record.incidents[incident_id-1].place) if incident_id<=game.crime.record.incidents.size() else "",reaction],forbidden,incident_id)

func warning(index: int) -> String:
	if index<=0 or index>=profiles.size():return ""
	var profile: Dictionary=profiles[index]
	var attachment: int=attachment(profile)
	if profile.can_betray and profile.trust<=maxi(0,int(profile.thresholds.betrayal)-attachment):return "Trust is critically low; capable of betrayal."
	if profile.trust<=maxi(0,int(profile.thresholds.breaking)-attachment):return "Trust is at a breaking point."
	if profile.trust<=maxi(0,int(profile.thresholds.breaking)-attachment)+10:return "Trust is weakening; your companion is losing faith in your leadership."
	return ""

func has_sick(game) -> bool:
	return game.party_health.members.any(func(member):return game.party_health.is_active(member) and not member.conditions.is_empty())

func valid_setup(setup: Dictionary) -> bool:
	if not setup.get("profiles") is Array or not valid(setup.profiles,5,0) or not setup.get("contracts") is Dictionary:return false
	for profile in setup.profiles:
		if profile.specials.size()>creation_special_limit(profile):return false
		if profile.trust!=RELATIONSHIPS[profile.relationship] or not profile.memories.is_empty() or not profile.contract.is_empty() or not profile.exit_warning.is_empty():return false
		var key:=str(int(profile.id))
		if "Mercenary" in profile.specials:
			var terms: Variant=setup.contracts.get(key)
			if not terms is Dictionary or terms.size()!=2 or not acceptable_terms(terms.get("wage_cents"),terms.get("interval_days"),profile):return false
		elif setup.contracts.has(key):return false
	for key in setup.contracts:
		if key not in ["1","2","3","4"]:return false
	return true

func creation_special_limit(profile: Dictionary) -> int:
	return MAX_CREATION_SPECIALS+profile.get("flaws",[]).size()

func generate_candidate(seed_value: int, candidate_index: int, relationship: String="stranger") -> Dictionary:
	if candidate_index<0 or candidate_index>1000000 or (relationship!="random" and relationship not in catalog.data.relationships):return {}
	var random:=RandomNumberGenerator.new()
	random.seed=seed_value ^ (candidate_index*104729) ^ 0x52454352
	if relationship=="random":relationship=catalog.data.relationships.keys()[random.randi_range(0,catalog.data.relationships.size()-1)]
	var temperament: String=catalog.data.temperaments.keys()[random.randi_range(0,catalog.data.temperaments.size()-1)]
	var values: String=catalog.data.values.keys()[random.randi_range(0,catalog.data.values.size()-1)]
	var profile: Dictionary={"id":1,"traits":[temperament,values],"skill":SKILLS[random.randi_range(0,SKILLS.size()-1)],"trust":RELATIONSHIPS[relationship],"memories":[],"specials":[],"relationship":relationship,"boundaries":catalog.boundaries(values),"thresholds":{"loyalty":80,"breaking":20,"betrayal":10},"can_betray":values in ["Ruthless","Opportunistic"],"contract":{},"exit_warning":{}}
	if random.randi_range(0,2)==0:profile.flaws=[FLAWS.keys()[random.randi_range(0,FLAWS.size()-1)]]
	var pool: Array=SPECIALS.duplicate()
	for index in range(pool.size()-1,0,-1):
		var other:=random.randi_range(0,index)
		var swap: Variant=pool[index]
		pool[index]=pool[other]
		pool[other]=swap
	profile.specials=pool.slice(0,random.randi_range(0,creation_special_limit(profile)))
	var terms: Dictionary={}
	if "Mercenary" in profile.specials:terms={"wage_cents":wage_quote(profile).daily_cents*7,"interval_days":7}
	return {"candidate_id":"%d:%d" % [seed_value,candidate_index],"name":"%s %s" % [catalog.data.first_names[random.randi_range(0,catalog.data.first_names.size()-1)],catalog.data.surnames[random.randi_range(0,catalog.data.surnames.size()-1)]],"profile":profile,"terms":terms}

func daily(game, resting: bool, working: bool, sick_before: bool) -> void:
	advance_contracts(game)
	for profile in profiles:review_exit(game,profile)
	for profile in profiles:
		if profile.id==0 or not game.party_health.is_active(game.party_health.members[profile.id]):continue
		if resting and catalog.reaction(profile,"idle_trust")!=0:remember(game,profile,"action_idle",catalog.reaction(profile,"idle_trust"),"You spent a day resting in camp.")
		if not sick_before:continue
		if resting and catalog.reaction(profile,"rest_sick")!=0:
			remember(game,profile,"rest_sick",catalog.reaction(profile,"rest_sick"),"You stopped to rest while someone was ill or injured.")
		elif working and game.state.pace==2 and catalog.reaction(profile,"push_sick")!=0:
			remember(game,profile,"push_sick",catalog.reaction(profile,"push_sick"),"You pushed a grueling pace while someone was ill or injured.")

func care(game, patient: int) -> void:
	for profile in profiles:
		if profile.id==0 or not game.party_health.is_active(game.party_health.members[profile.id]):continue
		var reaction: int=2*catalog.reaction(profile,"personal_care",1) if profile.id==patient else catalog.reaction(profile,"care_others")
		if reaction!=0:remember(game,profile,"care",reaction,"You arranged care for %s." % game.party_health.members[patient].name)

func defense(game) -> void:
	for profile in profiles:
		if profile.id==0 or not game.party_health.is_active(game.party_health.members[profile.id]):continue
		var forbidden: bool="defend" in profile.boundaries.forbidden
		var reaction: int=catalog.reaction(profile,"defense",-1) if willing(profile.id,"defend") else -1
		remember(game,profile,"defend",-12 if forbidden else reaction,"You stood and fought to defend the wagon." if reaction>0 else "You risked the party in an armed defense.",forbidden)

func remember(game, profile: Dictionary, kind: String, delta: float, text: String, forbidden: bool=false,incident_id: int=0,attack_id: int=0,remains_id: int=0) -> void:
	if not whole(delta,-12,2):return
	# A second incident, attack or grave the same day is its own memory; repeating one is not.
	if profile.memories.any(func(memory):return memory.day==game.state.day and memory.kind==kind and int(memory.get("incident_id",0))==incident_id and int(memory.get("attack_id",0))==attack_id and int(memory.get("remains_id",0))==remains_id):return
	var first: bool=not profile.memories.any(func(memory):return memory.kind==kind)
	var previous_warning:=warning(int(profile.id))
	if delta<0 and "Loyal" in profile.specials and not forbidden:delta*=0.5
	if not forbidden:
		delta=roundf(delta*catalog.factor(profile,"trust_loss" if delta<0 else "trust_gain")*2)/2
	delta=clampf(delta,-12,2)
	var actual:=clampf(float(profile.trust)+delta,0,100)-float(profile.trust)
	profile.trust+=actual
	profile.memories.append({"day":int(game.state.day),"kind":kind,"delta":actual,"text":text})
	if incident_id>0:profile.memories.back()["incident_id"]=incident_id
	if attack_id>0:profile.memories.back()["attack_id"]=attack_id
	if remains_id>0:profile.memories.back()["remains_id"]=remains_id
	if profile.memories.size()>12:profile.memories.pop_front()
	game.journal.append("Day %d · %s: %s (trust %+.1f)." % [game.state.day,game.party_health.members[profile.id].name,text,actual])
	var current_warning:=warning(int(profile.id))
	if (first and actual!=0) or (not current_warning.is_empty() and current_warning!=previous_warning):
		var notice: String="%s: %s" % [game.party_health.members[profile.id].name,text]
		if actual<0:notice+=" I object to that decision."
		if not current_warning.is_empty():notice+=" "+current_warning
		game.health_events.append(notice)
	review_exit(game,profile)

func description(index: int) -> String:
	if index>=profiles.size():return ""
	if index==0:return "PARTY LEADER · YOU\nYou choose your character's decisions and values."
	var profile: Dictionary=profiles[index]
	var lines: Array[String]=["COMPANION", "Traits: "+", ".join(profile.traits), "Background: "+profile.skill, "Trust in you: %s / 100" % trust_text(profile.trust),"Relationship: "+profile.relationship.replace("_"," "),"Specials: "+(", ".join(profile.specials) if not profile.specials.is_empty() else "None")]
	for flaw in profile.get("flaws",[]):lines.append("Flaw: %s. %s" % [flaw,FLAWS[flaw]])
	var forbidden: Array=effective_forbidden(profile)
	if not forbidden.is_empty():lines.append("Forbidden: "+", ".join(forbidden))
	if not warning(index).is_empty():lines.append(warning(index))
	if not profile.exit_warning.is_empty():lines.append("INTENDS TO LEAVE: "+profile.exit_warning.reason+". Resolve before leaving a settlement.")
	if profile.trust<=breaking_point(profile):lines.append("REFUSES TO ASSIST with optional work or armed defense until trust improves.")
	lines.append("PARTY BENEFIT\n"+benefit_description(index))
	if not profile.contract.is_empty():
		var contract: Dictionary=profile.contract
		lines.append("Wages: $%.2f every %d days.\nOwed: $%.2f · next due day %d." % [contract.wage_cents/100.0,contract.interval_days,contract.arrears_cents/100.0,contract.next_due_day])
		lines.append("On-time pay: %d / 7 days toward the next +2 trust." % contract.get("reward_days",0))
	lines.append("RECENT MEMORIES")
	for memory in profile.memories:
		lines.append("Day %d · %s (%+.1f trust)" % [memory.day,memory.text,memory.delta])
	if profile.memories.is_empty():lines.append("No decisions remembered yet.")
	return "\n\n".join(lines)

func trust_text(value: float) -> String:
	return str(int(value)) if value==floor(value) else "%.1f" % value

func valid(value: Variant, count: int, day: int, legacy: bool=false, framework_version: int=3) -> bool:
	if not value is Array or value.size()!=count:return false
	for index in range(count):
		var profile: Variant=value[index]
		if not profile is Dictionary or profile.get("id")!=index or not profile.get("traits") is Array or profile.traits.size()!=(0 if index==0 else 2):return false
		if index==0:
			if profile.get("skill")!="Leadership":return false
		elif profile.traits[0] not in catalog.data.temperaments or profile.traits[1] not in catalog.data.values or profile.get("skill") not in SKILLS:return false
		if not half_number(profile.get("trust"),0,100) or (legacy and not whole(profile.trust,0,100)) or not profile.get("memories") is Array or profile.memories.size()>12:return false
		if not legacy and not valid_framework(profile,index,day):return false
		var flaws: Variant=profile.get("flaws",[])
		if not flaws is Array or flaws.size()>1 or (index==0 and not flaws.is_empty()):return false
		for flaw in flaws:
			if not flaw is String or flaw not in FLAWS:return false
		if not legacy and framework_version==2 and profile.has("exit_warning"):return false
		if not legacy and framework_version>=3:
			var notice: Variant=profile.get("exit_warning")
			if not notice is Dictionary:return false
			if not notice.is_empty() and (index==0 or notice.size()!=2 or not whole(notice.get("day"),0,day) or notice.get("reason") not in ["lost trust","repeated unpaid wages"]):return false
		if legacy and FRAMEWORK_FIELDS.any(func(key):return profile.has(key)):return false
		if index==0 and (profile.trust!=50 or not profile.memories.is_empty()):return false
		var seen: Array=[]
		var previous_day: int=-1
		for memory in profile.memories:
			var kinds: Array=KINDS if legacy else KINDS+["wage_paid","wage_missed","action_idle","remains_disturbed"]+ACTIONS.map(func(action):return "action_"+action)
			if not memory is Dictionary or not whole(memory.get("day"),0,day) or memory.get("kind") not in kinds or not half_number(memory.get("delta"),-12 if not legacy else -2,2) or not memory.get("text") is String or memory.text.length()>240:return false
			if memory.has("incident_id") and not whole(memory.incident_id,1,10000):return false
			if memory.has("attack_id") and (not whole(memory.attack_id,1,100) or memory.kind!="action_murder" or memory.has("incident_id")):return false
			if memory.has("remains_id") and (not whole(memory.remains_id,1,200) or memory.kind!="remains_disturbed" or memory.has("incident_id") or memory.has("attack_id")):return false
			if memory.kind=="remains_disturbed" and not memory.has("remains_id"):return false
			var key: String=str(memory.day)+":"+memory.kind+":"+str(int(memory.get("incident_id",0)))+":"+str(int(memory.get("attack_id",0)))+":"+str(int(memory.get("remains_id",0)))
			if key in seen or memory.day<previous_day:return false
			seen.append(key)
			previous_day=int(memory.day)
	return true

func half_number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(value) and value>=low and value<=high and value*2==floor(value*2)

func whole(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(value) and value==floor(value) and value>=low and value<=high

func start_contract(game, index: int, wage_cents: int, interval_days: int) -> bool:
	if index<=0 or index>=profiles.size() or game.state.status!="traveling" or not game.party_health.is_active(game.party_health.members[index]):return false
	var profile: Dictionary=profiles[index]
	if "Mercenary" not in profile.specials or not profile.contract.is_empty() or not acceptable_terms(wage_cents,interval_days,profile):return false
	profile.contract={"wage_cents":wage_cents,"interval_days":interval_days,"next_due_day":int(game.state.day)+interval_days,"arrears_cents":0,"oldest_due_day":-1,"misses":0,"last_due_day":-1,"last_assessed_day":-1,"reward_days":0,"last_late_reward_day":-7}
	game.journal.append("Day %d · Agreed to pay %s $%.2f every %d days." % [game.state.day,game.party_health.members[index].name,wage_cents/100.0,interval_days])
	return true

func wage_quote(profile: Dictionary) -> Dictionary:
	# Cash plus party provisions; monthly sources are scaled to journey days.
	var daily: int=benefits.wage_bases.get(profile.get("skill",""),40)
	var lines: Array[String]=["%s background: $%.2f" % [profile.get("skill","Base"),daily/100.0]]
	var modifiers: Dictionary=benefits.wage_modifiers
	for modifier_name in modifiers:
		if modifier_name in profile.get("traits",[]) or modifier_name in profile.get("specials",[]):
			daily+=modifiers[modifier_name]
			lines.append("%s: %s$%.2f" % [modifier_name,"+" if modifiers[modifier_name]>=0 else "-",absf(modifiers[modifier_name]/100.0)])
	for special in profile.get("specials",[]):
		var premium: int=catalog.data.specials.get(special,{}).get("wage_cents",0)
		if premium>0:
			daily+=premium
			lines.append("%s: +$%.2f" % [special,premium/100.0])
	return {"daily_cents":maxi(30,daily),"breakdown":lines}

func acceptable_terms(wage_cents: Variant, interval_days: Variant, profile: Dictionary={}) -> bool:
	return whole(wage_cents,1,100000) and whole(interval_days,1,MAX_PAYMENT_INTERVAL) and wage_cents>=wage_quote(profile).daily_cents*interval_days

func advance_contracts(game) -> void:
	for profile in profiles:
		if profile.id==0 or profile.contract.is_empty() or not game.party_health.is_active(game.party_health.members[profile.id]):continue
		var contract: Dictionary=profile.contract
		if contract.last_due_day>=0 and contract.last_due_day<game.state.day and contract.last_assessed_day<contract.last_due_day:
			contract.last_assessed_day=contract.last_due_day
			if contract.arrears_cents>0:
				contract.misses+=1
				remember(game,profile,"wage_missed",-2 if contract.misses==1 else -4,"You missed an agreed wage payment; the debt remains.","miss_wages" in profile.boundaries.forbidden)
		while contract.next_due_day<=game.state.day:
			if contract.arrears_cents==0:contract.oldest_due_day=contract.next_due_day
			contract.last_due_day=contract.next_due_day
			contract.next_due_day+=contract.interval_days
			contract.arrears_cents+=contract.wage_cents
			game.journal.append("Day %d · Wages due for %s: $%.2f owed. Pay through View Party before another day passes." % [game.state.day,game.party_health.members[profile.id].name,contract.arrears_cents/100.0])

func can_receive_wages(game, index: int) -> bool:
	if index<=0 or index>=profiles.size() or game.state.status not in ["traveling","arrived"]:return false
	var member: Dictionary=game.party_health.members[index]
	if not member.alive:return false
	if not member.get("departed",false):return true
	return game.pending.get("landmark",game.service_return.get("landmark",""))==member.departure_place

func pay_wages(game, index: int, cents: int=-1) -> bool:
	if not can_receive_wages(game,index):return false
	var profile: Dictionary=profiles[index]
	if profile.contract.is_empty():return false
	var contract: Dictionary=profile.contract
	var amount: int=int(contract.arrears_cents) if cents==-1 else cents
	if amount<=0 or amount>contract.arrears_cents or roundi(game.state.money*100)<amount:return false
	var on_time: bool=contract.oldest_due_day==game.state.day
	game.state.money=snappedf(game.state.money-amount/100.0,0.01)
	game.supply_history.append({"day":int(game.state.day),"event":"wages","changes":{"money":-amount/100.0}})
	contract.arrears_cents-=amount
	game.journal.append("Day %d · Paid %s $%.2f in wages; $%.2f remains owed." % [game.state.day,game.party_health.members[index].name,amount/100.0,contract.arrears_cents/100.0])
	if contract.arrears_cents==0:
		contract.oldest_due_day=-1
		if game.party_health.is_active(game.party_health.members[index]):
			if on_time:
				var credit: int=int(contract.get("reward_days",0))+int(contract.interval_days)
				contract["reward_days"]=credit%7
				if credit>=7:remember(game,profile,"wage_paid",2,"You honored a week of agreed wages.")
			elif game.state.day-int(contract.get("last_late_reward_day",-7))>=7:
				contract["last_late_reward_day"]=int(game.state.day)
				remember(game,profile,"wage_paid",1,"You cleared the overdue wages.")
	review_exit(game,profile)
	return true

func due_total() -> int:
	var total:=0
	for profile in profiles:
		if not profile.contract.is_empty():total+=int(profile.contract.arrears_cents)
	return total

func valid_framework(profile: Dictionary, index: int, day: int) -> bool:
	if not profile.get("specials") is Array or profile.specials.size()>SPECIALS.size():return false
	var seen: Array=[]
	for special in profile.specials:
		if special not in SPECIALS or special in seen:return false
		seen.append(special)
	if profile.get("relationship") not in RELATIONSHIPS or (profile.relationship=="self")!=(index==0) or not profile.get("can_betray") is bool:return false
	var boundaries: Variant=profile.get("boundaries")
	if not boundaries is Dictionary or boundaries.size()!=3:return false
	seen.clear()
	for tier in ["approved","disapproved","forbidden"]:
		if not boundaries.get(tier) is Array or boundaries[tier].size()>ACTIONS.size():return false
		for action in boundaries[tier]:
			if action not in ACTIONS or action in seen:return false
			seen.append(action)
	var thresholds: Variant=profile.get("thresholds")
	if not thresholds is Dictionary or thresholds.size()!=3:return false
	for key in ["loyalty","breaking","betrayal"]:
		if not whole(thresholds.get(key),0,100):return false
	if thresholds.betrayal>thresholds.breaking or thresholds.breaking>=thresholds.loyalty:return false
	var contract: Variant=profile.get("contract")
	if not contract is Dictionary:return false
	if not contract.is_empty():
		var optional: int=(1 if contract.has("reward_days") else 0)+(1 if contract.has("last_late_reward_day") else 0)
		if "Mercenary" not in profile.specials or contract.size()!=8+optional:return false
		if not whole(contract.get("reward_days",0),0,6) or not whole(contract.get("last_late_reward_day",-7),-7,day):return false
		if not whole(contract.get("wage_cents"),1,100000) or not whole(contract.get("interval_days"),1,30) or not whole(contract.get("arrears_cents"),0,10000000000) or not whole(contract.get("misses"),0,100000):return false
		if not whole(contract.get("next_due_day"),1,day+30) or not whole(contract.get("last_due_day"),-1,day) or not whole(contract.get("last_assessed_day"),-1,day):return false
		if contract.last_assessed_day>contract.last_due_day or contract.last_due_day>=contract.next_due_day:return false
		if not whole(contract.get("oldest_due_day"),-1,day) or (contract.arrears_cents==0)!=(contract.oldest_due_day==-1):return false
		if contract.oldest_due_day>contract.last_due_day or (contract.last_due_day>=0 and contract.next_due_day-contract.last_due_day!=contract.interval_days):return false
	if index==0 and (not profile.specials.is_empty() or not contract.is_empty() or profile.can_betray or not seen.is_empty()):return false
	return true


