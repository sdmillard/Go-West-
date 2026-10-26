extends "res://tests/farmer_mastery_campaign.gd"
var income_arm: String="off"
func make_study_game(seed_value: int):
 var game=preload("res://tests/income_balance_observer.gd").new(seed_value,"classic",true)
 game.provisions=preload("res://tests/farmer_mastery_food.gd").new();game.provisions.carriers=game.party_health.members
 game.use_income=income_arm=="combined"
 return game
func extra_settings() -> Dictionary:
 var settings: Dictionary=super.extra_settings()
 settings.merge({"income_arm":income_arm,"income_policy_version":1,"income_policy":"Both arms bring five identical keepsakes. Combined: after ordinary buying, sell carried skins; sell consented keepsakes only below $10. A sale-only visit must exceed the estimated visit meal cost. Below $10 and with >=2 party meals, work at posts before October while basic food/produce/ammo is offered; choose highest eligible wage without taking nurses or reserved livestock carers. Pelts: only actual existing leader hunts, cash<$20, >=4 carried meals and before October; choose positive estimated 75%-price margin after an extra meal and displaced meat, using regional staple-price estimate. No autonomous skinning or extra hunting."})
 return settings
func extra_row(game,count: Dictionary) -> Dictionary:
 var row: Dictionary=super.extra_row(game,count)
 row.income={"skin_decisions":game.skin_decisions.duplicate(),"sales":game.income_sales.duplicate(true),"work_days":game.income_days.duplicate(true),"work_payments":game.supply_history.filter(func(e):return e.event=="settlement_wages").duplicate(true),"pelt_recoveries":game.pelt_recoveries.duplicate(true),"record":game.income.record.duplicate(true),"retained_keepsakes":game.income.record.keepsakes.keys().reduce(func(n,k):return n+int(game.state.get(game.income.key(int(k)),0)),0),"arrival_points":game.income.points(game)}
 return row
func counter_visit(game,p: Dictionary,count: Dictionary,fundraising: bool=false) -> bool:
 if super.counter_visit(game,p,count,fundraising):return true
 if income_arm!="combined" or not game.can_service():return false
 var market: Dictionary=game.trade_counter()
 if market.is_empty():return false
 var cart: Dictionary={}
 for row in market.rows:
  if int(row.held)<1:continue
  if game.income.is_keepsake(row.item) and float(game.state.money)<10:
   var owner: int=int(str(row.item).trim_prefix("keepsake_"))
   game.income.consent(game,owner,true)
  elif row.item not in game.provisions.data.pelts.goods:continue
  # Re-read after permission; the original preview remains immutable.
  var updated: Array=game.trade_counter().rows.filter(func(r):return r.item==row.item)
  if updated.is_empty():continue
  var n: int=int(updated[0].can_sell)
  while n>0:
   cart[row.item]=-n
   if game.counter_quote(cart).valid:break
   n-=1
  if n==0:cart.erase(row.item)
 if not cart.is_empty():
  var q: Dictionary=game.counter_quote(cart)
  var visit_meal_cents: float=int(q.days)*int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])*5.0*float(game.context.region(game).price)
  if q.valid and q.net_cents>visit_meal_cents and game.counter_checkout(cart):bump(count,"income_sales");return true
 if float(game.state.money)>=10 or int(game.calendar().month)>=10:return false
 var meal: int=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])
 if int(game.state.food)<meal*2 or not market.rows.any(func(r):return r.item in ["food","dried_produce","produce","bullets"] and r.can_buy>0):return false
 var candidates: Array=[]
 for offer in game.income.offers(game):
  for member in game.party_health.members:
   var id: int=int(member.id)
   if id in chore_reserved or game.camp_tasks.job(id).job=="nurse":continue
   var q: Dictionary=game.income.quote(game,id,offer.id)
   if q.valid:candidates.append({"worker":id,"job":offer.id,"cents":int(q.cents)})
 candidates.sort_custom(func(a,b):return a.cents>b.cents if a.cents!=b.cents else a.worker<b.worker)
 if not candidates.is_empty() and game.income.work(game,candidates[0].worker,candidates[0].job):bump(count,"income_work");return true
 return false
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--income="):income_arm=arg.get_slice("=",1)
 if income_arm not in ["off","combined"]:printerr("Invalid income arm");quit(1);return
 await super.run()
