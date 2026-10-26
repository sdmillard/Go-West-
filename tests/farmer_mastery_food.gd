extends "res://tests/livestock_balance_food.gd"
## Read-only classifications; preview models keep their own independent audit.
var preservation_audit: Dictionary={"raw_meat_spoiled":0,"dried_meat_spoiled":0,"produce_spoiled":0,"other_spoiled":0,"drying_batches":0,"units_processed":0,"units_retained":0,"classification_errors":0}
func spoil(day: int,total: int) -> int:
 var model=load("res://simulation/provisions.gd").new()
 model.data=data.duplicate(true);model.fresh.assign(fresh.duplicate(true));model.reconcile(total)
 var classified: Dictionary={"raw_meat_spoiled":0,"dried_meat_spoiled":0,"produce_spoiled":0,"other_spoiled":0}
 for batch in model.fresh:
  if int(batch.expires)>day:continue
  var kind: String="produce_spoiled" if batch.get("vitamin_c",false) else ("dried_meat_spoiled" if batch.get("preserved",false) else ("other_spoiled" if batch.get("table_product",false) else "raw_meat_spoiled"))
  classified[kind]+=int(batch.pounds)
 var lost: int=super.spoil(day,total)
 var sum:=0
 for kind in classified:preservation_audit[kind]+=int(classified[kind]);sum+=int(classified[kind])
 if sum!=lost:preservation_audit.classification_errors+=1
 return lost
func preserve(amount: int,day: int,salted: bool) -> Dictionary:
 var result: Dictionary=super.preserve(amount,day,salted)
 if result.input>0:
  preservation_audit.drying_batches+=1;preservation_audit.units_processed+=int(result.input);preservation_audit.units_retained+=int(result.kept)
 return result
