extends "res://tests/feeding_compare_stock.gd"
## Read-only condition exposure, outside the saved livestock record.
func _init():
 super()
 audit.merge({"animal_days":{},"condition_points":{},"poor_animal_days":{}})
func tick(game,resting: bool,working: bool) -> void:
 super.tick(game,resting,working)
 for animal in record.animals:
  var kind: String=animal.kind
  audit.animal_days[kind]=int(audit.animal_days.get(kind,0))+1
  audit.condition_points[kind]=int(audit.condition_points.get(kind,0))+int(animal.condition)
  if int(animal.condition)<50:audit.poor_animal_days[kind]=int(audit.poor_animal_days.get(kind,0))+1
