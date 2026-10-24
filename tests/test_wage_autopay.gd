extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
const Main=preload("res://ui/main.tscn")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func party(interval: int=1):
 var game=Sim.new(57,"classic",true)
 game.depart("banker",["A","B","C","D","E"],5,{"oxen":6,"food":1000,"clothing":5,"bullet_boxes":5})
 game.party_health.daily_onset_chance=0
 game.survival.forced_weather="clear"
 game.survival.data.event_chance=0
 var p: Dictionary=game.characters.profiles[1]
 p.specials=["Mercenary"]
 p.trust=50
 var wage: int=int(game.characters.wage_quote(p).daily_cents)*interval
 check(game.characters.start_contract(game,1,wage,interval),"A real priced agreement starts")
 return game
func day(game):
 game.pending={}
 game.rest()
func run():
 var store=Store.new()
 var game=party(7)
 var c: Dictionary=game.characters.profiles[1].contract
 var cash: float=game.state.money
 check(not c.has("auto_pay"),"Existing/new agreements default to manual")
 check(game.characters.set_auto_pay(game,1,true) and game.state.money==cash,"Enabling before due date does not prepay")
 for i in range(6):day(game)
 check(game.state.money==cash and c.arrears_cents==0,"Auto-pay waits for the actual agreed date")
 day(game)
 check(roundi(game.state.money*100)==roundi(cash*100)-c.wage_cents and c.arrears_cents==0 and c.misses==0,"Due wages pay exact cents without a missed bill")
 var wage_events: Array=game.supply_history.filter(func(e):return e.event=="wages")
 check(wage_events.size()==1 and game.characters.profiles[1].memories.filter(func(m):return m.kind=="wage_paid").size()==1,"On-time pay records one transaction and the usual trust reward")
 cash=game.state.money
 game.characters.advance_contracts(game)
 check(game.state.money==cash,"Repeated same-day settlement cannot double-pay")
 var snapshot: Dictionary=store.capture(game)
 var restored=store.restore(JSON.parse_string(JSON.stringify(snapshot)))
 check(restored!=null and restored.characters.profiles[1].contract.auto_pay,"Auto-pay survives JSON save/load")
 if restored!=null:
  restored.party_health.daily_onset_chance=0
  restored.survival.forced_weather="clear"
  restored.survival.data.event_chance=0
  day(game);day(restored)
  check(store.capture(game)==store.capture(restored),"Loaded policy preserves the next day, supplies and random streams")
 for invalid in [1,"true",null]:
  var bad: Dictionary=snapshot.duplicate(true)
  bad.characters[1].contract.auto_pay=invalid
  check(store.restore(bad)==null,"Non-boolean saved policy rejects")
 check(game.characters.set_auto_pay(game,1,false) and not c.has("auto_pay"),"Turning off restores manual policy")
 for i in range(6):day(game)
 check(c.arrears_cents>0,"Disabled policy leaves the next due payment manual")
 game=party()
 game.state.money=0
 game.characters.set_auto_pay(game,1,true)
 day(game)
 c=game.characters.profiles[1].contract
 check(c.arrears_cents==c.wage_cents and c.misses==0,"Insufficient cash leaves the full debt and normal due-day grace")
 day(game)
 check(c.misses==1 and c.arrears_cents==c.wage_cents*2,"An unpaid automatic bill incurs the normal missed-payment consequence")
 check(game.characters.profiles[1].memories.any(func(m):return m.kind=="wage_missed"),"Unpaid wages still affect companion trust")
 game.state.money=100
 day(game)
 check(c.arrears_cents==0 and roundi(game.state.money*100)==10000-c.wage_cents*3,"A later day retries full arrears without changing the agreement")
 game=party()
 day(game)
 cash=game.state.money
 c=game.characters.profiles[1].contract
 check(game.characters.set_auto_pay(game,1,true) and c.arrears_cents==0 and roundi(game.state.money*100)==roundi(cash*100)-c.wage_cents,"Enabling settles affordable existing arrears immediately")
 game=party()
 var other: Dictionary=game.characters.profiles[2]
 other.specials=["Mercenary"]
 game.characters.start_contract(game,2,int(game.characters.wage_quote(other).daily_cents),1)
 game.characters.set_auto_pay(game,1,true);game.characters.set_auto_pay(game,2,true)
 game.state.money=game.characters.profiles[1].contract.wage_cents/100.0
 day(game)
 check(game.state.money==0 and game.characters.profiles[1].contract.arrears_cents==0 and other.contract.arrears_cents>0,"Limited cash pays eligible agreements in deterministic party order")
 check(not game.characters.set_auto_pay(game,0,true) and not game.characters.set_auto_pay(game,3,true),"Leader and unpaid companions cannot opt in")
 game=party()
 game.characters.set_auto_pay(game,1,true)
 cash=game.state.money
 game.abandon_wagon({"food":20,"clothing":4},[1])
 check(game.party_health.members[1].get("guarding",false) and game.state.money==cash and game.characters.profiles[1].contract.arrears_cents>0,"Absent wagon guards accrue wages but cannot receive remote payments")
 check(not game.characters.set_auto_pay(game,1,false),"Absent guard policy cannot be manipulated remotely")
 game=party()
 game.characters.set_auto_pay(game,1,true)
 game.party_health.kill(game.party_health.members[1],0,"test")
 cash=game.state.money
 day(game)
 check(game.state.money==cash and game.characters.profiles[1].contract.arrears_cents==0,"Deceased companions receive no new automatic wages")
 var screen=Main.instantiate()
 root.add_child(screen)
 await process_frame
 var setup=screen.departure_view
 setup.open_editor(1)
 setup.special_checks.Mercenary.button_pressed=true
 setup.auto_pay.button_pressed=true
 setup.open_editor(2)
 check(not setup.auto_pay.button_pressed,"Each companion has an independent default policy")
 setup.open_editor(1)
 check(setup.auto_pay.button_pressed and setup.auto_pay.visible,"Creation sheet remembers the checkbox")
 var custom: Dictionary=setup.customization()
 check(screen.game.characters.valid_setup(custom) and custom.contracts["1"].auto_pay,"Departure validates the optional automatic-pay agreement")
 var invalid_custom: Dictionary=custom.duplicate(true)
 invalid_custom.contracts["1"].auto_pay="yes"
 check(not screen.game.characters.valid_setup(invalid_custom),"Malformed setup policy rejects")
 check(screen.game.depart("banker",setup.party_names(),5,{"oxen":6,"food":600,"clothing":5},custom) and screen.game.characters.profiles[1].contract.auto_pay,"Departure carries the setting into the real agreement")
 screen.departure_view.hide()
 screen._select_member(1)
 check(screen.auto_pay_wages.visible and screen.auto_pay_wages.button_pressed,"Party character sheet shows the enabled checkbox")
 cash=screen.game.state.money
 var history_size: int=screen.game.journal.size()
 screen._refresh_party();screen._refresh_party()
 check(screen.game.state.money==cash and screen.game.journal.size()==history_size,"Displaying/refreshing the checkbox has no financial side effects")
 screen.auto_pay_wages.button_pressed=false
 check(not screen.game.characters.profiles[1].contract.has("auto_pay"),"Party checkbox disables automatic payment")
 screen._select_member(0)
 check(not screen.auto_pay_wages.visible,"The leader has no mercenary payment checkbox")
 var old=party()
 var old_snapshot: Dictionary=store.capture(old)
 var old_copy=store.restore(JSON.parse_string(JSON.stringify(old_snapshot)))
 check(old_copy!=null and not old_copy.characters.profiles[1].contract.has("auto_pay"),"An existing manual agreement loads without silently opting in")
 print("Mercenary auto-pay: %d checks, %d failures" % [checks,failures])
 screen.queue_free()
 await process_frame
 quit(1 if failures else 0)
