extends RefCounted
## One pure view of local forage, season and water. Species retain their response rules.
static func grazers(game) -> int:
 var count:=0
 for kind in ["oxen","horses","mules","dairy_cows","goats"]:count+=int(game.state.get(kind,0))
 return count
static func assess(game) -> Dictionary:
 var region: String=game.context.region_id(game)
 var seasonal: Dictionary=game.seasonal_pressure()
 var month: int=game.calendar().month
 var feeding: Dictionary=game.livestock.data.feeding
 var habitat: Dictionary=feeding.habitats.get(region,feeding.habitats.plains)
 var season: float=game.livestock.data.months[month-1]
 var waterless: bool=game.on_dry_stretch()
 var activity: Dictionary=game.context.data.activities.get(str(game.state.landmark),{})
 var grazing: bool=game.grazing_activity and activity.get("kind","")=="graze"
 # A named better camp removes the broad habitat limit for this one rest day.
 # Calendar availability, drinking water and individual feed needs still constrain it.
 var grass: float=1.0 if grazing else float(habitat.dairy_cows)
 var browse: float=1.0 if grazing else float(habitat.goats)
 var late_dry: int=1 if region in ["plains","sagebrush"] and month in [7,8,9] else 0
 var base: int=int(game.context.region(game).strain)+int(seasonal.working_strain)+int(game.survival.weather.get("ox_strain",0))+(int(game.WATERLESS.ox_strain) if waterless else 0)
 var work_strain: int=base+late_dry
 var rest_recovery: int=0 if waterless else int(seasonal.rest_ox_recovery)
 # A farmer leader's stock sense: easier on a hard-worked team, better use of a rest on grass.
 var stock: Dictionary=preload("res://simulation/profession_skill.gd").stockman(game)
 if not stock.is_empty():
  if work_strain>1:work_strain=maxi(1,work_strain-int(stock.ox_strain_less))
  if rest_recovery>0:rest_recovery+=int(stock.ox_recovery_more)
 return {"region":region,"month":month,"season":season,"waterless":waterless,"better_camp":grazing,"grass_habitat":grass,"browse_habitat":browse,"scratch_habitat":float(habitat.scratch),"grass":0.0 if waterless else minf(season,grass),"browse":0.0 if waterless else minf(season,browse),"base_work_strain":base,"ox_work_strain":work_strain,"ox_rest_recovery":rest_recovery}
static func intake(pasture: Dictionary,kind: String,feed_time: float,season: float) -> float:
 if pasture.waterless:return 0.0
 return minf(season,minf(float(pasture.grass_habitat if kind=="dairy_cows" else pasture.browse_habitat),feed_time))
