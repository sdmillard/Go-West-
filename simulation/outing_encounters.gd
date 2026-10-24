extends RefCounted
const Actor=preload("res://simulation/outing_actor.gd")
static func response(game,trip: Dictionary,child) -> int:
 var profile: Dictionary=child.characters.profiles[int(trip.member)]
 var bold: bool=profile.traits.any(func(t):return t in ["Bold","Reckless"]) or "Veteran" in profile.specials
 if bold and child.characters.willing(int(trip.member),"defend"):
  for i in range(child.pending.choices.size()):
   if child.pending.choices[i].get("combat","")=="defend" and child.can_choose(i):return i
 var demand: Dictionary=child.pending.choices[0].get("requires",{})
 var harsh: bool=int(demand.get("food",0))*2>int(child.state.food) or int(demand.get("horses",0))+int(demand.get("mules",0))>0
 if (bold or harsh) and game.Mounts.animals(trip.stock)>0 and int(trip.condition)>=40 and not profile.traits.any(func(t):return t in ["Cautious","Nervous"]):
  var flee: int=child.pending.choices.find_custom(func(c):return int(c.get("effects",{}).get("days",0))>0)
  if flee>=0 and child.can_choose(flee):return flee
 return 0
static func attempt(game,trip: Dictionary,random) -> Dictionary:
 var cache: Dictionary=trip.camp
 var rules: Dictionary=game.field_outings.rules
 var none: Dictionary={"happened":false,"elapsed":false}
 if float(rules.bandit_daily_chance)<=0 or cache.get("encounters",[]).size()>=int(rules.bandit_max_per_trip) or cache.get("return_failed",false):return none
 if random.randf()>=float(rules.bandit_daily_chance):return none
 var child=Actor.build(game,trip,random)
 child.combat.data.bandit_demands.goods=rules.bandit_goods.duplicate(true)
 var definition: Dictionary=child.trail_events.events.filter(func(event):return event.id=="bandits")[0]
 child._present_trail_event(definition)
 var selected: int=response(game,trip,child)
 var choice: Dictionary=child.pending.choices[selected].duplicate(true)
 var elapsed: bool=int(choice.get("effects",{}).get("days",0))>0
 if not elapsed:child.state.day=int(game.state.day)
 var before: int=child.journal.size()
 if not child.choose(selected):return none
 random.state=child.rng.state
 var actual: Dictionary=child.party_health.members[int(trip.member)]
 var tactic: String="defend" if choice.has("combat") else ("flee" if elapsed else "yield")
 if tactic=="flee" and actual.alive:
  var escape: float=child.crime.Wanted.flight_chance(child.crime,child,{"escape_capture":0.5})
  if random.randf()>escape:
   child.party_health.affect(actual,-int(rules.bandit_chase_damage),game.state.day,"wounds from pursuing bandits")
   if actual.alive:child.party_health.begin_condition(int(trip.member),"wound",game.state.day,2)
   child._collect_health_events();child._check_health()
   child.journal.append("The bandits caught the lone traveler during the escape.")
 if tactic=="defend" and not child.combat.history.is_empty() and child.combat.history.back().outcome=="injured" and actual.alive and random.randf()<float(rules.bandit_lone_fatal_on_hit):
  child.party_health.affect(actual,-int(actual.health),game.state.day,"shot by bandits")
  child.combat.history.back().outcome="fatal"
  child._collect_health_events();child._check_health()
 for line in child.journal.slice(before):cache.camp_log.append(str(line))
 Actor.sync(game,trip,child)
 var outcome: String="fatal" if not actual.alive else ("injured" if actual.conditions.any(func(c):return c.id=="wound") else ("won" if tactic=="defend" else ("escaped" if tactic=="flee" else "robbed")))
 if not cache.has("encounters"):cache["encounters"]=[]
 cache.encounters.append({"day":int(game.state.day),"kind":"bandits","tactic":tactic,"outcome":outcome,"demand":choice.get("requires",{}).duplicate(true)})
 cache.camp_log.append("Day %d: Bandits encountered; %s, %s. Demanded %s." % [game.state.day,tactic,outcome,child.combat.BanditDemand.describe(choice.get("requires",{}))])
 if not actual.alive:Actor.lost(game,trip,"The hunter was killed by bandits. Their remaining outfit was taken.")
 else:Actor.lost_mount(game,trip)
 return {"happened":true,"elapsed":elapsed}
static func valid(camp: Dictionary,game) -> bool:
 if not camp.has("encounters"):return true
 if not camp.encounters is Array or camp.encounters.size()>int(game.field_outings.rules.bandit_max_per_trip):return false
 for event in camp.encounters:
  if not event is Dictionary or event.size()!=5 or not game.crime.whole(event.get("day"),0,int(game.state.day)) or event.get("kind")!="bandits" or event.get("tactic") not in ["yield","flee","defend"] or event.get("outcome") not in ["fatal","injured","won","escaped","robbed"] or not event.get("demand") is Dictionary:return false
  for item in event.demand:
   if item not in game.combat.BanditDemand.GOODS or not game.crime.whole(event.demand[item],1,1000000):return false
 return true
