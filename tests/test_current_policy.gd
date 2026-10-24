extends "res://tests/current_journey_policy.gd"
const Observed=preload("res://tests/balance_observer.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func prepare(type,seed_value: int):
 var game=type.new(seed_value,"classic",true)
 var cart: Dictionary={}
 for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
 cart.dried_produce=20
 check(game.depart("farmer",["A","B","C","D","E"],5,cart),"Study party departs legally")
 return game
func run():
 adaptive=true
 hunting_study=true
 var a=prepare(Observed,3033)
 var b=prepare(Simulation,3033)
 var profile: Dictionary={"pace":0,"rations":1,"hunt":true,"accuracy":0.65,"rest":true,"preserve":"salt","slaughter":true,"slaughter_team_floor":4,"hunt_below":90,"rest_below":55,"produce":true,"preserve_meals":3.3,"opportunity":1}
 var aim_a:=RandomNumberGenerator.new()
 var aim_b:=RandomNumberGenerator.new()
 aim_a.seed=3044
 aim_b.seed=3044
 var counts: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
 var other: Dictionary=counts.duplicate(true)
 for step in range(180):
  if a.state.status!="traveling":break
  check(act(a,profile,aim_a,counts)==act(b,profile,aim_b,other),"Observer never changes which action succeeds")
  if step%10==0:check(Store.new().capture(a)==Store.new().capture(b),"Observed daily accounting preserves the actual game and RNG exactly")
 check(a.audit.days==a.state.day and a.audit.working_days+a.audit.rest_days+a.audit.other_days==a.state.day,"Every elapsed day is counted once by the observer")
 var game=prepare(Observed,3033)
 game.state.food=0
 game.provisions.fresh.clear()
 game.party_health.daily_onset_chance=0
 game._tick_day(true)
 check(game.audit.underfed_days==1,"Actual partial or missing meals count as underfed days")
 game=prepare(Observed,3034)
 game.pending={}
 game.state.vehicle="foot"
 game.state.food=0
 game.provisions.fresh.clear()
 for key in ["wheels","axles","tongues","salt","bullets","medicine"]:game.state[key]=0
 for member in game.party_health.members:member.health=35
 game.state.health=game.party_health.average_health()
 check(game.provisions.cargo(game.state)>game.provisions.capacity(game.state),"Injured walking fixture cannot carry fixed gear")
 var before_day: int=game.state.day
 check(trim_foot(game,counts) and game.state.day==before_day+1,"Study chooses an actual recovery day when no sensible discard remains")
 game=prepare(Observed,3035)
 game.state.ox_health=0
 game.party_health.daily_onset_chance=0
 game.survival.forced_weather="clear"
 before_day=game.state.day
 check(act(game,profile,aim_a,counts) and game.state.day==before_day+1 and game.state.ox_health>0,"A worn team receives a real recovery day instead of a no-time warning loop")
 game=prepare(Observed,3036)
 game.state.vehicle="foot"
 game.state.household_gear_lb=75
 game.state.oxen=0
 game.state.food=0
 game.state.money=0
 game.provisions.fresh.clear()
 for key in ["wheels","axles","tongues","salt","medicine"]:game.state[key]=0
 game.state.bullets=20
 for member in game.party_health.members:member.health=60
 game.state.health=60
 game.party_health.daily_onset_chance=0
 game.survival.data.event_chance=0
 game.survival.forced_weather="clear"
 game.configure(0,2)
 game.start_hunt();game.hunt.meat=60;game.finish_hunt()
 counts.last_hunt_day=game.state.day
 game.pending={}
 var walking_profile: Dictionary=profile.duplicate(true)
 walking_profile.produce=false
 walking_profile.preserve=""
 before_day=game.state.day
 var before_miles: int=game.state.miles
 check(game.state.food<20 and game.last_hunt_recovery.eaten_food==15,"A weak hunter has eaten but cannot carry the bot's old target buffer")
 check(act(game,walking_profile,aim_a,counts) and game.state.day==before_day+1 and game.state.miles>before_miles and game.hunt.is_empty(),"A just-fed walker makes real progress instead of hunting forever for an impossible reserve")
 print("Current balance policy: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
