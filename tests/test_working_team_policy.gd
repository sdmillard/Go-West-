extends "res://tests/full_trail_balance.gd"
## Guard the development-study error: preserve the working team before elective slaughter.
func run():
	adaptive=true
	hunting_study=true
	var failures:=0
	for scenario in [{"team":4,"floor":4,"after":4,"slaughtered":0},{"team":6,"floor":4,"after":5,"slaughtered":1},{"team":4,"floor":1,"after":3,"slaughtered":1}]:
		var game=Simulation.new(57,"classic",true)
		game.depart("farmer",["A","B","C","D","E"],5,{"oxen":scenario.team,"food":70,"clothing":5,"bullet_boxes":10,"wheels":1,"axles":1,"tongues":1,"medicine":2,"salt":10})
		game.state.money=0
		game.party_health.daily_onset_chance=0
		game.survival.data.event_chance=0
		game.survival.forced_weather="clear"
		var profile: Dictionary={"id":"test","pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":45,"slaughter":true,"slaughter_team_floor":scenario.floor}
		var counts: Dictionary={"hunts":0,"rests":0,"trades":0,"care":0,"last_care":-100,"oxen_slaughtered":0}
		var aim:=RandomNumberGenerator.new()
		if not act(game,profile,aim,counts) or game.state.oxen!=scenario.after or counts.oxen_slaughtered!=scenario.slaughtered:
			failures+=1;printerr("FAIL: Working-team policy %s" % JSON.stringify(scenario))
	print("Working-team policy: 3 checks, %d failures" % failures)
	quit(1 if failures else 0)
