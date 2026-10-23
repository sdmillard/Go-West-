extends RefCounted
## What people at a trading counter tell the party (ASK FOR NEWS), a fragment at a time: news from the States and
## Oregon as it travels the road, notes on the road ahead, and whatever word of the party itself has reached them. Information only;
## nothing here changes the game, so data/trail_news.json is not one of the rule files.
const MILES_PER_DAY := 15
var data: Dictionary={}
var error: String=""
func _init():
	load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/trail_news.json")))
func load_data(value: Variant) -> bool:
	data={}
	error="Invalid trail news"
	if not value is Dictionary or not value.get("headlines") is Array or not value.get("road") is Dictionary or not value.get("lag") is Dictionary or not value.get("limits") is Dictionary:return false
	for kind in ["post","traders","camp"]:
		if not numeric(value.limits.get(kind)) or value.limits[kind]!=int(value.limits[kind]) or value.limits[kind]<1:return false
	if not numeric(value.lag.get("base_days")) or value.lag.base_days<0 or not numeric(value.lag.get("miles_per_day")) or value.lag.miles_per_day<=0:return false
	if not value.get("asks") is Dictionary:return false
	for mood in ["generous","fair","stingy"]:
		if not numeric(value.asks.get(mood)) or value.asks[mood]!=int(value.asks[mood]) or value.asks[mood]<1 or value.asks[mood]>8:return false
	var ids: Array=[]
	for item in value.headlines:
		if not item is Dictionary or not item.get("id") is String or item.id in ids or not item.get("text") is String or not item.get("from") is String or not dated(item.get("known")):return false
		if item.has("miles_per_day") and (not numeric(item.miles_per_day) or item.miles_per_day<=0):return false
		ids.append(item.id)
	for id in value.road:
		if not value.road[id] is String:return false
	data=value.duplicate(true)
	error=""
	return true
func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
func dated(value: Variant) -> bool:
	return value is String and RegEx.create_from_string("^1848-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])$").search(value)!=null
## Seconds from 1970 (negative for 1848) at the start of a "1848-03-12" date.
func unix(value: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(value+"T00:00:00"))
## Every stop a headline or road note names must be on the route.
func valid_for(route) -> bool:
	for item in data.get("headlines",[]):
		if not route.nodes.has(item.from):return false
	for id in data.get("road",{}):
		if not route.nodes.has(id):return false
	return not data.is_empty()

## Everything the people at a counter of this kind ("post", "traders" or "camp") might say; ASK FOR NEWS shows one
## fragment at a time. place is the venue's key for word of the party's crimes.
func fragments(game,kind: String,place: String) -> Array:
	return headlines(game).slice(0,int(data.limits[kind]))+road_ahead(game)+about_party(game,place,kind)

## The fragment told at the given ask: a seeded order per counter, so asking again tells something else.
func pick(told: Array,key: String,asked: int) -> String:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash(key+"|news")
	var order: Array=range(told.size())
	for i in range(order.size()-1,0,-1):
		var j: int=rng.randi_range(0,i)
		var swap: int=order[i]
		order[i]=order[j]
		order[j]=swap
	return told[order[asked%order.size()]]

## Headlines that have reached the party's place on the road by today, newest arrival first.
## News travels from where it happened (the Missouri border, Oregon City, a post) at about a train's pace.
func headlines(game) -> Array:
	var today: int=unix("1848-%02d-01" % int(game.state.departure_month))+int(game.state.day)*86400
	var miles: Dictionary=game.route.node_miles()
	var arrived: Array=[]
	for item in data.headlines:
		if not miles.has(item.from):continue
		var distance: float=absf(float(miles[item.from])-float(game.state.miles))
		var days: float=float(data.lag.base_days)+distance/float(item.get("miles_per_day",data.lag.miles_per_day))
		var reached: int=unix(item.known)+int(days*86400.0)
		if reached<=today:arrived.append([reached,item.text])
	arrived.sort_custom(func(a,b):return a[0]>b[0])
	return arrived.map(func(entry):return entry[1])

## The next stops, as [id, miles from here]: every fork out of the current stop, then the main road beyond.
func stops_ahead(game,count: int=2) -> Array:
	var nodes: Dictionary=game.route.nodes
	var here: String=str(game.state.landmark)
	var next: String=str(game.state.next_landmark)
	var result: Array=[]
	if game.pending.has("landmark") or next=="" or next==here or not nodes.has(next):
		for edge in nodes[here].next:result.append([str(edge.to),int(edge.miles)])
	else:
		result.append([next,maxi(0,int(game.state.leg_length)-int(game.state.leg_miles))])
	while result.size()<count and not result.is_empty() and not nodes[result[-1][0]].next.is_empty():
		var edge: Dictionary=nodes[result[-1][0]].next[0]
		result.append([str(edge.to),int(result[-1][1])+int(edge.miles)])
	return result

func road_ahead(game) -> Array:
	var nodes: Dictionary=game.route.nodes
	var lines: Array=[]
	var ahead: Array=stops_ahead(game)
	for stop in ahead:
		if data.road.has(stop[0]):lines.append(data.road[stop[0]])
	var month: int=int(game.calendar().month)
	# The first river ahead: what the weather and the season are doing to it.
	for stop in ahead:
		if nodes[stop[0]].kind!="river":continue
		var name: String=nodes[stop[0]].name
		var chance: float=game.survival.river_high_chance(month,nodes[stop[0]].get("river_source","rain"))
		if game.survival.wet_ground>=4:lines.append("The rains have the rivers up. Expect high water at %s." % name)
		elif chance>=0.5:lines.append("At this time of year the river at %s usually runs high." % name)
		elif game.survival.wet_ground==0 and chance<0.25:lines.append("The weather has been dry. The river at %s should be low." % name)
		break
	var post: Array=next_post(game)
	var price: float=float(game.context.region(game).price)
	if not post.is_empty():
		var there: float=float(game.context.data.regions[nodes[post[0]].hunting_region].price)
		var change: int=roundi((there/price-1.0)*100.0)
		var compare: String="about the same as here" if absi(change)<5 else ("about %d%% %s than here" % [absi(change),"higher" if change>0 else "lower"])
		lines.append("The next store is at %s, about %d miles on. Prices there run %s." % [nodes[post[0]].name,post[1],compare])
	# Whether the food will last to the next store (or the end of the road), at the party's rations and a train's pace.
	var reach: int=int(post[1]) if not post.is_empty() else maxi(0,game.destination()-int(game.state.miles))
	var lasts: int=game.provisions.expected_days(int(game.state.food),int(game.state.party_size),int(game.state.rations))
	var needed: int=ceili(float(reach)/MILES_PER_DAY)
	if reach>0 and lasts<needed:lines.append("At your rations your food lasts about %d days. %s is about %d days off." % [lasts,nodes[post[0]].name if not post.is_empty() else "The end of the road",needed])
	var miles: Dictionary=game.route.node_miles()
	if month>=9 and int(game.state.miles)<int(miles.get("blue_mountains",0)):lines.append("It is getting late in the year. Snow can close the Blue Mountains and the Cascades in October.")
	elif month<=5 and int(game.state.miles)<int(miles.get("fort_kearny",0)):lines.append("The grass on the plains is still short this early. Let the teams graze when you can.")
	return lines

## The next post with a store on the main road ahead, as [id, miles from here], or [].
func next_post(game) -> Array:
	var nodes: Dictionary=game.route.nodes
	var ahead: Array=stops_ahead(game,1)
	if ahead.is_empty():return []
	var id: String=ahead[0][0]
	var distance: int=int(ahead[0][1])
	while true:
		if nodes[id].get("trade_bulk",false):return [id,distance]
		if nodes[id].next.is_empty():return []
		distance+=int(nodes[id].next[0].miles)
		id=nodes[id].next[0].to
	return []

## Word of the party's crimes that has reached this place. Silent for a party with nothing to hide.
## A family on the road also says which posts ahead have heard of the party.
func about_party(game,place: String,kind: String="post") -> Array:
	if game.crime.record.incidents.is_empty() and game.crime.tales(game).is_empty():return []
	var said: String=game.crime.news_text(game,place)
	if kind=="camp":return ([said] if not said.is_empty() else [])+[game.camp_news()]
	return [said] if not said.is_empty() else ["Nobody here has said anything about your party."]
