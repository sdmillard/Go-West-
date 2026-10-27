extends SceneTree
const Study=preload("res://tests/fixed_hide_campaign.gd")
const Store=preload("res://simulation/save_store.gd")
var checks:=0
var failures:=0
func _initialize():call_deferred("run")
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func run():
 var study=Study.new();var d=study.driver("none","hired","crew");var source=d.make_study_game(572901)
 check(source.depart("farmer",["A","B","C","D","E"],4,d.starting_cart(source,"foot","shared")),"Actual study setup departs")
 source.pending={};source.state.deer_hide=1
 var snapshot: Dictionary=Store.new().capture(source)
 var a=study.clone(snapshot);var b=study.clone(snapshot);var plain=Store.new().restore(snapshot)
 check(Store.new().capture(a)==snapshot and Store.new().capture(b)==snapshot,"Both branches start from the exact complete saved state")
 check(a!=b and a.provisions!=b.provisions and a.party_health!=b.party_health and a.rng!=b.rng,"Clones have independent production modules and random streams")
 check(a.rest() and plain.rest() and Store.new().capture(a)==Store.new().capture(plain),"Read-only observation preserves the actual next day's state and RNG")
 check(Store.new().capture(b)==snapshot and b.days.is_empty(),"Advancing one branch cannot modify the other")
 check(a.days.size()==1 and a.days[0].day==snapshot.state.day+1,"Only days after the checkpoint are counted")
 check(study.eligible(b),"A genuine available artisan and existing material qualify")
 b.state.deer_hide=0;check(not study.eligible(b),"No checkpoint is invented when there are no hides")
 b.state.deer_hide=1;b.characters.profiles[2].skill="Carpentry"
 check(not study.eligible(b),"Missing leatherworking skill cannot qualify")
 check(study.errors.is_empty(),"Clone capture equality checks remain clean")
 d.free();study.free()
 print("Fixed-hide study: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
