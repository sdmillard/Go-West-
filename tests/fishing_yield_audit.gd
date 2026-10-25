extends "res://tests/fishing_campaign.gd"
## Controlled one-day public-action probes. These are not full-route arrivals.
func run():
 var label: String="fishing-yield-audit-01"
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--yield-label="):label=argument.get_slice("=",1).validate_filename()
 if FileAccess.file_exists("res://.tools/"+label+".json"):printerr("Existing yield report");quit(1);return
 var rows: Array=[];var errors: Array=[]
 var frozen: Dictionary=source_hashes();var store=Store.new();var rules: String=store.fingerprint()
 for distance in [0,4,12]:
  for ration in [0,1,2]:
   for health in [100,40]:
    for seed_value in range(225000,225100):
     var game=make_study_game(seed_value)
     if not game.depart("banker",["A","B","C","D","E"],5,{"oxen":4,"horses":1,"saddles":1,"food":60,"clothing":5,"bullet_boxes":1}):errors.append("Departure failed");continue
     game.pending={}
     game.state.landmark="elm_grove";game.state.next_landmark="wakarusa";game.state.leg_length=20;game.state.leg_miles=20-distance;game.state.miles=53-distance
     game.configure(1,ration);game.party_health.daily_onset_chance=0.0;game.survival.forced_weather="clear"
     game.party_health.members[0].health=health;game.state.health=game.party_health.average_health()
     for id in range(1,5):game.camp_tasks.assign(game,id,"rest")
     var count: Dictionary=count_template();var p: Dictionary=policy("foot")
     p.accuracy=0.65
     fishing_policy="leader"
     if not try_fishing(game,p,count) or game.fishing_days.size()!=1:errors.append("Fishing failed");continue
     var row: Dictionary=game.fishing_days[0].duplicate(true)
     row.merge({"seed":seed_value,"ration":ration,"leader_health":health})
     rows.append(row)
     if row.day_end!=row.day+1 or row.bullets_delta!=0 or row.miles_delta!=0 or store.restore(JSON.parse_string(JSON.stringify(store.capture(game))))==null:errors.append("Accounting or save failed")
     if seed_value%20==0:await process_frame
 if frozen!=source_hashes() or rules!=store.fingerprint():errors.append("Sources changed")
 FileAccess.open("res://.tools/"+label+".json",FileAccess.WRITE).store_string(JSON.stringify({"runs":rows,"errors":errors,"rules_signature":rules,"source_hashes":frozen,"seed_start":225000,"seeds":100,"note":"Five present travelers; actual one-day fishing, normal meals; other companions assigned Rest. No extra fish, removed travel costs or forced catches."},"\t"))
 print("Fishing yield audit: %d trips, %d errors" % [rows.size(),errors.size()])
 quit(0 if rows.size()==1800 and errors.is_empty() else 1)
