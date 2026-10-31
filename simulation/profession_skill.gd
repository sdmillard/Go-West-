extends RefCounted
## The leader's starting profession as a skill, like a companion's background (Spencer: abilities,
## not extra gear). Hunters, saddlers, carpenters, doctors and merchants count as specialists in the
## matching companion background; farmers are Stockmen. Soldiers and
## outlaws carry the Soldiering and Outlawry backgrounds. Bankers' edge is their cash.
## Rules live in data/party_benefits.json profession_skills; every skill needs a fit leader.
static func rules(game) -> Dictionary:
	if game is Dictionary or not "characters" in game or game.characters==null:return {}
	return game.characters.benefits.get("profession_skills",{}).get(str(game.state.get("profession","")),{})
## The leader can work the skill: alive, active, at least the companions' minimum health, no serious condition.
static func fit(game) -> bool:
	if game.party_health.members.is_empty():return true
	var leader: Dictionary=game.party_health.members[0]
	return game.party_health.is_active(leader) and int(leader.health)>=int(game.characters.benefits.minimum_health) and not leader.conditions.any(func(c):return int(c.get("severity",1))>=3)
static func background(game) -> String:
	var skill: Dictionary=rules(game)
	return str(skill.get("background","")) if not skill.is_empty() and fit(game) else ""
## Stockman numbers when the farmer leader can tend the animals today, else {}.
static func stockman(game) -> Dictionary:
	var skill: Dictionary=rules(game)
	if not skill.has("ox_strain_less") or not fit(game):return {}
	return skill
static func valid(value: Variant,backgrounds: Array) -> bool:
	if not value is Dictionary:return false
	for profession in value:
		if profession not in preload("res://simulation/outfitting.gd").PROFESSIONS:return false
		var skill: Variant=value[profession]
		if not skill is Dictionary or not skill.get("label") is String or not skill.get("description") is String:return false
		if skill.has("background") and skill.background not in backgrounds:return false
		if skill.has("ox_strain_less"):
			for key in ["ox_strain_less","ox_recovery_more"]:
				if not (skill.get(key) is int or skill.get(key) is float) or skill[key]!=floor(skill[key]) or skill[key]<0 or skill[key]>5:return false
			for key in ["forage_worker_factor","butcher_meat_factor","dairy_factor"]:
				if not (skill.get(key) is int or skill.get(key) is float) or not is_finite(skill[key]) or skill[key]<1 or skill[key]>3:return false
	return true
