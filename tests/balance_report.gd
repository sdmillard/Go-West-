extends SceneTree
## Development experiment using real engine actions. Not a historical rate model.
const Simulation = preload("res://simulation/trail_engine.gd")
const PROFILES = [
	{"id": "cautious", "pace": 0, "rations": 2, "rest": true, "care": true},
	{"id": "grueling", "pace": 2, "rations": 2, "rest": false, "care": false},
	{"id": "bare_rations", "pace": 0, "rations": 0, "rest": true, "care": true},
	{"id": "meager_rations", "pace": 0, "rations": 1, "rest": true, "care": true},
	{"id": "no_rest", "pace": 0, "rations": 2, "rest": false, "care": false}
]

func _initialize() -> void:
	call_deferred("run")

func act(game, profile: Dictionary, aim: RandomNumberGenerator, counters: Dictionary) -> void:
	if not game.pending.is_empty():
		for index in range(game.pending.choices.size()):
			if game.can_choose(index):
				game.choose(index)
				return
		return
	game.configure(profile.pace, profile.rations)
	if game.state.food < 120 and game.state.money >= 15:
		if game.open_trade():
			game.choose(0)
		return
	if game.state.food < 45 and game.state.bullets >= 3:
		if game.start_hunt():
			counters.hunts += 1
			for shot in range(5):
				var target := 0
				while target in game.hunt.targets and target < game.hunt.animals.size():
					target += 1
				if target == game.hunt.animals.size():
					break
				game.advance_hunt(1.5)
				game.hunt_shot(target if aim.randf() < 0.65 else -1)
			game.finish_hunt()
		return
	if game.state.oxen == 0:
		if game.open_trade():
			game.choose(8 if game.state.money >= 30 else 18)
		return
	var worst := 100
	var patient := -1
	for member in game.party_health.members:
		if member.alive:
			worst = mini(worst, int(member.health))
			if not member.conditions.is_empty() and member.health < 55:
				patient = int(member.id)
	if profile.care and patient >= 0 and game.state.day - int(counters.last_care) >= 3 and (game.state.medicine > 0 or game.state.money >= 20):
		var desired := 6 if game.state.medicine > 0 else 12
		if game.open_care():
			for index in range(game.pending.choices.size()):
				var option: Dictionary = game.pending.choices[index]
				if option.get("member_id", -1) == patient and option.get("care", 0) == desired and game.can_choose(index):
					game.choose(index)
					counters.care += 1
					counters.last_care = game.state.day
					return
	if profile.rest and (worst < 65 or game.state.fatigue > 50):
		game.rest()
		counters.rest += 1
	else:
		var old_miles: int = game.state.miles
		game.travel()
		if game.state.miles > old_miles:
			counters.travel_days += 1
			counters.travel_miles += int(game.state.miles) - old_miles

func run() -> void:
	var initial_food := 600
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--food="):
			initial_food = int(argument.trim_prefix("--food="))
	var groups: Array[Dictionary] = []
	var sample_failures: Array[Dictionary] = []
	for profile in PROFILES:
		for month in [3, 5, 8]:
			for profession in ["farmer", "banker"]:
				var group := {"profile": profile.id, "month": month, "profession": profession, "runs": 20, "arrived": 0, "intact": 0, "lost": 0, "unfinished": 0, "days": 0, "survivors": 0, "health": 0, "hunts": 0, "rest": 0, "care": 0, "travel_days": 0, "travel_miles": 0}
				for seed_value in range(20):
					var game = Simulation.new(seed_value, "classic", true)
					game.depart(profession, ["A", "B", "C", "D", "E"], month, {"oxen": 6, "food": initial_food, "clothing": 5, "bullet_boxes": 10, "wheels": 1, "axles": 1, "tongues": 1, "medicine": 2})
					var aim := RandomNumberGenerator.new()
					aim.seed = seed_value ^ 0x41494d
					var counters := {"hunts": 0, "rest": 0, "care": 0, "last_care": -100, "travel_days": 0, "travel_miles": 0}
					for step in range(600):
						if game.state.status != "traveling":
							break
						act(game, profile, aim, counters)
					if game.state.status == "arrived":
						group.arrived += 1
						group.intact += 1 if game.state.party_size == 5 else 0
					elif game.state.status == "lost":
						group.lost += 1
					else:
						group.unfinished += 1
					if game.state.status != "arrived" and sample_failures.size() < 12:
						sample_failures.append({"profile": profile.id, "month": month, "profession": profession, "seed": seed_value, "state": game.state.duplicate(true), "pending": game.pending.get("id", ""), "recent_journal": game.journal.slice(maxi(0, game.journal.size() - 8))})
					group.days += int(game.state.day)
					group.survivors += int(game.state.party_size)
					group.health += int(game.state.health)
					for key in ["hunts", "rest", "care", "travel_days", "travel_miles"]:
						group[key] += int(counters[key])
				groups.append(group)
	var result := {"initial_food_lb": initial_food, "policy": "buy below 120 lb if affordable; otherwise hunt below 45 lb", "runs": PROFILES.size() * 120, "accuracy": 0.65, "seed_range": [0, 19], "groups": groups, "sample_failures": sample_failures}
	var label := "current"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):
			label = argument.trim_prefix("--label=")
	var path := "res://.tools/balance-" + label.validate_filename() + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	for profile in PROFILES:
		var totals := {"arrived": 0, "intact": 0, "lost": 0, "unfinished": 0, "days": 0, "survivors": 0, "hunts": 0, "rest": 0, "care": 0, "travel_days": 0, "travel_miles": 0}
		for group in groups:
			if group.profile == profile.id:
				for key in totals:
					totals[key] += int(group[key])
		print(profile.id, ": ", JSON.stringify(totals))
	print("Saved balance experiment: ", path)
	quit()
