extends "res://tests/fishing_campaign.gd"
var checks:=0
var failures:=0
func check(ok: bool,text: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+text)
func party(kind):
 var g=kind.new(290101,"classic",true)
 g.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"horses":1,"saddles":1,"saddlebags":1,"food":100,"clothing":5,"bullet_boxes":5,"salt":5})
 g.pending={};g.state.landmark="elm_grove";g.state.next_landmark="wakarusa";g.state.leg_length=20;g.state.leg_miles=20;g.state.miles=53
 g.party_health.daily_onset_chance=0.0;g.survival.forced_weather="clear"
 return g
func run():
 adaptive=true;hunting_study=true;motion_policy="mobile";camp_policy="support"
 var a=party(preload("res://simulation/trail_engine.gd"))
 var b=party(preload("res://tests/fishing_audit_observer.gd"))
 for game in [a,b]:
  check(game.start_fishing("foot"),"Actual fishing launches")
  while not game.hunt.ended:
   if game.hunt.phase in ["ready","bite"]:game.fishing_click()
   game.advance_fishing(0.1)
  check(game.finish_fishing(),"Actual fishing settles")
 check(Store.new().capture(a)==Store.new().capture(b),"Observer preserves exact catch, state, saves and random streams")
 check(b.fishing_days.size()==1 and b.fishing_days[0].day_end==b.fishing_days[0].day+1,"Observation records the real one-day cost")
 check(b.fishing_days[0].bullets_delta==0 and b.fishing_days[0].miles_delta==0,"Fishing uses no ammunition or road progress")
 check(b.fishing_days[0].caught_edible_lb>=b.fishing_days[0].retrieved,"Retrieval never exceeds caught physical fish")
 a=party(preload("res://simulation/trail_engine.gd"));b=party(preload("res://tests/fishing_audit_observer.gd"))
 for game in [a,b]:
  check(game.camp_tasks.assign(game,1,"fish") and game.rest_in_camp(),"Companion fishes through real camp work")
 check(Store.new().capture(a)==Store.new().capture(b),"Companion observer preserves exact simulation")
 check(b.fishing.returns.size()==1 and b.fishing.returns[0].food>=0,"Companion observation records actual returned food")
 var c: Dictionary=count_template();var aim:=RandomNumberGenerator.new();aim.seed=19
 fishing_policy="leader";b=party(preload("res://tests/fishing_audit_observer.gd"))
 check(try_fishing(b,policy("foot"),c),"Leader policy uses visible bite states")
 b.pending={}
 check(not try_fishing(b,policy("foot"),c) and b.state.day==1,"One-river rule prevents endless fishing stops")
 fishing_policy="support";b=party(preload("res://tests/fishing_audit_observer.gd"));b.state.food=40
 plan_jobs(b)
 check(b.camp_tasks.assignments.values().any(func(j):return j.job=="fish"),"Support plan assigns one actual fisher")
 fishing_policy="off";b=party(preload("res://tests/fishing_audit_observer.gd"));b.state.food=40
 plan_jobs(b)
 check(not b.camp_tasks.assignments.values().any(func(j):return j.job=="fish"),"Baseline plan does not fish")
 a=party(preload("res://tests/mobile_camp_observer.gd"));b=party(preload("res://tests/fishing_audit_observer.gd"))
 var ca: Dictionary=count_template();var cb: Dictionary=count_template()
 var ra:=RandomNumberGenerator.new();var rb:=RandomNumberGenerator.new()
 ra.seed=91;rb.seed=91
 for step in range(15):
  check(baseline_act(a,policy("foot"),ra,ca)==act(b,policy("foot"),rb,cb),"Off policy preserves baseline public decisions")
  check(Store.new().capture(a)==Store.new().capture(b),"Off policy and instrumentation preserve baseline state and RNG")
 print("Fishing audit: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
