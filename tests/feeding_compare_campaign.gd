extends "res://tests/livestock_balance_campaign.gd"
## Same source on both runtimes. Primary decisions stay fixed; secondary enables fodder buying.
var feeding_policy: String="fixed"
var runtime_label: String="new"
func make_study_game(seed_value: int):return preload("res://tests/feeding_compare_observer.gd").new(seed_value,"classic",true)
func extra_settings() -> Dictionary:
 var settings: Dictionary=super.extra_settings()
 settings.merge({"feeding_policy":feeding_policy,"runtime_label":runtime_label,"comparison_policy_version":1,"fodder_policy":"After ordinary food/medicine/produce and grain buying, fill ten days of current deficient forage below three days held, preserving $20 and actual storage. No initial fodder. Drop carried animal feed before other cargo when forced to walk."})
 return settings
func extra_row(game,count: Dictionary) -> Dictionary:
 var row: Dictionary=super.extra_row(game,count)
 row["feeding_comparison"]={"audit":game.livestock.audit.duplicate(true),"samples":game.feeding_samples.duplicate(true)}
 return row
func buy_fodder(game,count: Dictionary) -> bool:
 if feeding_policy!="fodder" or "livestock_fodder" not in game.livestock.GOODS:return false
 var o: Dictionary=game.livestock.outlook(game)
 var gap:=0.0
 for kind in ["dairy_cows","goats"]:
  var n: Dictionary=o.feeding.animals[kind]
  if float(n.natural)<float(game.livestock.data.feeding.full_production_fraction)-0.000000001:gap+=float(n.ration_lb)*maxf(0,1.0-float(n.natural))
 if gap<=0:return false
 var held: float=game.livestock.Feeding.available(game,"livestock_fodder")
 if held>=gap*3:return false
 var counter: Dictionary=game.post_store()
 if counter.is_empty():return false
 var matches: Array=counter.rows.filter(func(r):return r.item=="livestock_fodder")
 if matches.is_empty():return false
 var row: Dictionary=matches[0]
 var budget: int=maxi(0,roundi(float(game.state.money)*100)-2000)
 var amount: int=mini(mini(int(row.can_buy),ceili(gap*10-held)),floori(float(budget)/int(row.buy_cents)))
 while amount>0:
  var quote: Dictionary=game.counter_quote({"livestock_fodder":amount})
  if quote.valid and float(quote.cargo_after_lb)<=float(quote.capacity_after_lb):
   if game.counter_checkout({"livestock_fodder":amount}):bump(count,"fodder_visits");bump(count,"fodder_lb_bought",amount);return true
  amount-=1
 return false
func counter_visit(game,p: Dictionary,count: Dictionary,fundraising: bool=false) -> bool:
 if super.counter_visit(game,p,count,fundraising):return true
 if fundraising:return false
 return buy_fodder(game,count)
func act(game,p: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 if game.can_service() and game.state.vehicle=="foot" and "livestock_fodder" in game.livestock.GOODS:
  var excess: float=game.provisions.cargo(game.state)-game.provisions.storage_capacity(game.state)
  var held: int=int(game.state.get("livestock_fodder",0))
  if excess>0 and held>0:
   if game.livestock.drop_feed(game,"livestock_fodder",mini(held,ceili(excess))):bump(count,"fodder_discards");return true
  if excess>0 and int(game.state.get("poultry_feed",0))==0 and game.livestock.FEED_REMAINDERS.any(func(key):return float(game.state.get(key,0))>0):
   if game.livestock.discard_feed_remainders(game):bump(count,"partial_feed_discards");return true
 return super.act(game,p,aim,count)
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--feeding-policy="):feeding_policy=arg.get_slice("=",1)
  if arg.begins_with("--runtime-label="):runtime_label=arg.get_slice("=",1)
 if feeding_policy not in ["fixed","fodder"] or runtime_label not in ["old","new"]:printerr("Invalid feeding comparison settings");quit(1);return
 await super.run()
