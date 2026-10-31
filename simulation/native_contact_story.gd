extends RefCounted
## Authored individual agreements; all identity and standing is local to one contact.
const KINDS=["talk","work","barter","pay","guide","introduce","exchange","work_goods"]
static func whole(v: Variant,lo: int,hi: int) -> bool:return (v is int or v is float) and is_finite(v) and v==floor(v) and v>=lo and v<=hi
static func valid_data(value: Variant,site: String) -> bool:
 if not value is Dictionary or value.size()!=4 or not value.get("id") is String or value.id.is_empty() or not value.get("label") is String or value.label.is_empty() or value.get("initial")!="new" or not value.get("stages") is Dictionary or not value.stages.has("new") or value.stages.size()>16:return false
 if site not in ["platte","fort_hall","grande_ronde","umatilla","deschutes","the_dalles","columbia_raft"]:return false
 for key in value.stages:
  var stage: Variant=value.stages[key]
  if not key is String or not stage is Dictionary or stage.size()!=4 or not stage.get("text") is String or not whole(stage.get("standing"),-1,1) or not stage.get("work_done") is bool or not stage.get("choices") is Array or stage.choices.size()>5:return false
  var used: Array=[]
  for a in stage.choices:
   if not a is Dictionary or not a.get("id") is String or a.id.is_empty() or a.id in used or not a.get("label") is String or not value.stages.has(a.get("next")) or a.get("kind") not in KINDS:return false
   used.append(a.id)
   for field in a:
    if field not in ["id","label","next","kind","wage_floor","background","months","cost_cents","guide_days","exchange_item","exchange_amount","offer"]:return false
   if a.kind=="work" and not whole(a.get("wage_floor"),0,10000):return false
   if a.has("background") and (a.kind!="work" or a.background!="Carpentry"):return false
   if a.has("months") and (a.kind!="work" or not a.months is Array or a.months.is_empty() or not a.months.all(func(m):return whole(m,1,12))):return false
   if a.kind in ["pay","guide"] and not whole(a.get("cost_cents"),1,10000):return false
   if a.kind=="guide" and (site!="deschutes" or not whole(a.get("guide_days"),1,3)):return false
   if a.kind=="introduce" and site!="the_dalles":return false
   if a.kind=="barter" and site!="fort_hall":return false
   if a.kind=="exchange" and (site!="platte" or a.get("exchange_item")!="salt" or not whole(a.get("exchange_amount"),1,1000) or a.get("offer")!="provisions"):return false
   if a.kind=="work_goods" and (site!="umatilla" or a.get("offer")!="fresh"):return false
   for field in ["exchange_item","exchange_amount"]:
    if a.has(field) and a.kind!="exchange":return false
   if a.has("offer") and a.kind not in ["exchange","work_goods"]:return false
 return true
static func state(model,site: String) -> Dictionary:
 return model.contact(site).get("story",{"step":"new","work_day":-1,"agreement_until":-1,"agreement_loads":0,"agreement_closed":false})
static func stage(model,site: String) -> Dictionary:
 return model.data.sites.get(site,{}).get("contact",{}).get("stages",{}).get(state(model,site).step,{})
static func standing(model,site: String) -> int:return int(stage(model,site).get("standing",0))
static func valid_state(model,site: String,v: Variant,day: int) -> bool:
 if not model.data.sites[site].has("contact") or not v is Dictionary or v.size()!=5 or not v.get("step") is String or not model.data.sites[site].contact.stages.has(v.step) or not whole(v.get("work_day"),-1,day) or not whole(v.get("agreement_until"),-1,day+2) or not whole(v.get("agreement_loads"),0,1000000) or not v.get("agreement_closed") is bool:return false
 if (int(v.agreement_until)<0)!=(int(v.agreement_loads)==0):return false
 if int(v.agreement_loads)>0 and (site!="deschutes" or v.step not in ["contract","contract_reconciled"]):return false
 if v.step in ["contract","contract_reconciled"] and int(v.agreement_loads)==0:return false
 if model.data.sites[site].contact.stages[v.step].work_done and int(v.work_day)<0:return false
 if v.step=="new" and int(v.work_day)>=0:return false
 return true
static func active_guide(model,game) -> bool:
 var s: Dictionary=state(model,"deschutes")
 return not s.agreement_closed and game.state.landmark=="deschutes" and game.Direction.heading(game)=="west" and int(s.agreement_until)>=int(game.state.day) and int(s.agreement_loads)>=maxi(1,game.wagon_count()) and standing(model,"deschutes")>=0
static func end_guide(model,game,reason: String) -> void:
 if not model.record.get("deschutes",{}).has("story"):return
 var s: Dictionary=model.record.deschutes.story
 if int(s.agreement_loads)==0 or s.agreement_closed:return
 s.agreement_closed=true
 game.journal.append("Day %d · The river pilot's short agreement ended: %s." % [game.state.day,reason])
static func portage_credit(model) -> int:
 return 100 if state(model,"columbia_raft").step=="credit" else 0
static func redeem_portage(model,game) -> void:
 if portage_credit(model)==0:return
 model.record.columbia_raft.story.step="redeemed"
 game.journal.append("Day %d · Used the portage crew's $1 labor credit against the whole carrying bill." % game.state.day)
static func action(model,site: String,id: String) -> Dictionary:
 for a in stage(model,site).get("choices",[]):
  if a.id==id:return a
 return {}
static func worker_available(game,a: Dictionary) -> bool:
 var leader: int=game.camp_tasks.leader_id(game)
 if not game.income.worker_available(game,leader):return false
 return not a.has("background") or game.camp_tasks.specialist(game,leader,str(a.background)) or (leader==0 and game.state.profession=="carpenter")
static func wages(game,a: Dictionary) -> int:
 return maxi(int(a.wage_floor),int(game.characters.wage_quote(game.characters.profiles[game.camp_tasks.leader_id(game)]).daily_cents)) if int(a.wage_floor)>0 else 0
static func cost(game,a: Dictionary) -> int:return int(a.get("cost_cents",0))*(maxi(1,game.wagon_count()) if a.kind=="guide" else 1)
static func can_choose(model,game,site: String,a: Dictionary) -> bool:
 if a.is_empty():return false
 if a.has("months") and not a.months.any(func(m):return int(m)==int(game.calendar().month)):return false
 match a.kind:
  "work":return worker_available(game,a)
  "exchange":return int(game.state.get(str(a.exchange_item),0))>=int(a.exchange_amount) and model.available(game,site,model.offer_at(site,str(a.offer)))
  "work_goods":return worker_available(game,a) and model.available(game,site,model.offer_at(site,str(a.offer)))
  "barter":return int(game.state.clothing)>0 and model.available(game,site,model.offer_at(site,"provisions"))
  "pay":return roundi(game.state.money*100)>=cost(game,a)
  "guide":return game.Direction.heading(game)=="west" and not active_guide(model,game) and model.guidance_factor(game)>=1 and roundi(game.state.money*100)>=cost(game,a)
 return true
static func description(model,game,site: String) -> String:
 var rule: Dictionary=model.data.sites[site].contact
 var s: Dictionary=state(model,site)
 var text: String=rule.label+"\n"+stage(model,site).text
 if s.step!="new":text+="\nThis contact remembers your earlier dealings."
 if site=="deschutes" and int(s.agreement_until)>=0:
  text+="\nGuide agreement: "+("active through day %d, or arrival at The Dalles." % s.agreement_until if active_guide(model,game) else "ended or not applicable to this direction/team.")
 return text
static func options(model,game,site: String) -> Array:
 var result: Array=[]
 for a in stage(model,site).get("choices",[]):
  var label: String=a.label
  if a.kind=="work":label+=" · 1 day, meals"+(" · earn $%.2f" % (wages(game,a)/100.0) if int(a.wage_floor)>0 else " · unpaid")
  elif a.kind=="guide":label+=" · $%.2f · arrange 1 day · up to %d days" % [cost(game,a)/100.0,a.guide_days]
  elif a.kind=="exchange":label+=" · %d lb salt for %d food units · no extra day" % [a.exchange_amount,model.offer_at(site,str(a.offer)).amount]
  elif a.kind=="work_goods":
   label+=" · %d produce baskets · 1 day, meals" % model.offer_at(site,str(a.offer)).amount
   if not model.available(game,site,model.offer_at(site,str(a.offer))):label+=" · unavailable"
  elif a.kind=="barter":label+=" · %d food units · no extra day" % model.offer_at(site,"provisions").amount
  if a.has("months") and not a.months.any(func(m):return int(m)==int(game.calendar().month)):label+=" · out of season"
  result.append(model.choice(label,"story",str(a.id)))
 result.append(model.choice("Other business with this household","overview"))
 result.append(model.choice("Back to the trail","back"))
 return result
static func choose(model,game,site: String,id: String) -> bool:
 var a: Dictionary=action(model,site,id)
 if not can_choose(model,game,site,a):return false
 var c: Dictionary=model.contact(site).duplicate(true)
 var s: Dictionary=state(model,site).duplicate(true)
 s.step=a.next;c["story"]=s;model.record[site]=c
 var earnings: int=0
 match a.kind:
  "work":
   var leader: int=game.camp_tasks.leader_id(game)
   earnings=wages(game,a);s.work_day=int(game.state.day)+1
   game.income.worker=leader;game.income.workers=[leader]
   game._apply({"money":earnings/100.0,"days":1},"injuries",false,"settlement_work")
   game.income.workers=[];game.income.worker=-1
  "exchange":
   var offer: Dictionary=model.offer_at(site,str(a.offer))
   c.purchases[a.offer]=int(c.purchases.get(a.offer,0))+1
   if int(c.first_trade_day)<0:c.first_trade_day=int(game.state.day)
   game._apply({str(a.exchange_item):-int(a.exchange_amount),"food":int(offer.amount)})
  "work_goods":
   var offer: Dictionary=model.offer_at(site,str(a.offer))
   var leader: int=game.camp_tasks.leader_id(game)
   c.purchases[a.offer]=int(c.purchases.get(a.offer,0))+1
   if int(c.first_trade_day)<0:c.first_trade_day=int(game.state.day)
   s.work_day=int(game.state.day)+1
   game.income.worker=leader;game.income.workers=[leader]
   game._apply({"days":1},"injuries",false,"settlement_work")
   game.income.workers=[];game.income.worker=-1
   if game.state.status=="traveling":
    var payment: Dictionary={str(offer.item):int(offer.amount)}
    game.Produce.commit(game,payment);game._apply(payment)
    game.supply_history.append({"day":int(game.state.day),"event":"local_in_kind_pay","site":site,"item":str(offer.item),"amount":int(offer.amount)})
  "pay":game._apply({"money":-cost(game,a)/100.0})
  "barter":
   var offer: Dictionary=model.offer_at(site,"provisions")
   c.purchases.provisions=int(c.purchases.get("provisions",0))+1
   if int(c.first_trade_day)<0:c.first_trade_day=int(game.state.day)
   game._apply({"clothing":-1,"food":int(offer.amount)})
  "guide":
   game._apply({"money":-cost(game,a)/100.0,"days":1})
   s.agreement_until=int(game.state.day)+int(a.guide_days)-1;s.agreement_loads=maxi(1,game.wagon_count());s.agreement_closed=false
 game.journal.append("Day %d · %s: %s%s." % [game.state.day,model.data.sites[site].contact.label,a.label,"; earned $%.2f" % (earnings/100.0) if earnings>0 else ""])
 game.supply_history.append({"day":int(game.state.day),"event":"local_agreement","site":site,"contact":model.data.sites[site].contact.id,"action":id,"earned_cents":earnings})
 if a.kind=="introduce" and game.state.status=="traveling" and game.pending.get("native_menu",false):
  game.pending=game.service_return.duplicate(true);game.service_return={}
  return game.recruitment.open(game)
 if game.state.status=="traveling" and game.pending.get("native_menu",false):game.pending=model.menu(game,site,"contact")
 return true
