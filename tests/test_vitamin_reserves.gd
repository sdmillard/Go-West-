extends SceneTree
const Health=preload("res://simulation/party_health.gd")
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func model():
 var h=Health.new();h.start(["A","B"],137);h.daily_onset_chance=0
 return h
func run():
 var h=model();var random_state=h.rng.state
 for day in range(45):h.feed_vitamins(0)
 check(h.members[0].vitamin_debt_milli==45000 and h.scurvy_chance(45)==0,"Empty diet retains the existing onset grace period")
 h.feed_vitamins(0)
 check(h.members[0].vitamin_debt_milli==46000 and h.scurvy_chance(46)>0,"Sustained depletion reaches existing onset risk")
 h.feed_vitamins(1)
 check(h.members[0].vitamin_debt_milli==45000 and h.days_without_fresh==45,"One good meal restores one day instead of erasing deficiency")
 check(h.rng.state==random_state,"Reserve accounting draws no randomness")
 h=model()
 for day in range(20):h.feed_vitamins(0.25)
 check(h.members[0].vitamin_debt_milli==10000,"Quarter servings halve depletion")
 for day in range(20):h.feed_vitamins(0.5)
 check(h.members[0].vitamin_debt_milli==10000,"Half a replenishing portion maintains the reserve")
 for day in range(10):h.feed_vitamins(1)
 check(h.members[0].vitamin_debt_milli==0,"Repeated adequate meals replenish gradually")
 h.feed_vitamins(5)
 check(h.members[0].vitamin_debt_milli==0,"Excess meals cannot bank an unlimited reserve")
 h=model();h.feed_vitamins(0.001)
 check(h.members[0].vitamin_debt_milli==998,"Small partial coverage is retained below whole-day precision")
 h.members[0].vitamin_debt_milli=30000;h.members[0].vitamin_days=30
 h.members[1].vitamin_debt_milli=10000;h.members[1].vitamin_days=10;h.members[1]["away"]=true
 h.feed_vitamins(1)
 check(h.members[0].vitamin_debt_milli==29000 and h.members[1].vitamin_debt_milli==10000,"An absent companion cannot share the main camp's produce")
 h.members[1].away=false;h.feed_vitamins(0)
 check(h.members[0].vitamin_debt_milli==30000 and h.members[1].vitamin_debt_milli==11000,"Returning companions retain distinct personal reserves")
 h.members[0].vitamin_debt_milli=60000;h.members[0].vitamin_days=60;h.members[1].vitamin_debt_milli=0;h.members[1].vitamin_days=0
 h.scurvy.base_chance=1.0;h.scurvy.max_chance=1.0;h._deficiency(61,2,0)
 check(h.members[0].conditions.size()==1 and h.members[1].conditions.is_empty(),"Onset uses individual reserves even when the aggregate fallback is zero")
 var g=Sim.new(137,"classic",true)
 check(g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":300,"clothing":5,"dried_produce":2}),"Actual shared-meal fixture departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.survival.forced_weather="clear";g.party_health.days_without_fresh=20
 check(g.rest_in_camp(),"Actual partial shared meal settles")
 check(g.party_health.members.all(func(m):return m.vitamin_debt_milli==19400),"Two dried baskets for five travelers reduce old deficiency by six tenths of a day")
 var store=Save.new();var snapshot: Dictionary=store.capture(g);var loaded=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
 check(loaded!=null and store.capture(loaded)==snapshot,"Personal fractional reserves survive exact save/load")
 for invalid in [-1,0.5,100000001,"100",NAN,INF]:
  var bad: Dictionary=snapshot.duplicate(true);bad.party[0].vitamin_debt_milli=invalid
  check(store.restore(bad)==null,"Invalid personal reserve rejects")
 var old: Dictionary=snapshot.duplicate(true)
 old.days_without_fresh=30
 for m in old.party:m.erase("vitamin_debt_milli");m.erase("vitamin_days")
 old.party[0]["vitamin_days"]=40
 loaded=store.restore(old)
 check(loaded!=null,"Older aggregate and individual deficiency saves load")
 loaded.party_health.feed_vitamins(1)
 check(loaded.party_health.members[0].vitamin_debt_milli==39000 and loaded.party_health.members[1].vitamin_debt_milli==29000,"Legacy initialization preserves prior individual deficiency without a reset")
 loaded.party_health.members[0].vitamin_debt_milli=40000
 check(loaded.party_health.description(0).contains("Vitamin reserve: LOW"),"Personal health details expose low reserves")
 g.pending={};g.state.bullets=20
 g.field_outings.rules.mishap_chance=0;g.field_outings.rules.bandit_daily_chance=0
 check(g.field_outings.start(g,1,"foot",1,1),"Companion leaves with their own reserve and packed meal")
 var trip: Dictionary=g.field_outings.record.trips[0]
 check(trip.camp.guards[0].vitamin_debt_milli==19400,"Detached camp starts with the companion's exact fractional reserve")
 g.state.food+=g.provisions.add_produce(4,int(g.state.day))
 check(g.rest_in_camp(),"Main party and detached camp each settle a real day")
 check(g.party_health.members[0].vitamin_debt_milli==18400,"Main party's produce replenishes its own reserve")
 check(trip.camp.guards[0].vitamin_debt_milli==20400,"Outrider's packed staple meal cannot borrow the main party's vitamins")
 var guarded: Dictionary=trip.camp.duplicate(true);guarded.guards[0].vitamin_debt_milli=-1
 check(not g.Guards.valid(guarded,g,int(g.state.day)),"Detached camp rejects a malformed personal reserve")
 print("Vitamin reserves: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
