extends SceneTree
## How an attack opens: caught off guard, the target gets away, or a fight (docs/ATTACK_OPENINGS.md).
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String):
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func outfit(seed_value: int=57):
	var game=Simulation.new(seed_value,"classic",true)
	for act in game.crime.recognition.acts:if act!="theft":game.crime.recognition.acts[act]=1.0
	game.crime.recognition.half_life_days=100000000
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["Lead","Ada","Ben","Cora","Dell"],5,cart)
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	game.pending={}
	for profile in game.characters.profiles.slice(1):
		profile.traits=["Cautious","Opportunistic"]
		profile.boundaries=game.characters.catalog.boundaries("Opportunistic")
	game.crime.record.bonds=[]
	return game
func at(game,id: String="fort_bridger"):
	game.state.next_landmark=id
	game._arrive_landmark()
	return game
func restore(game):return Store.new().restore(JSON.parse_string(JSON.stringify(Store.new().capture(game))))
func pick(game,command: String) -> bool:
	for index in range(game.pending.get("choices",[]).size()):
		if game.pending.choices[index].get("crime_command","")==command:return game.choose(index)
	return false
func sums(shares: Dictionary) -> bool:return absf(shares.ambush+shares.fled+shares.fight-1.0)<0.0001 and shares.values().all(func(v):return v>=0)
func run():
	var game=at(outfit())
	var crime=game.crime
	var keeper: String=crime.owner_id("fort_bridger")
	var gun: Dictionary=crime.strike_odds(game,"fort_bridger",keeper,false)
	var fists: Dictionary=crime.strike_odds(game,"fort_bridger",keeper,true)
	check(sums(gun) and sums(fists),"The three openings always add up to one")
	check(gun.ambush>fists.ambush and gun.fled<fists.fled,"A gun drops someone off guard more often than bare hands, and gives them less time to run")
	# One hired hand on hand: one bystander step off the base.
	var edge: float=crime.odds(game,"fort_bridger","murder").edge
	check(is_equal_approx(gun.ambush,0.35+edge-0.05) and is_equal_approx(gun.fled,0.25),"At a two-man store the starting odds are as authored, moved by the edge and one bystander")
	crime.record.actors[keeper].health=60
	var hurt: Dictionary=crime.strike_odds(game,"fort_bridger",keeper,false)
	check(hurt.ambush>gun.ambush and hurt.fled<gun.fled,"A wounded target is easier to drop and slower to run")
	crime.record.actors[keeper].health=100
	game.combat.history.append({"day":1,"event":"bandits","tactic":"defend","outcome":"won","victim":0,"risk":0.2})
	check(crime.strike_odds(game,"fort_bridger",keeper,false).ambush>gun.ambush,"Experience makes surprise likelier")
	game.combat.history.clear()
	var fort=at(outfit(),"fort_kearny")
	if fort.crime.staffed(fort,"fort_kearny"):
		var soldier: Dictionary=fort.crime.strike_odds(fort,"fort_kearny",fort.crime.staff_ids("fort_kearny")[1],false)
		check(soldier.fled==0 and soldier.ambush<gun.ambush,"Soldiers never run and are hard to surprise")
	check(crime.strike_text(gun).begins_with("As you strike: off guard %d%%" % roundi(gun.ambush*100)),"The menu names the odds")
	game.open_local_attack(keeper)
	check("As you strike" in game.pending.text,"The attack preview shows the three openings for both ways of attacking")

	# Off guard: the shot drops the keeper and the party may take what it came for.
	crime.scenes.fort_bridger.shot_fatal=0
	crime.forced_strike="ambush"
	check(pick(game,"shoot"),"An attack on the keeper can be made")
	var current: Dictionary=crime.incident()
	check(current.strike=="ambush" and current.attempt=="wounded" and current.stage=="loot","Caught off guard, a wounded keeper cannot stop the party taking the goods")
	check(crime.local_witnesses(current).size()==2,"The hired hand still saw it")
	check(restore(game)!=null,"An attack that caught its target off guard saves and loads: "+Store.new().error)
	var bad: Dictionary=Store.new().capture(game)
	bad.crime.record.incidents[0].strike="lucky"
	check(Store.new().restore(JSON.parse_string(JSON.stringify(bad)))==null,"Only the three openings load")
	bad=Store.new().capture(game)
	bad.crime.record.incidents[0].erase("strike")
	check(Store.new().restore(JSON.parse_string(JSON.stringify(bad)))==null,"Only a surprise lets a wounded keeper be looted")

	# They get away: nobody is hurt, the alarm is raised, and the party must get clear.
	game=at(outfit())
	crime=game.crime
	var bullets: int=game.state.bullets
	game.open_local_attack(crime.owner_id("fort_bridger"))
	crime.forced_strike="fled"
	pick(game,"shoot")
	current=crime.incident()
	check(current.strike=="fled" and current.attempt=="missed" and current.stage=="escape" and crime.actor("fort_bridger",current.target).health==100,"A target who gets away is unhurt and the party is in the escape step")
	check(game.state.bullets==bullets-1 and crime.service("fort_bridger").alarmed,"The shot was fired after them and the alarm is up")
	check(restore(game)!=null,"A target who got away saves and loads")

	# Bare hands, they run: nobody takes a hurt in a struggle that never happened.
	game=at(outfit())
	crime=game.crime
	crime.unarmed_data.mishap_chance=1.0
	game.open_local_attack(crime.owner_id("fort_bridger"))
	crime.forced_strike="fled"
	pick(game,"assault")
	check(not game.journal.any(func(line):return "unarmed struggle" in str(line)),"No struggle, no injury from it")

	# A fight with bare hands goes to the grid with no powder; the party's shot stays in the wagon.
	game=at(outfit())
	crime=game.crime
	bullets=game.state.bullets
	game.open_local_attack(crime.owner_id("fort_bridger"))
	check(game.start_tactical_combat("assault"),"An unarmed attack that comes to blows opens the grid")
	check(crime.incident().strike=="fight" and crime.incident().action=="assault" and crime.incident().shots==0,"The fight is recorded as an unarmed attack")
	check(int(game.tactical_session.bullets_start)==0,"Nobody's gun is loaded in an unarmed fight")
	for u in game.tactical_session.units:
		if u.team=="enemy":u.health=0
	game.tactical_session.resolved=true
	game.tactical_session.outcome="victory"
	check(game.finish_tactical_combat(),"The grid fight settles")
	check(crime.incident().attempt=="killed" and game.state.bullets==bullets,"Beaten to death in the struggle; no powder spent")
	check(restore(game)!=null,"An unarmed fight saves and loads: "+Store.new().error)

	# Companions: the same three openings.
	game=outfit()
	game.crime.record.bonds=[{"a":2,"b":3,"kind":"friend"}]
	game.characters.profiles[3].traits=["Bold","Opportunistic"]
	var party: Dictionary=game.crime.party_strike_odds(game,2,false)
	check(sums(party) and sums(game.crime.party_strike_odds(game,2,true)),"Companion openings add up to one")
	game.open_attack(2)
	check("As you strike" in game.pending.text,"The attack menu shows the openings")
	game.crime.forced_strike="fled"
	game.choose(0)
	var attack: Dictionary=game.crime.record.attacks[0]
	check(attack.strike=="fled" and attack.attempt=="missed" and attack.responses["2"]=="fled" and game.party_health.members[2].get("departed",false),"A companion who sees it coming runs and is gone")
	check(restore(game)!=null,"A companion who got away saves and loads")
	game=outfit()
	game.crime.companion_rules.fatal=0
	game.open_attack(2)
	game.crime.forced_strike="ambush"
	game.choose(0)
	attack=game.crime.record.attacks[0]
	check(attack.strike=="ambush" and attack.attempt=="wounded" and attack.responses["2"]=="fled","Caught off guard, a companion is hit and cannot strike back")

	# A fight within the party: the target and a Bold friend stand against the leader and those who join.
	game=outfit()
	game.crime.record.bonds=[{"a":2,"b":3,"kind":"friend"}]
	game.characters.profiles[3].traits=["Bold","Opportunistic"]
	game.open_attack(2)
	check(game.open_party_fight(0) and game.start_tactical_combat("party:2:gun"),"A fight with a companion opens the grid")
	var enemies: Array=game.tactical_session.units.filter(func(u):return u.team=="enemy").map(func(u):return u.id)
	var players: Array=game.tactical_session.units.filter(func(u):return u.team=="player").map(func(u):return u.id)
	check(enemies==["member:2","member:3"] and "0" in players and not "2" in players and not "3" in players,"The target and their Bold friend fight on the other side")
	bullets=game.state.bullets
	for u in game.tactical_session.units:
		if u.id=="member:2":u.health=0
		if u.id=="member:3":
			u.health=40
			u.yielded=true
	game.tactical_session.shots_fired=3
	game.tactical_session.resolved=true
	game.tactical_session.outcome="victory"
	check(game.finish_tactical_combat(),"The party fight settles")
	attack=game.crime.record.attacks[0]
	check(attack.strike=="fight" and attack.attempt=="killed" and not game.party_health.members[2].alive,"The target died in the fight")
	check(attack.responses["3"]=="retaliated" and game.party_health.members[3].get("departed",false) and game.party_health.members[3].health<100,"The friend who fought for them is hurt and leaves")
	check(game.state.bullets==bullets-3,"The shots fired come out of the party's powder and ball")
	check(restore(game)!=null,"A fight within the party saves and loads: "+Store.new().error)
	# A miss on a companion whose fight was left without a strike (older saves) still loads.
	var old: Dictionary=Store.new().capture(game)
	old.crime.record.attacks[0].erase("strike")
	check(Store.new().restore(JSON.parse_string(JSON.stringify(old)))!=null,"Attacks from older saves, with no opening recorded, still load")
	print("strike: %d checks, %d failures" % [checks,failures])
	quit(1 if failures>0 else 0)
