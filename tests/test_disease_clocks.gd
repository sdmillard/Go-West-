extends SceneTree
const Health=preload("res://simulation/party_health.gd")
const Sim=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func health(names: Array=["A","B","C"]):
 var h=Health.new();h.start(names,576200);h.daily_onset_chance=0;h.scurvy={};h.wound_infection.daily_chance=0;return h
func fixture(id: String="smallpox"):
 var g=Sim.new(576200,"classic",true)
 check(g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":1000,"clothing":5,"bullet_boxes":5,"medicine":40}),"Clinical clock fixture departs")
 g.pending={};g.configure(0,2);g.survival.forced_weather="clear";g.survival.data.event_chance=0;g.party_health.daily_onset_chance=0;g.party_health.scurvy={};g.party_health.wound_infection.daily_chance=0
 for definition in g.party_health.conditions.values():definition.spread_chance=0
 g.characters.profiles[3].skill="Caregiving";g.characters.profiles[3].specials=[];g.characters.profiles[3].trust=100
 g.party_health.begin_condition(1,id,0)
 return g
func run():
 for id in ["smallpox","pneumonia","measles"]:
  for policy in ["travel","rest","nurse","caregiver"]:
   var g=fixture(id)
   if policy=="nurse":g.characters.profiles[3].skill="Hunting"
   if policy in ["nurse","caregiver"]:check(g.camp_tasks.assign(g,3,"nurse",1),"Actual nurse assignment for "+id)
   var duration: int=int(g.party_health.conditions[id].recovery_days)
   for day in range(1,duration+1):
    g._tick_day(policy!="travel",policy=="travel","travel" if policy=="travel" else "rest")
    if day<duration:check(g.party_health.members[1].alive and g.party_health.members[1].conditions.any(func(c):return c.id==id and c.elapsed==day),"One calendar step for %s/%s day%d" % [id,policy,day])
   check(g.party_health.members[1].alive and not g.party_health.members[1].conditions.any(func(c):return c.id==id),"Course ends on its calendar day: "+id+"/"+policy)
   if policy in ["nurse","caregiver"]:check(g.state.medicine==40-duration,"Nursing remains a real daily supplied task")
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/health_conditions.json"))
 for mutation in ["calendar","incubation","order","phase"]:
  var invalid: Dictionary=data.duplicate(true)
  for c in invalid.conditions:
   if c.id!="smallpox":continue
   match mutation:
    "calendar":c.calendar_course="yes"
    "incubation":c.incubation_days=[0,14]
    "order":c.incubation_days=[14,10]
    "phase":c.contagious_after_days=-1
  check(not Health.new().load_data(invalid),"Malformed clinical clock data rejected: "+mutation)
 var h=health();h.begin_condition(0,"wound",0);h.begin_condition(0,"wound_infection",0,3)
 var infection: Dictionary=h.members[0].conditions[1]
 h.support_condition(infection,100)
 check(infection.elapsed==0 and infection.severity==2,"Support improves infection severity without skipping its course")
 h.members[0].health=100
 for day in range(1,10):h.tick(day,true)
 check(h.members[0].conditions.any(func(c):return c.id=="wound_infection" and c.elapsed==9),"Rest cannot prematurely clear the infection after its wound heals")
 h.tick(10,true)
 check(not h.members[0].conditions.any(func(c):return c.id=="wound_infection"),"Wound infection completes its own ten-day course")
 var original_random: int=h.rng.state
 h.infection_chance(0,8);h.description(0)
 check(h.rng.state==original_random,"Viewing risk/details does not reroll clinical outcomes")
 h=health();h.begin_condition(1,"broken_arm",0);h.conditions.smallpox.spread_chance=0
 check(h.expose(1,"smallpox",0,1,"A") and not h.expose(1,"smallpox",0),"Injury permits one latent exposure, without duplicates")
 var due: int=int(h.members[1].exposures[0].onset_day)
 check(due>=10 and due<=14 and not "smallpox" in h.description(1).to_lower(),"Incubation uses the configured range without revealing a future diagnosis")
 for day in range(1,due):h.tick(day,false)
 check(not h.members[1].conditions.any(func(c):return c.id=="smallpox") and h.members[1].exposures.size()==1,"No disease damage or active diagnosis before onset")
 h.tick(due,false)
 check(not h.members[1].has("exposures") and h.members[1].conditions.any(func(c):return c.id=="smallpox" and c.started_day==due and c.elapsed==0) and h.members[1].health==85-due,"Onset preserves the injury and does not charge immediate smallpox damage")
 check(h.members[1].history.any(func(s):return "caught smallpox from A" in s),"Onset and source enter individual history")
 h=health();h.conditions.smallpox.spread_chance=1;h.begin_condition(0,"smallpox",0)
 for day in range(1,4):h.tick(day,false)
 check(not h.members[1].has("exposures"),"Smallpox early fever phase does not transmit")
 h.tick(4,false)
 check(h.members[1].get("exposures",[]).size()==1 and h.members[1].conditions.is_empty(),"Rash-phase contact creates a latent exposure")
 h=health();h.conditions.measles.spread_chance=1;h.begin_condition(0,"measles",0);h.begin_condition(1,"broken_leg",0);h.members[2]["immune"]=["measles"];h.tick(1,false)
 check(h.members[1].get("exposures",[]).size()==1 and not h.members[2].has("exposures"),"Injured contacts can be exposed; immune contacts remain protected")
 h=health(["A"]);h.begin_condition(0,"broken_arm",0);h.daily_onset_chance=1
 for definition in h.conditions.values():definition.weight=0
 h.conditions.pneumonia.weight=1;h.tick(1,false)
 check(h.members[0].conditions.any(func(c):return c.id=="pneumonia"),"Spontaneous onset is not blocked by an unrelated injury")
 h=health(["A"]);h.begin_condition(0,"wound",0)
 for day in range(1,12):h.tick(day,false)
 h.wound_infection.daily_chance=.035
 check(h.infection_chance(0,12)>0,"A still-open wound has risk after day7")
 h.tick(12,false)
 check(h.infection_chance(0,13)==0,"Healed wound has no remaining complication risk")
 var g=fixture();g.party_health.begin_condition(2,"broken_arm",0);g.party_health.expose(2,"measles",0,1,"A")
 g._collect_health_events()
 var store=Store.new();var snapshot: Dictionary=store.capture(g);var restored=store.restore(snapshot)
 check(restored!=null and store.capture(restored)==snapshot,"Incubation saves and restores exactly")
 for copy in [g,restored]:
  copy.party_health.daily_onset_chance=0;copy.party_health.scurvy={};copy.party_health.wound_infection.daily_chance=0;copy.survival.forced_weather="clear"
  for definition in copy.party_health.conditions.values():definition.spread_chance=0
 for day in range(1,13):
  g._tick_day(true,false,"rest");restored._tick_day(true,false,"rest")
 check(store.capture(g)==store.capture(restored) and not g.party_health.members[2].has("exposures"),"Saved incubation produces identical future onset and random state")
 g=fixture();g.party_health.begin_condition(2,"broken_arm",0);g.party_health.expose(2,"measles",0,1,"A")
 snapshot=store.capture(g)
 for mutation in ["date","duplicate","condition","severity","source","immune"]:
  var bad: Dictionary=snapshot.duplicate(true)
  match mutation:
   "date":bad.party[2].exposures[0].onset_day=0
   "duplicate":bad.party[2].exposures.append(bad.party[2].exposures[0].duplicate())
   "condition":bad.party[2].exposures[0].id="broken_arm"
   "severity":bad.party[2].exposures[0].severity=4
   "source":bad.party[2].exposures[0].source=5
   "immune":bad.party[2]["immune"]=["measles"]
  check(store.restore(bad)==null,"Malformed latent record rejected: "+mutation)
 check(g.abandon_wagon({"food":20,"clothing":4},[2]),"An exposed traveler can guard an actual wagon")
 snapshot=store.capture(g);check(store.restore(snapshot)!=null,"Guard incubation record round-trips")
 var bad: Dictionary=snapshot.duplicate(true);bad.wagon_cache.guards[0].exposures[0].onset_day=0
 check(store.restore(bad)==null,"Malformed guard exposure is rejected")
 g=fixture();check(g.open_care(),"Direct care is still available")
 var choice: int=-1
 for i in range(g.pending.choices.size()):
  if g.pending.choices[i].get("member_id",-1)==1 and g.pending.choices[i].get("care",0)>0:choice=i;break
 check(choice>=0 and g.choose(choice) and g.party_health.members[1].conditions[0].elapsed==1,"Direct care supports health without skipping the clinical clock")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-disease-clock-save-v1.json"))
 restored=store.restore(old)
 check(restored!=null and restored.state==store.normalize(old.state) and restored.party_health.members==store.normalize(old.party),"Genuine old illness/protection/immunity save keeps earned progress")
 var before: int=int(restored.party_health.members[1].conditions[0].elapsed)
 restored._tick_day(true,false,"rest")
 check(restored.party_health.members[1].conditions[0].elapsed==before+1,"A legacy case continues with one new step per day")
 check(store.restore(store.capture(restored))!=null,"Legacy case remains saveable after its next day")
 print("Disease calendar corrections: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
