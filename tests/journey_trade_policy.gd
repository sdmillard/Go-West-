extends RefCounted
## Shared journey-study policy. Inspect effects: menu positions can be Wait/Back instead of transactions.
static func raise_toll_money(game,count: Dictionary) -> bool:
	if not game.open_trade():return false
	for item in ["bullets","wheels","axles","tongues","food","oxen"]:
		for index in range(game.pending.choices.size()):
			var effects: Dictionary=game.pending.choices[index].get("effects",{})
			if effects.get("money",0)>0 and effects.get(item,0)<0 and game.can_choose(index):
				var accepted: bool=game.choose(index)
				if accepted:count.trades+=1
				return accepted
	# No trader today: wait through the real public action, including meals and weather.
	if game.pending.title=="No traders nearby":
		for index in range(game.pending.choices.size()):
			if game.pending.choices[index].get("effects",{}).get("days",0)>0 and game.can_choose(index):
				var accepted: bool=game.choose(index)
				if accepted:count["trade_waits"]=int(count.get("trade_waits",0))+1
				return accepted
	# A refusal or exhausted sale opportunities is a policy block, not a successful transaction.
	game.choose(game.pending.choices.size()-1)
	return false
