extends TabContainer
## Read-only inventory ledger. Physical pounds are distinct from food-value units.
static func food_rows(game) -> Array:
 var rows: Array=[{"name":"Staples","units":0,"mass":0.0},{"name":"Fresh meat","units":0,"mass":0.0},{"name":"Greens / berries","units":0,"mass":0.0},{"name":"Dried meat","units":0,"mass":0.0},{"name":"Dried fruit / greens","units":0,"mass":0.0}]
 var left: int=game.state.food
 for batch in game.provisions.fresh:
  var used: int=mini(left,int(batch.pounds))
  var index: int=(4 if batch.get("vitamin_c",false) else 3) if batch.get("preserved",false) else (2 if batch.get("vitamin_c",false) else 1)
  rows[index].units+=used
  rows[index].mass+=used*game.provisions.mass_ratio(batch)
  left-=used
 rows[2].mass+=float(game.state.get("camp_greens_lb",0))
 rows[0].units=left
 rows[0].mass=float(left)
 return rows
func words(text: String) -> Label:
 var result:=Label.new()
 result.text=text
 return result
func page(title: String) -> VBoxContainer:
 var scroll:=ScrollContainer.new()
 scroll.name=title
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 add_child(scroll)
 var rows:=VBoxContainer.new()
 rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 rows.add_theme_constant_override("separation",5)
 scroll.add_child(rows)
 return rows
func grid(rows: VBoxContainer,headings: Array) -> GridContainer:
 var table:=GridContainer.new()
 table.columns=headings.size()
 table.add_theme_constant_override("h_separation",20)
 table.add_theme_constant_override("v_separation",3)
 rows.add_child(table)
 for heading in headings:table.add_child(words(heading))
 return table
func _init(game):
 custom_minimum_size=Vector2(560,175)
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var food:=page("Food")
 var table:=grid(food,["FOOD","FOOD UNITS","WEIGHT LB"])
 var units:=0
 var mass:=0.0
 for row in food_rows(game):
  table.add_child(words(row.name))
  table.add_child(words(str(row.units)))
  table.add_child(words("%.1f" % row.mass))
  units+=int(row.units)
  mass+=float(row.mass)
 table.add_child(words("TOTAL"));table.add_child(words(str(units)));table.add_child(words("%.1f" % mass))
 var per_day: int=game.state.party_size*int(game.provisions.data.rations_lb[game.state.rations])
 food.add_child(words("%d travelers · %d units/day · up to %d days before spoilage" % [game.state.party_size,per_day,game.provisions.expected_days(game.state.food,game.state.party_size,game.state.rations)]))
 food.add_child(words("Preserve meat in Camp. Eaten greens / berries supply vitamin C."))
 if game.state.get("camp_greens_lb",0)>0:food.add_child(words("%d lb loose greens: below one food unit; served for vitamin C at the next meal." % game.state.camp_greens_lb))
 var gear:=page("Gear")
 var equipment:=grid(gear,["SUPPLY","QUANTITY","WEIGHT LB"])
 for item in game.provisions.data.weights_lb:
  if item=="food":continue
  var amount: int=int(game.state.get(item,0))
  equipment.add_child(words(str(item).capitalize()))
  equipment.add_child(words(str(amount)))
  equipment.add_child(words("%.1f" % (amount*float(game.provisions.data.weights_lb[item]))))
 var loose: Dictionary=game.Mounts.loose_tack(game.provisions.data.mounts,game.state)
 for key in loose:
  if int(loose[key])>0:
   equipment.add_child(words("Loose "+str(key).replace("_"," ")))
   equipment.add_child(words(str(loose[key])))
   equipment.add_child(words("%.1f" % (loose[key]*float(game.provisions.data.mounts.loose_bags_lb if key=="saddlebags" else game.provisions.data.mounts.pack_tack_lb))))
 var personal: float=float(game.provisions.data.walking.personal_gear_lb_per_person)*game.state.party_size if game.state.vehicle=="foot" else game.provisions.household_mass(game.state)
 gear.add_child(words("Personal / household gear: %.0f lb · Carried remains: %d lb" % [personal,game.state.get("remains_lb",0)]))
 var transport:=page("Transport")
 transport.name="TransportRows"
 set_tab_title(2,"Transport")
 transport.add_child(words((game.Mounts.label(game.mount_plan())+" · NO WAGON") if game.state.vehicle=="foot" else "TRAVELING WITH THE WAGON"))
 transport.add_child(words("%d oxen %s · Condition: %s" % [game.state.oxen,"herded alongside your party" if game.state.vehicle=="foot" else "owned; %d in the working team" % game.team_conditions.pulling(game.state),game.PartyHealth.condition_label(game.state.ox_health)]))
 transport.add_child(words("Individual animal conditions and working-team selection: Livestock."))
 transport.add_child(words("Oxen graze; they do not eat the party's provisions."))
 if game.Mounts.animals(game.state)>0 or game.Mounts.TACK.any(func(key):return game.Mounts.count(game.state,key)>0):
  var plan: Dictionary=game.mount_plan()
  transport.add_child(words("%d horses, %d mules · Condition: %s · %s" % [game.Mounts.count(game.state,"horses"),game.Mounts.count(game.state,"mules"),game.PartyHealth.condition_label(game.Mounts.condition(game.state)),game.Mounts.describe(plan) if game.state.vehicle=="foot" else "led behind the wagon"]))
  transport.add_child(words("Tack: %d saddles, %d pack saddles, %d saddlebags" % [game.Mounts.count(game.state,"saddles"),game.Mounts.count(game.state,"pack_saddles"),game.Mounts.count(game.state,"saddlebags")]))
  if game.state.vehicle=="foot":transport.add_child(words("Travel: %s. Animals carry %.0f lb.%s" % [game.Mounts.label(plan).to_lower(),plan.animal_lb," Poor grass in dry country wears horses down faster than oxen." if game.Mounts.animals(game.state)>0 else ""]))
 if game.state.vehicle=="foot":
  transport.add_child(words("Cargo: %.1f lb · Working %.0f / Allowed %.0f lb" % [game.provisions.cargo(game.state),game.provisions.capacity(game.state),game.provisions.storage_capacity(game.state)]))
  var burden: Dictionary=game.provisions.load_profile(game.state)
  transport.add_child(words("Animal load: %.0f rider + %.0f tack + %.0f cargo lb" % [burden.rider_lb,burden.tack_lb,burden.animal_cargo_lb]))
  if burden.ratio>1:transport.add_child(words("Above working load: slower travel and extra animal wear."))
  if not game.wagon_cache.is_empty():transport.add_child(words("Wagon cache: mile %d · %s" % [game.wagon_cache.mile,"located" if game.wagon_cache.found else "not yet checked"]))
 else:
  transport.add_child(words("Team load guideline: %.0f lb · Pulling speed: %d%%" % [game.provisions.team_capacity(game.team_conditions.pulling(game.state)),roundi(game.survival.team_factor(game.team_conditions.pulling(game.state))*100)]))
 transport.add_child(words("Hunting retrieval: %d lb · Willing helpers at current health" % game.hunting_capacity()))
 transport.add_child(words("Broken legs prevent helping with retrieval and carrying."))
 set_meta("transport_rows",transport)
