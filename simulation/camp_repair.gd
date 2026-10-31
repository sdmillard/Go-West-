extends RefCounted
## A broken wagon part belongs to the wagon, including when cached.
const PARTS=["wheels","axles","tongues"]
var work: Dictionary={}
func blocked(game) -> bool:return game.state.vehicle=="wagon" and not work.is_empty()
func valid(value: Variant,game) -> bool:
 if not value is Dictionary:return false
 if value.is_empty():return true
 if value.size()!=4 or value.get("part") not in PARTS or value.get("method") not in ["","patch","wood"] or not value.get("kit_spent") is bool:return false
 if not game.characters.whole(value.get("progress"),0,maxi(int(game.camp_tasks.rules.repair_work_days.patch),int(game.camp_tasks.rules.repair_work_days.wood))-1):return false
 if value.method=="":return value.progress==0 and not value.kit_spent
 if value.method=="patch":return value.progress<int(game.camp_tasks.rules.repair_work_days.patch) and value.kit_spent
 return value.progress<int(game.camp_tasks.rules.repair_work_days.wood) and not value.kit_spent
func queue(game,part: String) -> bool:
 if part not in PARTS or blocked(game) or game.state.vehicle!="wagon":return false
 work={"part":part,"method":"","progress":0,"kit_spent":false}
 if game.state.has("wagon_train"):
  var wagon: Dictionary=game.state.wagon_train[game.rng.randi_range(0,game.state.wagon_train.size()-1) if game.state.wagon_train.size()>1 else 0]
  wagon.condition=0;game.state["repair_wagon_id"]=int(wagon.id)
 game.journal.append("Day %d · The broken %s needs camp repairs before wagon travel resumes." % [game.state.day,part])
 return true
func reason(game,index: int,method: String,kits: int=-1) -> String:
 if not blocked(game):return "No broken wagon part needs repair."
 if index>0 and method=="wood" and not game.camp_tasks.specialist(game,index,"Carpentry"):return "A Carpenter is needed to make a wooden repair."
 if not str(work.method).is_empty() and work.method!=method:return "A %s repair is already underway; resume that method or fit a spare." % work.method
 if method=="patch" and not work.kit_spent and (game.state.medicine if kits<0 else kits)<1:return "Needs one care kit to start patching."
 return ""
func advance(game,index: int) -> void:
 if not blocked(game):return
 var units:=1+(int(game.characters.benefits.carpentry_days_saved) if game.camp_tasks.specialist(game,index,"Carpentry") else 0)
 work.progress+=units
 var needed: int=int(game.camp_tasks.rules.repair_work_days[work.method])
 game.journal.append("Day %d · %s repaired the %s: %d / %d work units." % [game.state.day,game.party_health.members[index].name,work.part,mini(int(work.progress),needed),needed])
 if int(work.progress)>=needed:
  game.supply_history.append({"day":game.state.day,"event":"camp_repair_complete","part":work.part,"worker":index,"changes":{}})
  game.Train.repair_done(game)
  work={}
  game.journal.append("Day %d · The wagon repair is complete." % game.state.day)
func fit_spare(game) -> bool:
 if not game.can_service() or not blocked(game) or int(game.state.get(work.part,0))<1:return false
 var part: String=work.part
 game._apply({part:-1})
 game.Train.repair_done(game)
 work={}
 game.journal.append("Day %d · Fitted a spare %s; no day passed." % [game.state.day,part])
 return true

func leader_work(game,method: String) -> bool:
 if not game.can_service() or method not in ["patch","wood"] or not reason(game,0,method).is_empty():return false
 if method=="patch" and not work.kit_spent:
  game.state.medicine-=1
  work.kit_spent=true
  game.supply_history.append({"day":game.state.day,"event":"camp_repair_materials","changes":{"medicine":-1},"worker":0})
 work.method=method
 game._tick_day(false,false,"repair")
 if game.party_health.is_active(game.party_health.members[0]):advance(game,0)
 if game.state.status=="traveling" and game.pending.is_empty():game._schedule_event(false)
 return true
