extends SceneTree
const Health=preload("res://simulation/party_health.gd")
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func healthy():
 var h=Health.new();h.start(["A","B","C"],574200);h.daily_onset_chance=0;h.scurvy={};return h
func fixture():
 var g=Sim.new(574200,"classic",true)
 check(g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"food":400,"clothing":5,"bullet_boxes":5,"medicine":10}),"Health expansion fixture departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.party_health.scurvy={};g.party_health.wound_infection.daily_chance=0;g.survival.forced_weather="clear";g.survival.data.event_chance=0;g.party_health.begin_condition(1,"wound",0)
 return g
func run():
 var h=healthy()
 check(h.conditions.size()==14 and h.daily_onset_chance==0,"Expanded catalog loads; test onset disabled")
 check(h.automatic_conditions(1848).has("smallpox") and h.automatic_conditions(1848).has("pneumonia") and not h.automatic_conditions(1848).has("wound_infection"),"New diseases fit1848; infection is never a spontaneous illness")
 check(h.onset_weight("smallpox")<h.onset_weight("measles") and h.onset_weight("pneumonia",1)>h.onset_weight("pneumonia",7),"Smallpox is uncommon and pneumonia winter weighted")
 check(not h.begin_condition(0,"wound_infection",0) and h.infection_chance(0,3)==0,"Healthy people cannot acquire wound infection without a wound")
 h.begin_condition(0,"broken_leg",0)
 check(h.infection_chance(0,3)==0,"Closed fracture alone does not imply an infected open wound")
 h.begin_condition(1,"wound",0)
 check(h.infection_chance(1,1)==0 and h.infection_chance(1,8)==0,"Complication risk is restricted to the early healing window")
 var chance: float=h.infection_chance(1,2)
 check(is_equal_approx(chance,.035) and is_equal_approx(h.infection_chance(1,2,true),chance*.5),"Rest reduces the actual chance")
 h.dress_wound(1,2)
 check(is_equal_approx(h.infection_chance(1,2,true),chance*.5*.25) and is_equal_approx(h.infection_chance(1,3),chance),"Care protects only its recorded day and stacks with rest")
 h.wound_infection.daily_chance=1;h.wound_infection.dressed_factor=1;h.tick(2,false)
 check(h.members[1].conditions.any(func(c):return c.id=="wound_infection") and h.infection_chance(1,3)==0,"A real wound can develop one additional infection, not duplicates")
 check(h.members[1].health==80,"New infection adds no extra damage on its onset day")
 check(h.members[1].history.any(func(s):return "wound infection" in s) and "recovery is not guaranteed" in h.description(1),"Complication is visible in individual history and health guidance")
 h.members[1].conditions[0].elapsed=27;h.tick(3,false)
 check(h.members[1].conditions.any(func(c):return c.id=="wound_infection") and not h.members[1].conditions.any(func(c):return c.id=="wound"),"Infection can remain after the original wound heals")
 check(h.members[2].conditions.is_empty(),"Wound infection cannot spread to another traveler")
 h.members[1].health=1;h.tick(4,false)
 check(not h.members[1].alive and h.members[1].cause=="wound infection","Fatal infection records the actual death cause")
 h=healthy();h.conditions.smallpox.spread_chance=1;h.begin_condition(0,"smallpox",0);h.tick(1,false)
 check(h.members[1].conditions[0].id=="smallpox" and h.members[1].conditions[0].elapsed==0,"Smallpox spreads through existing contagion without same-day damage for new cases")
 h.members[0].conditions[0].elapsed=18;h.tick(2,true)
 check("smallpox" in h.members[0].get("immune",[]) and not h.begin_condition(0,"smallpox",3),"Recovered smallpox leaves saved immunity")
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/health_conditions.json"))
 for change in [["source","broken_leg"],["min_days",-1],["max_days",1],["daily_chance",2],["dressed_factor","yes"]]:
  var bad: Dictionary=data.duplicate(true);bad.wound_infection[change[0]]=change[1]
  check(not h.load_data(bad) and h.conditions.is_empty() and h.wound_infection.is_empty(),"Malformed infection rule rejected: "+change[0])
 var g=fixture()
 check(g.rest(),"Wound advances to the complication window")
 g.pending={}
 g.party_health.wound_infection.daily_chance=1;g.party_health.wound_infection.rest_factor=1;g.party_health.wound_infection.dressed_factor=0
 check(g.camp_tasks.assign(g,3,"nurse",1) and g.rest() and not g.party_health.members[1].conditions.any(func(c):return c.id=="wound_infection"),"Reserved nursing protects before the day's infection roll")
 g=fixture();g.rest();g.pending={};g.camp_tasks.assign(g,3,"nurse",1);g.state.medicine=0
 g.party_health.wound_infection.daily_chance=1;g.party_health.wound_infection.rest_factor=1;g.party_health.wound_infection.dressed_factor=0
 check(g.rest() and g.party_health.members[1].conditions.any(func(c):return c.id=="wound_infection"),"An unsupplied nursing order cannot grant free wound protection")
 g=fixture();g.party_health.dress_wound(1,1);g.party_health.begin_condition(1,"wound_infection",0);g.party_health.members[2]["immune"]=["smallpox"]
 var snapshot: Dictionary=Save.new().capture(g);var restored=Save.new().restore(snapshot)
 check(restored!=null and Save.new().capture(restored)==snapshot,"Dressing state round-trips exactly")
 var bad: Dictionary=snapshot.duplicate(true);bad.party[1].conditions[0].dressed_until_day=9999
 check(Save.new().restore(bad)==null,"Save cannot grant indefinite future wound protection")
 bad=snapshot.duplicate(true);bad.party[1].conditions[0].id="broken_arm"
 check(Save.new().restore(bad)==null,"Dressing metadata is rejected on an unrelated condition")
 g=fixture();check(g.camp_tasks.assign(g,3,"nurse",1) and g.rest(),"Actual nursing consumes a day")
 check(g.party_health.members[1].conditions[0].dressed_until_day==g.state.day and g.state.medicine==9,"Only actual supplied nursing dresses a wound for that day's risk roll")
 g=fixture();check(g.open_care(),"Existing care menu opens")
 var selected: int=-1
 for i in range(g.pending.choices.size()):
  if g.pending.choices[i].get("member_id",-1)==1 and g.pending.choices[i].get("care",0)>0:selected=i;break
 check(selected>=0 and g.choose(selected) and g.party_health.members[1].conditions[0].dressed_until_day==g.state.day,"Direct paid/kit care dresses the wound through its care day")
 g=fixture();g.party_health.dress_wound(1,1)
 check(g.abandon_wagon({"food":20,"clothing":4,"bullets":10},[1]),"Dressed traveler can remain as an actual wagon guard")
 snapshot=Save.new().capture(g)
 check(Save.new().restore(snapshot)!=null,"Cached guard retains valid short-lived dressing state")
 bad=snapshot.duplicate(true);bad.wagon_cache.guards[0].conditions[0].dressed_until_day=9999
 check(Save.new().restore(bad)==null,"Cached guard cannot smuggle indefinite wound protection")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-infection-save-v1.json"))
 restored=Save.new().restore(old)
 check(restored!=null and restored.state==Save.new().normalize(old.state) and restored.party_health.members==Save.new().normalize(old.party) and restored.characters.profiles==Save.new().normalize(old.characters),"Genuine earlier wound/immunity save preserves its state and profiles")
 print("Infectious disease expansion: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
