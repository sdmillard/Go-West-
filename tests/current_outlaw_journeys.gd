extends "res://tests/current_journey_policy.gd"
## Same twenty outlaw scenarios, with the current public-action survival policy.
## The original outlaw runner retains its archived behavior and reporting.
func survival_profile() -> Dictionary:
 return {"id":"current_outlaw","pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":90,"adaptive_rations":true,"preserve":"salt","slaughter":true,"slaughter_team_floor":4,"rest_below":55,"preserve_meals":3.3,"opportunity":1,"produce":true}
func report_path() -> String:return "res://.tools/current-outlaw-journeys.json"
func report_policy(_text: String) -> String:
 return "20 full-route journeys, same five outlaw/lawful strategies and four seeds as the archived outlaw runner. Current public-action counter/produce/foraging/nutrition policy, salted hunting at 65% scripted aim, four working oxen preserved, real recovery and discard actions. No scouting, companion dispatch or new outfitted-hunt balance claim. Integration evidence, not historical or survival-balance certification."
