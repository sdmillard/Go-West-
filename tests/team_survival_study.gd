extends "res://tests/full_trail_balance.gd"
## Matched seeded experiments. Forced herd losses and no-bonus controls are
## scenario fixtures; player actions thereafter use the ordinary engine.
const NO_BONUS=[0,0.25,0.5,0.75,1,1,1]
func pack_for_walking(game,from_cache: bool=false) -> Dictionary:
    var stock: Dictionary=game.CacheSupport.available(game,from_cache)
    var pack={"clothing":mini(stock.clothing,game.state.party_size),"bullets":mini(stock.bullets,40),"medicine":mini(stock.medicine,1),"salt":mini(stock.salt,5),"food":0}
    var low:=0
    var high: int=stock.food
    while low<high:
        var mid:=ceili((low+high)/2.0)
        pack.food=mid
        if game.pack_quote(pack,from_cache).valid:low=mid
        else:high=mid-1
    pack.food=low
    return pack

func act(game,profile: Dictionary,aim: RandomNumberGenerator,count: Dictionary) -> bool:
    if game.pending.is_empty():
        if profile.has("emergency") and not count.triggered and game.state.vehicle=="wagon" and game.state.miles>=profile.emergency_mile:
            count.triggered=true
            count.emergency_day=game.state.day
            count.emergency_mile=game.state.miles
            game.state.oxen=1 if profile.emergency=="last_ox_walk" else 0
            game.journal.append("Experiment fixture: herd reduced at guide mile %d." % game.state.miles)
        if profile.get("rebuild",false) and count.triggered and (profile.emergency=="trade" or count.recovered>0) and game.state.vehicle=="wagon" and game.state.oxen<4 and (game.state.money>=30 or game.state.food>=100):
            if not game.open_trade():return false
            if game.pending.title=="No traders nearby":return game.choose(0)
            for index in [8,18]:
                if game.can_choose(index):
                    count.trades+=1
                    return game.choose(index)
            game.choose(game.pending.choices.size()-1)
            if not game.pending.is_empty() and not game.pending.has("landmark"):return true
            return game.rest()
        if count.triggered and not count.packed and profile.get("emergency","")!="trade" and game.state.vehicle=="wagon":
            if game.state.oxen==1 and profile.emergency=="last_ox_walk":
                if game.ox_slaughter_offer().is_empty():return false
                count.oxen_slaughtered+=1
                return game.slaughter_ox()
            var pack:=pack_for_walking(game)
            var cached: int=game.state.food-int(pack.food)
            if not game.abandon_wagon(pack):return false
            count.packed=true
            count.pack_day=game.state.day
            count.cache_food=cached
            count.cache_mile=game.state.miles
            return true
        if game.state.vehicle=="foot" and game.provisions.cargo(game.state)>game.provisions.capacity(game.state):
            # Organize or discard through public actions, never enlarge capacity.
            if not game.preservation_offer(true).is_empty():
                count.preservations+=1
                return game.preserve_meat(true)
            for item in ["food","bullets","salt","medicine","clothing"]:
                if game.state[item]>0:
                    var excess: float=game.provisions.cargo(game.state)-game.provisions.capacity(game.state)
                    var amount:=mini(game.state[item],maxi(1,ceili(excess/float(game.provisions.data.weights_lb[item]))))
                    count.discarded+=amount
                    return game.discard_supply(item,amount)
            return false
        if game.state.vehicle=="foot" and profile.get("emergency","")=="return" and not count.returned and count.walk_steps>=2:
            count.returned=true
            var day: int=game.state.day
            var miles: int=game.state.miles
            if not game.recover_wagon():return false
            count.backtrack_days+=int(game.state.day)-day
            count.backtrack_miles+=miles-int(game.state.miles)
            count.cache_lost=game.wagon_cache.is_empty() and game.state.vehicle=="foot"
            if game.state.vehicle=="wagon":count.recovered+=1
            return true
        if game.state.vehicle=="foot" and count.returned and not game.wagon_cache.is_empty() and game.wagon_cache.found and game.state.miles==game.wagon_cache.mile:
            if game.state.food<game.state.party_size*6:
                var refill:=pack_for_walking(game,true)
                if refill.food>game.state.food:return game.repack_wagon_cache(refill)
            if game.state.oxen<1:
                if not game.open_trade():return false
                if game.pending.title=="No traders nearby":return game.choose(0)
                var index:=8 if game.can_choose(8) else 18
                if not game.can_choose(index):
                    game.choose(game.pending.choices.size()-1)
                    if not game.pending.is_empty() and not game.pending.has("landmark"):return true
                    # Cache can supply barter food without exceeding carry weight.
                    var pack:=pack_for_walking(game,true)
                    pack.food=mini(100,int(game.wagon_cache.inventory.food)+int(game.state.food))
                    for item in ["clothing","salt","bullets"]:
                        while pack[item]>0 and not game.pack_quote(pack,true).valid:pack[item]-=1
                    if game.pack_quote(pack,true).valid and game.state.food<100:return game.repack_wagon_cache(pack)
                    return game.rest()
                count.trades+=1
                return game.choose(index)
            count.recovered+=1
            return game.recover_wagon()
    return super.act(game,profile,aim,count)

func run() -> void:
    adaptive=true
    hunting_study=true
    var profiles: Array=[]
    for method in ["","dry","salt"]:
        profiles.append({"id":"fresh" if method=="" else method,"preserve":method})
    profiles.append({"id":"salt_slaughter","preserve":"salt","slaughter":true})
    for emergency in ["trade","walk","return","last_ox_walk"]:
        profiles.append({"id":"emergency_"+emergency,"preserve":"salt","emergency":emergency,"emergency_mile":600})
    profiles.append({"id":"late_walk","preserve":"salt","emergency":"walk","emergency_mile":1600})
    var rebuilding: bool="--rebuild" in OS.get_cmdline_user_args()
    if rebuilding:
        profiles=[]
        for emergency in ["trade","return"]:
            profiles.append({"id":"rebuild_"+emergency,"preserve":"salt","emergency":emergency,"emergency_mile":600,"rebuild":true})
    for profile in profiles:
        profile.merge({"pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":45,"adaptive_rations":true})
    var rows: Array=[]
    var errors: Array=[]
    for bonus in [false,true]:
        for team in [4,6]:
            for profile in profiles:
                for profession in ["farmer","carpenter","banker"]:
                    for month in [3,5,8]:
                        for seed_value in range(20):
                            var game=Simulation.new(seed_value,"classic",true)
                            if not bonus:game.survival.data.team_speed_factors=NO_BONUS.duplicate()
                            var cart: Dictionary={}
                            for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
                            cart.oxen=team
                            if not game.depart(profession,["A","B","C","D","E"],month,cart):
                                errors.append(game.departure_error)
                                continue
                            var aim:=RandomNumberGenerator.new()
                            aim.seed=seed_value^0x41494d
                            var count={"hunts":0,"rests":0,"trades":0,"travel_days":0,"road_miles":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0,"triggered":false,"packed":false,"returned":false,"recovered":0,"cache_lost":false,"cache_food":0,"cache_mile":-1,"pack_day":-1,"emergency_day":-1,"emergency_mile":-1,"backtrack_days":0,"backtrack_miles":0,"discarded":0,"foot_days":0,"walk_steps":0}
                            var outcome: String="limit"
                            for step in range(2400):
                                if game.state.status!="traveling":
                                    outcome=game.state.status
                                    break
                                if game.state.day>=365:break
                                var day: int=game.state.day
                                var miles: int=game.state.miles
                                var walking: bool=game.state.vehicle=="foot"
                                if not act(game,profile,aim,count):
                                    outcome="policy_blocked"
                                    break
                                if game.state.miles>miles:
                                    count.travel_days+=1
                                    count.road_miles+=int(game.state.miles)-miles
                                    if walking:count.walk_steps+=1
                                if walking:count.foot_days+=int(game.state.day)-day
                                if game.state.day>day and game.state.food==0:count.empty_food_days+=int(game.state.day)-day
                                if game.state.food<0 or game.state.money< -0.001 or game.state.party_size<0 or game.state.salt<0 or game.provisions.fresh_pounds(game.state.food)+game.provisions.preserved_pounds(game.state.food)>game.state.food or not game.error.is_empty():
                                    errors.append({"profile":profile.id,"seed":seed_value,"error":game.error})
                                    break
                            var row={"profile":profile.id,"team":team,"bonus":bonus,"profession":profession,"month":month,"seed":seed_value,"outcome":outcome,"days":game.state.day,"miles":game.state.miles,"survivors":game.state.party_size,"food":game.state.food,"money":game.state.money,"oxen":game.state.oxen,"vehicle":game.state.vehicle,"crossing_mishaps":game.crossing_history.filter(func(c):return c.mishap).size(),"swims":game.crossing_history.filter(func(c):return c.method=="swim").size(),"spoilage_lb":0,"deaths":[],"pending":game.pending.get("id","")}
                            for entry in game.supply_history:
                                if entry.event=="spoilage":row.spoilage_lb-=int(entry.changes.food)
                            for member in game.party_health.members:
                                if not member.alive:row.deaths.append({"cause":member.cause,"day":member.death_day})
                            row.merge(count)
                            rows.append(row)
                print("Team study: bonus=%s team=%d %s complete" % [bonus,team,profile.id])
                await process_frame
    var report={"rules_signature":Store.new().fingerprint(),"seed_range":[0,19],"profiles":profiles,"normal_team_factors":JSON.parse_string(FileAccess.get_file_as_string("res://data/survival_rules.json")).team_speed_factors,"control_team_factors":NO_BONUS,"scenario":"Full journeys, current suggested goods with four/six purchased oxen; difference in animal price retained as cash. Forced herd loss at first event-free point after 600 miles (late walk:1600). Thereafter ordinary public actions. No free supplies, animal replacements or cache-risk override. Return policy advances on two actual walking days before searching, buys/barters one ox if found. Walking packs maximize food after clothes,40 bullets,one kit,five salt; overload discarded publicly. Foot resupply/hunt threshold is half available physical food room capped at30; bulk-post purchases skipped on foot to avoid repeated over-capacity buying. Same 65% scripted hunting/rest/care/ferry policy as full_trail_balance. Early deaths remain in full denominator; triggered count identifies parties that reached the emergency. Return trips inherit engine limitation of no intermediate river choices. No historical speed or death-rate certification; no forced swimming or human playtest.","rules":{},"runs":rows,"errors":errors}
    for key in ["outfitting","provisions","survival_rules","trail_context"]:report.rules[key]=JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % key))
    report["rebuild_policy"]=rebuilding
    if rebuilding:report.scenario+=" Supplemental strategy: after loss/recovery, buy/barter toward four animals while cash or food permits; ordinary animal prices, days and meals apply."
    var study_label: String="team"
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--label="):study_label=argument.trim_prefix("--label=").validate_filename()
    var file=FileAccess.open("res://docs/"+study_label+("-rebuild-study.json" if rebuilding else "-survival-study.json"),FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"\t"))
    file.close()
    print("Team survival: %d journeys; %d invariant/setup errors" % [rows.size(),errors.size()])
    quit(0 if errors.is_empty() and rows.size()==(1440 if rebuilding else 6480) else 1)
