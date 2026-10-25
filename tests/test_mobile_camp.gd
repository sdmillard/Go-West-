extends "res://tests/mobile_camp_campaign.gd"
var checks:=0
var failures:=0
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func party(kind=preload("res://tests/mobile_camp_observer.gd"),seed_value: int=6740):
 var g=kind.new(seed_value,"classic",true)
 check(g.depart("banker",["Leader","Anne","Ben","Cara","Dan"],5,{"oxen":4,"horses":1,"saddles":1,"saddlebags":1,"food":500,"clothing":5,"bullet_boxes":5,"medicine":3,"salt":10}),"Fixture departs")
 g.pending={};g.state.next_landmark="elm_grove";g.state.leg_miles=1;g.state.leg_length=20;g.state.miles=1
 g.party_health.daily_onset_chance=0;g.survival.data.event_chance=0;g.survival.forced_weather="clear"
 for m in g.party_health.members:m.health=100
 g.state.health=100
 for p in g.characters.profiles:
  if int(p.id)>0:p.trust=80;p.boundaries.forbidden=[]
 return g
func run():
 adaptive=true;hunting_study=true;camp_policy="support";motion_policy="mobile"
 var g=party()
 g.state.food=60
 var counts: Dictionary=count_template()
 var aim:=RandomNumberGenerator.new();aim.seed=54
 var day: int=int(g.state.day)
 check(act(g,policy("foot"),aim,counts) and g.field_outings.record.trips.size()==1,"Mobile policy sends a mounted hunter before starvation")
 check(g.state.day==day and int(counts.get("proactive_dispatches",0))==1,"Dispatch itself does not charge a waiting day")
 var mile: int=int(g.state.miles)
 var okay:=true
 for step in range(20):
  if int(g.state.day)>day:break
  okay=okay and act(g,policy("foot"),aim,counts)
 check(okay and g.state.miles>mile,"Wagon travels while the dispatched hunter works")
 check(g.motion.away_travel_days==1 and g.motion.stationary_days==0,"Observation distinguishes actual moving support from camp time")
 check(g.motion.distance_progress_days==1 and g.motion.actions.get("travel",0)==1,"Distance progress is recorded separately from attempted travel")
 motion_policy="parallel"
 g=party();g.party_health.members[4].health=45;g.party_health.begin_condition(4,"dysentery",int(g.state.day),2)
 g.state.health=g.party_health.average_health();g.state.food+=g.provisions.add_meat(200,int(g.state.day))
 counts=count_template()
 check(act(g,policy("foot"),aim,counts),"Necessary health stop succeeds")
 check(g.motion.actions.get("rest",0)==1 and g.motion.actions.get("dry",0)==0,"Worker drying is combined with the health stop, not a separate drying day")
 check(g.camp_tasks.audit.nursing_visits==1 and g.camp_tasks.audit.drying_batches==1 and g.camp_tasks.audit.forager_days>0,"Nursing, drying and foraging actually settle together")
 check(g.motion.multi_job_days==1,"Parallel day requires executed work rather than merely assigned jobs")
 for mode in ["parallel","mobile"]:
  motion_policy=mode
  var a=party(preload("res://tests/mobile_camp_observer.gd"),6741)
  var b=party(Simulation,6741)
  var ca: Dictionary=count_template();var cb: Dictionary=count_template()
  var ra:=RandomNumberGenerator.new();var rb:=RandomNumberGenerator.new();ra.seed=66;rb.seed=66
  for step in range(100):
   if a.state.status!="traveling":break
   check(act(a,policy("foot"),ra,ca)==act(b,policy("foot"),rb,cb),"Motion observer preserves public decisions")
   if step%10==0:check(Store.new().capture(a)==Store.new().capture(b),"Motion observer preserves exact state and RNG")
 print("Mobile camp comparison: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
