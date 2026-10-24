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
func party(seed_value: int=57,walking: bool=false):
 var game=Simulation.new(seed_value,"classic",true)
 game.depart("banker",["Lead","A","B","C","D"],5,{"oxen":4,"food":600,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10})
 game.survival.forced_weather="clear"
 game.party_health.daily_onset_chance=0
 game.survival.data.event_chance=0
 for member in game.party_health.members:member.health=100
 game.state.health=100
 if walking:game.abandon_wagon({"food":40,"clothing":5,"bullets":20})
 game.route_path=game.route.main_path_to("fort_bridger")
 game.state.landmark="fort_bridger"
 game.state.next_landmark="fort_bridger"
 game.state.miles=int(game.route.node_miles()["fort_bridger"])
 game.state.leg_miles=0
 game.state.leg_length=0
 game.pending={}
 game._arrive_landmark(true,false)
 game.open_crime("fort_bridger")
 return game
func choose(game,command: String) -> bool:
 for i in range(game.pending.choices.size()):
  if game.pending.choices[i].get("crime_command","")==command and game.can_choose(i):return game.choose(i)
 return false
func trip(game,text: String):
 var snapshot: Dictionary=Store.new().capture(game)
 var restored=Store.new().restore(JSON.parse_string(JSON.stringify(snapshot)))
 check(restored!=null,text)
 if restored!=null:check(Store.new().capture(restored)==snapshot,text+" exact")
 return restored
func run():
 check(Simulation.RobberyDemand.valid_rules(Simulation.RobberyDemand.data) and not Simulation.RobberyDemand.valid_rules({"note":"bad","value_penalty":-1,"wagon_penalty":0.1}),"Demand rules validate finite bounded modifiers")
 var game=party()
 var snapshot: Dictionary=Store.new().capture(game)
 var small: Dictionary=game.robbery_quote({"cash_cents":100})
 var large: Dictionary=game.robbery_quote({"cash_cents":3000,"oxen":1})
 check(small.valid and large.valid and small.compliance>large.compliance,"More demanded value makes compliance less likely")
 check(Store.new().capture(game)==snapshot,"Changing demand preview spends no time, goods or randomness")
 check(not game.demand_robbery({"cash_cents":9999999}) and Store.new().capture(game)==snapshot,"Impossible demands reject atomically")
 check(not game.demand_robbery({"wagon":2}),"Cannot tow multiple demanded frames")
 check(not game.demand_robbery({"wagon":1}) and Store.new().capture(game)==snapshot,"Cannot seize a second active wagon")
 check(not game.demand_robbery({"cash_cents":-1}) and not game.demand_robbery({"free_money":1}),"Negative or unknown demand entries reject")
 var demand: Dictionary={"cash_cents":100,"wagon":1,"oxen":1,"food":5}
 var won=false
 var resisted=false
 for seed_value in range(30):
  game=party(seed_value,true)
  var old_cache: Dictionary=game.wagon_cache.duplicate(true)
  check(game.demand_robbery(demand),"Walking party commits a bounded wagon demand")
  var incident: Dictionary=game.crime.incident()
  check(incident.demand==demand and game.state.day==2,"Committed demand fixed before its real day and saved on the incident")
  trip(game,"Demand outcome saves")
  if incident.attempt=="resisted":
   resisted=true
   check(game.state.vehicle=="foot" and not choose(game,"take"),"Resistance grants no wagon, cash or supplies")
   continue
  won=true
  var money: float=game.state.money
  var oxen: int=game.state.oxen
  check(choose(game,"take") and game.state.vehicle=="wagon" and game.state.oxen==oxen+1,"Compliant owner yields the demanded wagon and specific extra ox")
  check(game.state.money==money+1 and incident.cash_cents==100 and incident.food==5 and incident.taken_goods=={"oxen":1,"wagon":1},"Only exact demanded cash, food and goods transfer")
  check(game.provisions.household_mass(game.state)==75 and game.wagon_cache.mile==old_cache.mile,"Seized frame creates no new household outfit and preserves the old cache")
  check(game.RobberyDemand.stock(game,"fort_bridger").wagon==0,"Seized wagon removed from finite post stock")
  check(not choose(game,"take"),"Cannot collect the same demanded basket twice")
  check(game.crime.Wanted.value_of(game,incident)>=10500,"Stolen frame and livestock count toward restitution and wanted value")
  trip(game,"Collected wagon and goods save")
  var forged: Dictionary=Store.new().capture(game)
  forged.crime.record.incidents[-1].taken_goods.wagon=2
  check(Store.new().restore(forged)==null,"Forged loot exceeding the fixed demand rejects")
  game.crime.scenes.fort_bridger.escape_capture=0
  game.crime.scenes.fort_bridger.escape_injury=0
  check(choose(game,"flee") and choose(game,"finish"),"After seizing goods the party must still escape through the existing crime flow")
  game.crime.Wanted.post_bounties(game.crime,game)
  check(not game.crime.record.reports.is_empty() and not game.crime.record.bounties.is_empty(),"Witnessed wagon robbery can produce a real report and reward posting")
  trip(game,"Wagon robbery bounty and return to stop save")
  if resisted:break
 check(won and resisted,"Seeded sample includes both compliance and resistance")
 game=party(57,true)
 check(not game.robbery_quote({"food":500}).valid,"Foot demands respect actual healthy hauling")
 # An actual emigrant family carries a wagon, not a guaranteed spare team.
 game.pending={}
 game.service_return={}
 game.state.landmark="independence"
 game.state.next_landmark="elm_grove"
 game.state.leg_length=33
 game.state.leg_miles=0
 game.state.miles=0
 game.route_path=["independence"]
 var camp: String=game.crime.camp(game)
 for n in range(30):
  if camp!="":break
  game._tick_day(true)
  camp=game.crime.camp(game)
 if camp!="":
  game.open_crime(camp)
  check(game.RobberyDemand.stock(game,camp).wagon==1,"A real nearby emigrant family can be targeted for its single wagon")
 else:check(false,"Find a camp fixture")
 game=party(57,true)
 for id in range(1,5):
  var profile: Dictionary=game.characters.profiles[id]
  profile.traits=["Cautious","Compassionate"]
  profile.boundaries=game.characters.catalog.boundaries("Compassionate")
  profile.trust=10
 game.party_health.begin_condition(0,"broken_leg",int(game.state.day))
 check(game.provisions.cargo(game.state)<game.provisions.capacity(game.state) and not game.robbery_quote({"food":1}).valid,"Available pack room cannot replace fit, willing criminal helpers")
 check(game.robbery_quote({"cash_cents":100}).valid,"Cash-only demands add no physical hauling")
 var screen=Main.instantiate()
 root.add_child(screen)
 await process_frame
 screen.departure_view.hide()
 screen.game=party(57,true)
 screen._show_service()
 var robbery_index: int=-1
 for i in range(screen.game.pending.choices.size()):
  if screen.game.pending.choices[i].get("crime_command","")=="robbery":robbery_index=i
 var day: int=screen.game.state.day
 screen._service_choice(robbery_index)
 check(screen.robbery_demand_view.visible and screen.game.state.day==day and screen.game.crime.incident().is_empty(),"Rob button opens demand selection without committing a crime")
 screen.robbery_demand_view.quantities.wagon.value=1
 check(screen.robbery_demand_view.last_offer.basket.wagon==1 and screen.robbery_demand_view.quote_label.text.contains("COMPLIANCE"),"Actual demand form includes wagon and live resistance preview")
 screen.robbery_demand_view.hide()
 screen.queue_free()
 await process_frame
 print("Robbery demands: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
