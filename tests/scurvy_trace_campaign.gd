extends "res://tests/farmer_mastery_campaign.gd"
func make_study_game(seed_value: int):
 var game=preload("res://tests/scurvy_trace_observer.gd").new(seed_value,"classic",true)
 game.provisions=preload("res://tests/farmer_mastery_food.gd").new();game.provisions.carriers=game.party_health.members
 return game
func extra_row(game,count: Dictionary) -> Dictionary:
 var row: Dictionary=super.extra_row(game,count)
 row["nutrition_trace"]=game.nutrition_trace.duplicate(true)
 return row
func extra_settings() -> Dictionary:
 var settings: Dictionary=super.extra_settings();settings["nutrition_trace_version"]=1
 return settings
