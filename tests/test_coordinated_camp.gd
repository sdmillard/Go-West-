extends "res://tests/coordinated_camp_campaign.gd"
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func party(kind=CampObserved,seed_value: int=5711):
 var g=kind.new(seed_value,"classic",true)
 check(g.depart("banker",["Leader","Anne","Ben","Cara","Dan"],5,{"oxen":4,"horses":1,"saddles":1,"saddlebags":1,"food":500,"clothing":5,"bullet_boxes":5,"medicine":3,"salt":10}),"Fixture departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.survival.data.event_chance=0;g.survival.forced_weather="clear"
 for m in g.party_health.members:m.health=100
 g.state.health=100
 for p in g.characters.profiles:
  if int(p.id)>0:p.trust=80;p.boundaries.forbidden=[]
 return g
func lose_original(g):
 g.party_health.kill(g.party_health.members[0],int(g.state.day),"a test accident")
 g._collect_health_events()
 g.state.party_size=g.party_health.living_count();g.state.health=g.party_health.average_health()
func setup_work(g):
 g.characters.profiles[1].skill="Caregiving"
 g.party_health.members[4].health=45
 g.party_health.begin_condition(4,"dysentery",int(g.state.day),2)
 g.state.health=g.party_health.average_health()
 g.state.food+=g.provisions.add_meat(200,int(g.state.day))
func run():
 adaptive=true;hunting_study=true;camp_policy="coordinated"
 var g=party()
 setup_work(g)
 var plan: Dictionary=plan_jobs(g)
 check(plan.nurse==1 and plan.patient==4 and plan.dryer>=0 and not plan.foragers.is_empty(),"Public roster assigns caregiver, resting patient, drying and forage without double jobs")
 check(g.camp_tasks.patient_nurses(g).has(4) and not g.camp_tasks.assign(g,4,"hunt_help"),"Nursed patient cannot become a worker")
 var before: Dictionary=Store.new().capture(g)
 g.camp_tasks.quote(g)
 check(Store.new().capture(g)==before,"Roster previews do not consume food, materials, time or RNG")
 var food: int=g.state.food;var kits: int=g.state.medicine;var day: int=g.state.day
 check(g.start_hunt({"members":[0],"kit":"ride_horse","bullets":5}),"Leader hunts while assigned companions work")
 g.hunt.meat=60
 check(g.finish_hunt() and g.state.day==day+1,"Hunt and support tasks settle one shared day")
 check(g.state.medicine==kits-1 and g.camp_tasks.audit.care_kits==1 and g.camp_tasks.audit.nursing_visits==1,"Exactly one actual kit buys one nursing visit")
 check(g.camp_tasks.audit.drying_batches==1 and g.camp_tasks.audit.food_retained>0,"Morning meat is actually processed once")
 check(g.camp_tasks.audit.forager_days>=1 and g.forage_audit.shared_calls==1 and g.forage_audit.shared_lb>=2,"Real workers bring measured produce into real inventory")
 check(g.party_health.members[4].health>45,"Patient receives actual care and rest")
 check(g.provisions.eaten_units==15,"Shared work does not create an extra meal or waive the daily meal")
 check(Store.new().restore(JSON.parse_string(JSON.stringify(Store.new().capture(g))))!=null,"Coordinated day remains saveable")
 # Instrumentation never changes the actual engine: same public actions and exact saves.
 var a=party(CampObserved,5712);var b=party(Simulation,5712)
 setup_work(a);setup_work(b)
 for item in [a,b]:
  plan_jobs(item)
  item.start_hunt({"members":[0],"kit":"ride_horse","bullets":5})
  item.hunt.meat=60
  item.finish_hunt()
 check(Store.new().capture(a)==Store.new().capture(b),"Food, work and forage observation preserve exact state and all RNG streams")
 for method in ["foot","lead"]:
  a=party(CampObserved,5713);b=party(Simulation,5713)
  var aa:=RandomNumberGenerator.new();var ab:=RandomNumberGenerator.new();aa.seed=1701;ab.seed=1701
  var ca: Dictionary=count_template();var cb: Dictionary=count_template()
  for step in range(100):
   if a.state.status!="traveling":break
   check(act(a,policy(method),aa,ca)==act(b,policy(method),ab,cb),"Observed coordinated policy preserves public actions")
   if step%10==0:check(Store.new().capture(a)==Store.new().capture(b),"Observed coordinated journey preserves exact saves")
 # A selected weak hunter works instead of receiving camp rest as well.
 g=party();g.party_health.members[1].health=35;g.state.health=g.party_health.average_health()
 g.camp_tasks.assign(g,1,"hunt_help")
 check(g.start_hunt({"members":[0,1],"kit":"foot","bullets":5}),"A willing poor helper retains the accepted partial hauling rule")
 check(not g.camp_tasks.day_plan.rest[1],"Selected helper cannot hunt and receive rest recovery")
 g.hunt.meat=0;g.finish_hunt()
 check(g.party_health.members[1].health<=36,"Weak hunter gets no free rest healing")
 # Camp leadership follows the first survivor rather than a dead slot zero.
 g=party();lose_original(g);g.party_health.members[1].health=60;g.state.health=g.party_health.average_health()
 g.camp_tasks.assign(g,2,"rest")
 check(g.camp_tasks.leader_id(g)==1 and g.forage_offer().available and g.forage_offer().workers>0,"Surviving leader can forage when the roster is enabled")
 check(not g.camp_tasks.assign(g,1,"forage") and not g.field_outings.start(g,1,"foot",1,5),"Current leader cannot also be an assigned worker or away companion")
 check(g.start_hunt({"members":[1],"kit":"ride_horse","bullets":5}) and not g.camp_tasks.day_plan.rest[1],"Successor leader actually works while hunting")
 check(1 not in g.hunt._camp_helpers,"Successor is not counted again as their own helper")
 g.finish_hunt();g.pending={}
 check(g.party_health.members[1].health<=61,"Successor receives no hunting-day rest recovery")
 check(Store.new().restore(JSON.parse_string(JSON.stringify(Store.new().capture(g))))!=null,"Existing deceased-leader saves remain valid without a schema change")
 g=party();lose_original(g);g.party_health.members[1].health=40;g.state.health=g.party_health.average_health()
 g.camp_tasks.assign(g,2,"nurse",1)
 kits=int(g.state.medicine)
 check(g.start_hunt({"members":[1],"kit":"ride_horse","bullets":5}),"Successor can stop being nursed by choosing an activity")
 check(g.camp_tasks.job(2).job=="rest" and not g.camp_tasks.day_plan.rest[1],"Nursing ends for the actual active leader")
 g.finish_hunt()
 check(g.state.medicine==kits,"Canceled successor nursing consumes no kit")
 var screen=Main.instantiate();root.add_child(screen);await process_frame
 screen.game=party();lose_original(screen.game);screen.departure_view.hide()
 screen._show_section("Companion tasks");await process_frame
 check(screen.section_rows.find_child("CampCompanion1",true,false)==null and screen.section_rows.find_child("CampCompanion2",true,false)!=null,"Camp roster excludes the current leader and keeps actual companions")
 screen.section_window.hide()
 screen.outing_window.open(screen.game,-1)
 check(screen.outing_window.actor.get_item_index(1)<0 and not screen.outing_window.helper_checks.has(1),"Outfitter has no duplicate successor companion/helper")
 screen.queue_free();await process_frame
 print("Coordinated camp work: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
