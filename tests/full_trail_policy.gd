extends RefCounted
## Decisions for full-route development playthroughs, using the actual public engine.
static func step(game) -> void:
 if game.state.status != "traveling":return
 game.configure(0,2)
 # Longer-lived stranded parties may now reach a real carry limit after losing the wagon.
 if game.state.vehicle=="foot" and game.pending.is_empty() and game.provisions.cargo(game.state)>game.provisions.capacity(game.state):
  var excess: float=game.provisions.cargo(game.state)-game.provisions.capacity(game.state)
  for item in ["wheels","axles","tongues","salt","medicine","food","clothing"]:
   var available: int=int(game.state.get(item,0))
   if available<=0:continue
   if game.discard_supply(item,mini(available,maxi(1,ceili(excess/float(game.provisions.data.weights_lb[item]))))):return
  game.rest()
  return
 if not game.pending.is_empty():
  if game.pending.has("landmark") and game.route.nodes[game.state.landmark].get("trade_bulk",false) and game.state.food < 1250 and game.state.money >= 60:
   if game.open_trade():
    if game.can_choose(0):
     game.choose(0)
     return
    game.choose(game.pending.choices.size()-1)
  for index in range(game.pending.choices.size()):
   if game.can_choose(index):
    game.choose(index)
    return
 elif game.state.oxen == 0:
  if game.open_trade():game.choose(8)
 elif game.state.food < 90 and game.state.money >= 15 and game.open_trade():
  if game.can_choose(0):
   game.choose(0)
   return
  # Traders with no food left to sell: close the counter and keep going rather than asking again.
  game.choose(game.pending.choices.size()-1)
  if game.pending.is_empty():game.travel()
 elif game.state.health < 75 or game.state.fatigue > 50 or game.state.ox_health < 65:
  game.rest()
 else:
  game.travel()
