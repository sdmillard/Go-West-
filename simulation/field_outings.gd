extends RefCounted
const Encounters=preload("res://simulation/outing_encounters.gd")
const Follow=preload("res://simulation/outing_follow.gd")
const Outfit=preload("res://simulation/outing_outfit.gd")
var moving:=false
var record: Dictionary={"next_id":1,"trips":[],"preferences":{}}
var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/field_outings.json"))
func snapshot() -> Dictionary:return record.duplicate(true)
func actual_alive(index: int) -> bool:
 for trip in record.trips:
  if int(trip.member)==index:
   var person: Dictionary=trip.camp.guards[0]
   return person.alive and not person.get("departed",false)
 return false
func at_origin(game,trip: Dictionary) -> bool:
 var here: Dictionary=game.CacheSupport.location(game)
 if here==trip.origin:return true
 if int(game.state.miles)!=int(trip.mile):return false
 var original_node: String=endpoint(game,trip.origin)
 return not original_node.is_empty() and original_node==endpoint(game,here)
func endpoint(game,at: Dictionary) -> String:
 var node: String=""
 if at.from==at.to or int(at.offset)==0:node=at.from
 elif int(at.offset)==int(game.route.edge_between(at.from,at.to).get("miles",-1)):node=at.to
 return node if not node.is_empty() and game.route.nodes[node].kind!="river" else ""

func same_road(game,trip: Dictionary) -> bool:
 if game.Direction.heading(game)!=trip.heading:return false
 var here: Dictionary=game.CacheSupport.location(game)
 if here.from==trip.origin.from and here.to==trip.origin.to:return game.route.edge_between(here.from,here.to).get("hazard","")!="river"
 if trip.heading!="west":return false
 var path: Array=game.travelled_path().duplicate()
 if str(game.state.next_landmark)!=str(game.state.landmark):path.append(str(game.state.next_landmark))
 var start: int=path.find(trip.origin.from)
 if start<0:return false
 for i in range(start,path.size()-1):
  if game.route.nodes[path[i]].kind=="river" or game.route.nodes[path[i+1]].kind=="river" or game.route.nodes[path[i]].next.size()!=1 or game.route.edge_between(path[i],path[i+1]).get("hazard","")=="river":return false
 return true
func start(game,index: int,kit: String,days: int,bullets: int) -> bool:
 if not game.can_service() or index<=0 or index>=game.party_health.members.size() or game.state.party_size<2:return false
 var offer: Dictionary=Outfit.quote(game,[index],kit,days,bullets)
 if not offer.valid:return false
 if days>1 and not offer.mounted:return false
 var original: Dictionary=game.party_health.members[index]
 var person: Dictionary=original.duplicate(true)
 person["vitamin_days"]=int(person.get("vitamin_days",game.party_health.days_without_fresh))
 var random:=RandomNumberGenerator.new()
 random.seed=int(game.state.seed)^int(record.next_id)*104729^0x4f5554
 var trip: Dictionary={"id":int(record.next_id),"member":index,"kit":kit,"stock":offer.stock.duplicate(true),"condition":game.Mounts.condition(game.state),"origin":game.CacheSupport.location(game),"mile":int(game.state.miles),"heading":game.Direction.heading(game),"started":int(game.state.day),"due":int(game.state.day)+days,"days":days,"left":false,"stage":"away","delayed":false,"camp":{"camp_random":str(random.state),"camp_day":int(game.state.day),"risk_cumulative":0.0,"gone":false,"guards":[person],"camp_log":[],"habitat":game.context.region_id(game),"camp_rations":int(game.state.rations),"camp_deficiency":int(game.party_health.days_without_fresh),"inventory":offer.inventory.duplicate(true),"fresh":offer.fresh.duplicate(true),"household_gear_lb":float(game.provisions.data.walking.personal_gear_lb_per_person),"location":game.CacheSupport.location(game),"field_working":true}}
 trip.camp["departure_kit"]=kit
 Outfit.reserve(game,offer)
 game.state.household_gear_lb=maxf(0,game.provisions.household_mass(game.state)-float(game.provisions.data.walking.personal_gear_lb_per_person))
 original["away"]=true
 original.history.append("Day %d · Left on a %d-day %s hunting trip. Expected day %d." % [game.state.day,days,"mounted" if offer.mounted else "foot",trip.due])
 record.trips.append(trip);record.next_id+=1
 record.preferences[str(index)]={"kit":kit,"days":days,"bullets":bullets}
 recount(game)
 game.journal.append("Day %d · %s set out hunting: %s; %d food units, %d bullets. Expected day %d." % [game.state.day,original.name,kit,offer.inventory.food,bullets,trip.due])
 game.supply_history.append({"day":game.state.day,"event":"outing_departure","member":index,"inventory":offer.inventory.duplicate(true),"stock":offer.stock.duplicate(true),"changes":{}})
 return true
func recount(game) -> void:
 game.state.party_size=game.party_health.living_count()
 game.state.health=game.party_health.average_health()
func _hunt(game,trip: Dictionary,random) -> bool:
 var cache: Dictionary=trip.camp
 var actual: Dictionary=cache.guards[0]
 if not actual.alive or actual.get("departed",false) or int(cache.inventory.bullets)<1:return false
 var limit: float=Outfit.capacity(game,[actual],trip.kit,trip.stock)
 var food=game.provisions.get_script().new()
 food.data=game.provisions.data.duplicate(true);food.fresh.assign(cache.fresh)
 var load: Dictionary=cache.inventory.duplicate()
 load.merge({"vehicle":"foot","party_size":1})
 var room: int=maxi(0,floori(limit-food.cargo(load)))
 if room<=0:return false
 cache.inventory.bullets-=1
 var region: Dictionary=game.hunting.data.regions[cache.habitat]
 var season: float=float(game.provisions.data.foraging.months[int(game.calendar().month)-1])
 var expert: bool=game.camp_tasks.specialist(game,int(trip.member),"Hunting")
 var chance: float=float(rules.hit_chance)+(float(rules.hunter_bonus) if expert else 0.0)
 var pounds:=0
 if random.randf()>float(region.empty_chance) and random.randf()<chance*(0.5+0.5*season):
  var total:=0
  for weight in region.weights:total+=int(weight)
  var roll: int=random.randi_range(1,total)
  var which:=0
  for weight in region.weights:
   roll-=int(weight)
   if roll<=0:break
   which+=1
  var species: Dictionary=game.hunting.data.species[which]
  pounds=mini(room,random.randi_range(int(species.meat_min),int(species.meat_max)))
 var units: int=food.add_meat(pounds,int(game.state.day))
 if units>0:food.fresh.back()["_outing_catch"]=true
 cache.fresh=food.fresh.duplicate(true);cache.inventory.food+=units
 cache.camp_log.append("Day %d · Spent one bullet hunting; hauled %d lb meat (%d food units)." % [game.state.day,pounds,units])
 return true
func tick(game) -> void:
 for trip in record.trips.duplicate():
  var cache: Dictionary=trip.camp
  if int(cache.camp_day)>=int(game.state.day):continue
  var random:=RandomNumberGenerator.new();random.state=int(cache.camp_random)
  var actual: Dictionary=cache.guards[0]
  var active: bool=actual.alive and not actual.get("departed",false)
  var was_left: bool=actual.get("departed",false)
  if active and not cache.has("crossing"):
   var incident: Dictionary=Encounters.attempt(game,trip,random)
   actual=cache.guards[0];active=actual.alive and not actual.get("departed",false)
   if incident.elapsed:
    cache.camp_day=int(game.state.day);cache.camp_random=str(random.state)
    trip.due+=1
    continue
  if active and cache.has("crossing"):
   Follow.cross(game,trip,random)
   cache.camp_day=int(game.state.day);cache.camp_random=str(random.state)
   trip.due=int(game.state.day)
   cache["return_after_day"]=int(game.state.day)+1
   continue
  var hunted:=false
  var needed: int=int(game.provisions.data.rations_lb[cache.camp_rations])
  if active and ((trip.stage=="away" and int(game.state.day)<=int(trip.started)+int(trip.days)) or (trip.stage=="stranded" and int(cache.inventory.food)<needed*int(game.provisions.data.wagon_guards.hunt_below_days))):hunted=_hunt(game,trip,random)
  # Reuse the cached-guard food, disease, exposure and desertion model.
  # Work trips do not get camp rest or a second automatic hunt.
  cache.field_working=trip.stage=="away" or hunted
  var ammo: int=cache.inventory.bullets
  cache.inventory.bullets=0
  game.Guards._day(game,cache,random)
  cache.inventory.bullets=ammo
  cache.camp_day=int(game.state.day)
  active=actual.alive and not actual.get("departed",false)
  if actual.get("departed",false) and not was_left:
   trip.stock=Outfit.stock("foot");trip.kit="foot"
   cache.camp_log.append("The departing hunter took the outing's animals and tack.")
  if trip.kit!="foot":
   var load: Dictionary=cache.inventory.duplicate()
   load.merge({"vehicle":"foot","party_size":1})
   var food=game.provisions.get_script().new();food.data=game.provisions.data;food.fresh.assign(cache.fresh)
   var wear: int=Outfit.wear(game,trip.kit,1,cache.habitat,food.cargo(load)/maxf(1,Outfit.capacity(game,[actual],trip.kit,trip.stock)),trip.stock)
   trip.condition=maxi(10,int(trip.condition)-wear) if cache.field_working else mini(100,int(trip.condition)+int(game.provisions.data.mounts.rest_recovery))
  cache.camp_random=str(random.state)
 if not moving:resolve_returns(game)
func resolve_returns(game) -> void:
 for trip in record.trips.duplicate():
  var cache: Dictionary=trip.camp
  var actual: Dictionary=cache.guards[0]
  var active: bool=actual.alive and not actual.get("departed",false)
  var random:=RandomNumberGenerator.new();random.state=int(cache.camp_random)
  if cache.get("return_failed",false):
   _missing(game,trip);continue
  if trip.stage=="away" and int(game.state.day)>=int(trip.due):
   if not trip.delayed and active and random.randf()<float(rules.mishap_chance):
    trip.delayed=true;trip.due+=random.randi_range(1,2)
    actual.health=maxi(1,int(actual.health)-random.randi_range(3,10))
    cache.camp_log.append("A difficult return delayed the hunter and left them worn or injured.")
   elif at_origin(game,trip):_return(game,trip)
   elif int(cache.get("return_after_day",0))>int(game.state.day):trip.due=int(cache.return_after_day)
   elif active and trip.kit in ["ride_horse","ride_mule","horse_and_mule"]:
    var result: String=Follow.advance(game,trip,random)
    if result=="joined":_return(game,trip)
    elif result in ["moving","crossing"]:trip.due=int(game.state.day)+1
    else:_strand(game,trip)
   else:_strand(game,trip)
  elif trip.stage=="stranded" and active and not cache.get("wrong_turn",false) and trip.kit in ["ride_horse","ride_mule","horse_and_mule"]:
   var profile: Dictionary=game.characters.profiles[int(trip.member)]
   if profile.trust>game.characters.breaking_point(profile) and ("Loyal" in profile.specials or not profile.traits.any(func(t):return t in ["Nervous","Self-serving"])):
    var result: String=Follow.advance(game,trip,random)
    if result=="joined":_return(game,trip)
    elif result in ["moving","crossing"]:trip.stage="away";trip.due=int(game.state.day)+1
  cache.camp_random=str(random.state)
  if trip in record.trips:_missing(game,trip)
func _strand(game,trip: Dictionary) -> void:
 trip.stage="stranded"
 trip.camp.camp_log.append("No reunion was possible; waiting at the marked camp.")
 if not trip.left:return
 for profile in game.characters.profiles:
  if int(profile.id)>0 and (game.party_health.is_active(game.party_health.members[profile.id]) or int(profile.id)==int(trip.member)):
   var bond: String=game.crime.bond(int(profile.id),int(trip.member))
   game.characters.remember(game,profile,"hunter_left",-4 if bond in ["family","partner"] or int(profile.id)==int(trip.member) else -1,"The hunter was separated from the wagon.")
func _missing(game,trip: Dictionary) -> void:
 if trip.camp.get("missing_notified",false) or int(game.state.day)<int(trip.started)+int(trip.days)+int(rules.missing_after_days):return
 trip.camp["missing_notified"]=true
 var name: String=game.party_health.members[int(trip.member)].name
 var text: String="%s still hasn't returned. You are beginning to fear something happened to them." % name
 game.journal.append("Day %d: %s" % [game.state.day,text]);game.health_events.append(text)
func _return(game,trip: Dictionary) -> void:
 var actual: Dictionary=trip.camp.guards[0]
 var original: Dictionary=game.party_health.members[trip.member]
 var history: Array=original.history.duplicate()
 for line in actual.history:
  if line not in history:history.append(line)
 original.clear();original.merge(actual.duplicate(true));original.erase("away");original.history=history
 var joined: bool=game.party_health.is_active(original)
 if joined:
  game.state.household_gear_lb=game.provisions.household_mass(game.state)+float(game.provisions.data.walking.personal_gear_lb_per_person)
 elif original.get("departed",false):
  game.state.departed_gear_lb=int(game.state.get("departed_gear_lb",0))+int(original.departure_supplies.gear_lb)
 else:
  game.Remains.add(game,game.crime.person_id(int(game.state.seed),int(trip.member)),original.name,original.cause,int(original.death_day),0,false)
 for line in trip.camp.camp_log:game.journal.append(str(line)+" [Learned on return]")
 game.combat.history.append_array(trip.camp.get("combat_history",[]).duplicate(true))
 # Restore personal supplies and real tack before calculating room for the catch.
 var catches: Array=[]
 for key in trip.camp.inventory:
  if key!="food":game.state[key]+=int(trip.camp.inventory[key])
 var all_food: int=int(trip.camp.inventory.food)
 for batch in trip.camp.fresh:
  if batch.get("_outing_catch",false):catches.append(batch)
  else:game.provisions.fresh.append(batch.duplicate(true))
 var caught: int=catches.reduce(func(n,b):return n+int(b.pounds),0)
 game.state.food+=all_food-caught
 Outfit.restore_stock(game,trip.stock,int(trip.condition))
 recount(game)
 var lost:=0
 for batch in catches:
  var room: float=maxf(0,game.provisions.storage_capacity(game.state)-game.provisions.cargo(game.state))
  var keep: int=mini(int(batch.pounds),maxi(0,floori(room/game.provisions.mass_ratio(batch))))
  lost+=int(batch.pounds)-keep
  if keep>0:
   var part: Dictionary=batch.duplicate(true);part.erase("_outing_catch");part.pounds=keep
   game.provisions.fresh.append(part);game.state.food+=keep
 record.trips.erase(trip)
 original.history.append("Day %d · Hunting trip resolved; %s." % [game.state.day,"rejoined the party" if joined else "the camp's fate was learned"])
 game.journal.append("Day %d · Recovered %s's outing. %d food units returned; %d catch units could not fit. No extra day passed." % [game.state.day,original.name,all_food-lost,lost])
 game.health_events.append(original.name+(" rejoined from hunting." if joined else "'s camp has been found."))
 game.supply_history.append({"day":game.state.day,"event":"outing_return","member":trip.member,"food":all_food-lost,"catch_lost":lost,"changes":{}})
func recover_here(game) -> bool:
 if not game.can_service():return false
 var found:=false
 for trip in record.trips.duplicate():
  if trip.stage=="stranded" and at_origin(game,trip):_return(game,trip);found=true
 return found
func needs_warning(game,all_trips: bool=false) -> bool:
 for trip in record.trips:
  if trip.left or trip.stage=="stranded":continue
  if all_trips or trip.kit not in ["ride_horse","ride_mule","horse_and_mule"] or int(game.state.day)>=int(trip.due):return true
 return false
func warn(game,flight: bool=false,all_trips: bool=false) -> bool:
 if not needs_warning(game,flight or all_trips):return false
 var choices: Array=[]
 if not flight:choices.append({"label":"Wait in camp · 1 day","outing_choice":"wait","effects":{},"result":""})
 choices.append({"label":"Leave without the hunters","outing_choice":"leave","effects":{},"result":""})
 choices.append({"label":"Back","outing_choice":"back","effects":{},"result":""})
 game.pending={"id":"outing_departure","outing_warning":true,"flight":flight,"resume":game.pending.duplicate(true),"title":"Hunters have not returned","text":"Hunters and their animals are still away. Riders can follow, but forks can lose their trail and rivers take a separate crossing. Leaving may strand them. You can return to their marked camp to look for them.","choices":choices}
 return true
func choose_warning(game,index: int) -> bool:
 if index<0 or index>=game.pending.choices.size():return false
 var action: String=game.pending.choices[index].outing_choice
 game.pending=game.pending.resume.duplicate(true)
 if action=="leave":
  for trip in record.trips:
   if trip.left or trip.stage=="stranded":continue
   trip.left=true
  return true
 if action=="wait":
  game._tick_day(true,false,"rest")
  if game.pending.is_empty():game._schedule_event(false)
 return true
func valid(value: Variant,game,party: Array,day: int) -> bool:
 if not value is Dictionary or value.size()!=3 or not game.crime.whole(value.get("next_id"),1,100000) or not value.get("trips") is Array or value.trips.size()>4 or not value.get("preferences") is Dictionary:return false
 var ids: Array=[]
 var members: Array=[]
 for trip in value.trips:
  if not trip is Dictionary or trip.size()!=15:return false
  if not game.crime.whole(trip.get("id"),1,int(value.next_id)-1) or trip.id in ids or not game.crime.whole(trip.get("member"),1,party.size()-1) or trip.member in members:return false
  ids.append(trip.id);members.append(trip.member)
  if not party[int(trip.member)].get("away",false):return false
  if trip.get("kit") not in Outfit.KITS or not trip.get("stock") is Dictionary or trip.stock.size()!=5:return false
  for key in Outfit.stock(trip.kit):
   if not game.crime.whole(trip.stock.get(key),0,2) or int(trip.stock[key])>int(Outfit.stock(trip.kit)[key]):return false
  if not game.crime.whole(trip.get("condition"),0,100) or not game.crime.whole(trip.get("days"),1,3) or not game.crime.whole(trip.get("started"),0,day) or not game.crime.whole(trip.get("due"),int(trip.started)+1,day+3) or not game.crime.whole(trip.get("mile"),0,game.route.longest_miles):return false
  if trip.get("heading") not in ["west","east"] or trip.get("stage") not in ["away","stranded"] or not trip.get("left") is bool or not trip.get("delayed") is bool:return false
  if not trip.get("origin") is Dictionary or not valid_origin(game,trip.origin):return false
  var origin_mile: int=int(trip.origin.offset)
  for i in range(trip.origin.path.size()-1):origin_mile+=int(game.route.edge_between(trip.origin.path[i],trip.origin.path[i+1]).miles)
  if origin_mile!=int(trip.mile):return false
  var camp: Variant=trip.get("camp")
  if not camp is Dictionary or not game.Guards.valid(camp,game,day) or camp.guards.size()!=1 or int(camp.guards[0].id)!=int(trip.member) or camp.guards[0].name!=party[int(trip.member)].name:return false
  if not Follow.valid(camp,game) or not Encounters.valid(camp,game):return false
  if not camp.get("field_working") is bool or not camp.get("inventory") is Dictionary or camp.inventory.size()!=game.provisions.data.weights_lb.size() or not camp.get("fresh") is Array or camp.fresh.size()>1000:return false
  for key in game.provisions.data.weights_lb:
   if not game.crime.whole(camp.inventory.get(key),0,1000000):return false
  var total:=0
  for batch in camp.fresh:
   if not batch is Dictionary or not game.provisions.valid_nutrients(batch) or not game.provisions.valid_mass_ratio(batch) or not game.crime.whole(batch.get("pounds"),1,1000000) or not game.crime.whole(batch.get("expires"),day+1,1000100):return false
   if batch.has("_outing_catch") and batch._outing_catch!=true:return false
   total+=int(batch.pounds)
  if total>int(camp.inventory.food) or camp.get("location")!=trip.origin:return false
  if camp.guards[0].has("away") or camp.guards[0].has("guarding"):return false
  if camp.guards[0].has("immune"):
   if not camp.guards[0].immune is Array:return false
   for disease in camp.guards[0].immune:
    if not game.party_health.conditions.has(disease) or not game.party_health.conditions[disease].get("immunizing",false):return false
 for person in party:
  if person.get("away",false) and int(person.id) not in members.map(func(id):return int(id)):return false
 for key in value.preferences:
  var pref: Variant=value.preferences[key]
  if not key is String or (key!="leader" and (not key.is_valid_int() or str(int(key))!=key or int(key)<1 or int(key)>=party.size())):return false
  if not pref is Dictionary or pref.size()!=3 or pref.get("kit") not in Outfit.KITS or not game.crime.whole(pref.get("days"),1,3) or not game.crime.whole(pref.get("bullets"),1,30):return false
 return true
func valid_origin(game,at: Dictionary) -> bool:
 if at.size()!=4 or not at.get("from") is String or not at.get("to") is String or not at.get("path") is Array or not game.route.valid_path(at.path) or at.path[-1]!=at.from:return false
 var edge: Dictionary=game.route.edge_between(at.from,at.to)
 # An expedition may start while stopped at Independence, before choosing its first road.
 if at.from==at.to:return game.route.nodes.has(at.from) and at.get("offset")==0
 return not edge.is_empty() and game.crime.whole(at.get("offset"),0,int(edge.miles))

func clamp_distance(game,distance: int) -> int:
 for trip in record.trips:
  if trip.stage!="stranded" or trip.origin.from!=game.state.landmark or trip.origin.to!=game.state.next_landmark:continue
  var gap: int=int(game.state.leg_miles)-int(trip.origin.offset) if game.Direction.heading(game)=="east" else int(trip.origin.offset)-int(game.state.leg_miles)
  if gap>0:distance=mini(distance,gap)
 return distance
func camp_notice(game) -> bool:
 if not record.trips.any(func(trip):return trip.stage=="stranded" and at_origin(game,trip)):return false
 game.pending={"id":"hunter_camp_reached","title":"The hunters' departure camp","text":"You have reached the marked hunting camp. Stop, then use Camp > Field trips > Look for hunters at this camp to learn their fate and recover surviving travelers and supplies.","choices":[{"label":"Stop here","effects":{},"result":"The party stops at the hunters' camp."}]}
 return true

func public_status(trip: Dictionary) -> String:return "MISSING" if trip.camp.get("missing_notified",false) else "AWAY"
func public_kit(trip: Dictionary) -> String:return str(trip.camp.get("departure_kit",trip.kit))
func expected_day(trip: Dictionary) -> int:return int(trip.started)+int(trip.days)
