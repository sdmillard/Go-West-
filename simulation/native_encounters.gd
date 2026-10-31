extends RefCounted
## Local households and services, not a single nation-wide reputation faction.
var data: Dictionary={}
var record: Dictionary={}
var error: String=""
const COMMANDS=["notes","trade","guidance","horses","portage","recruit","contact","overview","story","back"]
const Story=preload("res://simulation/native_contact_story.gd")
const GOODS=["food","produce","dried_produce"]
func _init() -> void:load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/native_encounters.json")))
static func whole(v: Variant,low: int,high: int) -> bool:return (v is int or v is float) and is_finite(v) and v==floor(v) and v>=low and v<=high
func load_data(v: Variant) -> bool:
 error="Invalid local Native encounter data."
 if not v is Dictionary or not v.get("note") is String or not v.get("sites") is Dictionary or v.sites.is_empty():return false
 for key in ["portage_cents_per_load","guide_cents_per_load"]:
  if not whole(v.get(key),1,100000):return false
 if not whole(v.get("portage_days"),1,2):return false
 for id in v.sites:
  var site: Variant=v.sites[id]
  if not id is String or not site is Dictionary:return false
  for key in ["name","people","intro","notes"]:
   if not site.get(key) is String or site[key].is_empty():return false
  if not site.get("sources") is Array or site.sources.is_empty() or not site.sources.all(func(s):return s is String and s.begins_with("https://")):return false
  if not site.get("offers") is Array or site.offers.size()>8:return false
  for flag in ["horses","portage","guidance"]:
   if site.has(flag) and not site[flag] is bool:return false
  if site.get("portage",false) and id!="columbia_raft":return false
  if site.get("guidance",false) and id!="deschutes":return false
  if site.get("horses",false) and id!="grande_ronde":return false
  if not site.get("recruit_heritages") is Array or site.recruit_heritages.is_empty() or not site.recruit_heritages.all(func(h):return h is String and not h.is_empty() and h.length()<=64 and not "\n" in h and not "\r" in h):return false
  if site.has("contact") and not Story.valid_data(site.contact,str(id)):return false
  var seen: Array=[]
  for offer in site.offers:
   if not offer is Dictionary or not offer.get("key") is String or offer.key.is_empty() or offer.key in seen or offer.get("item") not in GOODS or not whole(offer.get("amount"),1,100) or not whole(offer.get("lots"),1,8) or not offer.get("months") is Array or offer.months.is_empty():return false
   seen.append(offer.key)
   var months: Array=[]
   for month in offer.months:
    if not whole(month,1,12) or int(month) in months:return false
    months.append(int(month))
  if site.has("contact"):
   for stage in site.contact.stages.values():
    for a in stage.choices:
     if a.kind in ["exchange","work_goods"] and a.offer not in seen:return false
 data=v.duplicate(true)
 for site in data.sites.values():
  for offer in site.offers:offer.months=offer.months.map(func(m):return int(m))
 error="";return true
## Preserved provisions this household has sold or traded away; what is stolen is counted by the crime record.
func food_sold(site: String) -> int:
 var total:=0
 for offer in data.sites.get(site,{}).get("offers",[]):
  if offer.item=="food":total+=int(contact(site).purchases.get(offer.key,0))*int(offer.amount)
 return total
## Why this household turns the party away, or "" when it will deal with it.
func refusal(game,site: String) -> String:return game.crime.household_refusal(game,site)
func contact(site: String) -> Dictionary:return record.get(site,{"heard":false,"first_trade_day":-1,"purchases":{},"guide_day":-1,"guide_loads":0})
func site_at(game) -> String:
 if not data.sites.has(str(game.state.landmark)):return ""
 if game.pending.get("native_menu",false):return str(game.pending.get("native_site","")) if game.pending.get("native_site","")==game.state.landmark else ""
 return str(game.state.landmark) if game.can_service() and game.pending.get("landmark","")==game.state.landmark else ""
func offer_at(site: String,key: String) -> Dictionary:
 for offer in data.sites.get(site,{}).get("offers",[]):
  if offer.key==key:return offer
 return {}
func price(game,offer: Dictionary) -> int:
 var base: int=0
 if offer.item in ["produce","dried_produce"]:base=int(game.provisions.data.produce_trade.fresh_cents if offer.item=="produce" else game.provisions.data.produce_trade.dried_cents)
 else:
  for good in game.outfitter.goods:
   if good.id==offer.item:base=int(good.price_cents);break
 var factor: float=float(game.context.region(game).price)
 if game.characters.available(game,"Trading"):factor*=float(game.characters.benefits.trade_buy_factor)
 if Story.standing(self,str(game.state.landmark))>0:factor*=0.95
 return maxi(1,roundi(base*int(offer.amount)*factor))
func available(game,site: String,offer: Dictionary) -> bool:
 if not offer.is_empty() and offer.item=="food" and game.crime.food_left(game,game.crime.HOUSEHOLD+site)<int(offer.amount):return false
 return not offer.is_empty() and int(game.calendar().month) in offer.months and int(contact(site).purchases.get(offer.key,0))<int(offer.lots)
func guidance_factor(game) -> float:
 var c: Dictionary=contact(str(game.state.landmark))
 if data.sites.has(str(game.state.landmark)) and not refusal(game,str(game.state.landmark)).is_empty():return 1.0
 if Story.standing(self,str(game.state.landmark))<0:return 1.0
 if Story.active_guide(self,game):return float(game.context.data.prepared_risk_factor)
 return float(game.context.data.prepared_risk_factor) if str(game.state.landmark)=="deschutes" and int(c.guide_day)==int(game.state.day) and int(c.guide_loads)>=maxi(1,game.wagon_count()) else 1.0
func portage_choice(game) -> Dictionary:
 var fee: float=maxi(1,int(data.portage_cents_per_load)*maxi(1,game.wagon_count())-Story.portage_credit(self))/100.0
 return {"label":"Hire Upper Chinookan portage crews · $%.2f · %d day" % [fee,data.portage_days],"action":"leave","native_portage":true,"requires":{"money":fee},"effects":{"money":-fee,"days":int(data.portage_days)}}
func valid_portage(game,selected: Dictionary) -> bool:
 if selected.get("native_portage")!=true or selected.get("action","")!="leave" or not can_portage(game):return false
 var canonical: Dictionary=portage_choice(game)
 var effects: Variant=selected.get("effects");var needs: Variant=selected.get("requires")
 if not effects is Dictionary or effects.size()!=2 or not needs is Dictionary or needs.size()!=1:return false
 for value in [effects.get("money"),effects.get("days"),needs.get("money")]:
  if not (value is int or value is float) or not is_finite(value):return false
 return effects.money==canonical.effects.money and effects.days==canonical.effects.days and needs.money==canonical.requires.money
func can_portage(game) -> bool:
 return refusal(game,"columbia_raft").is_empty() and game.state.landmark=="columbia_raft" and game.Direction.heading(game)=="west" and game.pending.get("landmark","")=="columbia_raft" and not game.pending.get("retreat_without_crossing",false)
func choice(label: String,command: String,offer: String="") -> Dictionary:return {"label":label,"native_command":command,"native_offer":offer,"effects":{},"result":""}
func menu(game,site: String,view: String="intro") -> Dictionary:
 var local: Dictionary=data.sites[site];var c: Dictionary=contact(site)
 if view=="contact" and local.has("contact"):
  return {"id":"native_contacts","service_menu":true,"native_menu":true,"native_site":site,"native_view":view,"title":local.contact.label,"text":Story.description(self,game,site),"choices":Story.options(self,game,site)}
 var options: Array=[choice("Ask about this place · no extra time","notes")]
 if local.has("contact"):options.append(choice("Speak with "+str(local.contact.label).to_lower(),"contact"))
 for offer in local.offers:
  var left: int=maxi(0,int(offer.lots)-int(c.purchases.get(offer.key,0)))
  var label: String={"food":"preserved provisions","produce":"fresh produce baskets","dried_produce":"dried fruit baskets"}[offer.item]
  options.append(choice("Buy %d %s · $%.2f · %d parcel(s) left%s" % [offer.amount,label,price(game,offer)/100.0,left," · out of season" if int(game.calendar().month) not in offer.months else ""],"trade",str(offer.key)))
 if local.get("guidance",false):
  var ready: bool=guidance_factor(game)<1
  options.append(choice("Crossing guide already arranged for today" if ready else "Arrange a crossing guide · $%.2f · 1 day" % (int(data.guide_cents_per_load)*maxi(1,game.wagon_count())/100.0),"guidance"))
 if local.get("horses",false):options.append(choice("Discuss the horse-trading terms","horses"))
 if local.get("portage",false):options.append(choice("Arrange paid portage · $%.2f · %d day" % [portage_choice(game).requires.money,data.portage_days],"portage"))
 options.append(choice("Look for a companion · chance to meet someone","recruit"))
 options.append(choice("Back to the trail","back"))
 return {"id":"native_contacts","service_menu":true,"native_menu":true,"native_site":site,"native_view":view,"title":local.name,"text":(local.notes if view=="notes" else local.intro)+("\nThe first purchase uses a day and meals; further parcels from this household take no extra time." if not local.offers.is_empty() else ""),"choices":options}
func open(game) -> bool:
 var site: String=site_at(game)
 if site.is_empty() or not game.can_service():return false
 # A household the party wronged, or one that has heard it named, turns it away.
 var refused: String=refusal(game,site)
 if not refused.is_empty():
  game.service_return=game.pending.duplicate(true)
  game.pending={"id":"native_contacts","service_menu":true,"native_menu":true,"native_site":site,"native_view":"intro","title":data.sites[site].name,"text":refused,"choices":[choice("Back to the trail","back")]}
  return true
 if can_portage(game) and not game.pending.choices.any(func(c):return c.get("native_portage",false)):game.pending.choices.append(portage_choice(game))
 game.service_return=game.pending.duplicate(true);game.pending=menu(game,site);return true
func can_choose(game,index: int) -> bool:
 var site: String=site_at(game)
 if site.is_empty() or index<0 or index>=game.pending.get("choices",[]).size():return false
 var selected: Dictionary=game.pending.choices[index]
 var command: String=str(selected.get("native_command",""))
 if command=="back":return true
 if not refusal(game,site).is_empty():return false
 if command=="notes" or command=="overview":return true
 if command=="contact":return data.sites[site].has("contact")
 if command=="story":return game.pending.get("native_view","")=="contact" and Story.can_choose(self,game,site,Story.action(self,site,str(selected.get("native_offer",""))))
 if command=="trade":
  var offer: Dictionary=offer_at(site,str(selected.get("native_offer","")))
  return available(game,site,offer) and roundi(game.state.money*100)>=price(game,offer)
 if command=="guidance":return Story.standing(self,site)>=0 and data.sites[site].get("guidance",false) and guidance_factor(game)>=1 and game.state.money*100>=int(data.guide_cents_per_load)*maxi(1,game.wagon_count())
 if command=="recruit":return true
 if command=="horses":return data.sites[site].get("horses",false)
 if command=="portage":return data.sites[site].get("portage",false) and game.Direction.heading(game)=="west" and not game.service_return.get("retreat_without_crossing",false) and game.service_return.get("choices",[]).any(func(c):return c.get("native_portage",false)) and roundi(game.state.money*100)>=roundi(portage_choice(game).requires.money*100)
 return false
func choose(game,index: int) -> bool:
 if not can_choose(game,index):return false
 var site: String=site_at(game);var selected: Dictionary=game.pending.choices[index]
 var command: String=selected.native_command
 if command in ["contact","overview"]:game.pending=menu(game,site,"contact" if command=="contact" else "intro");return true
 if command=="story":return Story.choose(self,game,site,str(selected.native_offer))
 if command in ["back","horses","portage","recruit"]:
  if site=="columbia_raft":
   for i in range(game.service_return.get("choices",[]).size()):
    if game.service_return.choices[i].get("native_portage",false):game.service_return.choices[i]=portage_choice(game)
  game.pending=game.service_return.duplicate(true);game.service_return={}
  if command=="back":return true
  if command=="recruit":return game.recruitment.open(game)
  if command=="horses":return game.open_horse_traders()
  for i in range(game.pending.choices.size()):
   if game.pending.choices[i].get("native_portage",false):return game.choose(i)
  return false
 var c: Dictionary=contact(site).duplicate(true);record[site]=c
 if command=="notes":
  if not c.heard:game.journal.append("Day %d · Spoke with %s. %s" % [game.state.day,data.sites[site].name,data.sites[site].notes])
  c.heard=true;game.pending=menu(game,site,"notes");return true
 if command=="guidance":
  var fee: float=int(data.guide_cents_per_load)*maxi(1,game.wagon_count())/100.0
  game._apply({"money":-fee,"days":1})
  c.guide_day=int(game.state.day);c.guide_loads=maxi(1,game.wagon_count())
  game.journal.append("Day %d · Hired local Deschutes crossing assistance for $%.2f. Guidance is for the next crossing made today; risk remains." % [game.state.day,fee])
 else:
  var offer: Dictionary=offer_at(site,str(selected.native_offer))
  var days: int=1 if int(c.first_trade_day)<0 else 0
  var expense: float=price(game,offer)/100.0
  c.purchases[offer.key]=int(c.purchases.get(offer.key,0))+1
  if days>0:c.first_trade_day=int(game.state.day)
  var effects: Dictionary={"money":-expense,"days":days,offer.item:int(offer.amount)}
  game.Produce.commit(game,effects);game._apply(effects)
  game.supply_history.append({"day":int(game.state.day),"event":"native_trade","site":site,"item":str(offer.item),"amount":int(offer.amount),"price_cents":roundi(expense*100)})
  game.journal.append("Day %d · Bought %d %s from %s for $%.2f. Household stock is finite." % [game.state.day,offer.amount,offer.item,data.sites[site].name,expense])
 if game.state.status=="traveling" and game.pending.get("native_menu",false):game.pending=menu(game,site)
 return true
func valid(value: Variant,day: int) -> bool:
 if not value is Dictionary or value.size()>data.sites.size():return false
 for site in value:
  if not data.sites.has(site):return false
  var c: Variant=value[site]
  if not c is Dictionary or c.size() not in [5,6] or not c.get("heard") is bool or not whole(c.get("first_trade_day"),-1,day) or not whole(c.get("guide_day"),-1,day) or not whole(c.get("guide_loads"),0,1000000) or not c.get("purchases") is Dictionary:return false
  if c.size()==6 and (not c.has("story") or not Story.valid_state(self,str(site),c.story,day)):return false
  if (int(c.guide_day)<0)!=(int(c.guide_loads)==0) or (not data.sites[site].get("guidance",false) and c.guide_loads!=0):return false
  if c.purchases.size()>data.sites[site].offers.size() or (c.purchases.is_empty()!=(int(c.first_trade_day)<0)):return false
  for key in c.purchases:
   var offer: Dictionary=offer_at(str(site),str(key))
   if offer.is_empty() or not whole(c.purchases[key],1,int(offer.lots)):return false
 return true
func valid_menu(menu_: Dictionary,game) -> bool:
 if not menu_.get("native_menu",false):return true
 var site: Variant=menu_.get("native_site")
 if menu_.get("id")!="native_contacts" or not site is String or not data.sites.has(site) or site!=game.state.landmark or menu_.get("native_view") not in ["intro","notes","contact"] or game.service_return.get("landmark","")!=site:return false
 if menu_.native_view=="contact" and not data.sites[site].has("contact"):return false
 for item in menu_.get("choices",[]):
  if item.get("native_command","") not in COMMANDS:return false
  if item.native_command=="story" and (menu_.native_view!="contact" or Story.action(self,site,str(item.get("native_offer",""))).is_empty()):return false
  if item.native_command=="trade" and offer_at(site,str(item.get("native_offer",""))).is_empty():return false
 return true
