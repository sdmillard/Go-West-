extends SceneTree
const Sim=preload("res://simulation/trail_engine.gd")
const Save=preload("res://simulation/save_store.gd")
const Dog=preload("res://simulation/working_dog.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func game(with_dog: bool=true,seed_value: int=780101):
 var g=Sim.new(seed_value,"classic",true)
 var cart: Dictionary={"oxen":4,"food":500,"clothing":5,"bullet_boxes":2}
 if with_dog:cart["dog"]=1
 check(g.depart("banker",["Ada","Sam","Jo","Lou","Pat"],5,cart),"Dog outfit departs")
 g.pending={};g.party_health.daily_onset_chance=0;g.survival.forced_weather="clear"
 return g
func copy(g):return Save.new().restore(JSON.parse_string(JSON.stringify(Save.new().capture(g))))
func kcal(g) -> float:return int(g.state.food)*1000.0+float(g.livestock.available_kcal())
func _initialize():call_deferred("run")
func run():
 var g=game()
 check(g.dogs.alive() and g.party_health.members.size()==5,"One dog does not consume a traveler slot")
 var empty=game(false)
 check(empty.state.money-g.state.money==5.0,"Initial dog costs five real dollars")
 check(not empty.dogs.alive(),"Optional dog gives nothing to dog-free parties")
 var before: float=kcal(g)
 var mass: float=g.provisions.cargo(g.state)
 check(is_equal_approx(g.dogs.eat(g,1200),1200),"Exact dog meal is consumed")
 check(is_equal_approx(before-kcal(g),1200),"Partial serving conserves calories")
 check(g.state.food==498 and is_equal_approx(g.livestock.available_kcal(),800),"Unused serving remains real food")
 check(g.provisions.cargo(g.state)<mass,"Dog meal removes real cargo")
 check(copy(g)!=null,"Partial dog meal saves")
 before=kcal(g)
 g.dogs.eat(g,1200)
 check(is_equal_approx(before-kcal(g),1200),"A second meal uses the actual retained portion")
 check(copy(g)!=null,"Repeated fractional feeding saves")
 g=game();g.state.food=0;g.provisions.fresh.clear()
 g.provisions.add_produce(4,int(g.state.day));g.state.food=1
 before=kcal(g)
 check(g.dogs.eat(g,1200)==0 and kcal(g)==before,"Dog does not consume scarce vitamin-C produce")
 g=game();g.dogs.configure(g,"MURPHY","rest","share")
 before=kcal(g);var day: int=g.state.day
 g._tick_day(true,false,"rest")
 check(g.state.day==day+1 and is_equal_approx(before-kcal(g),16200),"Rest day charges human meals plus exact dog ration")
 check(g.dogs.last.eaten_kcal==1200 and g.dogs.record.dog.fed==1,"Rest ration covers dog need")
 before=kcal(g);g.dogs.tick(g,true,false)
 check(kcal(g)==before,"Same-day feeding cannot run twice")
 check(copy(g)!=null,"Dog state survives a day and JSON round trip")
 var loaded=copy(g)
 g.pending={};loaded.pending={};g._tick_day(true,false,"rest");loaded._tick_day(true,false,"rest")
 check(g.dogs.record==loaded.dogs.record and g.state.food==loaded.state.food,"Loaded next-day feeding is deterministic")
 g=game();g.state.food=15;g.dogs.configure(g,"MURPHY","rest","share");g._tick_day(true,false,"rest")
 check(g.livestock.last_meal.eaten==15 and g.dogs.last.eaten_kcal==0,"People eat before the dog when food is scarce")
 check(g.dogs.record.dog.condition==94 and not g.dogs.ready("rest"),"An unfed dog loses condition and cannot work")
 g=game();g.dogs.configure(g,"MURPHY","rest","surplus");g.state.food=30;g._tick_day(true,false,"rest")
 check(g.dogs.last.eaten_kcal==0 and g.state.food==15,"Reserve feeding protects tomorrow's human meals")
 g=game();g.dogs.configure(g,"MURPHY","rest","off");g._tick_day(true,false,"rest")
 check(g.dogs.last.eaten_kcal==0,"No-sharing policy really consumes no food")
 g=game();g.dogs.record.dog.condition=50;g.dogs.record.dog.fatigue=74
 check(g.dogs.ready("watch"),"Fair dog retains full work eligibility")
 g.dogs.record.dog.condition=49;check(not g.dogs.ready("watch"),"Poor condition prevents work")
 g.dogs.record.dog.condition=100;g.dogs.record.dog.fatigue=75;check(not g.dogs.ready("watch"),"Exhausted dog needs rest")
 g.dogs.configure(g,"MURPHY","rest","share");g._tick_day(true,false,"rest")
 check(g.dogs.record.dog.fatigue==59,"Rest recovers dog fatigue")
 var caught:=0
 for seed_value in range(780200,780260):
  g=game(true,seed_value);g.dogs.configure(g,"MURPHY","hunt","share")
  g.state.bullets=0
  check(g.start_hunt(),"Ready dog can accompany an unarmed hunt")
  g.hunt.animals=[{"kind":2,"x":100.0,"y":100,"direction":1,"escaped":false,"meat":2,"kcal_per_lb":520.0}]
  g.hunt.targets=[];g.hunt.meat=0;g.hunt.dog_seen_rabbits=[]
  # A controlled existing rabbit isolates dog catching from regional search RNG.
  var ammo: int=g.state.bullets
  g.advance_hunt(0.001)
  check(g.hunt.dog_seen_rabbits==[0] and g.hunt.elapsed<0.01,"Rabbit appearance triggers a chance without waiting")
  var meat: int=g.hunt.meat
  if meat>0:
   caught+=1
   check(meat==2 and g.hunt.targets==[0] and g.hunt_calorie_density()==520,"Rabbit catch uses existing species mass and calories")
  g.advance_hunt(8.1)
  check(g.hunt.meat==meat and g.state.bullets==ammo,"Dog never rerolls the same rabbit; catches spend no bullet")
  if seed_value==780200:
   check(g.finish_hunt() and g.state.day==1,"Dog hunt costs a real day")
   check(g.dogs.record.dog.fatigue==12,"Hunt work costs fatigue")
   check(copy(g)!=null,"Completed dog hunt saves")
 check(caught>0 and caught<60,"Rabbit catches are possible but not guaranteed")
 g=game();g.dogs.configure(g,"MURPHY","hunt","share");check(g.start_hunt(),"Dog hunt starts")
 g.hunt.animals=[{"kind":1,"x":100.0,"y":100,"direction":1,"escaped":false,"meat":53,"kcal_per_lb":550.0}]
 g.hunt.targets=[];g.hunt.meat=0;g.advance_hunt(9)
 check(g.hunt.meat==0,"Dog never kills deer or bison")
 g=game(false);g.state.bullets=0;check(not g.start_hunt(),"No gun and no dog cannot initiate hunting")
 g=game();g.dogs.configure(g,"MURPHY","watch","share")
 var warnings:=0
 for i in range(40):
  g.state.day=i
  var event: Dictionary={"id":"bandits","text":"Travelers approach."}
  var rng_before: int=g.rng.state;var survival_before: int=g.survival.rng.state
  g.dogs.warn(g,event)
  if event.text.contains("MURPHY"):warnings+=1
  check(g.rng.state==rng_before and g.survival.rng.state==survival_before,"Dog warnings do not disturb core random streams")
 check(warnings>0 and warnings<40,"Warnings are useful but not certain")
 g=game(false);var cash: float=g.state.money
 check(g.dogs.acquire(g) and g.state.money==cash-5,"Post dog purchase uses actual cash")
 check(not g.dogs.acquire(g),"Cannot purchase a second living dog")
 g.dogs.record.dog.condition=0
 check(not g.dogs.available(g),"Post offer cannot respawn after loss")
 g.state.landmark="fort_laramie";check(g.dogs.available(g),"Another real post can offer a replacement")
 g=game();var crossing: Dictionary={"method":"ferry","mishap":true};g.dogs.cross(g,crossing)
 check(g.dogs.record.dog.condition==100,"Dog on a ferry has no swimming risk")
 var lost:=0
 for seed_value in range(780300,780360):
  g=game(true,seed_value);crossing={"method":"float","mishap":true};g.dogs.cross(g,crossing)
  if not g.dogs.alive():lost+=1
  check(copy(g)!=null,"Crossing dog outcome saves")
 check(lost>0 and lost<60,"River mishaps can lose a dog, without guaranteed loss")
 g=game();var save=Save.new();var value: Dictionary=save.capture(g)
 for key in ["condition","fatigue","fed","last_day","last_hunt"]:
  var bad: Dictionary=value.duplicate(true);bad.dogs.dog[key]=10000000
  check(save.restore(bad)==null,"Invalid saved dog field rejected: "+key)
 for key in ["job","feeding"]:
  var bad: Dictionary=value.duplicate(true);bad.dogs.dog[key]="unknown"
  check(save.restore(bad)==null,"Unknown dog option rejected")
 var bad: Dictionary=value.duplicate(true);bad.dogs.purchased_at.append("no_such_place")
 check(save.restore(bad)==null,"Unknown dog purchase location rejected")
 var prior: String="5b8aba3939de03910fb7b9c205be63a752f815f4a28b0dc1dd215642118e6fa5"
 value.erase("dogs");value.rules=prior
 var migrated=save.restore(value)
 check(migrated!=null and not migrated.dogs.alive(),"Previous-rules save gains no free dog")
 var rules: Dictionary=g.dogs.data.duplicate(true)
 for field in ["price_cents","rest_kcal","work_kcal","rabbit_chance","search_chance"]:
  var broken: Dictionary=rules.duplicate(true);broken[field]=-1
  check(not Dog.new().load_data(broken),"Invalid dog rules rejected: "+field)
 g=game();g.dogs.record.dog.condition=1
 crossing={"method":"float","mishap":true};g.dogs.cross(g,crossing)
 check(not g.dogs.alive() and crossing.has("dog_lost"),"A weak dog's fatal crossing is explicitly recorded")
 g=game();g.dogs.configure(g,"MURPHY","hunt","share")
 var before_core: int=g.rng.state;var before_health: int=g.party_health.rng.state;var before_survival: int=g.survival.rng.state
 for i in range(8):g.dogs.available(g);g.dogs.valid(g.dogs.record,g)
 check(g.rng.state==before_core and g.party_health.rng.state==before_health and g.survival.rng.state==before_survival,"Read-only dog review does not reroll outcomes")
 var search_help:=0
 for seed_value in range(780400,780440):
  g=game(true,seed_value);g.dogs.configure(g,"MURPHY","hunt","share");g.hunting_outings=1
  g.hunt={"animals":[],"targets":[],"meat":0,"region":"plains","message":"No game."}
  g.dogs.begin_hunt(g)
  if g.hunt.animals.size()==1:search_help+=1
 check(search_help>0 and search_help<40,"A dog can find game on an empty search without guaranteeing it")
 g=game()
 g.dogs.configure(g,"MURPHY","hunt","share");g.dogs.data.rabbit_chance=1.0
 check(g.start_hunt(),"Appearance test hunt starts")
 g.hunt.animals=[];g.hunt.targets=[];g.hunt.meat=0;g.hunt.dog_seen_rabbits=[];g.hunt.dog_rabbit_lb=0
 g.hunt.animals.append({"kind":2,"x":100.0,"y":100,"direction":1,"escaped":false,"meat":2,"kcal_per_lb":520.0})
 g.advance_hunt(0.001)
 check(g.hunt.meat==2 and g.hunt.targets==[0],"Rabbit can be caught immediately on appearing")
 for i in range(12):g.advance_hunt(0.001)
 check(g.hunt.meat==2,"Many frames do not duplicate a caught rabbit")
 g.hunt.animals.append({"kind":2,"x":110.0,"y":100,"direction":1,"escaped":false,"meat":1,"kcal_per_lb":520.0})
 g.advance_hunt(0.001)
 check(g.hunt.meat==3 and g.hunt.targets==[0,1] and g.hunt.dog_rabbit_lb==3,"A newly appearing second rabbit has its own chance")
 g.hunt.animals.append({"kind":2,"x":120.0,"y":100,"direction":1,"escaped":true,"meat":2,"kcal_per_lb":520.0})
 g.advance_hunt(0.001)
 check(g.hunt.meat==3,"An escaped rabbit cannot be caught")
 var previous_dog_rules: String="cc971747c8d6a1ef15c480251962a7d97b1abf68e79806c5d6611d00249491fa"
 var previous_dog_save: Dictionary=Save.new().capture(game())
 previous_dog_save.rules=previous_dog_rules
 var previous_dog_restored=Save.new().restore(previous_dog_save)
 check(previous_dog_restored!=null and previous_dog_restored.dogs.record==previous_dog_save.dogs,"Eight-second-rule save preserves dog state after appearance correction")
 var panel=preload("res://ui/dog_view.gd").new();root.add_child(panel);await process_frame
 panel.open(g);check(panel.visible and panel.rows.get_child_count()>3,"Dog panel opens with controls")
 panel.hide();panel.queue_free()
 print("Working dogs: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
