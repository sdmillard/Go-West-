extends RefCounted
## Store replacement frame and cover; existing belongings and animals remain separate.
static func valid_rules(v: Variant) -> bool:
 return v is Dictionary and v.get("note") is String and whole(v.get("price_cents"),1,1000000) and whole(v.get("stock_per_post"),1,8)
static func whole(v: Variant,low: int,high: int) -> bool:return (v is int or v is float) and is_finite(v) and v==floor(v) and v>=low and v<=high
static func row(game,key: String) -> Dictionary:
 var rule: Dictionary=game.provisions.data.replacement_wagon
 var buy_key: String=key+"|buy_wagon"
 var left: int=maxi(0,int(rule.stock_per_post)+int(game.context.record.spent.get(key+"|sell_wagon|units",0))-int(game.context.record.spent.get(buy_key+"|units",0)))
 var factor: float=float(game.context.region(game).price)
 if game.characters.available(game,"Trading"):factor*=float(game.characters.benefits.trade_buy_factor)
 return {"item":"wagon","label":"Empty wagon","amount":1,"buy_cents":roundi(int(rule.price_cents)*factor),"sell_cents":0,"can_buy":left if game.state.vehicle=="foot" else 0,"can_sell":0,"held":int(game.state.vehicle=="wagon"),"buy_key":buy_key,"sell_key":key+"|sell_wagon","sells":true,"buys":false}
static func apply_inventory(game,inventory: Dictionary,amount: int) -> bool:
 if amount!=1 or inventory.vehicle!="foot":return false
 inventory.vehicle="wagon"
 inventory["household_gear_lb"]=int(game.provisions.data.walking.personal_gear_lb_per_person)*int(inventory.party_size)
 return true
static func commit(game,effects: Dictionary) -> void:
 if not effects.has("wagon"):return
 apply_inventory(game,game.state,int(effects.wagon))
 effects.erase("wagon")
 game.journal.append("Day %d · Bought an empty covered wagon. Oxen and supplies are separate; only existing personal belongings were loaded." % game.state.day)

static func sale_quote(game,cart: Dictionary,keep_oxen: int=-1) -> Dictionary:
 var result: Dictionary={"valid":false,"message":"No open post will buy the wagon here."}
 var counter: Dictionary=game.post_store()
 if game.state.vehicle!="wagon" or counter.is_empty():return result
 var key: String=counter.key
 if int(game.context.record.spent.get(key+"|sell_wagon|units",0))>=1:
  result.message="This post has already bought a wagon from you."
  return result
 var pack: Dictionary=game.CacheSupport.quote(game,cart,false,[],true)
 if not pack.valid:return pack
 if keep_oxen==-1:keep_oxen=int(game.state.oxen)
 if keep_oxen<0 or keep_oxen>int(game.state.oxen):return result
 var model=game.provisions.get_script().new()
 model.data=game.provisions.data.duplicate(true)
 model.fresh.assign(pack.stored.duplicate(true))
 var left: Dictionary={}
 for item in pack.stock:left[item]=int(pack.stock[item])-int(pack.inventory[item])
 left["oxen"]=int(game.state.oxen)-keep_oxen
 var sold: Dictionary={}
 var dropped: Dictionary={}
 var prices: Dictionary={}
 # Half the post's own price for a wagon: worth more where wagons cost more.
 var payout:=floori(float(game.provisions.data.replacement_wagon.price_cents)*float(game.context.region(game).price)*0.5)
 var rows: Array=counter.rows.duplicate(true)
 # Separate fruit baskets before offering the remaining generic food.
 rows.sort_custom(func(a,b):return (a.item in ["produce","dried_produce"]) and (b.item not in ["produce","dried_produce"]))
 for row in rows:
  var item: String=row.item
  if item=="wagon":continue
  var count: int=left.get(item,0)
  if item in ["produce","dried_produce"]:count=game.Produce.units(model,item,int(game.state.day))
  elif item=="food":count=maxi(0,int(left.food)-game.Produce.units(model,"produce",int(game.state.day))-game.Produce.units(model,"dried_produce",int(game.state.day)))
  var n:=mini(count,int(row.can_sell))
  if n<=0:continue
  if item in ["produce","dried_produce"]:
   game.Produce.take(model,item,n,int(game.state.day))
   left.food-=n
  else:left[item]-=n
  sold[item]=n
  prices[item]=roundi(float(n*int(row.sell_cents))/int(row.amount))
  payout+=int(prices[item])
 for item in left:
  if int(left[item])>0:dropped[item]=int(left[item])
 dropped["household gear lb"]=maxf(0.0,game.provisions.household_mass(game.state)-float(game.provisions.data.walking.personal_gear_lb_per_person)*int(game.state.party_size))
 result.merge({"valid":true,"message":"Sell the wagon and accepted leftovers; anything listed as LEFT BEHIND is permanently surrendered.","pack":pack,"cargo_lb":pack.cargo_lb,"capacity_lb":pack.capacity_lb,"keep_oxen":keep_oxen,"sold":sold,"dropped":dropped,"prices":prices,"payout_cents":payout,"days":int(counter.days),"key":key},true)
 return result
static func sell(game,cart: Dictionary,keep_oxen: int=-1) -> bool:
 var offer:=sale_quote(game,cart,keep_oxen)
 if not offer.valid:return false
 var counter: Dictionary=game.post_store()
 for row in counter.rows:
  var amount: int=offer.sold.get(row.item,0)
  if amount<=0:continue
  var key: String=row.sell_key
  var used: int=game._units_used(key,int(row.amount))+amount
  game.context.record.spent[key+"|units"]=used
  if row.item not in game.Produce.ITEMS:game.context.record.spent[key]=ceili(float(used)/int(row.amount))
 game.context.record.spent[str(counter.key)+"|sell_wagon|units"]=1
 if offer.days>0:game.context.record.spent[str(counter.key)+"|visit"]=1
 for item in offer.pack.inventory:game.state[item]=int(offer.pack.inventory[item])
 game.provisions.fresh.assign(offer.pack.carried.duplicate(true))
 game.state.oxen=int(offer.keep_oxen)
 game.state.parts=int(game.state.wheels)+int(game.state.axles)+int(game.state.tongues)
 game.state.vehicle="foot"
 game.state.household_gear_lb=float(game.provisions.data.walking.personal_gear_lb_per_person)*int(game.state.party_size)
 game.journal.append("Day %d · Sold the wagon and accepted leftovers for $%.2f. Sold: %s. Left behind permanently: %s." % [game.state.day,int(offer.payout_cents)/100.0,JSON.stringify(offer.sold),JSON.stringify(offer.dropped)])
 game.supply_history.append({"day":int(game.state.day),"event":"wagon_sale","sold":offer.sold.duplicate(true),"discarded":offer.dropped.duplicate(true),"payout_cents":offer.payout_cents})
 game._apply({"money":int(offer.payout_cents)/100.0,"days":int(offer.days)})
 game.refresh_stop_offers()
 return true
