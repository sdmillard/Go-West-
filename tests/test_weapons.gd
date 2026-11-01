extends SceneTree
## Arms: the travelers' own rifles and knives, bought arms, weight, saves, loadouts and how each weapon fights.
const Simulation=preload("res://simulation/trail_engine.gd")
const TacticalCombat=preload("res://simulation/tactical_combat.gd")
const Store=preload("res://simulation/save_store.gd")
const Armory=preload("res://simulation/armory.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit(extra: Dictionary={}):
	var game=Simulation.new(57,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	cart.merge(extra,true)
	check(game.depart("banker",["A","B","C","D","E"],5,cart),"The party departs with cart %s" % str(extra))
	return game
func session(squad: Array,bullets: int=20) -> Dictionary:
	var tc:=TacticalCombat.new()
	return {"tc":tc,"s":tc.start_session({"seed":7,"venue_kind":"store","place_name":"Test","bullets":bullets,"squad":squad,"enemies":[{"uid":"keeper:test","name":"Keeper","role":"owner","health":100}]})}
func pick(game,command: String) -> bool:
	for index in range(game.pending.get("choices",[]).size()):
		if game.pending.choices[index].get("crime_command","")==command:return game.choose(index)
	return false
func row(counter: Dictionary,item: String) -> Dictionary:
	for each in counter.rows:
		if each.item==item:return each
	return {}
## A party stopped at Fort Bridger's store.
func at_bridger(extra: Dictionary={}):
	var game=outfit(extra)
	game.survival.forced_weather="clear"
	game.party_health.daily_onset_chance=0
	game.survival.data.event_chance=0
	game.state.money=500.0
	game.route_path=game.route.main_path_to("fort_bridger")
	game.state.landmark="fort_bridger"
	game.state.next_landmark="fort_bridger"
	game.state.miles=int(game.route.node_miles()["fort_bridger"])
	game.state.leg_miles=0
	game.state.leg_length=0
	game.pending={}
	game._arrive_landmark(true,false)
	return game
func run() -> void:
	check(Armory.valid_rules(Armory.data),"Weapon rules load")
	# Everyone brings a rifle and a knife; bought arms come on top and cost money and weight.
	var plain=outfit()
	check(Armory.count(plain.state,"rifles")==5 and Armory.count(plain.state,"knives")==5 and int(plain.state.arms_home)==5,"Each traveler sets out with their own rifle and knife")
	check(Armory.count(plain.state,"revolvers")==0 and Armory.count(plain.state,"shotguns")==0,"Nobody has a Colt or shotgun unless one is bought")
	var armed=outfit({"shotguns":1,"revolvers":1,"hatchets":2})
	check(Armory.count(armed.state,"shotguns")==1 and Armory.count(armed.state,"revolvers")==1 and Armory.count(armed.state,"hatchets")==2,"Bought arms join the party's stock")
	check(is_equal_approx(plain.state.money-armed.state.money,12.0+50.0+3.0),"Arms cost their outfit prices")
	check(is_equal_approx(armed.provisions.cargo(armed.state)-plain.provisions.cargo(plain.state),8.0+4.0+4.0),"Only bought arms add weight; the travelers' own are personal gear")
	var colt: Dictionary
	for good in armed.outfitter.goods:
		if good.id=="revolvers":colt=good
	check(int(colt.maximum)==1 and int(colt.price_cents)>=4000,"The Colt is a single costly piece")
	var too_many: Dictionary={}
	for good in armed.outfitter.goods:too_many[good.id]=int(good.suggested)
	too_many.revolvers=2
	check(not armed.outfitter.quote("banker",too_many).valid,"Only one Colt can be bought")
	# Saves keep the arms; journeys from before arms get the rifles and knives they set out with.
	var store=Store.new()
	var snapshot: Dictionary=store.capture(armed)
	var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(copy!=null and store.capture(copy)==snapshot,"Arms round-trip through saves")
	var legacy: Dictionary=store.capture(plain)
	for key in Armory.KEYS+["arms_home"]:legacy.state.erase(key)
	copy=store.restore(JSON.parse_string(JSON.stringify(legacy)))
	check(copy!=null and Armory.count(copy.state,"rifles")==5 and Armory.count(copy.state,"knives")==5,"A journey saved before arms keeps a rifle and knife per traveler")
	var bad: Dictionary=store.capture(armed)
	bad.state.erase("arms_home")
	check(store.restore(bad)==null,"A save cannot drop who brought their own arms")
	bad=store.capture(armed)
	bad.state.rifles=-1
	check(store.restore(bad)==null,"A save cannot hold negative arms")
	# Loadouts: the scarcer, closer-range arms are always in someone's hands; the rest carry rifles.
	var kit: Array=Armory.loadout(armed.state,5)
	check(kit.map(func(item):return item.weapon)==["revolvers","shotguns","rifles","rifles","rifles"],"The leader takes the Colt, the next traveler the shotgun")
	check(kit[0].blade=="hatchets" and kit[1].blade=="hatchets" and kit[2].blade=="knives","Hatchets are handed out before knives")
	var bare: Dictionary={"rifles":1,"knives":0,"arms_home":0}
	check(Armory.loadout(bare,2)==[{"weapon":"rifles","blade":""},{"weapon":"","blade":""}],"Travelers past the party's arms fight bare-handed")
	var cfg: Dictionary=Armory.equip({"squad":[{"id":"0"},{"id":"1"}]},armed.state)
	check(cfg.squad[0].weapon=="revolvers" and cfg.squad[1].weapon=="shotguns","A fight's squad carries the party's arms")
	# The player can hand an arm to a chosen traveler; everyone else shares out the rest automatically.
	var picked=outfit({"shotguns":1,"revolvers":1,"hatchets":2})
	var party: Array=[0,1,2,3,4]
	Armory.assign(picked.state,3,"weapon","revolvers",party)
	Armory.assign(picked.state,0,"weapon","rifles",party)
	var chosen: Array=Armory.loadout_for(picked.state,party)
	check(chosen.map(func(item):return item.weapon)==["rifles","shotguns","rifles","revolvers","rifles"],"A chosen traveler carries the Colt and the rest share out what is left")
	Armory.assign(picked.state,2,"weapon","revolvers",party)
	check(Armory.pick(picked.state,3,"weapon")=="auto" and Armory.loadout_for(picked.state,party)[2].weapon=="revolvers","Handing the only Colt to someone else takes it from the first")
	Armory.assign(picked.state,4,"blade","",party)
	check(Armory.loadout_for(picked.state,party)[4].blade=="","A traveler can be told to carry no blade")
	picked.state.revolvers=0
	check(Armory.loadout_for(picked.state,party)[2].weapon=="rifles" and Armory.pick(picked.state,2,"weapon")=="revolvers","A pick that is gone falls back to the automatic share")
	picked.state.revolvers=1
	cfg=Armory.equip({"squad":[{"id":"0"},{"id":"2"},{"id":"3"}]},picked.state)
	check(cfg.squad[1].weapon=="revolvers" and cfg.squad[0].weapon=="rifles","A fight's squad carries the arms the player handed out")
	snapshot=store.capture(picked)
	copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
	check(copy!=null and store.capture(copy)==snapshot and Armory.pick(copy.state,2,"weapon")=="revolvers","Arms picks round-trip through saves")
	bad=store.capture(picked)
	bad.state.arms_assigned={"2":{"weapon":"cannon"}}
	check(store.restore(bad)==null,"A save cannot hand out an arm that does not exist")
	bad.state.arms_assigned={"x":{"weapon":"rifles"}}
	check(store.restore(bad)==null,"A save's arms picks are keyed by traveler")
	Armory.assign(picked.state,2,"weapon","auto",party)
	Armory.assign(picked.state,0,"weapon","auto",party)
	Armory.assign(picked.state,4,"blade","auto",party)
	check(not picked.state.arms_assigned.has("2") and picked.state.arms_assigned.is_empty(),"Setting every pick back to AUTO leaves no picks")
	# Custody takes the accused's own arms.
	Armory.assign(picked.state,3,"weapon","revolvers",party)
	var custody_arms: Dictionary=preload("res://simulation/detention.gd").take_arms(picked,[3])
	check(custody_arms.get("revolvers",0)==1 and Armory.count(picked.state,"revolvers")==0,"The accused give up the arms they carry")
	# Each weapon fights differently.
	var fight: Dictionary=session([{"id":"0","name":"A","weapon":"revolvers","blade":"hatchets"},{"id":"1","name":"B","weapon":"shotguns"},{"id":"2","name":"C","weapon":"pistols"},{"id":"3","name":"D","weapon":"","blade":"knives"},{"id":"4","name":"E"}])
	var tc=fight.tc
	var s: Dictionary=fight.s
	check(int(tc.get_unit(s,"0").rounds)==5 and int(tc.get_unit(s,"1").rounds)==2 and int(tc.get_unit(s,"4").rounds)==1,"A Colt holds five loads, a double gun two, a rifle one")
	check(not bool(tc.get_unit(s,"3").loaded) and tc.capacity(tc.get_unit(s,"3"))==0,"A traveler without a firearm carries no load")
	check(tc.get_unit(s,"4").weapon=="rifles","A config without arms means the old rifle")
	check(tc.shot_ap_cost("snap",tc.get_unit(s,"0"))==3 and tc.shot_ap_cost("snap",tc.get_unit(s,"4"))==4,"Pistols fire quicker than long guns")
	check(tc.reload_ap_cost(tc.get_unit(s,"0"))>tc.reload_ap_cost(tc.get_unit(s,"4")),"Reloading a Colt's cylinder is slow")
	check(tc.melee(tc.get_unit(s,"3")).label=="Knife" and tc.shot_ap_cost("club",tc.get_unit(s,"3"))==2,"A knife strikes quickly")
	check(tc.melee(tc.get_unit(s,"4")).label=="Clubbed stock","A rifleman without a blade clubs the stock")
	check(tc.melee(tc.get_unit(s,"2")).label=="Fists","A pistol without a blade leaves only fists")
	# Range and damage, from the same spot at the same target.
	var keeper: Dictionary=tc.get_unit(s,"keeper:test")
	for id in ["0","1","2","3","4"]:
		var unit: Dictionary=tc.get_unit(s,id)
		unit.x=int(keeper.x)-7
		unit.y=int(keeper.y)
	var far: Dictionary={}
	for id in ["0","1","2","3","4"]:far[id]=tc.shot_preview_at(s,id,int(keeper.x)-7,int(keeper.y),"keeper:test","snap","torso",0)
	check(int(far["4"].distance)==7,"Previews measure seven tiles")
	check(far["2"].reason.contains("range") and far["1"].reason.contains("range"),"Pistol and shotgun cannot reach seven tiles")
	check(not far["3"].can_shoot and far["3"].reason.contains("No firearm"),"No firearm, no shot")
	var close: Dictionary={}
	for id in ["0","1","4"]:close[id]=tc.shot_preview_at(s,id,int(keeper.x)-2,int(keeper.y),"keeper:test","snap","torso",0)
	check(int(close["1"].damage_max)>int(close["4"].damage_max) and int(close["0"].damage_max)<int(close["4"].damage_max),"Up close a shotgun hits hardest and a Colt lightest")
	check(float(close["1"].hit_chance)>=float(close["4"].hit_chance),"A shotgun is surer up close")
	# A Colt fires several times before reloading, and a reload fills the cylinder from the pouch.
	var colt_fight: Dictionary=session([{"id":"0","name":"A","weapon":"revolvers"}],6)
	tc=colt_fight.tc
	s=colt_fight.s
	var shooter: Dictionary=tc.get_unit(s,"0")
	var target: Dictionary=tc.get_unit(s,"keeper:test")
	shooter.x=int(target.x)-2
	shooter.y=int(target.y)
	tc.step(s,{"type":"start_combat"})
	s.active_unit_id="0"
	s.turn="player"
	shooter.ap=8
	tc._exec_attack(s,"0","keeper:test","snap","torso")
	check(int(shooter.rounds)==4 and bool(shooter.loaded) and int(s.bullets_left)==5,"A fired Colt stays loaded with four chambers")
	# Two chambers left and three balls in hand: one spare ball to load.
	shooter.rounds=2
	s.bullets_left=3
	shooter.ap=8
	check(tc._exec_reload(s,"0") and int(shooter.rounds)==3,"A reload fills the cylinder only as far as the pouch allows")
	# No gun: no shooting, no hunting.
	var unarmed=outfit()
	for key in ["rifles","shotguns","pistols","revolvers"]:unarmed.state[key]=0
	check(not unarmed.can_fire() and not unarmed.can_hunt_with_gun(),"Without a firearm the party cannot shoot or hunt")
	unarmed.state.pistols=1
	check(unarmed.can_fire() and not unarmed.can_hunt_with_gun(),"A pistol can shoot but is no hunting arm")
	# Posts sell plain arms by the piece at their own prices; no post has a Colt to sell.
	var post=at_bridger()
	var counter: Dictionary=post.post_store()
	check(not row(counter,"rifles").is_empty() and not row(counter,"hatchets").is_empty() and row(counter,"revolvers").is_empty(),"Fort Bridger sells rifles and hatchets but no Colt")
	check(int(row(counter,"rifles").buy_cents)>=1500 and int(row(counter,"rifles").sell_cents)<int(row(counter,"rifles").buy_cents),"A rifle costs at least the Independence price and sells back for less")
	check(int(row(counter,"rifles").can_buy)==2 and int(row(counter,"shotguns").can_buy)==1,"The post has only a couple of guns on hand")
	var rifles: int=Armory.count(post.state,"rifles")
	check(post.counter_checkout({"rifles":1,"knives":-1}) and Armory.count(post.state,"rifles")==rifles+1 and Armory.count(post.state,"knives")==4,"A rifle bought and a knife sold at the counter")
	check(int(row(post.post_store(),"rifles").can_buy)==1,"The post has one rifle left")
	var copy_post=store.restore(JSON.parse_string(JSON.stringify(store.capture(post))))
	check(copy_post!=null and int(row(copy_post.post_store(),"rifles").can_buy)==1,"Arms trades survive a save")
	# The post's arms can be stolen.
	var thief=at_bridger()
	check(thief.open_crime("fort_bridger"),"The post can be targeted")
	var quote: Dictionary=thief.theft_quote({"rifles":1,"hatchets":1})
	check(quote.valid,"A rifle and a hatchet can be lifted from the post: "+str(quote.get("message","")))
	check(not thief.theft_quote({"rifles":3}).valid and not thief.theft_quote({"revolvers":1}).valid,"Only arms the post holds can be taken")
	# Bandits who take the wagon take the spare arms in it, not the rifles in the travelers' hands.
	var robbed=outfit({"shotguns":1,"rifles":1})
	var rules: Dictionary=robbed.combat.data.bandit_demands.duplicate(true)
	rules.wagon_chance=1.0
	var content: Dictionary={"id":"bandits","text":"Thieves demand {demand}.","choices":[{}]}
	preload("res://simulation/bandit_demand.gd").prepare(robbed,content,rules)
	var asked: Dictionary=content.choices[0].requires
	check(int(asked.get("shotguns",0))==1 and int(asked.get("rifles",0))==1 and not asked.has("knives"),"The thieves take the spare shotgun and rifle from the wagon: "+str(asked))
	check(preload("res://simulation/bandit_demand.gd").valid_choice(content.choices[0]),"An arms demand is a valid bandit demand")
	# The accused give up their arms in custody and get them back when they walk free.
	var held=outfit({"revolvers":1,"hatchets":1})
	held.state.next_landmark="independence"
	held._arrive_landmark()
	held.state.miles=int(held.route.node_miles()["independence"])
	check(held.open_crime("independence"),"The Independence store can be targeted")
	held.crime.scenes.independence.theft_success=0
	pick(held,"theft")
	pick(held,"surrender")
	var current: Dictionary=held.crime.incident()
	check(current.get("stage","")=="custody" and current.custody.has("arms"),"The accused are in custody with their arms held")
	var taken: int=current.custody.accused.size()
	check(int(current.custody.arms.get("revolvers",0))==1 and Armory.count(held.state,"revolvers")==0 and Armory.count(held.state,"hatchets")==0,"The leader's Colt and hatchet are taken")
	check(Armory.count(held.state,"rifles")+Armory.count(held.state,"pistols")+Armory.count(held.state,"shotguns")+Armory.count(held.state,"revolvers")==6-taken,"Each accused gives up one firearm")
	var held_copy=store.restore(JSON.parse_string(JSON.stringify(store.capture(held))))
	check(held_copy!=null and store.capture(held_copy)==store.capture(held),"Held arms survive a save")
	var bad_held: Dictionary=store.capture(held)
	bad_held.crime.record.incidents.back().custody.arms={"cannons":1}
	check(store.restore(bad_held)==null,"A save cannot hold unknown arms in custody")
	for key in held.crime.detention_data.conviction:held.crime.detention_data.conviction[key]=0.0
	check(pick(held,"wait"),"The accused wait for the court")
	check(Armory.count(held.state,"revolvers")==1 and Armory.count(held.state,"hatchets")==1 and Armory.count(held.state,"rifles")==5,"Discharged, the accused get their arms back")
	print("Weapons: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
