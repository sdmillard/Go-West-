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
## Shared transition for travelers and offscreen guards. State remains optional in old saves.
static func step(rules: Dictionary,state: Dictionary,eaten: float,needed: float,ration: int) -> Dictionary:
 var before: float=float(state.get("hunger_days",0.0))
 var missing: float=clampf(1.0-float(eaten)/maxf(1,needed),0,1) if needed>0 else 0.0
 var debt: float=minf(100000,before+missing) if missing>0 else maxf(0,before-float(rules.recovery[ration]))
 debt=float(roundi(debt*1000))/1000.0 # Canonical precision survives JSON exactly, including partial meals.
 if debt>0:state["hunger_days"]=debt
 else:state.erase("hunger_days")
 var severity: int=int(rules.base_damage)+mini(int(rules.maximum_extra_damage),floori(debt/float(rules.ramp_days)))
 return {"damage":maxi(1,roundi(severity*missing)) if missing>0 else 0,"fatigue":ceili(float(rules.fatigue)*missing),"can_recover":before==0 and missing==0,"first_short":before==0 and missing>0,"recovered":before>0 and debt==0}
## Paying off hunger and recovering health cannot both happen on the same day.
static func tick(game,eaten: float,needed: float) -> bool:
 var result: Dictionary=step(game.provisions.data.shortfall,game.state,eaten,needed,int(game.state.rations))
 if result.damage>0:game._change_health(-int(result.damage),"lack of food")
 game.state.fatigue=mini(100,int(game.state.fatigue)+int(result.fatigue))
 if result.first_short:game.health_events.append("Food is short. Hunger will weaken the party; find provisions before it becomes prolonged.")
 if result.recovered:game.health_events.append("Regular meals have made up the food shortage. Rest can restore health again.")
 return bool(result.can_recover)
