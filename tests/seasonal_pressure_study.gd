extends SceneTree
const Rules=preload("res://simulation/survival_rules.gd")
func _initialize():
	var label: String="winter-pressure-before"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=").validate_filename()
	var path: String="res://docs/"+label+".json"
	if FileAccess.file_exists(path):printerr("Archive exists");quit(1);return
	var rows: Array=[]
	for terrain in ["plains","mountains","forest"]:
		var region: Dictionary={"cold":1.7 if terrain=="mountains" else (1.4 if terrain=="forest" else 1.0),"wet":1.4 if terrain=="forest" else 1.0}
		for month in range(1,13):
			var rules=Rules.new()
			rules.start(5108)
			var counts: Dictionary={}
			var speed:=0.0
			for sample in range(1000):
				rules.advance(month,terrain,region)
				counts[rules.weather.id]=int(counts.get(rules.weather.id,0))+1
				speed+=rules.movement_factor(6,100,0,0,terrain)*(float(rules.seasonal(month,terrain,region).travel) if rules.has_method("seasonal") else 1.0)
			rows.append({"terrain":terrain,"month":month,"weather":counts,"mean_movement_factor":speed/1000.0,"season":rules.seasonal(month,terrain,region) if rules.has_method("seasonal") else {}})
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows":rows,"samples_per_row":1000,"policy":"Same weather seed for every terrain/month; 36 independent monthly scenario samples, not chronological annual climate. Healthy six-ox team, zero fatigue, before cargo. Month-specific ground factor included where implemented. Authored model comparison, not historical climate reconstruction."},"\t"))
	file.close()
	print("Seasonal pressure sample:36 scenarios")
	quit()
