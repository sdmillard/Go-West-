extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
var checks: int=0
var failures: int=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func party():
 var game=Simulation.new(57,"classic",true)
 game.depart("banker",["A","B","C","D","E"],5,{"oxen":6,"food":600,"clothing":5,"bullet_boxes":5,"medicine":2})
 for member in game.party_health.members:member.health=100
 game.state.health=100
 game.party_health.daily_onset_chance=0
 game.survival.forced_weather="clear"
 game.survival.data.event_chance=0
 game.seen.append("muddy_trail")
 game.configure(0,1)
 return game
func run():
 var game=party()
 game.state.food=0
 for day in range(6):game._tick_day(true)
 check(game.state.party_size==5 and game.state.health>=80 and game.state.get("hunger_days",0)==6,"Six missed days weaken healthy travelers instead of killing them")
 var before: int=game.state.health
 game.state.food=1000
 game._tick_day(true)
 check(game.state.health==before and game.state.hunger_days<6,"A meal starts repaying hunger rather than instantly healing starvation")
 var store=Store.new()
 var copy=store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))
 check(copy!=null and copy.state.hunger_days==game.state.hunger_days,"Fractional hunger deficit survives JSON saves")
 if copy!=null:
  copy.survival.forced_weather="clear"
  copy.party_health.daily_onset_chance=0
  game._tick_day(true);copy._tick_day(true)
  check(store.capture(game)==store.capture(copy),"Loaded hunger produces exactly the same next day and random streams")
 var bad: Dictionary=store.capture(game)
 for invalid in [-1,"hungry",100001]:
  var candidate: Dictionary=bad.duplicate(true)
  candidate.state.hunger_days=invalid
  check(store.restore(candidate)==null,"Invalid hunger state rejects")
 for day in range(20):
  if game.state.get("hunger_days",0)==0:break
  game._tick_day(true)

 before=game.state.health
 game._tick_day(true)
 check(game.state.health>before,"Rest heals again after regular meals clear the deficit")
 game=party()
 for day in range(12):
  game.state.food=0 if day%2==0 else 15
  game.configure(0,2)
  game._tick_day(true)
 check(game.state.health<100,"Alternating fasting and full meals cannot manufacture health")
 game=party()
 game.state.food=0
 for day in range(60):
  if game.state.status!="traveling":break
  game._tick_day(true)
 check(game.state.status=="lost" and game.state.day>14,"Prolonged deprivation still kills, without a six-day starvation clock")
 game=party()
 game.state.food=5
 game._tick_day(false)
 check(game.state.health>=98 and is_equal_approx(game.state.hunger_days,0.5),"Partial meals cause proportional deprivation")
 game=party()
 var original: Dictionary=store.capture(game)
 var quote: Dictionary=game.pack_quote({"food":70,"clothing":5,"bullets":20,"medicine":1})
 check(quote.valid and game.abandon_wagon({"food":70,"clothing":5,"bullets":20,"medicine":1}),"A reasonable abandonment pack still costs actual supplies and time")
 game.pending={}
 var distance: int=game.walking_distance()
 check(distance>=12 and distance<=20,"A healthy loaded walker has plausible good-weather moving-day progress")
 game.party_health.begin_condition(1,"broken_leg",game.state.day)
 check(game.provisions.Carrying.factor(game.party_health.members[1])==0,"A broken leg still prevents hauling")
 game=party()
 check(not game.state.has("hunger_days"),"Well-fed journeys do not gain unnecessary saved hunger state")
 var legacy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/pre-emergency-travel-save-v1.json"))
 var previous=store.restore(legacy)
 check(previous!=null and not previous.state.has("hunger_days") and previous.state.day==0,"A genuine previous-rule save loads without inventing past starvation")
 print("Emergency travel: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
