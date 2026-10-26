extends RefCounted
## Purchase a single useful basket through public prices, stock, cargo and checkout.
static func buy(owner,game,profile: Dictionary,count: Dictionary) -> bool:
 for venue in ["","camp"]:
  var store: Dictionary=game.trade_counter(venue)
  if store.is_empty():continue
  var meal: int=int(game.state.party_size)*2
  var reserve: int=1000 if "barlow_pass" not in game.travelled_path() else 200
  if game.state.food<meal:reserve=200
  var budget: int=maxi(0,roundi(game.state.money*100)-reserve)
  var cart: Dictionary={};var targets: Dictionary={}
  var dried: Array=store.rows.filter(func(r):return r.item=="dried_produce" and r.can_buy>0)
  var held: int=owner.produce_held(game)
  if held==0 and (owner.has_scurvy(game) or int(game.party_health.days_without_fresh)>=10):
   if not dried.is_empty():targets.dried_produce=5 if store.kind=="post" else 3
   else:targets.produce=2
  if game.state.clothing<game.state.party_size:targets.clothing=int(game.state.party_size)
  if game.state.vehicle!="foot" and game.state.oxen<4:targets.oxen=4
  if game.state.bullets<30:targets.bullets=100 if store.kind=="post" else 40
  var target: int=maxi(300,meal*25) if store.kind=="post" else maxi(90,meal*7)
  # Public route knowledge: provision the long upland/dry segments before leaving a post.
  if store.kind=="post" and game.state.landmark=="fort_laramie":target=900
  elif store.kind=="post" and game.state.landmark in ["fort_hall","fort_boise"]:target=600
  if game.state.vehicle=="foot" and game.mount_plan().mode=="walking":target=mini(target,25)
  if game.state.food<(target if game.state.landmark in ["fort_laramie","fort_hall","fort_boise"] else meal*(10 if store.kind=="post" else 4)):targets.food=target
  if game.state.medicine<1:targets.medicine=1
  if game.state.salt<4:targets.salt=8
  for item in ["dried_produce","produce","clothing","oxen","bullets","food","medicine","salt"]:
   if not targets.has(item):continue
   var matches: Array=store.rows.filter(func(row):return row.item==item)
   if matches.is_empty():continue
   var row: Dictionary=matches[0]
   var price: float=float(row.buy_cents)/int(row.amount)
   var n: int=mini(mini(int(row.can_buy),maxi(0,int(targets[item])-int(row.held))),floori(budget/price))
   if n<=0:continue
   cart[item]=n
   var quote: Dictionary=game.counter_quote(cart,venue)
   while n>0 and (not quote.valid or float(quote.cargo_after_lb)>float(quote.capacity_after_lb)):
    n-=1
    if n==0:cart.erase(item)
    else:cart[item]=n
    quote=game.counter_quote(cart,venue)
   budget=maxi(0,roundi(game.state.money*100)-reserve+int(quote.get("net_cents",0)))
  var useful: bool=store.get("days",0)==0 or cart.has("food") or cart.has("produce") or cart.has("dried_produce") or cart.has("clothing") or cart.has("oxen") or (cart.has("bullets") and game.state.bullets<5) or (cart.has("medicine") and game.party_health.members.any(func(m):return game.party_health.is_active(m) and m.health<50))
  if useful and not cart.is_empty() and game.counter_quote(cart,venue).valid and game.counter_checkout(cart,venue):
   owner.bump(count,"expert_counter_visits")
   for item in cart:
    if item in ["produce","dried_produce"]:owner.bump(count,"expert_bought_"+item,int(cart[item]))
   return true
 return false
