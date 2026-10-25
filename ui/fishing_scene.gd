extends Control
## Presentation only. Animation never changes the fishing clock, RNG or catch.
const Palette=preload("res://ui/traveler_palette.gd")
const BANK=preload("res://art/pixels/fishing_riverbank.png")
const ANGLER=preload("res://art/pixels/fishing_angler.png")
const BOBBER=preload("res://art/pixels/fishing_bobber.png")
const SPLASH=preload("res://art/pixels/fishing_splash.png")
const FRAME_SECONDS:=0.16
const ANGLER_AT:=Vector2(52,108)
const WATER:=Vector2(288,110)
var encounter: Dictionary={}
var traveler_profile: Dictionary={}
var presentation: String=""
var age:=1.0
var clock:=0.0
var splash_age:=1.0
var previous_shots:=0
var previous_meat:=0
var previous_cast:=0
func _ready() -> void:
 custom_minimum_size=Vector2(432,150)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 clip_contents=true
func reset(profile: Dictionary={}) -> void:
 traveler_profile=profile
 encounter={}
 presentation="";age=1.0;clock=0.0;splash_age=1.0
 previous_shots=0;previous_meat=0;previous_cast=0
 queue_redraw()
func observe(activity: Dictionary) -> void:
 if activity.get("activity","")!="fish":return
 if int(activity.shots)>previous_shots:
  presentation="cast";age=0.0;splash_age=-0.48
 if int(activity.meat)>previous_meat:
  presentation="land";age=0.0;splash_age=0.0
 elif int(activity.cast)>previous_cast and int(activity.shots)==previous_shots:
  presentation="strike";age=0.0;splash_age=0.0
 previous_shots=int(activity.shots);previous_meat=int(activity.meat);previous_cast=int(activity.cast)
 encounter=activity
 queue_redraw()
func advance(delta: float) -> void:
 if not is_finite(delta) or delta<=0:return
 age+=delta;clock+=delta;splash_age+=delta
 queue_redraw()
func pose() -> Dictionary:
 var playing: bool=not presentation.is_empty() and age<FRAME_SECONDS*4
 var action: String=presentation if playing else "wait"
 var frame: int=mini(3,floori(age/FRAME_SECONDS)) if playing else int(clock/FRAME_SECONDS)%4
 var row: int={"cast":0,"wait":1,"strike":2,"land":3}[action]
 return {"action":action,"frame":frame,"row":row,"bobber":not encounter.is_empty() and encounter.phase in ["waiting","bite"] and action!="land"}
func rod_tip(current: Dictionary) -> Vector2:
 var frame: int=current.frame
 match current.action:
  "cast":return ANGLER_AT+[Vector2(4,2),Vector2(17,1),Vector2(30,3),Vector2(31,12)][frame]
  "strike":return ANGLER_AT+Vector2(29-frame*2,4)
  "land":return ANGLER_AT+Vector2(27,2)
 return ANGLER_AT+Vector2(30,8+frame/2)
func _draw() -> void:
 var scale_by:=size/Vector2(432,150)
 draw_set_transform(Vector2.ZERO,0,scale_by)
 draw_texture(BANK,Vector2.ZERO)
 var current: Dictionary=pose()
 var tip: Vector2=rod_tip(current).round()
 var bobber: Vector2=WATER
 if current.action=="cast":
  bobber=tip.lerp(WATER,clampf(age/(FRAME_SECONDS*3),0,1)).round()
 if current.bobber:
  # Cream line is runtime geometry; rod-tip positions follow the supplied Lua source.
  draw_line(tip,bobber,Color("f6e7bc"),1.0,false)
  var row: int=2 if encounter.phase=="bite" else (1 if float(encounter.phase_time)>float(encounter.casts[encounter.cast].wait)*0.75 else 0)
  var frame: int=int(clock/FRAME_SECONDS)%4
  draw_texture_rect_region(BOBBER,Rect2(bobber-Vector2(3,6),Vector2(8,8)),Rect2(frame*8,row*8,8,8))
 if splash_age>=0 and splash_age<FRAME_SECONDS*4:
  draw_texture_rect_region(SPLASH,Rect2(WATER-Vector2(8,12),Vector2(16,16)),Rect2(mini(3,int(splash_age/FRAME_SECONDS))*16,0,16,16))
 # The landing row already includes its fish; never add a duplicate catch sprite.
 draw_texture_rect_region(Palette.texture(ANGLER,traveler_profile),Rect2(ANGLER_AT,Vector2(32,32)),Rect2(current.frame*32,current.row*32,32,32))
 draw_set_transform(Vector2.ZERO)
