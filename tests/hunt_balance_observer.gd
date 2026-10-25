extends "res://tests/balance_observer.gd"
## Instrumentation only. Tests compare this observer against the unmodified engine.
func _init(seed_value: int=1848,mode: String="classic",setup: bool=false,end_at: String=""):
 super(seed_value,mode,setup,end_at)
 provisions=preload("res://tests/hunt_balance_food.gd").new()
 provisions.carriers=party_health.members
 field_outings=preload("res://tests/hunt_balance_outings.gd").new()
