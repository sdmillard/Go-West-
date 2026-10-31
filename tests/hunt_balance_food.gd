extends "res://simulation/provisions.gd"
## Observe actual meals/spoilage; quotations create their own independent models.
var eaten_units:=0
var spoiled_units:=0
func eat(amount: int,size: int,total: int,vitamin_offset: float=0.0,vitamin_target: float=-1.0) -> float:
 eaten_units+=amount
 return super.eat(amount,size,total,vitamin_offset,vitamin_target)
func spoil(day: int,total: int) -> int:
 var lost: int=super.spoil(day,total)
 spoiled_units+=lost
 return lost
