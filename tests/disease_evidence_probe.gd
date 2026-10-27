extends SceneTree
## Diagnostic benchmarks of released rules, not clinical calibration or journeys.
const Sim=preload("res://simulation/trail_engine.gd")
const Health=preload("res://simulation/party_health.gd")
const Store=preload("res://simulation/save_store.gd")
var errors: Array=[]
func _initialize():call_deferred("run")
func fixture(id: String,severity: int,policy: String):
 var g=Sim.new(575100,"classic",true)
 if not g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":1000,"clothing":5,"bullet_boxes":5,"medicine":40}):errors.append(g.departure_error)
 g.pending={};g.configure(0,2);g.survival.forced_weather="clear";g.survival.data.event_chance=0;g.party_health.daily_onset_chance=0;g.party_health.scurvy={};g.party_health.wound_infection.daily_chance=0
 for definition in g.party_health.conditions.values():definition.spread_chance=0
 g.characters.profiles[3].skill="Caregiving" if policy=="caregiver" else "Hunting"
 g.characters.profiles[3].specials=[];g.characters.profiles[3].trust=100
 if not g.party_health.begin_condition(1,id,0,severity):errors.append("Cannot seed diagnostic condition")
 if policy in ["nurse","caregiver"] and not g.camp_tasks.assign(g,3,"nurse",1):errors.append("Cannot assign diagnostic nurse")
 return g
func course(id: String,severity: int,policy: String) -> Dictionary:
 var g=fixture(id,severity,policy);var trace: Array=[]
 for day in range(1,41):
  if not g.party_health.members[1].alive or not g.party_health.members[1].conditions.any(func(c):return c.id==id):break
  g._tick_day(policy!="travel",policy=="travel","travel" if policy=="travel" else "rest")
  var m: Dictionary=g.party_health.members[1]
  trace.append({"day":g.state.day,"health":m.health,"conditions":m.conditions.duplicate(true)})
  if not g.error.is_empty() or g.state.money<0 or g.state.food<0:errors.append("Diagnostic invariant failed")
 var m: Dictionary=g.party_health.members[1]
 return {"condition":id,"severity":severity,"policy":policy,"calendar_days":g.state.day,"outcome":"recovered" if m.alive and not m.conditions.any(func(c):return c.id==id) else ("dead" if not m.alive else "limit"),"terminal_health":m.health,"kits_spent":40-int(g.state.medicine),"trace":trace}
func run():
 var path: String="res://.tools/disease-evidence-probe-02.json"
 if FileAccess.file_exists(path):printerr("Refusing to overwrite audit evidence");quit(1);return
 var rows: Array=[]
 for id in ["smallpox","pneumonia","measles"]:
  for severity in [1,2,3]:
   for policy in ["travel","rest","nurse","caregiver"]:rows.append(course(id,severity,policy))
 var h=Health.new();h.start(["Source","Wounded","Well"],575100);h.daily_onset_chance=0;h.scurvy={};h.conditions.smallpox.spread_chance=1
 h.begin_condition(0,"smallpox",0);h.begin_condition(1,"broken_arm",0);h.tick(1,false)
 var shield: Dictionary={"wounded_caught":h.members[1].conditions.any(func(c):return c.id=="smallpox"),"healthy_caught":h.members[2].conditions.any(func(c):return c.id=="smallpox"),"forced_spread":1.0}
 h=Health.new();h.start(["A"],575100);h.daily_onset_chance=0;h.scurvy={};h.begin_condition(0,"wound",0)
 var window: Array=[]
 for day in range(1,12):
  if day in [1,2,7,8,11]:window.append({"day":day,"wound_still_present":not h.members[0].conditions.is_empty(),"elapsed_before_tick":h.members[0].conditions[0].elapsed,"risk":h.infection_chance(0,day)})
  h.wound_infection.daily_chance=0;h.tick(day,false);h.wound_infection.daily_chance=.035
 var source_hashes: Dictionary={}
 for file in ["simulation/party_health.gd","simulation/camp_tasks.gd","simulation/trail_engine.gd","data/health_conditions.json","data/camp_tasks.json","data/party_benefits.json","data/survival_rules.json","tests/disease_evidence_probe.gd"]:source_hashes[file]=FileAccess.get_sha256("res://"+file)
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"production_base":"3a9db2c6a4cdc00425ac265a212346b9b6918b71","rules":Store.new().fingerprint(),"source_hashes":source_hashes,"fixture":"Five healthy85 travelers, day0 May1848, filling rations, steady pace, supplied care; no other illness, contagion or complications in course runs; actual daily engine/camp tasks, no journey miles.","courses":rows,"injury_shield":shield,"open_wound_risk":window,"errors":errors},"\t"))
 print("Disease evidence diagnostics: %d courses, %d errors" % [rows.size(),errors.size()]);quit(1 if not errors.is_empty() else 0)
