extends "res://tests/mount_balance_campaign.gd"
var checks: int=0
var failures: int=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func prepare(type,mode: String):
 var game=type.new(61001,"classic",true)
 check(game.depart("banker",["A","B","C","D","E"],5,outfit(game,mode)),"Legal "+mode+" departure")
 return game
func counts() -> Dictionary:
 return {"hunts":0,"rests":0,"trades":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
func run():
 adaptive=true
 hunting_study=true
 for profession in ["farmer","carpenter","banker"]:
  for mode in MODES:
   var game=Simulation.new(61001,"classic",true)
   var quote: Dictionary=game.outfitter.quote(profession,outfit(game,mode))
   check(quote.valid and quote.mounts.mode==mode,"Every declared outfit is affordable and actually uses "+mode+" for "+profession)
 for mode in MODES:
  var observed=prepare(Observed,mode)
  var actual=prepare(Simulation,mode)
  var profile: Dictionary=policy(mode,"salt")
  var aim_a:=RandomNumberGenerator.new()
  var aim_b:=RandomNumberGenerator.new()
  aim_a.seed=61001
  aim_b.seed=61001
  var a: Dictionary=counts()
  var b: Dictionary=counts()
  for step in range(70):
   if observed.state.status!="traveling":break
   check(act(observed,profile,aim_a,a)==act(actual,profile,aim_b,b),"Observation preserves public action success for "+mode)
   if step%10==0:check(Store.new().capture(observed)==Store.new().capture(actual),"Observation preserves game state and random streams for "+mode)
  check(observed.audit.days==observed.state.day,"Every elapsed day is counted for "+mode)
 var game=prepare(Simulation,"mounted")
 game.state.horse_health=60
 var before: int=game.state.day
 check(act(game,policy("mounted","salt"),RandomNumberGenerator.new(),counts()) and game.state.day==before+1 and game.state.horse_health>60,"The declared horse policy rests tired mounts through a real day")
 game=prepare(Simulation,"mounted")
 game.state.food=10
 game.provisions.fresh.clear()
 game.state.next_landmark="fort_laramie"
 game._arrive_landmark(false,false)
 check(counter_visit(game,policy("mounted","salt"),counts()) and game.state.food>25,"Mounted resupply is not capped at the walkers-only 25 units")
 game=prepare(Simulation,"mounted")
 game.state.money=0
 game.state.next_landmark="big_blue"
 game.state.river_stage="low"
 game._arrive_landmark(false,false)
 check(act(game,policy("mounted","salt"),RandomNumberGenerator.new(),counts()) and game.last_crossing.get("method","")=="horses","A poor mounted party uses the real horse crossing when no ferry is affordable")
 print("Mount campaign policy: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
