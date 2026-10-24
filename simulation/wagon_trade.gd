extends RefCounted
## Store replacement frame and cover; existing belongings and animals remain separate.
static func valid_rules(v: Variant) -> bool:
 return v is Dictionary and v.get("note") is String and whole(v.get("price_cents"),1,1000000) and whole(v.get("stock_per_post"),1,8)
static func whole(v: Variant,low: int,high: int) -> bool:return (v is int or v is float) and is_finite(v) and v==floor(v) and v>=low and v<=high
static func row(game,key: String) -> Dictionary:
 var rule: Dictionary=game.provisions.data.replacement_wagon
 var buy_key: String=key+"|buy_wagon"
 var left: int=maxi(0,int(rule.stock_per_post)-int(game.context.record.spent.get(buy_key+"|units",0)))
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
