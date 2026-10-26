extends "res://tests/income_balance_campaign.gd"
## Version 2: use known harvest food; allow the game's work opportunities after September.
func make_study_game(seed_value: int):
 var game=preload("res://tests/income_followup_observer.gd").new(seed_value,"classic",true)
 game.provisions=preload("res://tests/farmer_mastery_food.gd").new();game.provisions.carriers=game.party_health.members
 game.use_income=income_arm=="combined"
 return game
func extra_settings() -> Dictionary:
 var settings: Dictionary=super.extra_settings()
 settings.income_policy_version=2
 settings.income_policy="Same version-1 buying/sale/work rules, except no study-imposed October work cutoff; game availability still applies. Skin preparation tests four meals against carried food plus known recoverable food from this actual kill, not only pre-hunt camp stock. The same positive margin and physical limits remain. No new hunts, wages, prices or production-rule changes."
 return settings
func counter_visit(game,p: Dictionary,count: Dictionary,fundraising: bool=false) -> bool:
 if super.counter_visit(game,p,count,fundraising):return true
 # Before October the parent already checked this identical paid-work path.
 if income_arm!="combined" or not game.can_service() or int(game.calendar().month)<10 or float(game.state.money)>=10:return false
 var market: Dictionary=game.trade_counter()
 if market.is_empty():return false
 var meal: int=int(game.state.party_size)*int(game.provisions.data.rations_lb[game.state.rations])
 if int(game.state.food)<meal*2 or not market.rows.any(func(r):return r.item in ["food","dried_produce","produce","bullets"] and r.can_buy>0):return false
 var candidates: Array=[]
 for offer in game.income.offers(game):
  for member in game.party_health.members:
   var id: int=int(member.id)
   if id in chore_reserved or game.camp_tasks.job(id).job=="nurse":continue
   var q: Dictionary=game.income.quote(game,id,offer.id)
   if q.valid:candidates.append({"worker":id,"job":offer.id,"cents":int(q.cents)})
 candidates.sort_custom(func(a,b):return a.cents>b.cents if a.cents!=b.cents else a.worker<b.worker)
 if not candidates.is_empty() and game.income.work(game,candidates[0].worker,candidates[0].job):bump(count,"income_work");return true
 return false
