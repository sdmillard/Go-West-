extends RefCounted
## Led milk animals, cooped hens and short-lived table products. No global random draws.
const Feeding=preload("res://simulation/livestock_feeding.gd")
const ANIMALS=["dairy_cows","goats","hens"]
const FEED_REMAINDERS=["poultry_feed_remainder_lb","livestock_fodder_remainder_lb"]
const GOODS=["dairy_cows","goats","hens","poultry_feed","livestock_fodder"]
var data: Dictionary={}
var error: String=""
var record: Dictionary={"animals":[],"products":[],"next_id":0,"care":true,"share_scraps":true}
var last: Dictionary={}
var last_meal: Dictionary={}
# Reference to the current hunt's split serving; packing updates the retained fraction.
var hunt_portion: Dictionary={}
func _init():
 load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/livestock.json")))
static func number(v: Variant) -> bool:return (v is int or v is float) and is_finite(v)
static func whole(v: Variant,lo: int,hi: int) -> bool:return number(v) and v==floor(v) and v>=lo and v<=hi
func load_data(v: Variant) -> bool:
 error="Invalid livestock rules."
 if not v is Dictionary or not v.get("note") is String or not v.get("animals") is Dictionary or v.animals.size()!=3:return false
 for key in ["milk_days","egg_days","ferry_head_cents"]:
  if not whole(v.get(key),1,30):return false
 for key in ["care_hours_per_person","moving_care_hours","resting_care_hours","sell_factor"]:
  if not number(v.get(key)) or v[key]<=0 or v[key]>8:return false
 if v.sell_factor>1 or not v.get("months") is Array or v.months.size()!=12:return false
 for n in v.months:
  if not number(n) or n<0 or n>1:return false
 for kind in ANIMALS:
  if not v.animals.get(kind) is Dictionary:return false
  var a: Dictionary=v.animals[kind]
  if not a.get("label") is String:return false
  for key in ["price_cents","maximum","meat_lb","stock"]:
   if not whole(a.get(key),1,100000):return false
  if not whole(a.get("lactation_days"),0,366):return false
  for key in ["daily_lb","kcal_per_lb","care_hours","meat_kcal_per_lb","daily_feed_lb"]:
   if not number(a.get(key)) or a[key]<=0 or a[key]>10000:return false
 if not Feeding.valid(v):return false
 data=v.duplicate(true);error="";return true
static func count(s: Dictionary,kind: String) -> int:return int(s.get(kind,0))
static func cargo(s: Dictionary) -> float:
 var hens:=count(s,"hens")
 return hens*4.0+ceil(hens/6.0)*6.0
func sync(game) -> void:
 for kind in ANIMALS:
  var existing: Array=record.animals.filter(func(a):return a.kind==kind)
  while existing.size()>count(game.state,kind):
   record.animals.erase(existing.pop_back())
  while existing.size()<count(game.state,kind):
   var animal: Dictionary={"id":int(record.next_id),"kind":kind,"condition":100,"remaining":int(data.animals[kind].lactation_days),"egg_progress":0.0}
   record.next_id+=1;record.animals.append(animal);existing.append(animal)
func workers(game) -> int:
 var result:=0
 var busy: Array=game.hunt.get("field",{}).get("members",[]).duplicate()
 if not game.camp_tasks.day_plan.is_empty() and game.camp_tasks.day_plan.get("action","") not in ["","rest"]:busy.append(int(game.camp_tasks.day_plan.leader))
 var patients: Array=[]
 # Only actual camp work reserves care labor. Standing orders do not execute while traveling.
 var plan: Dictionary=game.camp_tasks.day_plan
 for entry in plan.get("jobs",[]):
  if not plan.get("rest",{}).get(int(entry.member),false) and entry.get("ready",true):
   if entry.job!="guard":busy.append(int(entry.member))
   if entry.job=="nurse":patients.append(int(entry.patient))
 if plan.get("action","")=="care":
  # Main-action patients also rest; this marker is assigned by the care action.
  if int(plan.get("leader_patient",-1))>=0:patients.append(int(plan.leader_patient))
 for m in game.party_health.members:
  if game.party_health.is_active(m) and m.health>=50 and int(m.id) not in patients and int(m.id) not in busy:result+=1
 return result
func outlook(game,resting: bool=false) -> Dictionary:
 var hours:=0.0
 for kind in ANIMALS:hours+=count(game.state,kind)*float(data.animals[kind].care_hours)
 var budget: float=minf(float(data.resting_care_hours if resting else data.moving_care_hours),workers(game)*float(data.care_hours_per_person)) if record.care else 0.0
 var season: float=data.months[int(game.calendar().month)-1]
 var waterless: bool=game.current_edge().get("hazard","")=="waterless"
 var result: Dictionary={"hours":hours,"budget":budget,"care_factor":minf(1.0,budget/hours) if hours>0 else 1.0,"season":season,"waterless":waterless,"feed_needed":count(game.state,"hens"),"feed_held":count(game.state,"poultry_feed")}
 result["feeding"]=Feeding.plan(game,result,resting,not resting)
 return result
func tick(game,resting: bool,working: bool) -> void:
 sync(game)
 last={}
 if record.animals.is_empty() and record.products.is_empty():return
 var day: int=game.state.day
 var o:=outlook(game,resting)
 var eggs:=0
 var milk:=0.0
 var milk_kcal:=0.0
 var expired_lb:=0.0
 var expired_kcal:=0.0
 for p in record.products:
  if int(p.expires)<=day:expired_lb+=float(p.lb);expired_kcal+=float(p.kcal)
 record.products=record.products.filter(func(p):return int(p.expires)>day)
 if expired_kcal>0:
  game.supply_history.append({"day":day,"event":"table_food_spoilage","changes":{},"lb":expired_lb,"kcal":expired_kcal})
  game.journal.append("Day %d · Spoiled table food: %.2f lb (%.2f food units)." % [day,expired_lb,expired_kcal/float(game.provisions.data.food_energy.unit_kcal)])
 var deaths: Array=[]
 var feeding: Dictionary=Feeding.plan(game,o,resting,working,true)
 var feed: int=feeding.grain_quarters
 for a in record.animals:
  var rule: Dictionary=data.animals[a.kind]
  var nutrition: Dictionary=feeding.animals[a.kind]
  var settled: Dictionary=Feeding.settle(data,int(a.condition),float(a.get("strain_carry",0)),float(nutrition.intake),bool(o.waterless),str(game.survival.weather.get("id","")),resting,working,int(game.state.pace))
  a.condition=int(settled.condition)
  if float(settled.strain_carry)>0:a["strain_carry"]=settled.strain_carry
  else:a.erase("strain_carry")
  if a.condition==0:
   deaths.append(a);continue
  # Food, water, body condition and collection are constraints, not stacked percentages.
  var factor: float=minf(float(nutrition.production),minf(Feeding.capacity(data,int(a.condition)),float(o.care_factor)))
  factor=minf(factor,0.1 if o.waterless else 1.0)
  if a.kind=="hens":factor=minf(factor,float(nutrition.quality))
  if a.kind=="hens":
   a.egg_progress=float("%.12f" % (float(a.egg_progress)+0.5*factor*float(data.feeding.laying_months[int(game.calendar().month)-1])))
   if a.egg_progress>=1:
    var n:=floori(a.egg_progress);a.egg_progress=float("%.12f" % (float(a.egg_progress)-n));eggs+=n
    record.products.append({"kind":"egg","lb":float(rule.daily_lb)*n,"kcal":float(rule.daily_lb)*float(rule.kcal_per_lb)*n,"expires":day+int(data.egg_days)})
  elif int(a.remaining)>0:
   var mass: float=float(rule.daily_lb)*factor*clampf(float(a.remaining)/60.0,0,1)
   a.remaining-=1
   if mass>0:
    milk+=mass;milk_kcal+=mass*float(rule.kcal_per_lb)
    record.products.append({"kind":"milk","lb":mass,"kcal":mass*float(rule.kcal_per_lb),"expires":day+int(data.milk_days)})
 for a in deaths:
  record.animals.erase(a);game.state[a.kind]=count(game.state,a.kind)-1
  game.journal.append("Day %d · Lost a %s to poor condition." % [day,data.animals[a.kind].label.to_lower()])
 # Products keep their own calories, edible mass and expiry until an actual meal.
 product_mass(game)
 var food: float=(milk_kcal+eggs*float(data.animals.hens.daily_lb)*float(data.animals.hens.kcal_per_lb))/float(game.provisions.data.food_energy.unit_kcal)
 var left:=0.0
 if o.hours>0 and o.budget>0:game.state.fatigue=mini(100,int(game.state.fatigue)+ceili(minf(float(o.hours),float(o.budget))))
 last={"day":day,"milk_lb":snappedf(milk,0.01),"eggs":eggs,"feed_quarters":feed,"food":food,"left_lb":snappedf(left,0.01),"care_factor":o.care_factor,"feeding":feeding}
 if milk>0 or eggs>0 or feed>0 or feeding.fodder_lb>0 or feeding.scraps_kcal>0 or not deaths.is_empty():
  game.supply_history.append({"day":day,"event":"livestock","changes":{"food":0,"poultry_feed":-feed,"livestock_fodder":-int(feeding.fodder_units)},"products":last.duplicate()})
  game.journal.append("Day %d · Livestock: %.2f lb milk, %d eggs; %.2f food units produced. Grain %.2f lb; fodder %.2f lb; scratching %.2f lb feed-equivalent; shared portions %.2f lb. Care %d%%." % [day,milk,eggs,food,feeding.grain_lb,feeding.fodder_lb,feeding.scratch_lb,feeding.scraps_lb,roundi(float(o.care_factor)*100)])
func rows(game,key: String) -> Array:
 var result: Array=[]
 for item in GOODS:
  var rule: Dictionary=data.animals.get(item,data.supplies.get(item,{}))
  var buy_key: String=key+"|buy_"+item
  var sell_key: String=key+"|sell_"+item
  var held:=count(game.state,item)
  var limit: int=int(rule.get("maximum",4000))
  var cents: int=maxi(1,roundi(int(rule.price_cents)*float(game.context.region(game).price)))
  result.append({"item":item,"label":rule.label,"amount":1,"buy_cents":cents,"sell_cents":floori(cents*float(data.sell_factor)),"can_buy":mini(limit-held,maxi(0,int(rule.stock)-int(game.context.record.spent.get(buy_key+"|units",0)))),"can_sell":mini(held,maxi(0,int(rule.stock)-int(game.context.record.spent.get(sell_key+"|units",0)))),"held":held,"buy_key":buy_key,"sell_key":sell_key,"sells":true,"buys":true})
 return result
func valid(v: Variant,s: Dictionary) -> bool:
 if not v is Dictionary or v.size() not in [4,5] or not v.get("animals") is Array or not v.get("products") is Array or not whole(v.get("next_id"),0,1000000) or not v.get("care") is bool:return false
 if v.has("share_scraps") and not v.share_scraps is bool:return false
 if v.size()==5 and not v.has("share_scraps"):return false
 if v.animals.size()>36 or v.products.size()>1000:return false
 var ids: Array=[]
 for a in v.animals:
  if not a is Dictionary or a.size() not in [5,6] or a.get("kind") not in ANIMALS:return false
  if not whole(a.get("id"),0,int(v.next_id)-1) or a.id in ids or not whole(a.get("condition"),1,100) or not whole(a.get("remaining"),0,int(data.animals[a.kind].lactation_days)) or not number(a.get("egg_progress")) or a.egg_progress<0 or a.egg_progress>=1:return false
  if a.size()==6 and not a.has("strain_carry"):return false
  if a.has("strain_carry") and (not number(a.strain_carry) or a.strain_carry<0 or a.strain_carry>=1):return false
  ids.append(a.id)
 for kind in data.supplies:
  var remainder: Variant=s.get(kind+"_remainder_lb",0)
  if not number(remainder) or remainder<0 or remainder>=float(data.supplies[kind].unit_lb):return false
 for kind in GOODS:
  if not whole(s.get(kind,0),0,int(data.animals.get(kind,data.supplies.get(kind,{})).get("maximum",4000))):return false
  if kind in ANIMALS and v.animals.filter(func(a):return a.kind==kind).size()!=count(s,kind):return false
 var product_mass:=0.0
 for p in v.products:
  if not p is Dictionary or p.size() not in [4,5] or p.get("kind") not in ["milk","egg","portion"]:return false
  if p.size()==5 and (p.kind!="portion" or not number(p.get("vitamin_c_lb")) or p.vitamin_c_lb<0 or p.vitamin_c_lb>100):return false
  if not number(p.get("lb")) or not number(p.get("kcal")) or p.lb<=0 or p.lb>100 or p.kcal<=0 or p.kcal>100000:return false
  if not whole(p.get("expires"),int(s.day)+1,1000100 if p.kind=="portion" else int(s.day)+int(data.egg_days)):return false
  var low: float=277.0 if p.kind=="milk" else (float(data.animals.hens.kcal_per_lb) if p.kind=="egg" else 0.01)
  var high: float=313.0 if p.kind=="milk" else (low if p.kind=="egg" else 100000)
  if p.kind=="portion" and p.kcal>=float(1000)+0.000001:return false
  if float(p.kcal)/float(p.lb)<low-0.001 or float(p.kcal)/float(p.lb)>high+0.001:return false
  product_mass+=float(p.lb)
 if not number(s.get("livestock_products_lb",0)) or absf(float(s.get("livestock_products_lb",0))-product_mass)>0.000001:return false
 return true
func set_care(game,on: bool) -> bool:
 if not game.can_service():return false
 record.care=on;return true
func butcher_offer(game,kind: String,by_hand: bool=false) -> Dictionary:
 if kind not in ANIMALS or not game.can_service() or count(game.state,kind)<1:return {}
 var hand: bool=by_hand or kind=="hens"
 if not hand and int(game.state.bullets)<1:return {}
 var animals: Array=record.animals.filter(func(a):return a.kind==kind)
 if animals.is_empty():return {}
 var a: Dictionary=animals[-1]
 return {"kind":kind,"id":a.id,"meat":float(data.animals[kind].meat_lb)*(0.5+float(a.condition)/200.0),"bullets":0 if hand else 1,"injury_chance":0.0 if kind=="hens" or not hand else 0.35,"by_hand":hand}
func butcher(game,kind: String,by_hand: bool=false) -> bool:
 var offer:=butcher_offer(game,kind,by_hand)
 if offer.is_empty():return false
 record.animals=record.animals.filter(func(a):return int(a.id)!=int(offer.id))
 game.state[kind]=count(game.state,kind)-1;game.state.bullets-=int(offer.bullets)
 if offer.injury_chance>0:game._butcher_by_hand(offer,str(data.animals[kind].label))
 # Butchery is beside the party's cargo; all edible flesh is available, but physical storage still limits it.
 var room: float=maxf(0,game.provisions.storage_capacity(game.state)-game.provisions.cargo(game.state))
 var mass: float=minf(float(offer.meat),room)
 var units: int=game.provisions.add_meat(mass,int(game.state.day)+1,float(data.animals[kind].meat_kcal_per_lb),false)
 game.state.food+=units
 game.journal.append("Day %d · Butchered a %s: %.1f lb edible meat packed, %.1f lb left; %d food units. One day, %d bullet(s)." % [game.state.day+1,data.animals[kind].label.to_lower(),mass,float(offer.meat)-mass,units,offer.bullets])
 game.supply_history.append({"day":game.state.day+1,"event":"livestock_slaughter","changes":{kind:-1,"bullets":-int(offer.bullets),"food":units},"packed_lb":mass,"left_lb":float(offer.meat)-mass})
 game._tick_day(false,false,"slaughter");game._update_river_stage();return true
func cross(game,result: Dictionary) -> void:
 if record.animals.is_empty() or not result.get("mishap",false) or result.get("method","")=="ferry":return
 var rng:=RandomNumberGenerator.new();rng.seed=hash("livestock-cross|%s|%s|%s" % [game.state.seed,game.state.day,game.state.landmark])
 var lost: Dictionary={}
 for kind in ANIMALS:
  if count(game.state,kind)>0 and rng.randf()<(0.3 if kind=="hens" else 0.25):
   game.state[kind]=count(game.state,kind)-1;lost[kind]=1
 sync(game)
 result["livestock_lost"]=lost
 if not lost.is_empty():game.journal.append("Day %d · Crossing livestock losses: %s." % [game.state.day,str(lost)])

func drop_grain(game,amount: int) -> bool:return drop_feed(game,"poultry_feed",amount)
func drop_feed(game,kind: String,amount: int) -> bool:
 if kind not in data.supplies or not game.can_service() or amount<1 or amount>count(game.state,kind):return false
 game.state[kind]-=amount
 game.supply_history.append({"day":game.state.day,"event":"discard_"+kind,"changes":{kind:-amount}})
 game.journal.append("Day %d · Discarded %.2f lb %s." % [game.state.day,amount*float(data.supplies[kind].unit_lb),data.supplies[kind].label.to_lower()]);return true
func discard_feed_remainders(game) -> bool:
 if not game.can_service():return false
 for key in FEED_REMAINDERS:game.state.erase(key)
 game.journal.append("Day %d · Discarded partial grain and fodder servings." % game.state.day);return true
func set_scraps(game,on: bool) -> bool:
 if not game.can_service():return false
 record["share_scraps"]=on;return true
func discard_products(game) -> bool:
 if not game.can_service() or record.products.is_empty():return false
 record.products.clear();game.state.livestock_products_lb=0.0
 game.journal.append("Day %d · Discarded the unconverted milk and eggs." % game.state.day);return true

func product_mass(game) -> float:
 var mass:=0.0
 for p in record.products:
  p.lb=float("%.12f" % float(p.lb));p.kcal=float("%.9f" % float(p.kcal))
  if p.has("vitamin_c_lb"):p.vitamin_c_lb=float("%.12f" % float(p.vitamin_c_lb))
  mass+=float(p.lb)
 mass=float("%.12f" % mass)
 game.state["livestock_products_lb"]=mass
 return mass
func available_kcal() -> float:
 return record.products.reduce(func(n,p):return n+float(p.kcal),0.0)
func meal(game,needed: int,vitamin_offset: float=0.0) -> Dictionary:
 return preload("res://simulation/table_meals.gd").serve(game,needed,vitamin_offset)
func pack(game) -> void:
 # Today's table food can be eaten before packing. Every retained fraction has real mass.
 var mass:=product_mass(game)
 var room: float=maxf(0,game.provisions.storage_capacity(game.state)-game.provisions.cargo(game.state)+mass)
 var left:=0.0
 record.products.sort_custom(func(a,b):return a.expires>b.expires)
 for p in record.products:
  var keep: float=minf(float(p.lb),room)
  var fraction: float=keep/float(p.lb)
  left+=float(p.lb)-keep;room=maxf(0,room-keep)
  p.lb=keep;p.kcal*=fraction
  if p.has("vitamin_c_lb"):p.vitamin_c_lb*=fraction
 record.products=record.products.filter(func(p):return float(p.lb)>0.000000001 and float(p.kcal)>0.000000001)
 product_mass(game)
 if left>0.000001:
  last["left_lb"]=float(last.get("left_lb",0))+left
  game.supply_history.append({"day":game.state.day,"event":"livestock_packing","changes":{},"left_lb":left})
  game.journal.append("Day %d · Left %.2f lb table food after meals: no cargo room." % [game.state.day,left])
