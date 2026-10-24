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
 var gear:=page("Gear")
 var equipment:=grid(gear,["SUPPLY","QUANTITY","WEIGHT LB"])
 for item in game.provisions.data.weights_lb:
  if item=="food":continue
  var amount: int=int(game.state.get(item,0))
  equipment.add_child(words(str(item).capitalize()))
  equipment.add_child(words(str(amount)))
  equipment.add_child(words("%.1f" % (amount*float(game.provisions.data.weights_lb[item]))))
 var personal: float=float(game.provisions.data.walking.personal_gear_lb_per_person)*game.state.party_size if game.state.vehicle=="foot" else float(game.provisions.data.household_gear_lb)+float(game.state.get("recruited_gear_lb",0))-float(game.state.get("departed_gear_lb",0))
 gear.add_child(words("Personal / household gear: %.0f lb · Carried remains: %d lb" % [personal,game.state.get("remains_lb",0)]))
 var transport:=page("Transport")
 transport.name="TransportRows"
 set_tab_title(2,"Transport")
 transport.add_child(words("ON FOOT · WAGON LEFT BEHIND" if game.state.vehicle=="foot" else "TRAVELING WITH THE WAGON"))
 transport.add_child(words("%d oxen %s · Condition: %s" % [game.state.oxen,"herded alongside your party" if game.state.vehicle=="foot" else "in the wagon team",game.PartyHealth.condition_label(game.state.ox_health)]))
 transport.add_child(words("Oxen graze; they do not eat the party's provisions."))
 if game.state.vehicle=="foot":
  transport.add_child(words("Pack limit: %.0f lb, based on the active party's health." % game.provisions.capacity(game.state)))
  if not game.wagon_cache.is_empty():transport.add_child(words("Wagon cache: mile %d · %s" % [game.wagon_cache.mile,"located" if game.wagon_cache.found else "not yet checked"]))
 else:
  transport.add_child(words("Team load guideline: %.0f lb · Pulling speed: %d%%" % [game.provisions.team_capacity(game.state.oxen),roundi(game.survival.team_factor(game.state.oxen)*100)]))
 transport.add_child(words("Hunting retrieval: %d lb · Willing helpers at current health" % game.hunting_capacity()))
 transport.add_child(words("Broken legs prevent helping with retrieval and carrying."))
 set_meta("transport_rows",transport)
