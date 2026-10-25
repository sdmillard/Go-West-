extends "res://tests/hunting_balance_campaign.gd"
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func prepare(type,seed_value: int):
 var g=type.new(seed_value,"classic",true)
 check(g.depart("farmer",["A","B","C","D","E"],5,starting_cart(g,"ride","shared")),"Party departs legally")
 return g
func emergency():
 var g=prepare(Observed,5711)
 g.pending={};g.state.next_landmark="elm_grove";g.state.leg_length=20;g.state.leg_miles=1;g.state.miles=1
 g.state.food=0;g.provisions.fresh.clear()
 g.party_health.daily_onset_chance=0;g.survival.data.event_chance=0;g.survival.forced_weather="clear"
 for member in g.party_health.members:member.health=100
 g.state.health=100
 return g
func run():
 adaptive=true;hunting_study=true
 # Observer and unmodified game must preserve exact state, saves and random streams.
 for method in ["foot","outrider"]:
  var a=prepare(Observed,84001)
  var b=prepare(Simulation,84001)
  var p: Dictionary=policy(method)
  var aa:=RandomNumberGenerator.new();var ab:=RandomNumberGenerator.new()
  aa.seed=1701;ab.seed=1701
  var ca: Dictionary=count_template();var cb: Dictionary=count_template()
  for step in range(200):
   if a.state.status!="traveling":break
   check(act(a,p,aa,ca)==act(b,p,ab,cb),"Instrumentation preserves successful public actions")
   if step%10==0:check(Store.new().capture(a)==Store.new().capture(b),"Food/field observers preserve inventory and RNG exactly")
  check(a.audit.days==a.state.day,"Observed elapsed days remain exact")
 var g=emergency()
 var offer: Dictionary=foot_offer(g)
 var before: Dictionary=Store.new().capture(g)
 var q: Dictionary=g.hunt_outfit_quote(offer.members,offer.kit,offer.bullets)
 check(q.valid and q.short_provisions and q.inventory.food==0,"A starving day party can hunt without invented reserve food")
 check(Store.new().capture(g)==before,"Emergency quote and existing helper orders consume no resources or RNG")
 check(not g.field_outings.Outfit.quote(g,[1],"ride_horse",2,5).valid,"Longer expeditions retain their reserve requirement")
 check(g.start_hunt(offer),"Starving explicit day hunt starts")
 var day: int=g.state.day;var bullets: int=g.state.bullets
 g.hunt.meat=100
 check(g.finish_hunt() and g.state.day==day+1 and g.state.food>0,"Actual catch feeds this day before remaining food is packed")
 check(g.last_hunt_recovery.eaten_food==15 and g.audit.underfed_days==0,"Successful emergency catch supplies exactly one party meal")
 check(g.state.bullets==bullets+offer.bullets,"Unused reserved ammunition returns once")
 g=emergency();offer=foot_offer(g)
 check(g.start_hunt(offer) and g.finish_hunt() and g.state.food==0 and g.audit.underfed_days==1,"Failed emergency hunt still costs a hungry day without free food")
 g=emergency();g.state.clothing=0
 offer=foot_offer(g);q=g.hunt_outfit_quote(offer.members,offer.kit,offer.bullets)
 check(q.valid and q.short_provisions and q.inventory.clothing==0,"Missing clothing warns rather than inventing clothing or blocking a day hunt")
 check(g.start_hunt(offer) and g.finish_hunt() and g.state.clothing==0,"Short clothing is never duplicated on return")
 g=emergency();g.state.bullets=0
 check(not g.hunt_outfit_quote([0],"foot",1).valid,"Emergency hunting still requires real ammunition")
 print("Hunting balance instrumentation / emergency outings: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
