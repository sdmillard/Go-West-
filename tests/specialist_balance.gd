extends "res://tests/full_trail_balance.gd"
## Matched whole-route cohorts, not a claim that wages currently buy exclusive abilities.
func _initialize():call_deferred("run")
func run():
	adaptive=true
	hunting_study=true
	var runs: Array=[]
	var errors: Array=[]
	var store=Store.new()
	var policy: Dictionary={"id":"specialist","pace":0,"rations":1,"rest":true,"hunt":true,"accuracy":0.65,"hunt_below":45,"adaptive_rations":true,"preserve":"salt","slaughter":true}
	for roster in ["volunteers","paid_same","free_loyal_veterans","paid_loyal_veterans","paid_one","paid_two"]:
		for profession in ["farmer","carpenter","banker"]:
			var arrivals:=0
			for month in [3,5,8]:
				for seed_value in range(10):
					var game=Simulation.new(seed_value,"classic",true)
					var cart: Dictionary={}
					for good in game.outfitter.goods:cart[good.id]=int(good.suggested)
					var characters=preload("res://simulation/party_character.gd").new()
					characters.start(seed_value,5)
					var terms: Dictionary={}
					for person in characters.profiles.slice(1):
						if "loyal_veterans" in roster:person.specials=["Loyal","Veteran"]
						if roster.begins_with("paid") and (roster not in ["paid_one","paid_two"] or person.id<=(1 if roster=="paid_one" else 2)):
							person.specials.append("Mercenary")
							if person.specials.size()>2:person.flaws=["Slow Healer"]
							terms[str(person.id)]={"wage_cents":characters.wage_quote(person).daily_cents*7,"interval_days":7}
					if not game.depart(profession,["A","B","C","D","E"],month,cart,{"profiles":characters.profiles.duplicate(true),"contracts":terms}):
						errors.append(game.departure_error)
						continue
					var aim:=RandomNumberGenerator.new()
					aim.seed=seed_value ^ 0x41494d
					var count: Dictionary={"hunts":0,"rests":0,"trades":0,"travel_days":0,"empty_food_days":0,"care":0,"last_care":-100,"shots":0,"meat_obtained":0,"meat_carried":0,"empty_hunts":0,"preservations":0,"oxen_slaughtered":0}
					var paid_cents:=0
					var outcome: String="limit"
					for step in range(2400):
						if game.state.status!="traveling":
							outcome=game.state.status
							break
						if game.state.day>=365:break
						for person in game.characters.profiles.slice(1):
							if not game.party_health.is_active(game.party_health.members[person.id]) or person.contract.is_empty():continue
							var due: int=person.contract.arrears_cents
							if due>0 and game.state.money>=due/100.0+10:
								if game.characters.pay_wages(game,person.id):paid_cents+=due
						var day: int=game.state.day
						var mile: int=game.state.miles
						if not act(game,policy,aim,count):
							outcome="policy_blocked"
							break
						if game.state.miles>mile:count.travel_days+=1
						if game.state.day>day and game.state.food==0:count.empty_food_days+=game.state.day-day
						var active: int=game.party_health.living_count()
						if game.state.food<0 or game.state.money<0 or game.state.party_size!=active or game.state.health!=game.party_health.average_health() or game.provisions.cargo(game.state)<0:
							errors.append({"roster":roster,"seed":seed_value,"day":game.state.day,"error":"state invariant"})
							break
					if outcome=="arrived":arrivals+=1
					var departures: int=game.party_health.members.filter(func(member):return member.get("departed",false)).size()
					var deaths: int=game.party_health.members.filter(func(member):return not member.alive).size()
					var total_debt: int=game.characters.due_total()
					var snapshot: Dictionary=store.capture(game)
					if not snapshot.is_empty() and store.restore(JSON.parse_string(JSON.stringify(snapshot)))==null:errors.append({"roster":roster,"seed":seed_value,"error":"save round trip"})
					var trust_total:=0.0
					var retained:=0
					var retained_trust:=0.0
					for person in game.characters.profiles.slice(1):
						trust_total+=float(person.trust)
						if game.party_health.is_active(game.party_health.members[person.id]):
							retained+=1
							retained_trust+=float(person.trust)
					var row: Dictionary={"roster":roster,"profession":profession,"month":month,"seed":seed_value,"outcome":outcome,"days":game.state.day,"survivors_with_party":game.state.party_size,"retained_companions":retained,"mean_companion_trust":trust_total/4,"mean_retained_trust":retained_trust/retained if retained>0 else null,"departures":departures,"deaths":deaths,"cash":game.state.money,"wages_paid_cents":paid_cents,"unpaid_cents":total_debt,"food":game.state.food}
					row.merge(count)
					runs.append(row)
			print("%s %s: %d/30 arrived" % [roster,profession,arrivals])
	var file=FileAccess.open("res://docs/flaw-budget-balance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"rules_signature":store.fingerprint(),"runs":runs,"errors":errors,"seed_range":[0,9],"party_benefit_rules":JSON.parse_string(FileAccess.get_file_as_string("res://data/party_benefits.json")),"policy":"Existing salted-hunt/spare-ox policy, 65% center aim, ordinary seeded weather and disease, actual route. Pay full active-companion debt in member-id order whenever cash covers it plus a $10 reserve, before another policy action. At most365days/2400actions; no recruiting or forced walking. Roster retains all four backgrounds. Free special cohorts select Loyal/Veteran without Mercenary; paid ones add Mercenary, minimum weekly contracts and the required Slow Healer flaw for a third special. That flaw is a confound, so these are creation-rule cohorts, not an isolated pay comparison. paid_one and paid_two hire only roster positions 1 or 1–2; backgrounds remain seed-shuffled. Departures are acknowledged through normal service choices. Final states round-trip through actual save validation."},"\t"))
	file.close()
	print("Specialist balance: %d journeys; %d errors" % [runs.size(),errors.size()])
	quit(0 if runs.size()==540 and errors.is_empty() else 1)



