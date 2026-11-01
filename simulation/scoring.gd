extends RefCounted
## A final score for every ending (Spencer, October 31): surviving travelers by health, what the party still
## owns at Independence prices, cash and keepsakes, scaled by the ending and by how poor the profession began.
static var data: Dictionary=load_rules()
## Goods counted at Independence prices, by the state key that holds them.
const GOODS=["oxen","horses","mules","saddles","pack_saddles","saddlebags","food","clothing","rifles","shotguns","pistols","revolvers","knives","hatchets","wheels","axles","tongues","medicine","salt","dried_produce"]

static func load_rules() -> Dictionary:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/scoring.json"))
	return parsed if valid_rules(parsed) else {}
static func number(v: Variant) -> bool:return (v is int or v is float) and is_finite(float(v))
static func valid_rules(v: Variant) -> bool:
	if not v is Dictionary or not v.get("note") is String or not v.get("traveler_points") is Dictionary or not v.get("endings") is Dictionary:return false
	if not ["healthy","fair","poor"].all(func(k):return number(v.traveler_points.get(k)) and v.traveler_points[k]>=0):return false
	if not ["arrived","settled","cul_de_sac","run_off","returned_east","lost"].all(func(k):return number(v.endings.get(k)) and v.endings[k]>=0 and v.endings[k]<=1):return false
	if not number(v.get("healthy_at")) or not number(v.get("fair_at")) or v.fair_at>v.healthy_at or not number(v.get("dollars_per_point")) or v.dollars_per_point<=0:return false
	return v.get("profession_base") is String

## Which ending a finished journey reached, or "" while it goes on.
static func ending(game) -> String:
	if game.state.status=="settled":
		var kind: String=game.state.get("settled",{}).get("kind","")
		return kind if kind in ["run_off","cul_de_sac"] else "settled"
	return str(game.state.status) if game.state.status in ["arrived","returned_east","lost"] else ""

static func goods_cents(game) -> int:
	var cents:=0
	for good in game.outfitter.goods:
		if good.id in GOODS:cents+=int(game.state.get(good.id,0))*int(good.price_cents)
		elif good.id=="wagon" and game.state.vehicle=="wagon":cents+=int(good.price_cents)*maxi(1,game.Train.count(game.state))
		elif good.id=="bullet_boxes":cents+=int(int(game.state.get("bullets",0))/20.0*int(good.price_cents))
	return cents

static func profession_factor(game) -> float:
	var purse:=func(id):
		for entry in game.outfitter.professions:
			if entry is Dictionary and entry.get("id")==id:return float(entry.get("cash_cents",0))
		return 0.0
	var mine: float=purse.call(str(game.state.get("profession","")))
	var base: float=purse.call(str(data.profession_base))
	return snappedf(base/mine,0.1) if mine>0 and base>0 else 1.0

## The parts of the score, before and after the ending and profession are applied.
static func breakdown(game) -> Dictionary:
	var travelers:=0
	var tp: Dictionary=data.traveler_points
	for member in game.party_health.members:
		if not game.party_health.is_active(member):continue
		travelers+=int(tp.healthy if member.health>=data.healthy_at else (tp.fair if member.health>=data.fair_at else tp.poor))
	var goods: int=floori(goods_cents(game)/100.0/float(data.dollars_per_point))
	var cash: int=floori(float(game.state.money)/float(data.dollars_per_point))
	var keepsakes: int=game.income.held_points(game)
	var end: String=ending(game)
	var factor: float=float(data.endings.get(end,0.0))
	var calling: float=profession_factor(game)
	var subtotal: int=travelers+goods+cash+keepsakes
	return {"travelers":travelers,"goods":goods,"cash":cash,"keepsakes":keepsakes,"subtotal":subtotal,"ending":end,"ending_factor":factor,"profession_factor":calling,"total":roundi(subtotal*factor*calling)}

static func text(game) -> String:
	var b: Dictionary=breakdown(game)
	var names: Dictionary={"arrived":"Reached Oregon","settled":"Settled short","cul_de_sac":"Settled in the houses in the sage","run_off":"Run off","returned_east":"Turned back east","lost":"Journey lost"}
	return "SCORE %d\nTravelers %d + goods %d + cash %d + keepsakes %d = %d\nx %.2f for %s, x %.1f for a %s" % [b.total,b.travelers,b.goods,b.cash,b.keepsakes,b.subtotal,b.ending_factor,names.get(b.ending,"the ending").to_lower(),b.profession_factor,str(game.state.get("profession",""))]
