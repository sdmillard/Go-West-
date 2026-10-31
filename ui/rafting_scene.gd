extends Control
## Approved isometric rafting art. Water-contact anchors align with simulation collisions.
signal steering(target: float)
const BANK=preload("res://art/pixels/river_crossing.png")
const RAFT=preload("res://art/pixels/rafting_raft.png")
const OBSTACLES=preload("res://art/pixels/rafting_obstacles.png")
const FOAM=preload("res://art/pixels/rafting_foam.png")
const WAGON=preload("res://art/pixels/cross_wagon.png")
const PEOPLE=preload("res://art/pixels/cross_people.png")
var session: Dictionary={}
var target: float=0.0
var wagon: bool=true
var profiles: Array=[]
const Palette=preload("res://ui/traveler_palette.gd")
const ANCHOR=Vector2(190,100)
const CROSS_AXIS=Vector2(105,52.5)
const DECK_CENTER_OFFSET=Vector2(-22,12)
const BANK_ORIGIN=Vector2(504,-60)
const BANK_SCALE=0.8
func _ready() -> void:
 custom_minimum_size=Vector2(432,180);clip_contents=true
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;mouse_filter=Control.MOUSE_FILTER_STOP
 mouse_default_cursor_shape=Control.CURSOR_CROSS
func project(x: float,z: float) -> Vector2:
 return (ANCHOR+Vector2(1.6,-0.8)*z+CROSS_AXIS*x).round()
func steering_at(point: Vector2) -> float:
 # Inverse projection: downstream position cancels, leaving cross-channel position.
 var relative: Vector2=point-ANCHOR
 return clampf((relative.y+relative.x*0.5)/(CROSS_AXIS.y+CROSS_AXIS.x*0.5),-2.0,2.0)
func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion:
  target=steering_at(event.position)
  steering.emit(target)
func _draw() -> void:
 draw_rect(Rect2(0,0,432,180),Color("548db3"))
 # Mirror the existing banks to align the river with the raft's northeast axis.
 draw_set_transform(BANK_ORIGIN,0,Vector2(-BANK_SCALE,BANK_SCALE));draw_texture(BANK,Vector2.ZERO);draw_set_transform(Vector2.ZERO)
 if session.is_empty():return
 var progress: float=session.progress
 for i in range(28):
  var z: float=fposmod(float(i*19)-progress,155.0)-30.0
  var x: float=sin(i*2.7)*0.8
  var p:=project(x,z)
  draw_line(p,p+Vector2(9,-4),Color("8db8c3"),1,false)
 var frame: int=int(float(session.elapsed)*6)%4
 for i in range(9):
  var z: float=fposmod(float(i*23)-progress,155.0)-25
  var p: Vector2=project(sin(i*3.1)*0.82,z)
  draw_texture_rect_region(FOAM,Rect2(p-Vector2(16,8),Vector2(32,16)),Rect2(((frame+i)%4)*32,0,32,16))
 for obstacle in session.obstacles:
  if project(float(obstacle.x),float(obstacle.z)-progress).y<=project(float(session.x),0).y:draw_hazard(obstacle,frame)
 var at:=project(float(session.x),0)
 var bob:=Vector2(0,int(sin(float(session.elapsed)*4)))
 if session.wrecked:
  for i in range(4):draw_texture_rect_region(OBSTACLES,Rect2(at+Vector2(i*12-28,(i%2)*7-12),Vector2(32,32)),Rect2(((frame+i)%4)*32,64,32,32))
 else:
  # The imported sprite was anchored at its stern. Align its deck center with physics.
  at+=DECK_CENTER_OFFSET
  draw_texture_rect_region(RAFT,Rect2(project(float(session.x),0)-Vector2(36,24)+bob,Vector2(72,48)),Rect2(0,0,72,48))
  if wagon:draw_texture_rect_region(WAGON,Rect2(at+Vector2(-2,-52)+bob,Vector2(64,48)),Rect2(0,96,64,48))
  for i in range(mini(3,profiles.size())):
   var person: Vector2=at+Vector2(5+i*13,-9-i*6)+bob
   draw_texture_rect_region(Palette.texture(PEOPLE,profiles[i]),Rect2(person-Vector2(8,17),Vector2(16,20)),Rect2(0,(i%2)*20,16,20))
 for obstacle in session.obstacles:
  if project(float(obstacle.x),float(obstacle.z)-progress).y>project(float(session.x),0).y:draw_hazard(obstacle,frame)
 draw_rect(Rect2(0,0,432,180),Color("302b2c"),false,1)

func draw_hazard(obstacle: Dictionary,frame: int) -> void:
 var relative: float=float(obstacle.z)-float(session.progress)
 if relative< -50 or relative>185:return
 var p:=project(float(obstacle.x),relative)
 var row: int=1 if obstacle.kind=="log" else 0
 draw_texture_rect_region(OBSTACLES,Rect2(p-Vector2(16,22),Vector2(32,32)),Rect2(((frame+int(obstacle.id))%4)*32,row*32,32,32))
 for contact in session.impacts:
  if int(contact.id)==int(obstacle.id) and int(session.ticks)-int(contact.tick)<24:
   draw_texture_rect_region(FOAM,Rect2(p-Vector2(16,5),Vector2(32,16)),Rect2(frame*32,0,32,16))
