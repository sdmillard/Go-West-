extends "res://tests/current_journey_policy.gd"
## Big balance pass baseline (October 31, 2026): whole journeys through public actions,
## one declared bot per play style, so later tuning has before/after numbers.
## Usage: godot --headless --path . --script tests/play_style_baseline.gd -- --label=baseline-01 [--seeds=10] [--seed-start=90000] [--styles=a,b] [--professions=a,b]
## Writes .tools/play-style-<label>.json (raw rows) and prints a summary table.
const Observed=preload("res://tests/balance_observer.gd")
const STYLES=["careful_apr","careful_may","reckless","fighter","on_foot","horses","criminal","petty","late_jun","late_jul"]
const PROFESSIONS=["farmer","carpenter","banker"]
func style_month(style: String) -> int:
 return {"careful_may":5,"late_jun":6,"late_jul":7}.get(style,4)
func outfit(game,style: String) -> Dictionary:
 var cart: Dictionary={}
 if style=="on_foot":return {"wagon":0,"oxen":0,"food":45,"clothing":5,"bullet_boxes":1,"medicine":1,"salt":2,"dried_produce":3}
 if style=="horses":return {"wagon":0,"oxen":0,"food":450,"clothing":5,"bullet_boxes":5,"medicine":1,"salt":5,"dried_produce":10,"horses":5,"mules":3,"saddles":5,"pack_saddles":3,"saddlebags":5}
 for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
 cart.dried_produce=20
 return cart
func profile_for(style: String) -> Dictionary:
 var p: Dictionary={"id":style,"pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":90,"rest_below":55,"care_below":55,"adaptive_rations":true,"produce":true,"forage_gap":20,"preserve":"salt","preserve_meals":3.3,"slaughter":true,"slaughter_team_floor":4,"opportunity":1,"cash_reserve":20,"post_food":600,"team_rest_below":65}
 if style=="reckless":p.merge({"pace":2,"rations":1,"rest_below":25,"care_below":0,"adaptive_rations":false,"hunt_below":45,"preserve":"","produce":false,"team_rest_below":30},true)
 if style in ["on_foot","horses"]:p.merge({"mount_support":true,"mount_rest_below":65,"mount_targets":{"horses":5,"mules":3} if style=="horses" else {}},true)
 return p
## Reckless players push at a grueling pace on meager rations, rest only near collapse,
## fight bandits and ford instead of paying ferries. Fighters are careful but always defend.
func reckless_choice(game,style: String) -> bool:
 if game.pending.get("id","")=="bandits":
  for index in range(game.pending.choices.size()):
   if game.pending.choices[index].has("combat") and game.can_choose(index):return game.choose(index)
 if style=="fighter":return false
 if game.pending.has("landmark") and game.route.nodes[game.state.landmark].kind=="river":
  var methods: Array=["swim","wade"] if game.state.vehicle=="foot" else ["float" if game.state.river_stage=="high" else "ford","ford","float"]
  for method in methods:
   if service_choice(game,"method",method):return true
 return false
func run():
 adaptive=true
 hunting_study=true
 var label: String="baseline-01"
 var seed_start: int=90000
 var seeds: int=10
 var styles: Array=STYLES.duplicate()
 var professions: Array=PROFESSIONS.duplicate()
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--label="):label=argument.get_slice("=",1).validate_filename()
  if argument.begins_with("--seed-start="):seed_start=int(argument.get_slice("=",1))
  if argument.begins_with("--seeds="):seeds=clampi(int(argument.get_slice("=",1)),1,60)
  if argument.begins_with("--styles="):styles=Array(argument.get_slice("=",1).split(","))
  if argument.begins_with("--professions="):professions=Array(argument.get_slice("=",1).split(","))
 if not styles.all(func(v):return v in STYLES) or not professions.all(func(v):return v in PROFESSIONS):
  printerr("Unknown style or profession");quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tools"))
 var store=Store.new()
 var rows: Array=[]
 var errors: Array=[]
 var started: int=Time.get_ticks_msec()
 for style in styles:
  for profession in professions:
   for seed_value in range(seed_start,seed_start+seeds):
    var game=Observed.new(seed_value,"classic",true)
    var cart: Dictionary=outfit(game,style)
    var id: Array=[style,profession,seed_value]
    if not game.depart(profession,["A","B","C","D","E"],style_month(style),cart):
     errors.append({"run":id,"error":"Departure: "+game.departure_error});continue
    var start_cash: float=game.state.money
    var outfit_cents: int=int(game.outfitter.quote(profession,cart).get("total_cents",0))
    var profile: Dictionary=profile_for(style)
    var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
    var aim:=RandomNumberGenerator.new()
    aim.seed=seed_value ^ 0x42414c
    var acts: Dictionary={"theft":0,"robbery":0}
    var events: Dictionary={}
    var last_event: String=""
    var min_food: int=game.state.food
    var min_cash: float=start_cash
    var outcome: String="action_limit"
    var idle: int=0
    var onset_miles: Array=[]
    var sick_seen: int=0
    for step in range(3000):
     if game.state.status!="traveling":outcome=game.state.status;break
     if game.state.day>=365:outcome="year_limit";break
     var pid: String=str(game.pending.get("id",""))
     if pid!="" and pid!=last_event and not game.pending.has("landmark"):events[pid]=int(events.get(pid,0))+1
     last_event=pid
     var day: int=game.state.day
     var mile: int=game.state.miles
     var available: bool=game.pending.is_empty() or game.pending.has("landmark")
     var okay: bool=true
     if game.pending.get("crime_menu",false):
      var stage: String=game.crime.incident().get("stage","")
      if stage=="custody":okay=pick(game,"crime_command","bail") or pick(game,"crime_command","vouch") or pick(game,"crime_command","wait")
      elif stage=="standoff":okay=pick(game,"crime_command","flee") or pick(game,"crime_command","surrender")
      else:okay=settle_crime(game)
     elif game.pending.get("remains_menu",false) or game.pending.get("attack_menu",false):okay=game.choose(game.pending.choices.size()-1)
     elif style=="petty" and available and acts.theft==0 and game.state.day>=10 and game.crime.eligible(game) and game.crime.transient(game.crime.target(game)):
      acts.theft+=1
      okay=game.open_crime() and pick(game,"crime_command","theft")
     elif style=="criminal" and available and game.crime.eligible(game) and game.crime.transient(game.crime.target(game)) and (acts.theft<3 or (acts.robbery<3 and game.state.bullets>0)):
      var kind: String="theft" if acts.theft<=acts.robbery or game.state.bullets==0 else "robbery"
      acts[kind]+=1
      okay=game.open_crime() and pick(game,"crime_command",kind)
     elif style in ["reckless","fighter"] and reckless_choice(game,style):okay=true
     else:
      okay=act(game,profile,aim,count)
      # The shared bot gives up when a hunt cannot start (for example no long gun left); move on instead.
      if not okay and game.pending.is_empty() and game.state.status=="traveling":
       count["fallbacks"]=int(count.get("fallbacks",0))+1
       okay=game.travel() or game.rest()
     if not okay:outcome="policy_blocked";errors.append({"run":id,"error":outcome,"pending":game.pending.get("id",""),"day":game.state.day,"stage":game.crime.incident().get("stage",""),"status":game.state.status,"can_act":game._can_act(),"repair":game.camp_repair.blocked(game),"raft":not game.raft.is_empty(),"hunt":not game.hunt.is_empty(),"vehicle":game.state.vehicle,"oxen":game.state.oxen,"journal":game.journal.slice(-4),"choices":game.pending.get("choices",[]).map(func(c):return [c.get("label",""),c.get("crime_command","")])});break
     idle=idle+1 if day==game.state.day and mile==game.state.miles else 0
     if idle>40:outcome="policy_stalled";errors.append({"run":id,"error":outcome,"pending":game.pending.get("id","")});break
     if game.state.miles>mile:count.travel_days+=1
     if game.state.day>day and game.state.food==0:count.empty_food_days+=game.state.day-day
     min_food=mini(min_food,int(game.state.food))
     var sick_now: int=game.party_health.members.reduce(func(n,m):return n+m.history.filter(func(h):return h.ends_with("has scurvy.")).size(),0)
     if sick_now>sick_seen:
      onset_miles.append([int(game.state.day),int(game.state.miles),str(game.state.landmark)])
      sick_seen=sick_now
     min_cash=minf(min_cash,game.state.money)
     if game.state.food<0 or game.state.money<0 or game.state.party_size!=game.party_health.living_count() or not game.error.is_empty():
      outcome="invariant_failed";errors.append({"run":id,"error":outcome});break
     if step%150==0 and store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:
      outcome="save_failed";errors.append({"run":id,"error":"save: "+store.error});break
    var leader: Dictionary=game.party_health.members[0]
    var deaths: Array=[]
    for member in game.party_health.members:
     if not member.alive:deaths.append({"id":int(member.id),"cause":str(member.cause)})
    var record: Dictionary=game.crime.record
    rows.append({"style":style,"profession":profession,"seed":seed_value,"month":style_month(style),"outcome":outcome,"loss_reason":str(game.state.get("loss_reason","")),
     "days":int(game.state.day),"arrival_month":int(game.calendar().month),"miles":int(game.state.miles),"survivors":int(game.state.party_size),"leader_alive":bool(leader.alive),
     "deaths":deaths,"scurvy_onsets":game.party_health.members.reduce(func(n,m):return n+m.history.filter(func(h):return h.ends_with("has scurvy.")).size(),0),
     "scurvy_recoveries":game.party_health.members.reduce(func(n,m):return n+m.history.filter(func(h):return h.ends_with("recovered from scurvy.")).size(),0),
     "scurvy_onset_miles":onset_miles,"produce_held":produce_held(game),"departures":game.party_health.members.filter(func(m):return m.get("departed",false)).size(),
     "start_cash":start_cash,"outfit_cents":outfit_cents,"end_cash":game.state.money,"min_cash":min_cash,"end_food":int(game.state.food),"min_food":min_food,
     "oxen":int(game.state.oxen),"bullets":int(game.state.bullets),"audit":game.audit.duplicate(),"counts":count.duplicate(),
     "events":events,"fights":game.combat.history.map(func(r):return {"event":r.get("event",""),"tactic":r.get("tactic",""),"outcome":r.get("outcome","")}),
     "crossings":game.crossing_history.map(func(r):return {"method":r.get("method",""),"mishap":r.get("mishap",false),"lost":r.get("lost",false)}),
     "crimes":record.incidents.map(func(i):return "%s:%s:%s" % [i.action,i.attempt,i.resolution]),"sentences":record.incidents.filter(func(i):return i.has("sentence")).map(func(i):return i.sentence.get("kind",""))})
    await process_frame
   print("%s %s: %d rows, %d errors, %.0fs" % [style,profession,rows.size(),errors.size(),(Time.get_ticks_msec()-started)/1000.0])
 var path: String="res://.tools/play-style-"+label+".json"
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"label":label,"rules_signature":store.fingerprint(),"seed_start":seed_start,"seeds":seeds,"styles":styles,"professions":professions,"runs":rows,"errors":errors},"\t"))
 print("Wrote %s: %d journeys, %d errors" % [path,rows.size(),errors.size()])
 for error in errors:printerr("RUN ERROR: "+JSON.stringify(error))
 quit(0)
