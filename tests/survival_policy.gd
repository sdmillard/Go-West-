extends RefCounted
## Integration-test decisions through public engine actions, not a second simulator.
static func step(game) -> void:
	if game.state.status != "traveling":
		return
	if not game.pending.is_empty():
		for index in range(game.pending.choices.size()):
			if game.can_choose(index):
				game.choose(index)
				return
	elif game.state.food < 120 and game.state.money >= 15:
		if game.open_trade():
			game.choose(0)
	elif game.state.food < 45 and game.state.bullets >= 3:
		if game.start_hunt():
			for target in range(game.hunt.animals.size()):
				game.advance_hunt(1.5)
				game.hunt_shot(target)
			game.finish_hunt()
	elif game.state.oxen == 0:
		if game.open_trade():
			var target := 8 if game.state.money >= 30 else 18
			game.choose(target)
	elif game.state.fatigue > 50 or game.state.health < 70:
		game.rest()
	else:
		game.travel()
