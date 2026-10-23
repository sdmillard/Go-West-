extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,text: String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+text)
func party(seed_value: int=57):
	var game=Simulation.new(seed_value,"classic",true)
	var cart: Dictionary={}
	for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
	game.depart("banker",["Lead","Ada","Ben","Cora","Dell"],5,cart)
	game.party_health.daily_onset_chance=0
	game.survival.forced_weather="clear"
	game.survival.data.event_chance=0
	game.seen.append("muddy_trail")
	game.crime.record.bonds=[]
	game.social.start(game)
	return game
func restore(game):return Store.new().restore(JSON.parse_string(JSON.stringify(Store.new().capture(game))))
func restored_data(value):return Store.new().restore(JSON.parse_string(JSON.stringify(value)))
func stop(game,id: String="fort_bridger"):
	game.state.next_landmark=id
	game._arrive_landmark()
func command(game,text: String) -> bool:
	for i in range(game.pending.choices.size()):
		if game.pending.choices[i].get("recruit_command","")==text:return game.choose(i)
	return false
func kill(game,id: int):
	game.party_health.kill(game.party_health.members[id],int(game.state.day),"test injury")
	game._collect_health_events()
	game.state.party_size=game.party_health.living_count()
	game.state.health=game.party_health.average_health()
func find(game,site_name: String="fort_bridger") -> bool:
	stop(game,site_name)
	game.recruitment.rules.find_chance=1.0
	game.open_companions()
	return command(game,"search")
func run():
	var game=party()
	stop(game)
	var before=Store.new().capture(game)
	check(game.open_companions() and not command(game,"search"),"A full party cannot search or overfill")
	check(command(game,"back") and Store.new().capture(game)==before,"Canceling recruitment is free and pure")
	kill(game,1)
	var grave: Dictionary=game.crime.record.remains.back().duplicate(true)
	check(game.current_party_slots()==[0,-1,2,3,4],"Death leaves a vacancy in the original position")
	check(find(game),"A populated stop permits a one-day search")
	check(game.state.day==1 and not game.recruitment.candidate(game).is_empty(),"Search advances daily rules and freezes a generated candidate")
	check(restore(game)!=null,"Open candidate preview saves")
	var damaged: Dictionary=Store.new().capture(game)
	damaged.recruitment.slots[2]=0
	check(restored_data(damaged)==null,"Duplicate physical slot identities are rejected")
	damaged=Store.new().capture(game)
	damaged.recruitment.searches[game.recruitment.site(game)].candidate.terms={"wage_cents":1,"interval_days":7}
	check(restored_data(damaged)==null,"Invalid or underpriced candidate contracts cannot load")
	var offer: Dictionary=game.recruitment.candidate(game).duplicate(true)
	before=Store.new().capture(game)
	command(game,"back")
	game.open_companions()
	check(game.recruitment.candidate(game)==offer and game.state.day==1,"Reopening cannot reroll or charge again")
	check(command(game,"accept") and game.state.party_size==5,"Accepting fills exactly one vacancy")
	check(game.party_health.members.size()==6 and game.current_party_slots()==[0,5,2,3,4],"New permanent identity fills the old physical slot")
	check(game.crime.record.remains[0]==grave and not game.party_health.members[1].alive and game.party_health.members[5].alive,"Recruitment never overwrites the old dead traveler or grave")
	check(game.characters.profiles[5].appearance==offer.profile.appearance,"The preview appearance is the person who joins")
	check(restore(game)!=null,"Recruits, graves, extended ids and relationships round-trip")
	command(game,"back")
	game.pending={}
	game.open_care()
	check(restore(game)!=null,"Care offers remain valid with recruited travelers")
	game.choose(game.pending.choices.size()-1)
	if game.pending.get("id","")=="party_health":game.choose(0)
	check(game.open_attack(5),"Recruited traveler can be targeted through the existing attack framework")
	check(restore(game)!=null,"Attack confirmation supports extended traveler ids")
	damaged=Store.new().capture(game)
	damaged.pending.choices[0].attack_target=31
	check(restored_data(damaged)==null,"An attack cannot refer to an absent archived traveler")
	game.choose(game.pending.choices.size()-1)
	var witness_trust: float=game.characters.profiles[2].trust
	game.crime.record.bonds=[{"a":2,"b":5,"kind":"friend"},{"a":3,"b":4,"kind":"partner"}]
	check(game.open_dismiss(5),"A recruit can be dismissed nonviolently in camp")
	before=Store.new().capture(game)
	check(restore(game)!=null,"Dismissal confirmation saves")
	command(game,"back")
	check(game.party_health.is_active(game.party_health.members[5]),"Canceling dismissal keeps the companion")
	game.open_dismiss(5)
	var ammo: int=game.state.bullets
	var day: int=game.state.day
	command(game,"dismiss")
	check(game.state.bullets==ammo and game.state.day==day and game.party_health.members[5].dismissed,"Dismissal uses no bullet or day")
	check(game.characters.profiles[2].trust<witness_trust and witness_trust-game.characters.profiles[2].trust<=4,"Friends object more mildly than to an attack")
	check(game.current_party_slots()[1]==-1 and restore(game)!=null,"Living dismissal creates a vacancy and preserves a valid history")
	check(game.open_dismiss(3),"An existing partner can be asked to leave")
	check("accompanying their partner" in game.pending.text,"The confirmation warns that a partner goes too")
	command(game,"dismiss")
	check(game.party_health.members[3].dismissed and game.party_health.members[4].dismissed and game.state.party_size==2,"Partner-aware dismissal departs the pair with correct meals/health")
	check(restore(game)!=null,"Several same-day dismissals retain valid distinct social memories")
	check(find(game,"fort_hall") and command(game,"accept"),"A different stop can supply another candidate")
	check(game.party_health.members.size()==7 and game.party_health.members[6].alive and game.party_health.members[5].departed,"A dismissed recruit's identity is never recycled")
	check(restore(game)!=null,"Repeated replacements preserve all past records")
	command(game,"back")
	check(find(game,"fort_boise"),"A further stop has its own offer")
	var declined: Dictionary=game.recruitment.candidate(game).duplicate(true)
	command(game,"decline")
	command(game,"back")
	game.open_companions()
	check(not command(game,"accept") and not command(game,"search") and game.recruitment.candidate(game)==declined,"Declining is final at that place; no free rerolls")
	check(restore(game)!=null,"Declined offers save")
	game=party()
	kill(game,1)
	stop(game)
	game.recruitment.rules.find_chance=0
	game.open_companions()
	command(game,"search")
	check(game.recruitment.candidate(game).is_empty() and game.state.day==1 and not command(game,"search"),"An unsuccessful search still costs a day and cannot be rerolled")
	check(restore(game)!=null,"Unsuccessful search persists")
	var paid=party()
	kill(paid,1)
	find(paid)
	var merc: Dictionary={}
	for index in range(100):
		var proposal: Dictionary=paid.characters.generate_candidate(57,index)
		if "Mercenary" in proposal.profile.specials:merc=proposal;break
	check(not merc.is_empty(),"Generated candidates include paid companions")
	paid.recruitment.record.searches[paid.recruitment.site(paid)].candidate=merc
	paid.pending=paid.recruitment.menu(paid)
	check(restore(paid)!=null,"Paid candidate preview saves with their quoted minimum")
	var hired_day: int=paid.state.day
	command(paid,"accept")
	var contract: Dictionary=paid.characters.profiles[5].contract
	check(contract.wage_cents==merc.terms.wage_cents and contract.next_due_day==hired_day+7,"A recruit's contract begins on their actual hire day")
	check(restore(paid)!=null,"Hired mercenary and contract round-trip")
	command(paid,"back")
	paid.pending={}
	kill(paid,5)
	check(paid.crime.record.remains.back().person==paid.crime.person_id(int(paid.state.seed),5) and paid.current_party_slots()[1]==-1,"A recruited traveler can die and leave their own remains and vacancy")
	check(restore(paid)!=null,"Death of a recruited traveler preserves valid saved remains")
	var screen=Main.instantiate()
	root.add_child(screen)
	await process_frame
	screen.departure_view.hide()
	screen.game=game
	screen._show_party()
	check(screen.party_rows.get_child(1).text.contains("EMPTY SLOT"),"Party UI shows the vacancy rather than an occupied dead row")
	screen._toggle_party_history()
	check(screen.party_rows.get_children().any(func(row):return row.has_meta("traveler_id") and int(row.get_meta("traveler_id"))==1),"The old traveler stays accessible under past travelers")
	screen._select_member(2)
	check(screen.dismiss_button.visible,"Party UI offers nonviolent dismissal")
	screen.queue_free()
	await process_frame
	print("Recruitment: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
