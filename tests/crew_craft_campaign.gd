extends "res://tests/farmer_mastery_campaign.gd"
var income_arm: String="off"
var contract_arm: String="free"
var best_crew: Dictionary={}
var best_cents:=0
func make_study_game(seed_value: int):
 var game=preload("res://tests/crew_craft_observer.gd").new(seed_value,"classic",true)
 game.provisions=preload("res://tests/farmer_mastery_food.gd").new();game.provisions.carriers=game.party_health.members
 game.use_income=income_arm!="off";game.hired=contract_arm=="hired";game.craft_income=income_arm=="craft"
 return game
func extra_settings() -> Dictionary:
 var settings: Dictionary=super.extra_settings()
 settings.merge({"income_arm":income_arm,"contract_arm":contract_arm,"crew_craft_policy_version":1})
 return settings
func extra_row(game,count: Dictionary) -> Dictionary:
 var row: Dictionary=super.extra_row(game,count)
 var goods: Dictionary={}
 for item in game.leathercraft.items()+["deer_hide"]:goods[item]=int(game.state.get(item,0))
 row.earnings={"opening":game.opening_party,"sales":game.trade_sales,"crew_days":game.crew_days,"days":game.day_costs,"skin_decisions":game.skin_decisions,"pelt_recoveries":game.pelt_recoveries,"events":game.supply_history.filter(func(e):return e.event in ["wages","settlement_wages","leathercraft"]),"work_record":game.income.record.work,"final_contract":game.characters.profiles[2].contract,"final_artisan":game.party_health.members[2],"final_goods":goods,"arrival_points":game.income.points(game)}
 return row
func plan_jobs(game) -> Dictionary:
 var plan: Dictionary=super.plan_jobs(game)
 if income_arm!="craft":return plan
 for id in workers(game):
  if id in chore_reserved or game.camp_tasks.job(id).job not in ["rest","hunt_help"]:continue
  var job: String="make_gloves" if not game.leathercraft.next_step(game.state,"make_gloves").is_empty() else "tan_leather"
  if game.leathercraft.quote(game,id,job).valid and game.camp_tasks.assign(game,id,job):break
 return plan
func search_crew(options: Array,index: int,cart: Dictionary,used: Dictionary,cents: int,cap: int) -> void:
 if cents>best_cents:best_cents=cents;best_crew=cart.duplicate()
 if index>=options.size() or cart.size()>=cap:return
 search_crew(options,index+1,cart,used,cents,cap)
 for q in options[index]:
  if int(used.get(q.job,0))>=q.openings:continue
  cart[str(q.id)]=q.job;used[q.job]=int(used.get(q.job,0))+1
  search_crew(options,index+1,cart,used,cents+q.cents,cap)
  cart.erase(str(q.id));used[q.job]-=1
func counter_visit(game,p: Dictionary,count: Dictionary,fundraising: bool=false) -> bool:
 if super.counter_visit(game,p,count,fundraising):return true
 if income_arm=="off" or not game.can_service():return false
 var market: Dictionary=game.trade_counter()
 if market.is_empty():return false
 var cart: Dictionary={}
 var pipeline: bool=["hide_scraped","hide_softened","buckskin","glove_pieces"].any(func(k):return int(game.state.get(k,0))>0)
 for row in market.rows:
  if int(row.held)<1:continue
  if game.income.is_keepsake(row.item) and float(game.state.money)<10:game.income.consent(game,int(str(row.item).trim_prefix("keepsake_")),true)
  elif row.item not in game.provisions.data.pelts.goods and not game.leathercraft.is_good(row.item):continue
  var updated: Array=game.trade_counter().rows.filter(func(r):return r.item==row.item)
  if updated.is_empty():continue
  var n: int=int(updated[0].can_sell)
  if income_arm=="craft" and float(game.state.money)>=2 and int(game.state.food)>=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations]):
   if row.item=="buckskin":n=maxi(0,n-1)
   if row.item=="deer_hide" and not pipeline:n=maxi(0,n-1)
  while n>0:
   cart[row.item]=-n
   if game.counter_quote(cart).valid:break
   n-=1
  if n==0:cart.erase(row.item)
 if not cart.is_empty():
  var q: Dictionary=game.counter_quote(cart)
  var meal_cost: float=int(q.days)*int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])*5.0*float(game.context.region(game).price)
  if q.valid and q.net_cents>meal_cost and game.counter_checkout(cart):bump(count,"income_sales");return true
 var bill: float=0
 for profile in game.characters.profiles:
  if not profile.contract.is_empty():bill+=profile.contract.wage_cents/100.0
 if float(game.state.money)>=20+bill:bump(count,"work_cash_sufficient");return false
 var meal: int=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])
 if int(game.state.food)<meal:bump(count,"work_food_gate");return false
 var offers: Array=game.income.offers(game)
 if offers.is_empty() or offers[0].left<1:bump(count,"work_no_openings");return false
 var options: Array=[]
 for member in game.party_health.members:
  var id: int=int(member.id)
  if id in chore_reserved or game.camp_tasks.job(id).job=="nurse":continue
  var choices: Array=[]
  for offer in offers:
   var q: Dictionary=game.income.quote(game,id,offer.id)
   if q.valid:choices.append({"id":id,"job":offer.id,"cents":int(q.cents),"market_cents":int(q.market_cents),"openings":int(offer.openings)})
  options.append(choices)
 best_crew={};best_cents=0
 search_crew(options,0,{},{},0,mini(int(offers[0].left),int(game.income.data.sites[str(game.state.landmark)].workers_per_day)))
 if best_crew.is_empty():bump(count,"work_no_eligible_crew");return false
 game.crew_launch=game.income.crew_quote(game,best_crew).duplicate(true)
 if game.income.work_crew(game,best_crew):bump(count,"income_work");return true
 return false
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--income="):income_arm=arg.get_slice("=",1)
  if arg.begins_with("--contract="):contract_arm=arg.get_slice("=",1)
 if income_arm not in ["off","crew","craft"] or contract_arm not in ["free","hired"]:printerr("Invalid crew/craft cell");quit(1);return
 await super.run()
