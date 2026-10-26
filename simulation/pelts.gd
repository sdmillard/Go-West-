extends RefCounted
## Rough trade skins from actual kills. No independent RNG or free finished robes.
static func whole(v: Variant,lo: int,hi: int) -> bool:return (v is int or v is float) and is_finite(v) and v==floor(v) and v>=lo and v<=hi
static func valid(v: Variant,weights: Dictionary) -> bool:
 if not v is Dictionary or not v.get("note") is String or not whole(v.get("raw_batch_lb"),1,200) or not v.get("goods") is Dictionary or v.goods.size()!=3:return false
 var species: Array=[]
 for id in ["bison_hide","deer_hide","rabbit_pelt"]:
  var r: Variant=v.goods.get(id)
  if not r is Dictionary or not r.get("label") is String or not r.get("short_label") is String or r.get("species") not in ["bison","deer","rabbit"] or r.species in species:return false
  species.append(r.species)
  for key in ["raw_lb","weight_lb"]:
   if not (r.get(key) is int or r.get(key) is float) or not is_finite(r[key]) or r[key]<=0 or r[key]>200:return false
  if r.weight_lb>r.raw_lb or weights.get(id)!=r.weight_lb:return false
  for key in ["sell_cents","post_demand","trader_demand"]:
   if not whole(r.get(key),1,10000):return false
 return true
static func quote(game,cart: Dictionary) -> Dictionary:
 var result: Dictionary={"valid":false,"message":"No animal hunt to recover skins from.","available":{},"selected":0,"raw_lb":0.0,"packed_lb":0.0,"days":0}
 var rules: Dictionary=game.provisions.data.pelts
 for item in rules.goods:result.available[item]=0
 if game.hunt.is_empty() or game.hunt.get("activity","")=="fish":return result
 for target in game.hunt.targets:
  var species: String=game.hunting.data.species[int(game.hunt.animals[target].kind)].id
  for item in rules.goods:
   if rules.goods[item].species==species:result.available[item]+=1
 for item in cart:
  var n: Variant=cart[item]
  if not rules.goods.has(item) or not whole(n,0,100) or n>result.available[item]:result.message="Choose whole skins from animals actually taken.";return result
  result.selected+=int(n);result.raw_lb+=int(n)*float(rules.goods[item].raw_lb);result.packed_lb+=int(n)*float(rules.goods[item].weight_lb)
 if result.raw_lb>float(rules.raw_batch_lb):result.message="One extra camp day can prepare at most %.0f lb of raw skins." % float(rules.raw_batch_lb);return result
 if result.raw_lb>game.hunting_capacity():result.message="Those raw hides exceed this hunting party's haul limit.";return result
 result.valid=true;result.days=1 if result.selected>0 else 0
 result.message="Meat only: normal one-day outing." if result.selected==0 else "%.1f lb raw hides displace meat; %.1f lb when prepared. ONE EXTRA CAMP DAY + MEALS. Rough skins, not tanned robes." % [result.raw_lb,result.packed_lb]
 return result
static func rows(game,key: String,kind: String) -> Array:
 var result: Array=[]
 if kind not in ["post","traders"]:return result
 for item in game.provisions.data.pelts.goods:
  var r: Dictionary=game.provisions.data.pelts.goods[item]
  var held: int=int(game.state.get(item,0))
  if held<1:continue
  var sell_key: String=key+"|sell_"+item
  var left: int=maxi(0,int(r.post_demand if kind=="post" else r.trader_demand)-int(game.context.record.spent.get(sell_key+"|units",0)))
  result.append({"item":item,"label":r.label,"amount":1,"buy_cents":0,"sell_cents":int(r.sell_cents) if kind=="post" else maxi(1,floori(int(r.sell_cents)*0.75)),"can_buy":0,"can_sell":mini(held,left),"held":held,"buy_key":key+"|buy_"+item,"sell_key":sell_key,"sells":false,"buys":true})
 return result

static func valid_inventory(value: Variant,weights: Dictionary,optional: Dictionary) -> bool:
 if not value is Dictionary:return false
 for key in value:
  if not weights.has(key):return false
 for key in weights:
  if not value.has(key) and optional.has(key):continue
  if not whole(value.get(key),0,1000000):return false
 return true
