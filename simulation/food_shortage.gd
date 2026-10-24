extends RefCounted
## A fractional ration-day deficit, not a second health bar or a clinical body-fat model.
static func valid_rules(value: Variant) -> bool:
 if not value is Dictionary or not value.get("note") is String:return false
 for key in ["base_damage","ramp_days","maximum_extra_damage","fatigue"]:
  if not (value.get(key) is int or value.get(key) is float) or not is_finite(float(value[key])) or value[key]!=floor(value[key]) or value[key]<1 or value[key]>100:return false
 if not value.get("recovery") is Array or value.recovery.size()!=3:return false
 for amount in value.recovery:
  if not (amount is int or amount is float) or not is_finite(float(amount)) or amount<0 or amount>1:return false
 return true
static func valid_state(state: Dictionary) -> bool:
 var value: Variant=state.get("hunger_days",0.0)
 return (value is int or value is float) and is_finite(float(value)) and value>=0 and value<=100000
## True only when the party had no outstanding deficit before this meal.
## Paying off hunger and recovering health cannot both happen on the same day.
static func tick(game,eaten: int,needed: int) -> bool:
 if needed<=0:return true
 var rules: Dictionary=game.provisions.data.shortfall
 var before: float=float(game.state.get("hunger_days",0.0))
 var missing: float=clampf(1.0-float(eaten)/needed,0,1)
 if missing>0:
  var debt: float=minf(100000,before+missing)
  game.state["hunger_days"]=debt
  var damage: int=int(rules.base_damage)+mini(int(rules.maximum_extra_damage),floori(debt/float(rules.ramp_days)))
  game._change_health(-maxi(1,roundi(damage*missing)),"lack of food")
  game.state.fatigue=mini(100,int(game.state.fatigue)+ceili(float(rules.fatigue)*missing))
  if before==0:game.health_events.append("Food is short. Hunger will weaken the party; find provisions before it becomes prolonged.")
  return false
 var debt: float=maxf(0,before-float(rules.recovery[int(game.state.rations)]))
 if debt>0:game.state["hunger_days"]=debt
 else:
  game.state.erase("hunger_days")
  if before>0:game.health_events.append("Regular meals have made up the food shortage. Rest can restore health again.")
 return before==0
