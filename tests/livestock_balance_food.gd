extends "res://tests/hunt_balance_food.gd"
var dairy_eaten:=0.0
var dairy_spoiled:=0
var dairy_removed:=0
func table_units() -> int:return fresh.filter(func(b):return b.get("table_product",false)).reduce(func(n,b):return n+int(b.pounds),0)
func eat(amount: int,size: int,total: int,vitamin_offset: float=0.0,vitamin_target: float=-1.0) -> float:
 var before:=table_units()
 var vitamin: float=super.eat(amount,size,total,vitamin_offset,vitamin_target)
 dairy_eaten+=before-table_units()
 return vitamin
func spoil(day: int,total: int) -> int:
 var before:=table_units()
 var lost: int=super.spoil(day,total)
 dairy_spoiled+=before-table_units()
 return lost
func remove(amount: int) -> float:
 var before:=table_units()
 var mass: float=super.remove(amount)
 dairy_removed+=before-table_units()
 return mass
