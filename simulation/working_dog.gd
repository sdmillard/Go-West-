extends RefCounted
## One working companion, independent of dairy stock and human party slots.
var data: Dictionary = {}
var error: String = ""
var record: Dictionary = {"dog":{},"purchased_at":[]}
var last: Dictionary = {}
func _init() -> void:
 load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/dogs.json")))
static func number(v: Variant) -> bool:
 return (v is int or v is float) and is_finite(float(v))
func load_data(v: Variant) -> bool:
 error="Invalid working-dog rules."
 if not v is Dictionary or not v.get("note") is String:return false
 for key in ["price_cents","body_kg","rest_kcal","work_kcal","theft_weight_factor"]:
  if not number(v.get(key)) or v[key]<=0 or v[key]>100000:return false
 if v.price_cents!=floor(v.price_cents) or v.work_kcal<v.rest_kcal:return false
 for key in ["search_chance","rabbit_chance","hunt_injury_chance","warning_chance","river_loss_chance"]:
  if not number(v.get(key)) or v[key]<0 or v[key]>1:return false
 data=v.duplicate(true);error="";return true
func alive() -> bool:
 return not record.dog.is_empty() and float(record.dog.condition)>0
func ready(job: String) -> bool:
 return alive() and record.dog.job==job and float(record.dog.condition)>=50 and float(record.dog.fatigue)<75 and float(record.dog.fed)>=0.75
func random(game,salt: int) -> RandomNumberGenerator:
 var result:=RandomNumberGenerator.new()
 result.seed=int(game.state.seed)+int(game.state.day)*7919+salt*104729
 return result
func available(game) -> bool:
 return game.can_service() and not alive() and game.route.nodes[game.state.landmark].kind in ["town","fort"] and game.state.landmark not in record.purchased_at
func acquire(game,paid: bool=true) -> bool:
 if paid and (not available(game) or roundi(game.state.money*100)<int(data.price_cents)):return false
 if alive():return false
 if paid:game.state.money=snappedf(float(game.state.money)-float(data.price_cents)/100.0,0.01)
 record.dog={"name":"BUDDY","condition":100.0,"fatigue":0.0,"fed":1.0,"job":"watch","feeding":"share","last_day":int(game.state.day),"last_hunt":-1}
 if game.state.landmark not in record.purchased_at:record.purchased_at.append(game.state.landmark)
 game.journal.append("Day %d · A working farm shepherd joins the party. Dog meals come from shared provisions after the travelers eat." % game.state.day)
 return true
func configure(game,dog_name: String,job: String,feeding: String) -> bool:
 if not game.can_service() or not alive() or dog_name.strip_edges().is_empty() or dog_name.length()>20 or job not in ["hunt","watch","rest"] or feeding not in ["share","surplus","off"]:return false
 record.dog.name=dog_name.strip_edges();record.dog.job=job;record.dog.feeding=feeding
 return true
func eat(game,wanted: float) -> float:
 # Real remaining portions first, then whole servings. The unused fraction retains mass,
 # vitamins and expiry; it is not an abstract calorie credit or a free scrap allowance.
 var left: float=maxf(0,wanted)
 var unit: float=game.provisions.data.food_energy.unit_kcal
 for portion in game.livestock.record.products:
  if left<0.000000001:break
  if int(portion.expires)<=int(game.state.day) or float(portion.get("vitamin_c_lb",0))>0:continue
  var take: float=minf(left,float(portion.kcal));var fraction: float=take/float(portion.kcal)
  portion.kcal-=take;portion.lb*=1.0-fraction
  if portion.has("vitamin_c_lb"):portion.vitamin_c_lb*=1.0-fraction
  left=maxf(0,left-take)
 game.livestock.record.products=game.livestock.record.products.filter(func(p):return float(p.kcal)>0.000000001)
 while left>0.000000001 and int(game.state.food)>0:
  var vegetables: int=game.provisions.fresh.filter(func(b):return b.get("vitamin_c",false)).reduce(func(n,b):return n+int(b.pounds),0)
  if int(game.state.food)<=vegetables:break
  game.provisions.eat(1,0,int(game.state.food));game.state.food-=1
  var take: float=minf(unit,left);left=maxf(0,left-take)
  var fraction: float=(unit-take)/unit
  if fraction>0.000000001:
   var source: Dictionary=game.provisions.last_serving
   game.livestock.record.products.append({"kind":"portion","lb":float(source.lb)*fraction,"kcal":unit-take,"expires":int(source.expires),"vitamin_c_lb":float(source.vitamin_c_lb)*fraction})
 game.livestock.product_mass(game)
 return wanted-left
func tick(game,resting: bool,moving: bool,hunting_today: bool=false) -> void:
 last={}
 if not alive() or int(record.dog.last_day)>=int(game.state.day):return
 var dog: Dictionary=record.dog
 dog.last_day=int(game.state.day)
 var watching: bool=ready("watch") and not hunting_today
 var working: bool=moving or hunting_today or watching
 var wanted: float=data.work_kcal if working else data.rest_kcal
 var budget: float=wanted
 if dog.feeding=="off":budget=0
 elif dog.feeding=="surplus":
  var reserve: float=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])*float(game.provisions.data.food_energy.unit_kcal)
  budget=minf(wanted,maxf(0,int(game.state.food)*float(game.provisions.data.food_energy.unit_kcal)+game.livestock.available_kcal()-reserve))
 var eaten: float=eat(game,budget) if budget>0 else 0.0
 dog.fed=clampf(eaten/wanted,0,1)
 var waterless: bool=game.on_dry_stretch()
 dog.condition=clampf(float(dog.condition)+(2.0 if resting and dog.fed>=0.95 else 0.0)-6.0*(1.0-float(dog.fed))-(3.0 if waterless else 0.0),0,100)
 dog.fatigue=clampf(float(dog.fatigue)+(12.0 if hunting_today else 3.0 if watching else 4.0 if moving else -16.0),0,100)
 last={"day":int(game.state.day),"eaten_kcal":eaten,"needed_kcal":wanted,"working":working}
 game.journal.append("Day %d · %s ate %.2f food units; condition %s, fatigue %d. Job: %s." % [game.state.day,dog.name,eaten/float(game.provisions.data.food_energy.unit_kcal),game.PartyHealth.condition_label(roundi(dog.condition)),roundi(dog.fatigue),dog.job])
 game.supply_history.append({"day":int(game.state.day),"event":"dog_meal","changes":{},"kcal":eaten})
 if not alive():game.journal.append("Day %d · %s died in poor condition." % [game.state.day,dog.name])
func begin_hunt(game) -> void:
 if not ready("hunt"):return
 var hunt: Dictionary=game.hunt
 hunt["dog"]=str(record.dog.name);hunt["dog_checked"]=false;hunt["dog_seen_rabbits"]=[]
 if hunt.animals.is_empty() and random(game,1000+int(game.hunting_outings)).randf()<float(data.search_chance):
  var r:=random(game,2000+int(game.hunting_outings))
  var rules: Dictionary=game.hunting.data.regions[hunt.region]
  var total: int=int(rules.weights.reduce(func(n,w):return n+int(w),0));var roll: int=r.randi_range(1,total);var kind:=0
  for weight in rules.weights:
   roll-=int(weight)
   if roll<=0:break
   kind+=1
  var species: Dictionary=game.hunting.data.species[kind]
  hunt.animals.append({"kind":kind,"x":100.0,"y":100,"direction":1,"escaped":false,"meat":r.randi_range(int(species.meat_min),int(species.meat_max)),"kcal_per_lb":float(species.kcal_per_lb)})
  hunt["dog_located_game"]=true
  hunt.message="%s located game. Watch for a clear shot." % record.dog.name
 else:hunt.message+=" %s is helping search." % record.dog.name
 hunt_step(game)
func hunt_step(game) -> void:
 var hunt: Dictionary=game.hunt
 if not hunt.has("dog"):return
 # Appearance creates one opportunity. Seeing the same rabbit next frame never rerolls.
 for index in range(hunt.animals.size()):
  var animal: Dictionary=hunt.animals[index]
  if int(animal.kind)!=2 or index in hunt.dog_seen_rabbits:continue
  hunt.dog_seen_rabbits.append(index)
  if index in hunt.targets or animal.get("escaped",false):continue
  hunt.dog_checked=true
  var r:=random(game,3000+int(game.hunting_outings)*100+index)
  if r.randf()>=float(data.rabbit_chance):continue
  hunt.targets.append(index);hunt.meat+=int(animal.meat)
  hunt["dog_rabbit_lb"]=int(hunt.get("dog_rabbit_lb",0))+int(animal.meat)
  hunt.message="%s caught a rabbit: %d lb usable meat." % [record.dog.name,int(animal.meat)]
  game.journal.append("Day %d · %s" % [int(game.state.day)+1,hunt.message])
func finish_hunt(game) -> void:
 if not game.hunt.has("dog") or not alive() or int(record.dog.last_hunt)==int(game.hunting_outings):return
 record.dog.last_hunt=int(game.hunting_outings)
 if random(game,4000+int(game.hunting_outings)).randf()<float(data.hunt_injury_chance):
  record.dog.condition=maxf(0,float(record.dog.condition)-20.0)
  game.journal.append("Day %d · %s was injured while hunting; rest and feeding will help." % [int(game.state.day)+1,record.dog.name])
func warn(game,event: Dictionary) -> void:
 if not ready("watch") or event.id not in ["bandits","riders","horse_thieves"]:return
 if random(game,5000+int(str(event.id).hash())%1000).randf()>=float(data.warning_chance):return
 var text: String="%s barks at movement near camp. You have warning, but cannot yet tell their intentions." % record.dog.name
 event.text=text+"\n"+str(event.text)
 game.journal.append("Day %d · %s" % [game.state.day,text])
func cross(game,crossing: Dictionary) -> void:
 if not alive() or crossing.get("method","")=="ferry":return
 if not crossing.get("mishap",false):return
 if random(game,6000+game.crossing_history.size()).randf()<float(data.river_loss_chance):
  record.dog.condition=0.0;crossing["dog_lost"]=str(record.dog.name)
  game.journal.append("Day %d · %s was lost in the river crossing." % [game.state.day,record.dog.name])
 else:
  record.dog.condition=maxf(0,float(record.dog.condition)-10.0)
  if not alive():crossing["dog_lost"]=str(record.dog.name)
  game.journal.append("Day %d · %s" % [game.state.day,("%s reached the bank, exhausted by the crossing." if alive() else "%s died after the crossing.") % record.dog.name])
func valid(value: Variant,game) -> bool:
 if not value is Dictionary or value.size()!=2 or not value.get("dog") is Dictionary or not value.get("purchased_at") is Array:return false
 if value.purchased_at.size()>game.route.nodes.size():return false
 var seen: Array=[]
 for place in value.purchased_at:
  if not place is String or place not in game.route.nodes or place in seen:return false
  seen.append(place)
 var d: Dictionary=value.dog
 if d.is_empty():return value.purchased_at.is_empty()
 if d.size()!=8 or not d.get("name") is String or d.name.strip_edges().is_empty() or d.name.length()>20:return false
 if d.get("job") not in ["hunt","watch","rest"] or d.get("feeding") not in ["share","surplus","off"]:return false
 for key in ["condition","fatigue","fed"]:
  if not number(d.get(key)) or d[key]<0 or d[key]>(1 if key=="fed" else 100):return false
 for key in ["last_day","last_hunt"]:
  if not number(d.get(key)) or d[key]!=floor(d[key]) or d[key]<(-1 if key=="last_hunt" else 0) or d[key]>(int(game.state.day) if key=="last_day" else int(game.hunting_outings)):return false
 return not value.purchased_at.is_empty()
