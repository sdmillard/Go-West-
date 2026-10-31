extends "res://tests/current_journey_policy.gd"
## Same ordinary decisions for every arm, with a declared shot-timing sensitivity.
var dog_arm: String="none"
var wait_for_dog: bool=true
func hunt_outing(game,profile: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
 if not game.start_hunt():return false
 count.hunts+=1
 if wait_for_dog:game.advance_hunt(8.0)
 var ammo: int=game.state.bullets
 for shot in range(5):
  if game.hunt.ended:break
  var target: int=-1
  for index in range(game.hunt.animals.size()):
   if index not in game.hunt.targets and not game.hunt.animals[index].escaped:
    target=index;break
  if target<0:break
  var point: Vector2=game.hunting.bounds(game.hunt,target).get_center() if aim.randf()<0.65 else Vector2.ZERO
  game.hunt_fire_at(point);game.advance_hunt(1.5)
 count.shots+=ammo-int(game.state.bullets);count.meat_obtained+=int(game.hunt.meat)
 if game.hunt.meat==0:count.empty_hunts+=1
 var okay: bool=game.finish_hunt()
 if okay:count["last_hunt_day"]=int(game.state.day)
 count.meat_carried+=float(game.last_hunt_recovery.get("mass",0))
 return okay
func manage_dog(game) -> void:
 if dog_arm=="none" or not game.dogs.alive() or not game.can_service():return
 var dog: Dictionary=game.dogs.record.dog
 var job: String="hunt" if dog_arm=="hunt" else "watch"
 # Use existing human rest days to rest the dog, without buying extra camp days.
 if float(dog.fatigue)>=65 or float(dog.condition)<70 or float(dog.fed)<0.75:job="rest"
 elif dog.job=="rest" and float(dog.fatigue)>25:job="rest"
 game.dogs.configure(game,"BUDDY",job,"share")
