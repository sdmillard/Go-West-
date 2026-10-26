extends "res://tests/feeding_compare_campaign.gd"
## Exploratory existing-setting comparison, declared after the sealed primary results.
var sharing: bool=true
func make_study_game(seed_value: int):
 var game=super.make_study_game(seed_value)
 game.livestock.record["share_scraps"]=sharing
 return game
func extra_settings() -> Dictionary:
 var settings: Dictionary=super.extra_settings()
 settings["sharing"]=sharing;settings["purpose"]="Exploratory sharing on/off; fresh seeds, not pooled with the primary/confirmation matrix."
 return settings
func extra_row(game,count: Dictionary) -> Dictionary:
 var row: Dictionary=super.extra_row(game,count)
 row["sharing_setting"]=game.livestock.record.get("share_scraps",true)
 return row
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--sharing="):sharing=arg.get_slice("=",1)=="on"
 await super.run()
