extends RefCounted
## A single actual traveler and actual outfit, isolated from the wagon's inventory.
static func build(game,trip: Dictionary,random):
 var child=load("res://simulation/trail_engine.gd").new(int(random.randi()),"classic",true)
 child.depart("banker",["One","Two","Three","Four","Five"],5,{"wagon":0,"food":0})
 child.state=game.state.duplicate(true)
 child.party_health.members.assign(game.party_health.members.duplicate(true))
 for person in child.party_health.members:person["guarding"]=true;person.erase("away")
 var actual: Dictionary=trip.camp.guards[0].duplicate(true)
 child.party_health.members[int(trip.member)]=actual
 child.characters.profiles.assign(game.characters.profiles.duplicate(true))
 child.state.day=int(game.state.day)-1;child.state.party_size=1;child.state.health=actual.health
 child.state.vehicle="foot";child.state.oxen=0;child.state.ox_health=100;child.state.money=0
 child.state.lead_mounts=game.field_outings.Outfit.mode(trip).begins_with("lead");child.state.strenuous_load=game.field_outings.Outfit.mode(trip).ends_with("strenuous")
 child.state.household_gear_lb=float(trip.camp.household_gear_lb);child.state.miles=int(trip.mile)
 for field in ["hunger_days","camp_greens_lb","camp_greens_expires","remains_lb","east_arrival"]:child.state.erase(field)
 if trip.camp.has("hunger_days"):child.state.hunger_days=trip.camp.hunger_days
 for good in trip.camp.inventory:child.state[good]=int(trip.camp.inventory[good])
 for good in trip.stock:child.state[good]=int(trip.stock[good])
 child.state.horse_health=int(trip.condition);child.state.rations=int(trip.camp.camp_rations);child.state.pace=0
 child.state.landmark=trip.origin.from;child.state.next_landmark=trip.origin.to
 child.state.leg_miles=int(trip.origin.offset);child.state.leg_length=int(game.route.edge_between(trip.origin.from,trip.origin.to).get("miles",0))
 child.route_path=trip.origin.path.duplicate();child.pending={}
 child.provisions.fresh.assign(trip.camp.fresh.duplicate(true));child.provisions.carriers=child.party_health.members
 child.party_health.days_without_fresh=int(trip.camp.camp_deficiency)
 child.party_health.daily_onset_chance=game.party_health.daily_onset_chance
 child.survival.forced_weather=game.survival.forced_weather;child.rng.state=random.state
 child.combat.history.assign(trip.camp.get("combat_history",[]).duplicate(true))
 return child
static func sync(game,trip: Dictionary,child) -> void:
 trip.camp.guards[0]=child.party_health.members[int(trip.member)].duplicate(true)
 for good in trip.camp.inventory:trip.camp.inventory[good]=int(child.state.get(good,0))
 trip.camp.fresh=child.provisions.fresh.duplicate(true);trip.camp.camp_deficiency=child.party_health.days_without_fresh
 if child.state.has("hunger_days"):trip.camp.hunger_days=child.state.hunger_days
 else:trip.camp.erase("hunger_days")
 for good in trip.stock:trip.stock[good]=int(child.state.get(good,0))
 trip.condition=game.Mounts.condition(child.state)
 if not child.combat.history.is_empty():trip.camp["combat_history"]=child.combat.history.duplicate(true)
static func lost(game,trip: Dictionary,text: String) -> void:
 for good in trip.camp.inventory:trip.camp.inventory[good]=0
 trip.camp.fresh=[];trip.camp.household_gear_lb=0
 trip.stock=game.field_outings.Outfit.stock("foot");trip.kit="foot"
 trip.camp["return_failed"]=true;trip.stage="stranded";trip.camp.camp_log.append(text)
static func lost_mount(game,trip: Dictionary) -> void:
 if trip.kit!="foot" and game.Mounts.animals(trip.stock)==0:
  trip.kit="foot";trip.stock=game.field_outings.Outfit.stock("foot");trip.stage="stranded"
