extends RefCounted
## A demand is drawn once, then lives in the saved pending choice, never in the UI.
const GOODS=["food","bullets","oxen","clothing","medicine","salt","wheels","axles","tongues"]
const NAMES={"food":["food unit","food units"],"bullets":["bullet","bullets"],"oxen":["ox","oxen"],"clothing":["clothing set","clothing sets"],"medicine":["care kit","care kits"],"salt":["lb salt","lb salt"],"wheels":["wheel","wheels"],"axles":["axle","axles"],"tongues":["wagon tongue","wagon tongues"]}
static func number(v: Variant) -> bool:return (v is int or v is float) and is_finite(v)
static func whole(v: Variant,low: int,high: int) -> bool:return number(v) and v==floor(v) and v>=low and v<=high
static func valid_rules(v: Variant) -> bool:
 if not v is Dictionary or not v.get("note") is String or not v.get("tiers") is Array or v.tiers.is_empty() or v.tiers.size()>8 or not v.get("goods") is Dictionary or v.goods.is_empty():return false
 for key in ["mixed_chance","goods_only_chance","wagon_chance"]:
  if not number(v.get(key)) or v[key]<0 or v[key]>1:return false
 if v.mixed_chance+v.goods_only_chance>1 or not whole(v.get("max_goods"),1,GOODS.size()):return false
 for item in v.goods:
  if item not in GOODS or not whole(v.goods[item],1,100):return false
 for tier in v.tiers:
  if not tier is Dictionary or not whole(tier.get("weight"),1,100) or not number(tier.get("goods_fraction")) or tier.goods_fraction<=0 or tier.goods_fraction>1:return false
  if tier.has("cash_cap")==tier.has("cash_fraction"):return false
  if tier.has("cash_cap") and not whole(tier.cash_cap,1,1000000):return false
  if tier.has("cash_fraction") and (not number(tier.cash_fraction) or tier.cash_fraction<=0 or tier.cash_fraction>1):return false
 return true
static func weighted(rows: Array,rng: RandomNumberGenerator) -> int:
 var total:=0
 for row in rows:total+=int(row.weight)
 var draw:=rng.randi_range(1,total)
 for index in range(rows.size()):
  draw-=int(rows[index].weight)
  if draw<=0:return index
 return rows.size()-1
static func cash(game,tier: Dictionary,rng: RandomNumberGenerator) -> float:
 var held: int=roundi(float(game.state.money)*100)
 var ceiling: int=mini(held,int(tier.cash_cap)*100 if tier.has("cash_cap") else floori(held*float(tier.cash_fraction)))
 if ceiling<=0:return 0.0
 # Whole dollars when possible, with the actual remaining cents as the ceiling.
 return rng.randi_range(1,floori(ceiling/100.0)) if ceiling>=100 else ceiling/100.0
static func describe(required: Dictionary) -> String:
 var pieces: Array[String]=[]
 if required.has("money"):pieces.append("$%.2f" % required.money)
 for item in GOODS:
  if required.has(item):pieces.append("%d %s" % [required[item],NAMES[item][0 if int(required[item])==1 else 1]])
 return " + ".join(pieces)
static func prepare(game,content: Dictionary,rules: Dictionary) -> void:
 if content.id!="bandits":return
 var rng: RandomNumberGenerator=game.survival.rng
 var tier: Dictionary=rules.tiers[weighted(rules.tiers,rng)]
 var required: Dictionary={}
 var amount:=cash(game,tier,rng)
 if amount>0:required.money=amount
 var wagon: bool=game.state.vehicle=="wagon" and rng.randf()<float(rules.wagon_chance)
 if wagon:
  for item in GOODS:
   var held: int=int(game.state.get(item,0))
   if item=="clothing":held=maxi(0,held-int(game.state.party_size))
   if held>0:required[item]=held
 else:
  var style: float=rng.randf()
  var goods_only: bool=style<float(rules.goods_only_chance)
  var pool: Array=[]
  for item in rules.goods:
   if int(game.state.get(item,0))>0:pool.append({"item":item,"weight":rules.goods[item]})
  # With no cash, ask for available goods rather than an impossible payment.
  if (goods_only or style<float(rules.goods_only_chance)+float(rules.mixed_chance) or required.is_empty()) and not pool.is_empty():
   if goods_only:required.erase("money")
   var count: int=mini(pool.size(),rng.randi_range(1,int(rules.max_goods)))
   for index in range(count):
    var selected: int=weighted(pool,rng)
    var item: String=pool[selected].item
    var ceiling: int=maxi(1,floori(int(game.state[item])*float(tier.goods_fraction)))
    required[item]=rng.randi_range(1,ceiling)
    pool.remove_at(selected)
 var choice: Dictionary=content.choices[0]
 choice["bandit_payment"]=true
 if wagon:choice["bandit_wagon"]=true
 choice.requires=required
 choice.effects={}
 for item in required:choice.effects[item]=-required[item]
 if wagon:choice.effects.vehicle="foot"
 var demand: String=describe(required)
 if wagon:
  demand="wagon, team and all packed goods"+(" + $%.2f" % required.money if required.has("money") else "")+". You keep worn clothes, tools and remaining cash; bodies stay here. Surrender means on foot, no food/ammo, no wagon recovery"
  choice.label="Surrender wagon, team and cargo"
  choice.result="The thieves drive off with the loaded wagon and team. You are left on foot; the stolen wagon cannot be recovered."
 elif required.is_empty():
  content.text="The thieves find nothing they want to take and wave your party on."
  choice.label="Continue"
  choice.result="The thieves leave the party alone."
  content.choices=[choice]
 else:
  choice.label="Surrender the demanded cash / goods"
  choice.result="The thieves leave with "+demand+"."
 if not required.is_empty() or wagon:content.text=content.text.replace("{demand}",demand)
static func valid_choice(choice: Dictionary) -> bool:
 if not choice.get("bandit_payment") is bool or not choice.bandit_payment or not choice.get("requires") is Dictionary or not choice.get("effects") is Dictionary or choice.has("combat") or choice.has("risk"):return false
 if choice.has("bandit_wagon") and (not choice.bandit_wagon is bool or not choice.bandit_wagon):return false
 var wagon: bool=choice.get("bandit_wagon",false)
 if choice.effects.size()!=choice.requires.size()+int(wagon):return false
 for item in choice.requires:
  var n: Variant=choice.requires[item]
  if item not in GOODS and item!="money":return false
  if not number(n) or n<=0 or n>1000000 or (item!="money" and n!=floor(n)) or not number(choice.effects.get(item)) or choice.effects[item]!=-n:return false
 return not wagon or (choice.effects.get("vehicle") is String and choice.effects.vehicle=="foot")
static func finish(game,choice: Dictionary) -> void:
 if not choice.get("bandit_wagon",false):return
 # An older abandoned cache is separate from the wagon being robbed now.
 for body in game.crime.record.remains:
  if body.state=="carried":
   body.state="lying"
   body.mile=int(game.state.miles)
 var lost: int=game.Remains.human_pounds(game)
 game.crime.record.human_food.clear()
 game.crime.record.meals.clear()
 game.Remains.reweigh(game)
 game.supply_history.append({"day":int(game.state.day),"event":"bandits","changes":{},"wagon_taken":true,"human_food_lost":lost})
 if lost>0:game.journal.append("Day %d · %d separately tracked food units were also lost with the wagon." % [game.state.day,lost])
