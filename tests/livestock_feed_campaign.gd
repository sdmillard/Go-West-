extends "res://tests/livestock_balance_campaign.gd"
## Integration cohorts for mixed feeding; no extra money and no changed suggested outfit.
var initial_fodder_lb:=0
func starting_cart(game,method: String,equipment: String) -> Dictionary:
 var cart: Dictionary=super.starting_cart(game,method,equipment)
 if initial_fodder_lb>0:cart.livestock_fodder=initial_fodder_lb
 return cart
func extra_settings() -> Dictionary:
 var settings: Dictionary=super.extra_settings()
 settings["initial_fodder_lb"]=initial_fodder_lb
 settings["purpose"]="Mixed-feeding integration smoke; not a survival balance comparison."
 return settings
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--fodder="):initial_fodder_lb=clampi(int(arg.get_slice("=",1)),0,2500)
 await super.run()
