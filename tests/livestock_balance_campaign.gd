extends "res://tests/fishing_campaign.gd"
## Matched outfits and two declared decision policies. No simulation rule changes.
const ARMS=["none","goats","cow","hens","mixed"]
var livestock_arm: String="none"
var stock_policy: String="existing"
var chore_reserved: Array=[]
func make_study_game(seed_value: int):return preload("res://tests/livestock_balance_observer.gd").new(seed_value,"classic",true)
func starting_cart(game,method: String,equipment: String) -> Dictionary:
 var cart: Dictionary=super.starting_cart(game,method,equipment)
 match livestock_arm:
  "goats":cart.goats=2
  "cow":cart.dairy_cows=1
  "hens":cart.merge({"hens":6,"poultry_feed":200},true)
  "mixed":cart.merge({"dairy_cows":1,"goats":1,"hens":6,"poultry_feed":200},true)
 return cart
func extra_settings() -> Dictionary:
 var settings: Dictionary=super.extra_settings()
 settings.merge({"livestock_arm":livestock_arm,"stock_policy":stock_policy,"livestock_balance_policy_version":1,"stock_policy_note":"Aware policy reserves noncritical helpers for animal care, buys up to 14 days grain below 3 days stock after normal purchases and a $20 reserve, butchers cow then goat after a hunger-day debt in a food emergency. No extra starting cash; no livestock replacement purchases."})
 return settings
func extra_row(game,count: Dictionary) -> Dictionary:
 var row: Dictionary=super.extra_row(game,count)
 row.livestock={"audit":game.livestock.audit.duplicate(true),"food_eaten":game.provisions.dairy_eaten,"food_spoiled":game.provisions.dairy_spoiled,"food_removed":game.provisions.dairy_removed,"needed_units":game.needed_units,"short_units":game.short_units,"first_short":game.first_short.duplicate(),"deaths":game.deaths.duplicate(true),"days":game.livestock_days.duplicate(true),"purchases":game.purchases.duplicate(true),"remaining":game.livestock.record.animals.duplicate(true),"slaughter":game.supply_history.filter(func(e):return e.event=="livestock_slaughter").duplicate(true)}
 return row
func plan_jobs(game) -> Dictionary:
 var plan: Dictionary=super.plan_jobs(game)
 chore_reserved=[]
 if stock_policy!="aware":return plan
 var hours: float=game.livestock.outlook(game).hours
 var target: int=ceili(hours/float(game.livestock.data.care_hours_per_person))
 if target<=0:return plan
 var candidates: Array=workers(game).filter(func(id):return game.party_health.members[id].health>=50 and not game.camp_tasks.patient_nurses(game).has(id))
 candidates.sort_custom(func(a,b):
  var priorities: Dictionary={"rest":0,"hunt_help":1,"fish":2,"forage":3,"dry":4,"salt_dry":4,"guard":5,"nurse":100}
  return int(priorities.get(game.camp_tasks.job(a).job,100))<int(priorities.get(game.camp_tasks.job(b).job,100)))
 for id in candidates:
  if chore_reserved.size()>=target:break
  var job: String=game.camp_tasks.job(id).job
  if job=="nurse" or (job=="forage" and plan.foragers.size()<=1):continue
  if game.camp_tasks.assign(game,id,"rest"):
   chore_reserved.append(id);plan.foragers.erase(id)
   if plan.dryer==id:plan.dryer=-1
 return plan
func dispatch_proactive(game,count: Dictionary) -> bool:
 if stock_policy!="aware" or chore_reserved.is_empty():return super.dispatch_proactive(game,count)
 if not game.field_outings.record.trips.is_empty():return false
 var candidates: Array=workers(game).filter(func(id):return id not in chore_reserved and not game.camp_tasks.patient_nurses(game).has(id) and game.party_health.members[id].health>=60 and not game.party_health.members[id].conditions.any(func(c):return c.severity>=2))
 candidates.sort_custom(func(a,b):return int(game.party_health.members[a].health)>int(game.party_health.members[b].health))
 for id in candidates:
  if game.field_outings.start(game,id,"ride_horse",1,5,"ride"):bump(count,"dispatches");bump(count,"proactive_dispatches");return true
 return false
func counter_visit(game,p: Dictionary,count: Dictionary,fundraising: bool=false) -> bool:
 if super.counter_visit(game,p,count,fundraising):return true
 if stock_policy!="aware" or fundraising:return false
 var hens: int=int(game.state.get("hens",0))
 var held: int=int(game.state.get("poultry_feed",0))
 if hens==0 or held>=hens*3:return false
 var counter: Dictionary=game.post_store()
 if counter.is_empty():return false
 var matches: Array=counter.rows.filter(func(r):return r.item=="poultry_feed")
 if matches.is_empty():return false
 var row: Dictionary=matches[0]
 var budget: int=maxi(0,roundi(float(game.state.money)*100)-2000)
 var amount: int=mini(mini(int(row.can_buy),hens*14-held),floori(float(budget)/int(row.buy_cents)))
 while amount>0:
  var quote: Dictionary=game.counter_quote({"poultry_feed":amount})
  if quote.valid and float(quote.cargo_after_lb)<=float(quote.capacity_after_lb):
   if game.counter_checkout({"poultry_feed":amount}):bump(count,"grain_visits");bump(count,"grain_quarters_bought",amount);return true
  amount-=1
 return false
func act(game,p: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 if game.can_service() and game.state.vehicle=="foot":
  var excess: float=game.provisions.cargo(game.state)-game.provisions.storage_capacity(game.state)
  var grain: int=int(game.state.get("poultry_feed",0))
  if excess>0 and grain>0:
   if game.livestock.drop_grain(game,mini(grain,ceili(excess/0.25))):bump(count,"grain_discards");return true
 if stock_policy=="aware" and game.can_service() and float(game.state.get("hunger_days",0))>=1 and game.state.food<int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations]):
  for kind in ["dairy_cows","goats"]:
   if game.livestock.butcher(game,kind,game.state.bullets<1):bump(count,"emergency_livestock_slaughter");return true
 return super.act(game,p,aim,count)
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--livestock="):livestock_arm=arg.get_slice("=",1)
  if arg.begins_with("--stock-policy="):stock_policy=arg.get_slice("=",1)
 if livestock_arm not in ARMS or stock_policy not in ["existing","aware"]:printerr("Invalid livestock arm or policy");quit(1);return
 await super.run()
