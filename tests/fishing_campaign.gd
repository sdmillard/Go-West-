extends "res://tests/mobile_camp_campaign.gd"
## Compare the existing mobile strategy with bounded leader or shared-stop fishing.
var fishing_policy: String="off"
func make_study_game(seed_value: int):return preload("res://tests/fishing_audit_observer.gd").new(seed_value,"classic",true)
func extra_settings() -> Dictionary:
 var result: Dictionary=super.extra_settings()
 result.merge({"fishing_policy":fishing_policy,"fishing_policy_version":1,"fishing_hook_accuracy":player_accuracy,"fishing_repeat_rule":"One leader attempt per named river per journey. Support fishing adds no new camp stop."})
 return result
func count_template() -> Dictionary:
 var result: Dictionary=super.count_template()
 result.merge({"fished_sites":[],"fishing_access_walk_days":0,"fishing_access_horse_only_days":0,"fishing_water_but_no_horse_days":0,"fishing_access_day":-1,"fishing_blocked_weather_days":0})
 return result
func extra_row(game,count: Dictionary) -> Dictionary:
 var row: Dictionary=super.extra_row(game,count)
 row.fishing={"leader":game.fishing_days.duplicate(true),"companions":game.fishing.returns.duplicate(true)}
 return row
func plan_jobs(game) -> Dictionary:
 var result: Dictionary=super.plan_jobs(game)
 if fishing_policy!="support" or not game.fishing_offer().walk:return result
 var meal: int=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])
 if game.state.food>=meal*6:return result
 # Protect the existing nurse, patient, dryers and foragers; replace one hunt helper.
 var helpers: Array=workers(game).filter(func(id):return game.camp_tasks.job(id).job=="hunt_help")
 var fisher: int=choose_worker(game,helpers,"fish")
 if fisher>=0:game.camp_tasks.assign(game,fisher,"fish")
 return result
func try_fishing(game,p: Dictionary,count: Dictionary) -> bool:
 if fishing_policy!="leader" or not game.can_service():return false
 var water: Dictionary=game.fishing_offer()
 if not water.visible or water.site in count.fished_sites:return false
 var kit: String="foot" if water.walk else "ride_horse_light"
 if not game.fishing_quote(kit).get("valid",false):return false
 if not game.start_fishing(kit):return false
 count.fished_sites.append(water.site)
 bump(count,"leader_fishing_days")
 var reactions:=RandomNumberGenerator.new()
 reactions.seed=int(game.state.seed)^0x46495348^int(game.hunting_outings)*7919
 var reacted: int=-1
 for step in range(400):
  if game.hunt.ended:break
  if game.hunt.phase=="ready":game.fishing_click()
  elif game.hunt.phase=="bite" and reacted!=int(game.hunt.cast):
   reacted=int(game.hunt.cast)
   if reactions.randf()<float(p.accuracy):game.fishing_click()
  game.advance_fishing(0.1)
 return game.finish_fishing()
func hunt_outing(game,p: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 if try_fishing(game,p,count):return true
 return super.hunt_outing(game,p,aim,count)
func baseline_act(game,p: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 return super.act(game,p,aim,count)
func act(game,p: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 if game.can_service() and int(count.fishing_access_day)!=int(game.state.day):
  count.fishing_access_day=int(game.state.day)
  var water: Dictionary=game.fishing_offer()
  if str(game.survival.weather.id) in ["blizzard","snow","thunderstorm"]:bump(count,"fishing_blocked_weather_days")
  elif water.walk:bump(count,"fishing_access_walk_days")
  elif water.horse:bump(count,"fishing_access_horse_only_days")
  elif is_finite(float(water.distance)) and water.distance<=game.fishing.data.horse_radius:bump(count,"fishing_water_but_no_horse_days")
 if fishing_policy=="leader" and game.can_service() and game.pending.has("landmark"):
  var ration: int=2 if game.party_health.members.any(func(m):return game.party_health.is_active(m) and (int(m.health)<80 or not m.conditions.is_empty())) else int(p.rations)
  game.configure(int(p.pace),ration)
  var meal: int=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])
  if game.state.food<meal*2:
   plan_jobs(game)
   if try_fishing(game,p,count):return true
 return super.act(game,p,aim,count)
func run():
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--fishing="):fishing_policy=argument.get_slice("=",1)
 if fishing_policy not in ["off","leader","support"]:printerr("Invalid fishing policy");quit(1);return
 motion_policy="mobile"
 await super.run()
