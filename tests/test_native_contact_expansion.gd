extends "res://tests/test_native_contact_stories.gd"
func stop(g,id: String):
 if id!="columbia_raft":super.stop(g,id);return
 g.route_path=g.route.main_path_to("the_dalles");g.route_path.append(id)
 g.state.landmark=id;g.state.next_landmark=id;g.state.leg_miles=0;g.state.leg_length=0;g.state.miles=int(g.route.node_miles()[id]);g._arrive_landmark(true,false)
func coin(g) -> int:
 for i in range(g.pending.choices.size()):
  var c: Dictionary=g.pending.choices[i]
  if c.get("effects",{}).get("horses",0)==1 and c.get("requires",{}).has("money"):return i
 return -1
func run():
 var g=party();visit(g,"platte");command(g,"story","ask")
 var before: Dictionary=snapshot(g)
 check(not command(g,"story","salt") and snapshot(g)==before,"A salt exchange cannot spend goods the party lacks")
 g.state.salt=20;var food: int=g.state.food;var day: int=g.state.day;var cash: float=g.state.money
 check(command(g,"story","salt") and g.state.salt==0 and g.state.food==food+40 and g.state.day==day and g.state.money==cash,"The Pawnee exchange spends exact salt for exact provisions without a free wage or day")
 check(g.native_encounters.contact("platte").purchases.provisions==1 and restored(g)!=null,"The exchange uses normal finite stock and saves")
 check(not command(g,"story","salt"),"The same exchange cannot be repeated")
 command(g,"back");g.open_native_contacts();command(g,"contact")
 check(Story.state(g.native_encounters,"platte").step=="exchanged" and g.pending.text.contains("remembers"),"The provision keeper recognizes the party on return")
 check(party().native_encounters.record.is_empty(),"A separate new journey starts without inherited contacts")
 var horse=party();stop(horse,"grande_ronde");horse.open_horse_traders();var old_price: float=horse.pending.choices[coin(horse)].requires.money
 horse.choose(horse.pending.choices.size()-1);horse.open_native_contacts();command(horse,"contact");command(horse,"story","ask");cash=horse.state.money;food=horse.state.food;day=horse.state.day
 check(command(horse,"story","help") and horse.state.day==day+1 and horse.state.money==cash and horse.state.food==food-15,"Horse handling is a real unpaid workday with party meals")
 command(horse,"overview");command(horse,"horses")
 var index: int=coin(horse)
 check(horse.pending.choices[index].requires.money==old_price*0.95 and horse.pending.choices[index].label.contains("19.00"),"Agreed coin price and displayed horse quote match")
 check(horse.pending.choices[0].requires.clothing==2 and horse.pending.choices[2].requires.bullets==60,"The agreement leaves indivisible barter quantities unchanged")
 check(restored(horse)!=null,"Agreed horse offers and household memory save")
 cash=horse.state.money;var mounts: int=horse.state.get("horses",0)
 check(horse.choose(index) and horse.state.money==cash-19 and horse.state.horses==mounts+1,"The existing herd sells a real horse at the agreed price")
 check(horse.context.record.spent["herders:grande_ronde|buy_horses"]==1,"The sale consumes the existing herd rather than a duplicate stock")
 horse.choose(horse.pending.choices.size()-1);horse.open_native_contacts();command(horse,"contact")
 check(not command(horse,"story","help"),"Herd work cannot be farmed on a second visit")
 var harvest=party();visit(harvest,"umatilla");command(harvest,"story","ask");harvest.state.departure_month=5
 before=snapshot(harvest)
 check(not command(harvest,"story","harvest") and snapshot(harvest)==before,"Harvest wages are unavailable outside the household produce season")
 harvest.state.departure_month=8;day=harvest.state.day;food=harvest.state.food;cash=harvest.state.money
 check(command(harvest,"story","harvest") and harvest.state.day==day+1 and harvest.state.food==food-15+4 and harvest.state.money==cash,"In-kind wages arrive after a normal workday and meals, with no cash wage")
 check(harvest.Produce.units(harvest.provisions,"produce",int(harvest.state.day))==4 and harvest.native_encounters.contact("umatilla").purchases.fresh==1,"Paid produce has normal physical/vitamin batches and uses one existing parcel")
 check(harvest.provisions.fresh.all(func(b):return int(b.expires)>int(harvest.state.day)) and restored(harvest)!=null,"Fresh wages retain normal expiry and save")
 check(not command(harvest,"story","harvest"),"The garden keeper offers no repeat harvest job")
 command(harvest,"overview")
 check(command(harvest,"trade","fresh") and not command(harvest,"trade","fresh"),"Only the one remaining produce parcel can be bought after in-kind wages")
 var no_stock=party();visit(no_stock,"umatilla");no_stock.state.departure_month=8;command(no_stock,"overview");command(no_stock,"trade","fresh");command(no_stock,"trade","fresh");command(no_stock,"contact");command(no_stock,"story","ask")
 check(not command(no_stock,"story","harvest"),"An employer cannot promise a produce parcel already sold")
 var ill=party();visit(ill,"umatilla");ill.state.departure_month=8;command(ill,"story","ask");ill.party_health.members[0].health=39
 check(not command(ill,"story","harvest"),"In-kind work observes the existing health restriction")
 var crew=party();visit(crew,"columbia_raft");command(crew,"story","ask");day=crew.state.day;cash=crew.state.money
 check(command(crew,"story","help") and crew.state.day==day+1 and crew.state.money==cash and Story.portage_credit(crew.native_encounters)==100,"Portage labor earns a credit, not cash, for one real unpaid day")
 check(restored(crew)!=null and not command(crew,"story","help"),"A saved credit survives without creating repeat labor")
 var loaded_credit=restored(crew)
 if loaded_credit!=null:
  command(loaded_credit,"overview");var quote: float=loaded_credit.native_encounters.portage_choice(loaded_credit).requires.money
  var paid: float=loaded_credit.state.money
  check(command(loaded_credit,"portage") and loaded_credit.state.money==paid-quote and Story.portage_credit(loaded_credit.native_encounters)==0,"Reloaded credit settles once against the regenerated canonical quote")
 else:check(false,"Reloaded portage-credit fixture exists")
 command(crew,"back")
 check(crew.pending.choices.any(func(c):return c.get("native_portage",false) and c.requires.money==2),"Returning to the landmark refreshes the actual portage quote")
 crew.open_native_contacts();crew.state.money=1.99;before=snapshot(crew)
 check(not command(crew,"portage") and snapshot(crew)==before and Story.portage_credit(crew.native_encounters)==100,"An unaffordable portage keeps the unspent credit")
 crew.state.money=2;day=crew.state.day
 check(command(crew,"portage") and crew.state.money==0 and crew.state.day==day+1 and crew.state.next_landmark=="oregon_city","Paid portage settles the credited bill and ordinary departure day")
 check(Story.portage_credit(crew.native_encounters)==0 and Story.state(crew.native_encounters,"columbia_raft").step=="redeemed" and restored(crew)!=null,"The credit is consumed once and redemption survives a save")
 stop(crew,"columbia_raft");crew.open_native_contacts()
 check(crew.native_encounters.portage_choice(crew).requires.money==3,"Revisiting after redemption restores the ordinary bill")
 var train=party();stop(train,"independence");train.context.record.spent["post:independence|visit"]=1;train.counter_checkout({"wagon":1})
 visit(train,"columbia_raft");command(train,"story","ask");command(train,"story","help")
 check(train.wagon_count()==2 and train.native_encounters.portage_choice(train).requires.money==5,"Two-wagon portage is six dollars minus one total credit")
 var legacy: Dictionary=snapshot(party());legacy.rules="366c6b144f0b00052a2a72efdbf4d4f97f6432b83ab83f54d36e85f26a1e594d"
 var copy=Save.new().restore(legacy)
 check(copy!=null and copy.native_encounters.record.is_empty(),"Previous contact journeys migrate without invented agreements")
 var rules: Dictionary=g.native_encounters.data.duplicate(true)
 rules.sites.platte.contact.stages.offer.choices[0].exchange_item="health"
 check(not preload("res://simulation/native_encounters.gd").new().load_data(rules),"Data cannot exchange arbitrary party statistics for supplies")
 rules=g.native_encounters.data.duplicate(true);rules.sites.umatilla.contact.stages.offer.choices[0].offer="invented"
 check(not preload("res://simulation/native_encounters.gd").new().load_data(rules),"Data cannot pay workers from a nonexistent supply offer")
 print("Remaining local contacts: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
