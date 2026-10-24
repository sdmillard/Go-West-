extends "res://tests/outlaw_journeys.gd"
## A declared player policy through current public actions. Archived policies remain unchanged.
func bump(count: Dictionary,key: String,n: int=1) -> void:count[key]=int(count.get(key,0))+n
func service_choice(game,key: String,value: Variant) -> bool:
 for index in range(game.pending.get("choices",[]).size()):
  if game.pending.choices[index].get(key)==value and game.can_choose(index):return game.choose(index)
 return false
func produce_held(game) -> int:
 return game.Produce.units(game.provisions,"produce",int(game.state.day))+game.Produce.units(game.provisions,"dried_produce",int(game.state.day))
func counter_visit(game,profile: Dictionary,count: Dictionary,fundraising: bool=false) -> bool:
 for venue in ["","camp"]:
  var store: Dictionary=game.trade_counter(venue)
  if store.is_empty():continue
  var emergency: bool=game.state.food<int(game.state.party_size)*3 or (profile.hunt and game.state.bullets<5)
  var toll_ahead: bool="barlow_pass" not in game.travelled_path()
  var reserve: int=(1000 if toll_ahead else 0) if emergency else int(profile.get("cash_reserve",20))*100
  var budget: int=maxi(0,roundi(game.state.money*100)-reserve)
  var cart: Dictionary={}
  var targets: Dictionary={}
  var walking: bool=game.state.vehicle=="foot"
  var food_goal: int=int(profile.get("post_food",600)) if store.kind=="post" else int(profile.get("road_food",90))
  if profile.get("opportunity",0)==1 and store.kind=="post":
   var habitat: String=game.route.nodes[game.state.landmark].get("hunting_region","plains")
   if habitat in ["plains","woodland"]:food_goal=90
   elif game.state.landmark=="fort_boise":food_goal=900
   elif habitat=="highcountry":food_goal=300
  if walking and (not profile.get("mount_support",false) or game.mount_plan().mode=="walking"):food_goal=mini(25,food_goal)
  if game.state.food<food_goal:targets.food=food_goal
  if game.state.clothing<game.state.party_size:targets.clothing=int(game.state.party_size)
  if profile.hunt and game.state.bullets<(60 if store.kind=="post" else 15):targets.bullets=100 if store.kind=="post" else 40
  if profile.get("preserve","")=="salt" and game.state.salt<4:targets.salt=8
  if not walking and game.state.oxen<4:targets.oxen=4
  if game.state.medicine<1:targets.medicine=1
  if walking and profile.get("mount_support",false):
   for stock in profile.get("mount_targets",{}):
    if game.Mounts.count(game.state,stock)<int(profile.mount_targets[stock]):targets[stock]=int(profile.mount_targets[stock])
  var gap: int=int(game.party_health.days_without_fresh)
  if profile.get("produce",true) and produce_held(game)==0 and gap>=int(profile.get("forage_gap",20)):
   targets.produce=2
   targets.dried_produce=3
  # Nutrition, missing clothes and an actual team come before stockpiling ordinary food.
  for item in ["produce","dried_produce","clothing","oxen","bullets","food","salt","medicine","horses","mules"]:
   if not targets.has(item):continue
   if item=="dried_produce" and int(cart.get("produce",0))>0:continue
   var matches: Array=store.rows.filter(func(row):return row.item==item)
   if matches.is_empty():continue
   var row: Dictionary=matches[0]
   var target: int=int(targets[item])
   var held: int=int(row.held)
   var cost: float=float(row.buy_cents)/float(row.amount)
   var n: int=mini(mini(int(row.can_buy),maxi(0,target-held)),floori(budget/cost))
   if n<=0:continue
   cart[item]=n
   var quote: Dictionary=game.counter_quote(cart,venue)
   # Avoid loading more than the current vehicle/team can reasonably carry.
   while n>0 and (not quote.valid or float(quote.cargo_after_lb)>float(quote.capacity_after_lb)):
    n-=1
    if n==0:cart.erase(item)
    else:cart[item]=n
    quote=game.counter_quote(cart,venue)
   budget=maxi(0,roundi(game.state.money*100)-reserve+int(quote.get("net_cents",0)))
  if fundraising:
   cart={}
   for item in ["wheels","axles","tongues","bullets","salt","food"]:
    var matches: Array=store.rows.filter(func(row):return row.item==item)
    if matches.is_empty():continue
    var row: Dictionary=matches[0]
    var keep: int=20 if item=="bullets" else (20 if item=="food" else 0)
    var n: int=mini(int(row.can_sell),maxi(0,int(row.held)-keep))
    if store.purse_cents>=0 and int(row.sell_cents)>0:n=mini(n,floori(float(store.purse_cents)*row.amount/row.sell_cents))
    if n>0:
     cart[item]=-n
     break
  if cart.is_empty():continue
  var quote: Dictionary=game.counter_quote(cart,venue)
  if quote.valid and game.counter_checkout(cart,venue):
   bump(count,"counter_visits")
   bump(count,"counter_cents",-int(quote.net_cents))
   bump(count,"counter_"+str(store.kind))
   for item in cart:
    if item in ["produce","dried_produce"] and int(cart[item])>0:bump(count,"bought_"+item,int(cart[item]))
   return true
 return false
func recruit(game,profile: Dictionary,count: Dictionary) -> bool:
 if not profile.get("recruit",false) or not game.current_party_slots().has(-1) or game.state.food<int(game.state.party_size)*6:return false
 var site: String=game.recruitment.site(game)
 if site.is_empty() or game.recruitment.blocked(game,site):return false
 if game.recruitment.record.searches.has(site):return false
 if not game.open_companions():return false
 var searched: bool=service_choice(game,"recruit_command","search")
 if not searched:
  service_choice(game,"recruit_command","back")
  return false
 bump(count,"recruit_searches")
 if game.state.status!="traveling":return true
 var candidate: Dictionary=game.recruitment.candidate(game)
 if not candidate.is_empty():
  var wage: int=int(candidate.terms.get("wage_cents",0))
  if wage==0 or game.state.money*100>wage*8+3000:
   if service_choice(game,"recruit_command","accept"):bump(count,"recruits")
  else:service_choice(game,"recruit_command","decline")
 service_choice(game,"recruit_command","back")
 return true
func trim_foot(game,count: Dictionary) -> bool:
 if game.pending.get("id","")=="packs_too_heavy":return game.choose(0)
 if not game.can_service() or game.state.vehicle!="foot":return false
 var excess: float=game.provisions.cargo(game.state)-game.provisions.capacity(game.state)
 if excess<=0:return false
 for item in ["wheels","axles","tongues","salt","bullets","medicine","food","clothing"]:
  var amount: int=int(game.state.get(item,0))
  var keep: int=int(game.state.party_size) if item=="clothing" else 0
  if amount<=keep:continue
  var n: int=mini(amount-keep,maxi(1,ceili(excess/float(game.provisions.data.weights_lb[item]))))
  if game.discard_supply(item,n):bump(count,"discards");return true
 # Fixed personal gear may exceed an injured party's capacity even after drops.
 # Use a real recovery day instead of repeating a no-time travel acknowledgement.
 bump(count,"rests")
 return game.rest_in_camp()
func abandon(game,count: Dictionary) -> bool:
 if not game._can_act() or game.state.vehicle=="foot":return false
 var pack: Dictionary={"clothing":mini(int(game.state.party_size),int(game.state.clothing)),"bullets":mini(20,int(game.state.bullets)),"medicine":mini(1,int(game.state.medicine)),"salt":mini(1,int(game.state.salt))}
 var quote: Dictionary=game.pack_quote(pack)
 if not quote.has("capacity_lb"):return false
 pack.food=mini(int(game.state.food),maxi(0,floori(float(quote.capacity_lb)-float(quote.cargo_lb))-5))
 while int(pack.food)>0 and not game.pack_quote(pack).valid:pack.food-=1
 if game.abandon_wagon(pack):bump(count,"abandonments");return true
 return false
func act(game,profile: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 if profile.get("legacy",false):return super.act(game,profile,aim,count)
 if trim_foot(game,count):return true
 var ration: int=int(profile.rations)
 if profile.get("adaptive_rations",true) and game.party_health.members.any(func(m):return game.party_health.is_active(m) and (int(m.health)<80 or not m.conditions.is_empty())):ration=2
 game.configure(int(profile.pace),ration)
 if game.can_service():
  if counter_visit(game,profile,count):return true
  if recruit(game,profile,count):return true
  if game.state.day-int(count.last_care)>=3 and _try_care(game,count,int(profile.get("care_below",55))):return true
  var deficient: bool=game.party_health.members.any(func(m):return game.party_health.is_active(m) and m.conditions.any(func(c):return c.id=="scurvy"))
  if profile.get("produce",true) and produce_held(game)==0 and int(game.party_health.days_without_fresh)>=int(profile.get("forage_gap",20)) and game.state.day-int(count.get("last_forage",-100))>=(2 if deficient else 4) and game.forage_offer().available:
   if game.open_forage() and service_choice(game,"foraging",true):
    bump(count,"forages")
    count.last_forage=int(game.state.day)
    return true
  if profile.get("dry_fruit",false) and not game.produce_drying_offer().is_empty() and game.produce_drying_offer().input>=3:
   bump(count,"produce_drying")
   return game.dry_produce()
 if not game.pending.is_empty():
  if game.pending.has("landmark"):
   for index in range(game.pending.choices.size()):
    var choice: Dictionary=game.pending.choices[index]
    if choice.get("action","")=="activity" and game.can_choose(index):
     var kind: String=game.context.data.activities[choice.activity].kind
     if (kind=="graze" and game.state.ox_health<85) or (kind=="prepare" and game.state.river_stage=="high" and game.state.medicine>1):return game.choose(index)
   if game.route.nodes[game.state.landmark].kind=="river":
    var methods: Array=["ferry",("horses" if profile.get("mount_support",false) and game.Mounts.animals(game.state)>0 else ("swim" if game.state.river_stage=="high" else "wade"))] if game.state.vehicle=="foot" else ["ferry","float" if game.state.river_stage=="high" else "ford"]
    for method in methods:
     if method=="ferry" and "barlow_pass" not in game.travelled_path():
      var ferries: Array=game.pending.choices.filter(func(c):return c.get("method","")=="ferry")
      var fare: float=float(ferries[0].get("requires",{}).get("money",0)) if not ferries.is_empty() else 0.0
      if game.state.money-fare<6.0:continue
     if service_choice(game,"method",method):return true
   # The route sensitivity sets a real branch label, never an invented shortcut.
   if profile.get("branch","")!="":
    for index in range(game.pending.choices.size()):
     var choice: Dictionary=game.pending.choices[index]
     if choice.get("action","")=="leave" and str(choice.label).to_lower().contains(str(profile.branch)) and game.can_choose(index):return game.choose(index)
  for index in range(game.pending.choices.size()):
   if game.pending.choices[index].get("action","") not in ["notes","trade","rest"] and game.can_choose(index):return game.choose(index)
  if game.pending.has("landmark") and game.route.nodes[game.state.landmark].has("toll_dollars"):
   if counter_visit(game,profile,count,true):return true
   # If stranded at a toll, wait for an actual passing party rather than a no-time loop.
   for index in range(game.pending.choices.size()):
    if game.pending.choices[index].get("action","")=="rest" and game.can_choose(index):bump(count,"toll_waits");return game.choose(index)
  return false
 if game.state.oxen==0 and game.state.vehicle!="foot":
  if abandon(game,count):return true
  bump(count,"rests")
  return game.rest()
 if profile.get("preserve","")!="":
  var salted: bool=profile.preserve=="salt" and not game.preservation_offer(true).is_empty()
  var offer: Dictionary=game.preservation_offer(salted)
  var meat: int=game.provisions.fresh.filter(func(b):return not b.get("preserved",false) and not b.get("vitamin_c",false)).reduce(func(total,b):return total+int(b.pounds),0)
  var meal: int=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])
  if not offer.is_empty() and meat>meal*float(profile.get("preserve_meals",0.0)):
   bump(count,"preservations")
   return game.preserve_meat(salted)
 if profile.get("slaughter",true) and game.state.oxen>int(profile.get("slaughter_team_floor",4)) and game.state.food<90 and not game.ox_slaughter_offer().is_empty():bump(count,"oxen_slaughtered");return game.slaughter_ox()
 var threshold: int=int(profile.get("hunt_below",45))
 if game.state.vehicle=="foot" and (not profile.get("mount_support",false) or game.mount_plan().mode=="walking"):threshold=mini(20,threshold)
 if profile.hunt and game.state.food<threshold and game.state.bullets>0:return hunt_outing(game,profile,aim,count)
 var worst: int=game.state.health
 for member in game.party_health.members:
  if game.party_health.is_active(member):worst=mini(worst,int(member.health))
 if profile.rest and (worst<int(profile.get("rest_below",55)) or game.state.fatigue>50 or (game.state.vehicle!="foot" and game.state.ox_health<65) or (profile.get("mount_support",false) and game.mount_plan().mode in ["mounted","doubled","packing"] and game.Mounts.condition(game.state)<int(profile.get("mount_rest_below",65)))) and game.state.food>=game.state.party_size*(ration+1):
  bump(count,"rests")
  return game.rest()
 return game.travel()
