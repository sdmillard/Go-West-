extends SceneTree
const Simulation=preload("res://simulation/trail_engine.gd")
const Store=preload("res://simulation/save_store.gd")
func _initialize():call_deferred("run")
func run():
    var rows: Array=[]
    var errors: Array=[]
    for health in [85,30,15]:
        for wins in [0,3]:
            var totals: Dictionary={"health":health,"previous_wins":wins,"attempts":400,"won":0,"injured":0,"fatal":0,"quoted_risk":0.0}
            for seed_value in range(400):
                var game=Simulation.new(seed_value,"classic",true)
                game.depart("banker",["A","B","C","D","E"],5,{"oxen":6,"food":1000,"clothing":5,"bullet_boxes":10,"medicine":2})
                game.party_health.daily_onset_chance=0
                game.survival.data.event_chance=0
                game.seen.append("muddy_trail")
                for member in game.party_health.members:member.health=health
                game.state.health=health
                for win in range(wins):game.combat.history.append({"day":0,"event":"bandits","tactic":"defend","outcome":"won","victim":0,"risk":0.25})
                for event in game.trail_events.events:
                    if event.id=="bandits":game._present_trail_event(event)
                totals.quoted_risk=game.pending.choices[1].quoted_risk
                if not game.choose(1):errors.append({"health":health,"wins":wins,"seed":seed_value,"error":"rejected defense"})
                else:totals[game.combat.history.back().outcome]+=1
                if game.state.bullets!=190 or game.state.food!=1000 or game.state.health!=game.party_health.average_health() or game.state.party_size!=game.party_health.living_count():errors.append({"seed":seed_value,"error":"accounting"})
            rows.append(totals)
            print("Health %d wins %d: %d injured, %d immediate deaths / 400" % [health,wins,totals.injured,totals.fatal])
    var output={"rules_signature":Store.new().fingerprint(),"scenario":"400 matched seeds per cohort; same fully fed five-person outfit, forced hostile bandit encounter and ordinary Defend choice. Only starting health and recorded prior victories differ. Immediate outcomes, not long-term wound mortality; separate regression verifies later untreated death.","combat_rules":JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json")),"rows":rows,"errors":errors}
    var file=FileAccess.open("res://docs/combat-risk-study.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(output,"\t"))
    file.close()
    print("Combat study: 2400 encounters; %d invariant errors" % errors.size())
    quit(1 if not errors.is_empty() else 0)
