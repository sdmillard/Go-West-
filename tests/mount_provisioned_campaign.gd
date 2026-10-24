extends "res://tests/mount_balance_campaign.gd"
## Independent policy sensitivity: spend on reserves at posts, hunt for a smaller buffer.
## No game rules, initial outfits or random outcomes change.
func policy(mode: String,strategy: String,accuracy: float=0.65) -> Dictionary:
 var result: Dictionary=super.policy(mode,strategy,accuracy)
 result.opportunity=0
 result.hunt_below=30
 return result
