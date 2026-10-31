extends SceneTree
## The leader's profession is a skill like a companion background (Spencer: abilities, not gear).
const Simulation=preload("res://simulation/trail_engine.gd")
const Skill=preload("res://simulation/profession_skill.gd")
const Tactical=preload("res://simulation/tactical_combat.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit(profession: String,seed_value: int=71):
	var game=Simulation.new(seed_value,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	check(game.depart(profession,["A","B","C","D","E"],6,cart),"%s departs with the suggested outfit" % profession)
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.survival.forced_weather="clear"
	game.pending={}
	return game
func run():
	var ids: Array=[]
	var cash: Dictionary={}
	var game0=Simulation.new(1,"classic",true)
	for entry in game0.outfitter.professions:ids.append(entry.id);cash[entry.id]=int(entry.cash_cents)
	check(ids==["banker","merchant","doctor","carpenter","saddler","hunter","farmer","soldier","outlaw"],"Nine professions, listed richest first: %s" % [ids])
	check(cash.banker>cash.merchant and cash.merchant>cash.doctor and cash.doctor>cash.carpenter and cash.farmer>cash.soldier and cash.soldier>cash.outlaw and cash.outlaw>=60000,"Poorer trades carry trail skills; richer ones lean on cash")
	var skills: Dictionary=game0.characters.benefits.profession_skills
	check(not skills.has("banker") and ids.all(func(id):return id=="banker" or skills.has(id)),"Every profession but the banker has a skill")
	# Companion backgrounds carried by the leader.
	var expected: Dictionary={"merchant":"Trading","doctor":"Caregiving","carpenter":"Carpentry","saddler":"Leatherworking","hunter":"Hunting","soldier":"Soldiering","outlaw":"Outlawry"}
	for profession in expected:
		var g=outfit(profession)
		check(Skill.background(g)==expected[profession] and g.camp_tasks.specialist(g,0,expected[profession]),"%s leader counts as a %s specialist" % [profession,expected[profession]])
		check(g.characters.available(g,expected[profession]),"%s leader provides the %s party benefit" % [profession,expected[profession]])
		g.party_health.members[0].health=20
		check(Skill.background(g)=="" and not g.camp_tasks.specialist(g,0,expected[profession]),"A badly hurt %s leader cannot work the skill" % profession)
	var banker=outfit("banker")
	check(Skill.background(banker)=="" and Skill.stockman(banker).is_empty(),"The banker's edge is cash alone")
	check(not banker.camp_tasks.specialist(banker,0,"Carpentry"),"A banker leader is no carpenter")
	# Stockman: farmer leader eases a working team and helps a resting one.
	var farmer=outfit("farmer")
	for g in [farmer,banker]:g.state.landmark="fort_kearny";g.state.terrain="plains"
	var fp: Dictionary=farmer.pasture_assessment()
	var bp: Dictionary=banker.pasture_assessment()
	check(int(fp.ox_work_strain)==maxi(1,int(bp.ox_work_strain)-1) or int(bp.ox_work_strain)<=1,"A farmer leader's team strains 1 less on working days: %d vs %d" % [fp.ox_work_strain,bp.ox_work_strain])
	check(int(bp.ox_rest_recovery)==0 or int(fp.ox_rest_recovery)==int(bp.ox_rest_recovery)+1,"and recovers 1 more on rest days with grass: %d vs %d" % [fp.ox_rest_recovery,bp.ox_rest_recovery])
	check(int(fp.base_work_strain)==int(bp.base_work_strain),"Horses keep their own wear rules")
	var fo: Dictionary=farmer.forage_offer()
	var bo: Dictionary=banker.forage_offer()
	check(not fo.available or float(fo.workers)>float(bo.workers),"A farmer leader gathers more when foraging")
	var f_ox: Dictionary=farmer.ox_slaughter_offer(true)
	var b_ox: Dictionary=banker.ox_slaughter_offer(true)
	check(not f_ox.is_empty() and int(f_ox.meat)>int(b_ox.meat) and float(f_ox.injury_chance)==0.0 and float(b_ox.injury_chance)>0.0,"A farmer butchers more meat by hand and is never cut: %d vs %d lb" % [f_ox.get("meat",0),b_ox.get("meat",0)])
	farmer.party_health.members[0].health=20
	check(Skill.stockman(farmer).is_empty() and int(farmer.pasture_assessment().ox_work_strain)==int(bp.ox_work_strain),"A badly hurt farmer cannot tend the stock")
	# Soldier: Veteran in confrontations and tactical saves.
	var soldier=outfit("soldier")
	check(soldier.characters.available(soldier,"","Veteran"),"A soldier leader counts as a Veteran")
	var t=Tactical.new()
	check(t._body_bonus({"slot":0},0,true)==int(t.rules.get("saves",{}).get("veteran_bonus",0)) and t._body_bonus({"slot":1},0,true)==0,"Only the soldier leader gets the Veteran's steadier save")
	# Outlaw: one prior job of crime experience, still capped; nothing else.
	var outlaw=outfit("outlaw")
	check(outlaw.crime.experience(outlaw)==1 and banker.crime.experience(banker)==0,"An outlaw sets out with one job's experience")
	check(Skill.stockman(outlaw).is_empty(),"An outlaw is no stockman")
	# Companion backgrounds: a Soldiering companion serves as a Veteran; an Outlawry companion brings a job.
	var party=outfit("banker",72)
	for profile in party.characters.profiles:
		if int(profile.id)>0:profile.skill="Hunting";profile.specials=[]
	check(not party.characters.available(party,"","Veteran") and party.crime.experience(party)==0,"Plain companions bring neither")
	party.characters.profiles[1].skill="Soldiering"
	party.characters.profiles[2].skill="Outlawry"
	check(party.characters.available(party,"","Veteran"),"A Soldiering companion counts as a Veteran")
	check(party.crime.experience(party)==1,"An Outlawry companion brings one job of experience")
	check(t._body_bonus({"slot":1,"profile":{"skill":"Soldiering","specials":[]}},0)==int(t.rules.get("saves",{}).get("veteran_bonus",0)),"A Soldiering companion has the Veteran's steadier save")
	check(party.characters.SKILLS.size()==7 and party.characters.DEALT_SKILLS.size()==5,"Seven backgrounds to choose; generated parties still deal the original five")
	# Trained aim in tactical fights: soldiers like soldiers, hunters (and Sharpshooters) about half that.
	check(t._trained_aim({"slot":0},"Hunting")=="hunter" and t._trained_aim({"slot":0},"Soldiering")=="soldier" and t._trained_aim({"slot":0},"Carpentry")=="","A hunter or soldier leader shoots with trained aim")
	check(t._trained_aim({"slot":2,"profile":{"skill":"Hunting","specials":[]}})=="hunter" and t._trained_aim({"slot":2,"profile":{"skill":"Trading","specials":["Sharpshooter"]}})=="hunter" and t._trained_aim({"slot":2,"profile":{"skill":"Trading","specials":[]}})=="","Hunting companions and Sharpshooters aim like hunters")
	check(float(t.rules.accuracy.hunter_bonus)<float(t.rules.accuracy.soldier_bonus),"A hunter's edge is smaller than a soldier's")
	print("Profession skills: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
