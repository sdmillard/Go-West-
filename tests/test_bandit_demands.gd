extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Demand=preload("res://simulation/bandit_demand.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func outfit(seed_value: int=57):
 var game=Simulation.new(seed_value,"classic",true)
 var cart: Dictionary={}
 for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
 cart.produce=4
 cart.dried_produce=20
 check(game.depart("banker",["A","B","C","D","E"],5,cart),"Legal outfit with mixed food")
 game.pending={}
 game.state.money=1000.0
 game.survival.forced_weather="clear"
 game.survival.data.event_chance=0
 game.party_health.daily_onset_chance=0
 return game
func encounter(game):
 game.pending={}
 for event in game.trail_events.events:
  if event.id=="bandits":game._present_trail_event(event);return
func trip(game,message: String):
 var store=Store.new()
 var snapshot: Dictionary=store.capture(game)
 var copy=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
 check(copy!=null,message)
 if copy!=null:check(store.capture(copy)==snapshot,message+" exactly")
 return copy
func command(game,kind: String) -> bool:
 for index in range(game.pending.choices.size()):
  if game.pending.choices[index].get("remains_command","")==kind:return game.choose(index)
 return false
func kill(game,id: int):
 game.party_health.affect(game.party_health.members[id],-200,game.state.day,"fixture injury")
 game._collect_health_events()
 game.state.party_size=game.party_health.living_count()
 game.state.health=game.party_health.average_health()
 game.pending={}
func run():
 var mixed:=0
 var cash_only:=0
 var goods_only:=0
 var wagons:=0
 var low:=0
 var high:=0
 var uneven:=0
 for seed_value in range(256):
  var game=outfit(seed_value)
  encounter(game)
  var choice: Dictionary=game.pending.choices[0]
  check(Demand.valid_choice(choice) and game.can_choose(0),"Generated demand is a payable validated bundle")
  for item in choice.requires:check(choice.requires[item]>0 and choice.requires[item]<=game.state[item],"Every demand is bounded by actual holdings")
  var money: float=choice.requires.get("money",0.0)
  if choice.requires.size()>int(money>0):mixed+=int(money>0);goods_only+=int(money==0)
  else:cash_only+=1
  low+=int(money>0 and money<=20)
  high+=int(money>=200)
  uneven+=int(int(money)%5!=0)
  wagons+=int(choice.get("bandit_wagon",false))
  var before: Dictionary=game.state.duplicate(true)
  var copy=trip(game,"Open demand survives save/load without reroll")
  check(game.choose(0),"Actual surrender resolves")
  for item in choice.requires:check(is_equal_approx(float(game.state[item]),float(before[item])-float(choice.requires[item])),"Surrender takes exactly the named quantity")
  check(game.party_health.days_without_fresh==0 and game.state.day==0,"Surrendering food gives no nutrition and spends no invented day")
  if copy!=null:
   check(copy.choose(0) and Store.new().capture(copy)==Store.new().capture(game),"Saved demand produces the same outcome and RNG")
  trip(game,"Paid demand saves")
 check(mixed>0 and cash_only>0 and goods_only>0,"Cash-only, mixed and goods-only demands occur")
 check(low>0 and high>0 and uneven>0,"Same rich outfit sees cheap, expensive and uneven-dollar demands")
 check(wagons>0 and wagons<30,"Loaded-wagon demand occurs rarely in the declared seed sweep")
 var game=outfit()
 game.state.money=0.25
 game.state.vehicle="foot"
 game.combat.data.bandit_demands.wagon_chance=1.0
 encounter(game)
 check(not game.pending.choices[0].get("bandit_wagon",false),"Walking parties cannot be asked for a wagon")
 for item in game.pending.choices[0].requires:check(game.pending.choices[0].requires[item]<=game.state[item],"Tiny purse remains bounded")
 game=outfit()
 game.state.money=0
 game.state.vehicle="foot"
 for item in Demand.GOODS:game.state[item]=0
 game.state.parts=0
 game.provisions.fresh.clear()
 encounter(game)
 check(game.pending.choices.size()==1 and game.pending.choices[0].requires.is_empty() and game.choose(0),"Nothing available means an explicit pass, not an impossible shakedown")
 game=outfit()
 check(game.discard_supply("food",400),"Make real cargo room before carrying remains")
 kill(game,4)
 check(game.open_remains() and command(game,"butcher_open"),"Prepare separately tracked food through real action")
 game.pending={}
 kill(game,3)
 check(game.open_remains() and command(game,"carry"),"Prepare a carried body through real action")
 game.pending={}
 game.combat.data.bandit_demands.wagon_chance=1.0
 encounter(game)
 check(game.pending.choices[0].bandit_wagon and game.can_choose(0),"Extreme demand is explicit and payable")
 var captured: Dictionary=Store.new().capture(game)
 var forged: Dictionary=captured.duplicate(true)
 forged.pending.choices[0].effects.food=1
 check(Store.new().restore(forged)==null,"Payment cannot change a demand into a food reward")
 var bad_flag: Dictionary=captured.duplicate(true)
 bad_flag.pending.choices[0].bandit_wagon="yes"
 check(Store.new().restore(bad_flag)==null,"Invalid wagon flag rejects cleanly")
 var foot: Dictionary=captured.duplicate(true)
 foot.state.vehicle="foot"
 var foot_copy=Store.new().restore(foot)
 check(foot_copy==null or not foot_copy.can_choose(0),"A saved wagon demand cannot take a nonexistent wagon")
 var clothes: int=mini(int(game.state.clothing),int(game.state.party_size))
 check(game.choose(0) and game.state.vehicle=="foot" and game.state.oxen==0 and game.state.food==0 and game.state.bullets==0 and game.state.clothing==clothes,"Loaded-wagon surrender leaves only worn clothing and personal equipment")
 check(game.wagon_cache.is_empty() and not game.recover_wagon(),"Stolen wagon is not a recoverable cache")
 check(game.Remains.carried(game)==0 and game.Remains.human_pounds(game)==0 and game.state.remains_lb==0,"Carried bodies are set down and tracked cargo food is lost once")
 check(game.supply_history.any(func(row):return row.get("wagon_taken",false)),"Wagon loss appears in structured supply history")
 trip(game,"Whole-wagon outcome saves")
 game=outfit()
 encounter(game)
 captured=Store.new().capture(game)
 captured.rules="70ef4aad8342b811479b0122dc1411ba920da95bfdcf7f169d0753110a4391eb"
 captured.pending.choices[0]={"label":"Surrender $20","requires":{"money":20},"effects":{"money":-20},"result":"The thieves leave with the money."}
 var old=Store.new().restore(captured)
 check(old!=null and old.pending.choices[0].requires.money==20 and old.choose(0),"Previous fixed-$20 pending saves keep their original demand")
 var bad: Dictionary=game.combat.data.duplicate(true)
 bad.bandit_demands.goods["health"]=1
 check(not Demand.valid_rules(bad.bandit_demands),"Demands cannot be authored as health damage")
 var screen=Main.instantiate()
 root.add_child(screen)
 await process_frame
 screen.game=outfit()
 screen.game.combat.data.bandit_demands.wagon_chance=1.0
 encounter(screen.game)
 screen._refresh()
 await process_frame
 check("wagon, team" in screen.event_text.text and screen.choices.get_child(0).text.contains("wagon"),"Actual UI states the wagon loss before the payment button")
 if "--capture" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://.tools/bandit-wagon-demand.png")
 screen.queue_free()
 await process_frame
 # A broken wheel waiting for camp repair leaves with a surrendered wagon; the save still loads.
 var broken=outfit()
 check(broken.camp_repair.queue(broken,"wheels"),"A wheel can break before the robbery")
 broken.combat.data.bandit_demands.wagon_chance=1.0
 encounter(broken)
 check(broken.pending.choices[0].get("bandit_wagon",false) and broken.choose(0) and broken.state.vehicle=="foot","The broken wagon is surrendered")
 check(broken.camp_repair.work.is_empty(),"No repair is left for a wagon the party no longer has")
 trip(broken,"Surrendering a wagon mid-repair saves")
 print("Bandit demands: %d checks, %d failures; mixed %d, cash-only %d, goods-only %d, wagons %d, low %d, high %d" % [checks,failures,mixed,cash_only,goods_only,wagons,low,high])
 quit(1 if failures else 0)
