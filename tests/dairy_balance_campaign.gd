extends "res://tests/feeding_compare_campaign.gd"
## Frozen ordinary decisions; common read-only measurements on both rule versions.
func make_study_game(seed_value: int):return preload("res://tests/dairy_balance_observer.gd").new(seed_value,"classic",true)
func extra_settings() -> Dictionary:
 var settings: Dictionary=super.extra_settings()
 settings["dairy_balance_version"]=1
 settings["study_note"]="Matched prior feeding versus calibrated dairy/shared pasture; primary ordinary decisions fixed, secondary current-rule hay shopping."
 return settings
func extra_row(game,count: Dictionary) -> Dictionary:
 var row: Dictionary=super.extra_row(game,count)
 row["dairy_balance"]={"feed_spent_cents":game.feed_spent_cents.duplicate(),"feed_purchases":game.feed_purchases.duplicate(true),"grazing_activities":game.context.record.activities.filter(func(id):return game.context.data.activities[id].get("kind","")=="graze")}
 return row
