extends "res://tests/dairy_balance_campaign.gd"
const Trade=preload("res://tests/farmer_mastery_trade.gd")
var mastery: String="baseline"
func make_study_game(seed_value: int):
 var game=super.make_study_game(seed_value)
 game.provisions=preload("res://tests/farmer_mastery_food.gd").new();game.provisions.carriers=game.party_health.members
 return game
func extra_row(game,count: Dictionary) -> Dictionary:
 var row: Dictionary=super.extra_row(game,count)
 row["preservation_audit"]=game.provisions.preservation_audit.duplicate(true)
 return row
func policy(method: String) -> Dictionary:
 var p: Dictionary=super.policy(method)
 if mastery!="baseline":p.adaptive_rations=false
 return p
func ration(game) -> int:
 var normal: int=int(game.state.party_size)*2
 var carried: float=game.state.food+game.livestock.available_kcal()/1000.0
 var serious: bool=game.party_health.members.any(func(m):return game.party_health.is_active(m) and (int(m.health)<50 or m.conditions.any(func(c):return int(c.severity)>=2)))
 # Use good rations while well supplied; economy alone is not mastery.
 var fresh: int=game.provisions.fresh.filter(func(b):return not b.get("preserved",false) and not b.get("vitamin_c",false)).reduce(func(n,b):return n+int(b.pounds),0)
 if mastery=="skilled" and (carried>=int(game.state.party_size)*3*12 or fresh>=int(game.state.party_size)*6):return 2
 return 2 if serious and carried>=normal*8 else 1
func counter_visit(game,p: Dictionary,count: Dictionary,fundraising: bool=false) -> bool:
 if mastery!="skilled" or fundraising:return super.counter_visit(game,p,count,fundraising)
 if Trade.buy(self,game,p,count):return true
 return buy_fodder(game,count)
func plan_jobs(game) -> Dictionary:
 var plan: Dictionary=super.plan_jobs(game)
 if mastery!="skilled" or int(plan.dryer)>=0:return plan
 var raw: Array=game.provisions.fresh.filter(func(b):return not b.get("preserved",false) and not b.get("vitamin_c",false))
 if not raw.any(func(b):return int(b.expires)<=int(game.state.day)+2):return plan
 var salted: bool=not game.preservation_offer(true,true).is_empty()
 var offer: Dictionary=game.preservation_offer(salted,true)
 if offer.is_empty() or int(offer.input)<maxi(2,int(game.state.party_size)):return plan
 var free: Array=workers(game).filter(func(id):return id not in chore_reserved and id not in plan.foragers and id!=plan.patient and game.camp_tasks.job(id).job in ["rest","hunt_help"])
 plan.dryer=give(game,free,"salt_dry" if salted else "dry")
 return plan
func act(game,p: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 if mastery=="baseline":return super.act(game,p,aim,count)
 var current: Dictionary=p.duplicate(true);current.adaptive_rations=false;current.rations=ration(game)
 if mastery=="skilled":current.hunt_while_away=true;current.forage_gap=10
 game.configure(int(current.pace),int(current.rations))
 if mastery=="skilled" and game.can_service() and game.pending.is_empty():
  plan_jobs(game)
  var meal: int=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])
  if game.field_outings.record.trips.is_empty() and game.state.food>=meal*3 and game.Mounts.condition(game.state)>=65:
   if dispatch_proactive(game,count):bump(count,"expert_early_dispatches");return true
  # Preserve a meaningful surviving surplus, after the quoted day's meals, before it expires.
  var raw: Array=game.provisions.fresh.filter(func(b):return not b.get("preserved",false) and not b.get("vitamin_c",false))
  var salted: bool=not game.preservation_offer(true).is_empty()
  var offer: Dictionary=game.preservation_offer(salted)
  if not offer.is_empty() and int(offer.input)>=meal and raw.any(func(b):return int(b.expires)<=int(game.state.day)+2):
   bump(count,"expert_preservations")
   return game.preserve_meat(salted)
 var previous_reserve: int=reserve_meals
 if mastery=="skilled":reserve_meals=4
 var okay: bool=super.act(game,current,aim,count)
 reserve_meals=previous_reserve
 return okay
func hunt_outing(game,p: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 if mastery=="skilled" and game.state.vehicle=="wagon":
  var members: Array=game.party_health.members.filter(func(m):return game.party_health.is_active(m)).map(func(m):return int(m.id))
  var quote: Dictionary=game.hunt_outfit_quote(members,"wagon",5)
  if quote.get("valid",false):
   var current: Dictionary=p.duplicate(true);current.method="wagon"
   return super.hunt_outing(game,current,aim,count)
 return super.hunt_outing(game,p,aim,count)
func extra_settings() -> Dictionary:
 var settings: Dictionary=super.extra_settings()
 settings["farmer_mastery"]=mastery;settings["mastery_policy_version"]=1
 return settings
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--mastery="):mastery=arg.get_slice("=",1)
 if mastery not in ["baseline","rations","skilled"]:printerr("Invalid mastery candidate");quit(1);return
 await super.run()
