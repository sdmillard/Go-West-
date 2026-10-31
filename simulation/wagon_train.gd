extends RefCounted
## Wagons share supplies, but never share drivers or draft animals.
static func count(s: Dictionary) -> int:
 if s.get("vehicle","")=="foot":return 0
 return s.wagon_train.size() if s.has("wagon_train") else 1
static func ensure(game,s: Dictionary) -> void:
 if s.has("wagon_train"):return
 s["wagon_train"]=[];s["next_wagon_id"]=0
 if s.vehicle!="foot":
  s.next_wagon_id=1
  s.wagon_train.append({"id":0,"driver":game.camp_tasks.leader_id(game),"team":game.team_conditions.record.working.duplicate(),"condition":100})
  if game.camp_repair.blocked(game):s.wagon_train[0].condition=0;s["repair_wagon_id"]=0
static func drivers(game) -> Array:
 var result: Array=[]
 var patients: Dictionary=game.camp_tasks.patient_nurses(game)
 for member in game.party_health.members:
  if game.party_health.is_active(member) and not patients.has(int(member.id)) and member.health>0:result.append(int(member.id))
 return result
static func balance(s: Dictionary,people: Array,stock: Array) -> void:
 var n: int=s.wagon_train.size()
 if n==0:return
 var animals: Array=range(int(s.oxen))
 animals.sort_custom(func(a,b):return int(stock[a] if a<stock.size() else 100)>int(stock[b] if b<stock.size() else 100))
 for wagon in s.wagon_train:wagon.team=[]
 for i in range(mini(animals.size(),n*6)):s.wagon_train[i%n].team.append(animals[i])
 var used: Array=[]
 for wagon in s.wagon_train:
  if wagon.driver not in people or wagon.driver in used:wagon.driver=-1
  else:used.append(int(wagon.driver))
 for wagon in s.wagon_train:
  if int(wagon.driver)>=0:continue
  for id in people:
   if id not in used:wagon.driver=int(id);used.append(int(id));break
static func working(s: Dictionary) -> Array:
 var result: Array=[]
 for wagon in s.get("wagon_train",[]):result.append_array(wagon.team)
 return result
static func sync(game) -> void:
 var s: Dictionary=game.state
 if not s.has("wagon_train"):return
 if s.vehicle=="foot":s.wagon_train=[];return
 if s.wagon_train.is_empty():
  s.wagon_train.append({"id":int(s.next_wagon_id),"driver":-1,"team":[],"condition":100});s.next_wagon_id+=1
  balance(s,drivers(game),game.team_conditions.record.oxen)
 var seen: Array=[]
 for wagon in s.wagon_train:
  var team: Array=[]
  for i in wagon.team:
   if int(i)>=0 and int(i)<int(s.oxen) and int(i) not in seen:team.append(int(i));seen.append(int(i))
  wagon.team=team
static func condition(game,wagon: Dictionary) -> int:
 if wagon.team.is_empty():return 0
 var total:=0
 for i in wagon.team:total+=int(game.team_conditions.record.oxen[int(i)])
 return roundi(float(total)/wagon.team.size())
static func ready(game) -> String:
 if not game.state.has("wagon_train") or count(game.state)==0:return ""
 sync(game)
 var people: Array=drivers(game)
 for wagon in game.state.wagon_train:
  var title: String="Wagon %d" % (int(wagon.id)+1)
  if wagon.driver not in people:return title+" needs an available driver. Reassign the train in Supplies > Wagons & teams."
  if wagon.team.is_empty() or condition(game,wagon)<=0:return title+" needs an ox team. Assign draft animals in Supplies > Wagons & teams."
  if int(wagon.condition)<=0:return title+" needs repairs before the train can move."
 return ""
static func capacity(s: Dictionary,per_ox: float,per_wagon: float) -> float:
 var total: float=0
 for wagon in s.get("wagon_train",[]):total+=minf(per_wagon,wagon.team.size()*per_ox)
 return total
static func speed(game) -> float:
 var result: float=INF
 var capacity: float=game.provisions.capacity(game.state)
 var cargo: float=game.provisions.cargo(game.state)
 for wagon in game.state.wagon_train:
  var load: float=cargo*game.provisions.team_capacity(wagon.team.size())/maxf(1,capacity)
  var factor: float=game.survival.movement_factor(wagon.team.size(),condition(game,wagon),game.state.fatigue,0,game.state.terrain,int(game.calendar().month),game.context.region(game))*game.provisions.movement_factor(load,wagon.team.size())
  result=minf(result,factor)
 return 0.0 if result==INF else result
static func auto_assign(game) -> bool:
 if not game.can_service():return false
 ensure(game,game.state);balance(game.state,drivers(game),game.team_conditions.record.oxen);game.team_conditions.sync(game);return true
static func assign(game,index: int,driver: int,team: Array) -> bool:
 if not game.can_service() or (driver!=-1 and driver not in drivers(game)) or team.size()>6:return false
 ensure(game,game.state)
 if index<0 or index>=game.state.wagon_train.size():return false
 var used: Array=[]
 for i in range(game.state.wagon_train.size()):
  if i==index:continue
  var other: Dictionary=game.state.wagon_train[i]
  if driver>=0 and int(other.driver)==driver:return false
  used.append_array(other.team)
 var selected: Array=[]
 for id in team:
  if not whole(id,0,int(game.state.oxen)-1) or int(id) in used or int(id) in selected:return false
  selected.append(int(id))
 game.state.wagon_train[index].driver=driver;game.state.wagon_train[index].team=selected
 game.team_conditions.sync(game);return true
static func discard_quote(game,index: int) -> Dictionary:
 if not game.can_service() or count(game.state)<2:return {}
 ensure(game,game.state)
 if index<0 or index>=game.state.wagon_train.size():return {}
 var after: Dictionary=game.state.duplicate(true);var wagon: Dictionary=after.wagon_train[index];after.wagon_train.remove_at(index)
 return {"wagon":int(wagon.id),"cargo":game.provisions.cargo(game.state),"capacity":game.provisions.storage_capacity(after)}
static func discard(game,index: int) -> bool:
 var offer: Dictionary=discard_quote(game,index)
 if offer.is_empty():return false
 if int(game.state.get("repair_wagon_id",-1))==int(offer.wagon):game.camp_repair.work={};game.state.erase("repair_wagon_id")
 game.state.wagon_train.remove_at(index);game.team_conditions.sync(game)
 game.journal.append("Day %d · Left empty wagon %d behind permanently. People, oxen and supplies were kept with the remaining train; cargo %.1f / %.0f lb." % [game.state.day,int(offer.wagon)+1,offer.cargo,offer.capacity])
 game.supply_history.append({"day":int(game.state.day),"event":"discard_empty_wagon","wagon":int(offer.wagon),"changes":{"wagons":-1}})
 return true
static func repair_done(game) -> void:
 if game.state.has("wagon_train"):
  for wagon in game.state.wagon_train:
   if int(wagon.id)==int(game.state.get("repair_wagon_id",-1)):wagon.condition=100
 game.state.erase("repair_wagon_id")
static func whole(v: Variant,lo: int,hi: int) -> bool:return (v is int or v is float) and is_finite(v) and v==floor(v) and v>=lo and v<=hi
static func valid(s: Dictionary,count_people: int,stock_count: int=-1) -> bool:
 if not s.has("wagon_train"):return not s.has("next_wagon_id") and not s.has("repair_wagon_id")
 if not s.wagon_train is Array or not whole(s.get("next_wagon_id"),0,2147483647):return false
 if (s.vehicle=="foot")!=s.wagon_train.is_empty():return false
 if s.has("repair_wagon_id") and not whole(s.repair_wagon_id,0,int(s.next_wagon_id)-1):return false
 var ids: Array=[];var people: Array=[];var teams: Array=[]
 for wagon in s.wagon_train:
  if not wagon is Dictionary or wagon.size()!=4 or not whole(wagon.get("id"),0,int(s.next_wagon_id)-1) or int(wagon.id) in ids or not whole(wagon.get("driver"),-1,count_people-1) or not whole(wagon.get("condition"),0,100) or not wagon.get("team") is Array or wagon.team.size()>6:return false
  ids.append(int(wagon.id))
  if int(wagon.driver)>=0:
   if int(wagon.driver) in people:return false
   people.append(int(wagon.driver))
  for id in wagon.team:
   if not whole(id,0,(int(s.oxen) if stock_count<0 else stock_count)-1) or int(id) in teams:return false
   teams.append(int(id))
 if s.has("repair_wagon_id") and int(s.repair_wagon_id) not in ids:return false
 return true
