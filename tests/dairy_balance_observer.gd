extends "res://tests/feeding_compare_observer.gd"
## Actual feed purchase prices, read before the same public checkout; no new decisions.
var feed_purchases: Array=[]
var feed_spent_cents: Dictionary={"poultry_feed":0,"livestock_fodder":0}
func _init(seed_value: int=1848,mode: String="classic",setup: bool=false,end_at: String=""):
 super(seed_value,mode,setup,end_at)
 livestock=preload("res://tests/dairy_balance_stock.gd").new()
func counter_checkout(cart: Dictionary,venue: String="") -> bool:
 var feed: Dictionary={}
 var store: Dictionary=trade_counter(venue)
 for row in store.get("rows",[]):
  if row.item in feed_spent_cents and int(cart.get(row.item,0))>0:
   feed[row.item]={"units":int(cart[row.item]),"cents":roundi(float(int(cart[row.item])*int(row.buy_cents))/int(row.amount))}
 var okay: bool=super.counter_checkout(cart,venue)
 if okay and not feed.is_empty():
  for kind in feed:feed_spent_cents[kind]+=int(feed[kind].cents)
  feed_purchases.append({"day":int(state.day),"place":str(state.landmark),"feed":feed})
 return okay
