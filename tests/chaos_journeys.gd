extends "res://tests/play_style_baseline.gd"
## Bug-hunting fuzzer (November 2026): the play-style bots, but a share of their turns are random
## public actions (menus, crimes, trades, toggles, settling, tactical fights, rafting), with invariant
## and save round-trip checks after every step. Not a balance study: it hunts crashes, stuck states and
## save drift. Usage: godot --headless --path . --script tests/chaos_journeys.gd -- [--seeds=4] [--seed-start=70000] [--styles=a,b] [--chaos=0.25]
## Writes .tools/chaos-<label>.json and prints one line per problem.
var problems: Array=[]
var current: Array=[]
var trace: bool=false
func report(kind: String,game,extra: Dictionary={}) -> void:
 var row: Dictionary={"run":current,"kind":kind,"day":int(game.state.day),"miles":int(game.state.miles),"landmark":str(game.state.get("landmark","")),"status":str(game.state.status),"pending":str(game.pending.get("id","")),"title":str(game.pending.get("title","")),"journal":game.journal.slice(-3)}
 row.merge(extra,true)
 problems.append(row)
 printerr("CHAOS PROBLEM: "+JSON.stringify(row))
func numeric_bad(value) -> bool:
 if value is float:return is_nan(value) or is_inf(value)
 return false
func invariants(game) -> String:
 var s: Dictionary=game.state
 for key in ["food","money","bullets","clothing","medicine","oxen","miles","day","health","party_size","ox_health"]:
  if s.has(key) and (numeric_bad(s[key]) or float(s[key])<0):return "negative or NaN state."+key+"="+str(s[key])
 for key in s:
  if numeric_bad(s[key]):return "NaN state."+str(key)
 if int(s.party_size)!=game.party_health.living_count():return "party_size %d != living %d" % [s.party_size,game.party_health.living_count()]
 if not game.error.is_empty():return "engine error: "+str(game.error)
 if not game.pending.is_empty() and not game.pending.has("choices"):return "pending without choices"
 if game.state.status=="traveling" and not game.pending.is_empty() and game.pending.choices.is_empty():return "pending with zero choices"
 return ""
func choosable(game) -> Array:
 var out: Array=[]
 if game.pending.is_empty():return out
 for index in range(game.pending.choices.size()):
  if game.can_choose(index):out.append(index)
 return out
## Mirrors ui/main.gd _choose(): combat choices and gunfights open the tactical game.
func ui_choose(game,index: int) -> bool:
 var choice: Dictionary=game.pending.choices[index]
 if game.pending.get("crime_menu",false):
  var ccmd: String=str(choice.get("crime_command",""))
  if ccmd=="jailbreak" and game.choose(index):
   game.start_tactical_combat("breakout");return true
  if ccmd in ["shoot","breakout"] and int(game.state.bullets)>0 and game.start_tactical_combat(ccmd):return true
 elif not game.pending.get("service_menu",false) and not game.pending.has("landmark"):
  var ev: String=str(game.pending.get("id",""))
  if (choice.has("combat") or (ev=="horse_thieves" and choice.has("risk"))) and not bool(game.pending.get("friendly",false)):
   if game.start_tactical_combat("trail:"+str(index)):return true
 var ok: bool=game.choose(index)
 return ok
func tactical_turn(game,chaos_rng: RandomNumberGenerator) -> bool:
 var t=game.tactical
 var session: Dictionary=game.tactical_session
 if bool(session.get("resolved",false)):
  if not game.finish_tactical_combat():report("tactical_finish_failed",game);return false
  return true
 var guard: int=0
 while not bool(game.tactical_session.get("resolved",false)) and guard<400:
  guard+=1
  session=game.tactical_session
  var roll: float=chaos_rng.randf()
  if not bool(session.get("started",false)):
   game.tactical_step({"type":"start_combat"});continue
  var active: String=str(session.get("active_unit_id",""))
  var unit: Dictionary=t.get_unit(session,active)
  if unit.is_empty() or str(unit.get("team",""))!="player":
   game.tactical_step({"type":"end_turn"});continue
  if roll<0.02:game.tactical_step({"type":"surrender"});continue
  if roll<0.05:game.tactical_step({"type":"retreat_all"});continue
  var enemies: Array=session.get("units",[]).filter(func(u):return str(u.get("team",""))!="player" and t._unit_active(u) if t.has_method("_unit_active") else str(u.get("team",""))!="player")
  var before: String=JSON.stringify(session.get("log",[]).size())
  if not enemies.is_empty() and roll<0.7:
   var target: Dictionary=enemies[chaos_rng.randi()%enemies.size()]
   game.tactical_step({"type":"shoot","target_id":str(target.get("id","")),"mode":["snap","called","club"][chaos_rng.randi()%3]})
  elif roll<0.8:game.tactical_step({"type":"reload"})
  elif roll<0.9:
   var tiles: Dictionary=t.reachable_tiles(session,active)
   if not tiles.is_empty():
    var key=tiles.keys()[chaos_rng.randi()%tiles.size()]
    var p: Vector2i=key if key is Vector2i else Vector2i(int(str(key).get_slice(",",0)),int(str(key).get_slice(",",1)))
    game.tactical_step({"type":"move","x":p.x,"y":p.y})
  game.tactical_step({"type":"end_turn"})
 if guard>=400:report("tactical_never_resolved",game);game.tactical_session={};return false
 if not game.finish_tactical_combat():report("tactical_finish_failed",game);return false
 return true
func chaos_action(game,chaos_rng: RandomNumberGenerator) -> Array:
 if not game.pending.is_empty():
  var options: Array=choosable(game)
  if options.is_empty():return ["no_choosable",false]
  var index: int=options[chaos_rng.randi()%options.size()]
  return ["choose:"+str(game.pending.choices[index].get("label","?")).left(40),ui_choose(game,index)]
 var actions: Array=["open_camp","open_trade","open_care","open_companions","open_remains","open_native_contacts","open_forage","open_horse_traders","open_departure_review","rest","guard","double","lead","strain","news","slaughter","preserve","dry","discard","recover","inspect","checkout","rob","steal","crime","east","west","pace"]
 var a: String=actions[chaos_rng.randi()%actions.size()]
 match a:
  "open_camp":return [a,game.open_camp()]
  "open_trade":return [a,game.open_trade()]
  "open_care":return [a,game.open_care()]
  "open_companions":return [a,game.open_companions()]
  "open_remains":return [a,game.open_remains()]
  "open_native_contacts":return [a,game.open_native_contacts()]
  "open_forage":return [a,game.open_forage()]
  "open_horse_traders":return [a,game.open_horse_traders()]
  "open_departure_review":return [a,game.open_departure_review()]
  "rest":return [a,game.rest_in_camp()]
  "guard":return [a,game.set_night_guard(chaos_rng.randf()<0.5)]
  "double":return [a,game.set_double_up(chaos_rng.randf()<0.5)]
  "lead":return [a,game.set_lead_mounts(chaos_rng.randf()<0.5)]
  "strain":return [a,game.set_strenuous_load(chaos_rng.randf()<0.5)]
  "news":return [a,game.ask_news()!=""]
  "slaughter":return [a,game.slaughter_ox(chaos_rng.randf()<0.5)]
  "preserve":return [a,game.preserve_meat(chaos_rng.randf()<0.5)]
  "dry":return [a,game.dry_produce()]
  "discard":
   var item: String=["food","clothing","bullets","medicine","salt","spare_parts"][chaos_rng.randi()%6]
   return [a+":"+item,game.discard_supply(item,chaos_rng.randi_range(1,20))]
  "recover":return [a,game.recover_wagon()]
  "inspect":return [a,game.inspect_cached_wagon()]
  "checkout":
   var counter: Dictionary=game.trade_counter()
   var cart: Dictionary={}
   for row in counter.get("rows",[]):
    if chaos_rng.randf()<0.3:
     var key: String=str(row.get("buy_key" if chaos_rng.randf()<0.5 else "sell_key",""))
     if key!="":cart[key]=chaos_rng.randi_range(1,5)
   return [a+":"+JSON.stringify(cart),game.counter_checkout(cart)]
  "rob":return [a,game.demand_robbery({"food":chaos_rng.randi_range(0,50),"money":chaos_rng.randi_range(0,20)})]
  "steal":return [a,game.steal({"food":chaos_rng.randi_range(0,30)})]
  "crime":return [a,game.open_crime()]
  "east":return [a,chaos_rng.randf()<0.02 and game.turn_direction("east")]
  "west":return [a,game.turn_direction("west")]
  "pace":
   game.configure(chaos_rng.randi_range(0,2),chaos_rng.randi_range(0,2));return [a,true]
 return [a,false]
func step_game(game,style: String,profile: Dictionary,aim,count: Dictionary,acts: Dictionary,chaos_rng: RandomNumberGenerator,chaos: float) -> Array:
 if not game.tactical_session.is_empty():return ["tactical",tactical_turn(game,chaos_rng)]
 if not game.raft.is_empty():
  var guard: int=0
  while not game.raft.ended and guard<20000:
   game.advance_rafting(0.05,chaos_rng.randf_range(-1,1));guard+=1
  if guard>=20000:report("raft_never_ended",game);return ["raft",false]
  return ["raft",game.finish_rafting()]
 if not game.hunt.is_empty():
  # A hunt left open (chaos opened it): finish it with whatever was shot.
  return ["finish_hunt",game.finish_hunt() or game.finish_fishing()]
 if chaos_rng.randf()<chaos:return chaos_action(game,chaos_rng)
 var available: bool=game.pending.is_empty() or game.pending.has("landmark")
 if game.pending.get("crime_menu",false):
  var stage: String=game.crime.incident().get("stage","")
  if stage=="custody":return ["custody",pick(game,"crime_command","bail") or pick(game,"crime_command","vouch") or pick(game,"crime_command","wait")]
  if stage=="standoff":return ["standoff",pick(game,"crime_command","flee") or pick(game,"crime_command","surrender")]
  return ["settle_crime",settle_crime(game) or game.choose(choosable(game)[0]) if not choosable(game).is_empty() else false]
 if game.pending.get("remains_menu",false) or game.pending.get("attack_menu",false) or game.pending.get("native_menu",false) or game.pending.get("recruit_menu",false) or game.pending.get("dismiss_menu",false) or game.pending.get("riders_menu",false):
  var options: Array=choosable(game)
  return ["back_out",game.choose(options[-1]) if not options.is_empty() else false]
 if style in ["criminal"] and available and game.crime.eligible(game) and game.crime.transient(game.crime.target(game)) and acts.theft<4:
  acts.theft+=1
  return ["crime",game.open_crime() and pick(game,"crime_command","theft" if acts.theft%2==0 or game.state.bullets==0 else "robbery")]
 if style in ["reckless","fighter"] and reckless_choice(game,style):return ["reckless",true]
 var ok: bool=act(game,profile,aim,count)
 if not ok and game.pending.is_empty() and game.state.status=="traveling":ok=game.travel() or game.rest()
 if not ok and game.pending.get("service_menu",false):
  var options: Array=choosable(game)
  if not options.is_empty():ok=game.choose(options[-1])
 return ["policy",ok]
func run():
 adaptive=true
 hunting_study=true
 var label: String="chaos"
 var seed_start: int=70000
 var seeds: int=3
 var chaos: float=0.25
 var styles: Array=["careful_apr","on_foot","horses","criminal","late_jul","reckless"]
 var professions: Array=["farmer","banker","outlaw","doctor"]
 var branches: Array=["","south road","salt lake","greenwood","raft"]
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--label="):label=argument.get_slice("=",1).validate_filename()
  if argument.begins_with("--seed-start="):seed_start=int(argument.get_slice("=",1))
  if argument.begins_with("--seeds="):seeds=int(argument.get_slice("=",1))
  if argument=="--trace":trace=true
  if argument.begins_with("--chaos="):chaos=float(argument.get_slice("=",1))
  if argument.begins_with("--styles="):styles=Array(argument.get_slice("=",1).split(","))
  if argument.begins_with("--professions="):professions=Array(argument.get_slice("=",1).split(","))
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools"))
 var store=Store.new()
 var outcomes: Dictionary={}
 var started: int=Time.get_ticks_msec()
 var journeys: int=0
 for style in styles:
  for profession in professions:
   for seed_value in range(seed_start,seed_start+seeds):
    var chaos_rng:=RandomNumberGenerator.new()
    chaos_rng.seed=seed_value*7919+hash(style+profession)
    var game=Observed.new(seed_value,"classic",true)
    var cart: Dictionary=outfit(game,style)
    while not game.outfitter.quote(profession,cart).get("valid",false) and int(cart.get("oxen",0))>4:cart.oxen=int(cart.oxen)-1
    while not game.outfitter.quote(profession,cart).get("valid",false) and int(cart.get("food",0))>100:cart.food=int(cart.food)-50
    current=[style,profession,seed_value]
    if not game.depart(profession,["A","B","C","D","E"],style_month(style),cart):
     report("departure_failed",game,{"error":game.departure_error});continue
    journeys+=1
    var profile: Dictionary=profile_for(style)
    profile["branch"]=branches[chaos_rng.randi()%branches.size()]
    var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
    var aim:=RandomNumberGenerator.new()
    aim.seed=seed_value ^ 0x42414c
    var acts: Dictionary={"theft":0,"robbery":0}
    var outcome: String="action_limit"
    var idle: int=0
    var fails: int=0
    var history: Array=[]
    for step in range(6000):
     if game.state.status!="traveling":outcome=game.state.status;break
     if game.state.day>=730:outcome="two_year_limit";break
     var day: int=game.state.day
     var mile: int=game.state.miles
     var result: Array=step_game(game,style,profile,aim,count,acts,chaos_rng,chaos)
     history.append(str(result[0]))
     if trace and (game.state.miles!=mile or game.state.day!=day):print("TRACE day %d->%d miles %d->%d leg %d %s->%s %s" % [day,game.state.day,mile,game.state.miles,game.state.leg_miles,game.state.landmark,game.state.next_landmark,str(result[0])])
     if history.size()>12:history.pop_front()
     if not result[1] and str(result[0]).begins_with("policy"):fails+=1
     else:fails=0
     var bad: String=invariants(game)
     if bad!="":report("invariant",game,{"detail":bad,"last":history});outcome="invariant";break
     idle=idle+1 if day==game.state.day and mile==game.state.miles else 0
     if fails>30:report("policy_blocked",game,{"last":history,"choices":game.pending.get("choices",[]).map(func(c):return str(c.get("label",""))),"can_act":game._can_act(),"vehicle":str(game.state.vehicle),"oxen":int(game.state.oxen)});outcome="blocked";break
     if idle>150:report("stalled",game,{"last":history,"choices":game.pending.get("choices",[]).map(func(c):return str(c.get("label",""))),"can_act":game._can_act()});outcome="stalled";break
     if step%40==0 and game.tactical_session.is_empty() and game.raft.is_empty() and game.hunt.is_empty():
      var saved: Dictionary=JSON.parse_string(JSON.stringify(store.capture(game)))
      var restored=store.restore(saved)
      if restored==null:
       FileAccess.open("res://.tools/chaos-fail-%s-%s-%d.json" % current,FileAccess.WRITE).store_string(JSON.stringify(saved,"\t"))
       report("save_failed",game,{"error":str(store.error),"last":history});outcome="save_failed";break
      var again: Dictionary=JSON.parse_string(JSON.stringify(store.capture(restored)))
      if JSON.stringify(again)!=JSON.stringify(saved):
       var diffs: Array=[]
       for key in saved:
        if JSON.stringify(saved.get(key))!=JSON.stringify(again.get(key)):diffs.append(key)
       report("save_drift",game,{"keys":diffs.slice(0,8),"last":history})
      elif chaos_rng.randf()<0.5:
       # Play on from the reloaded game, the way a player continues a save.
       game=restored
    outcomes[outcome]=int(outcomes.get(outcome,0))+1
    print("%s %s %d: %s day %d mile %d at %s" % [style,profession,seed_value,outcome,game.state.day,game.state.miles,game.state.get("landmark","")])
    await process_frame
 var path: String="res://.tools/chaos-"+label+".json"
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"label":label,"journeys":journeys,"outcomes":outcomes,"problems":problems},"\t"))
 print("CHAOS DONE %d journeys in %.0fs, outcomes %s, %d problems" % [journeys,(Time.get_ticks_msec()-started)/1000.0,JSON.stringify(outcomes),problems.size()])
 quit(0)
