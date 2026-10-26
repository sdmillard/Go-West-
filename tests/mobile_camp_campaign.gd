extends "res://tests/coordinated_camp_campaign.gd"
var motion_policy: String="serial"
func make_study_game(seed_value: int):return preload("res://tests/mobile_camp_observer.gd").new(seed_value,"classic",true)
func extra_settings() -> Dictionary:
 return {"camp_work_policy":camp_policy,"camp_policy_version":1,"motion_policy":motion_policy,"motion_policy_version":1}
func extra_row(game,count: Dictionary) -> Dictionary:
 var row: Dictionary=super.extra_row(game,count)
 row.motion=game.motion.duplicate(true)
 return row
func counter_visit(game,profile: Dictionary,count: Dictionary,fundraising: bool=false) -> bool:
 var current: Dictionary=profile.duplicate(true)
 var meal: int=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])
 if motion_policy=="mobile" and not fundraising and not game.field_outings.record.trips.is_empty() and game.state.food>=meal*2:
  current.opportunity=0;current.post_food=0;current.road_food=0
 return super.counter_visit(game,current,count,fundraising)
func _try_care(game,count: Dictionary,threshold: int=55) -> bool:
 if motion_policy!="serial" and not game.camp_tasks.patient_nurses(game).is_empty():return false
 return super._try_care(game,count,threshold)
func dispatch_proactive(game,count: Dictionary) -> bool:
 if not game.field_outings.record.trips.is_empty():return false
 var candidates: Array=workers(game).filter(func(id):return not game.camp_tasks.patient_nurses(game).has(id) and game.party_health.members[id].health>=60 and not game.party_health.members[id].conditions.any(func(c):return c.severity>=2))
 candidates.sort_custom(func(a,b):return float(game.party_health.members[a].health)+(20 if game.camp_tasks.specialist(game,a,"Hunting") else 0)>float(game.party_health.members[b].health)+(20 if game.camp_tasks.specialist(game,b,"Hunting") else 0))
 for id in candidates:
  if game.field_outings.start(game,id,"ride_horse",1,5,"ride"):
   bump(count,"dispatches");bump(count,"proactive_dispatches");return true
 return false
func act(game,p: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 if motion_policy=="serial" or not game.can_service():return super.act(game,p,aim,count)
 var ration: int=2 if p.get("adaptive_rations",true) and game.party_health.members.any(func(m):return game.party_health.is_active(m) and (int(m.health)<80 or not m.conditions.is_empty())) else int(p.rations)
 game.configure(int(p.pace),ration)
 var plan: Dictionary=plan_jobs(game)
 var meal: int=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])
 if motion_policy=="mobile" and game.pending.is_empty() and int(game.state.food)<=meal*6 and int(game.state.food)>=meal*2 and game.forage_offer().factor>0:
  if dispatch_proactive(game,count):return true
 var current: Dictionary=p.duplicate(true)
 var away: bool=not game.field_outings.record.trips.is_empty()
 if motion_policy=="mobile" and away and not p.get("hunt_while_away",false) and int(game.state.food)>=meal:
  current.hunt=false;current.slaughter=false
 var hunt_due: bool=bool(current.hunt) and int(game.state.food)<meal*reserve_meals and game.state.bullets>0
 var worst: int=100
 for person in game.party_health.members:
  if game.party_health.is_active(person):worst=mini(worst,int(person.health))
 var health_stop: bool=worst<int(p.rest_below) or game.state.fatigue>50 or (game.state.vehicle!="foot" and game.state.ox_health<65)
 var forage_due: bool=produce_held(game)==0 and (has_scurvy(game) or game.party_health.days_without_fresh>=int(p.forage_gap)) and game.state.day-int(count.get("last_forage",-100))>=(2 if has_scurvy(game) else 4) and game.forage_offer().available
 # Do not make a separate leader forage/drying action when reserved workers
 # can do it during a hunt or a necessary health stop.
 if not plan.foragers.is_empty() and (hunt_due or health_stop):current.produce=false
 var raw: Array=game.provisions.fresh.filter(func(b):return not b.get("preserved",false) and not b.get("vitamin_c",false))
 var meat: int=raw.reduce(func(n,b):return n+int(b.pounds),0)
 var expires_soon: bool=raw.any(func(b):return int(b.expires)<=int(game.state.day)+2)
 if not expires_soon or meat<=meal*2 or (plan.dryer>=0 and (hunt_due or health_stop or forage_due)):
  current.preserve=""
 return super.act(game,current,aim,count)
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--motion="):motion_policy=arg.get_slice("=",1)
 if motion_policy not in ["serial","parallel","mobile"]:printerr("Invalid motion policy");quit(1);return
 camp_policy="off" if motion_policy=="serial" else "support"
 await super.run()
