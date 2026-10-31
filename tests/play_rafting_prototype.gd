extends SceneTree
## Isolated practice scenario. Launcher redirects user data; normal saves are untouched.
const Main=preload("res://ui/main.tscn")
var screen: Control
var restart_down:=false
var restarting:=false
func _initialize() -> void:
 process_frame.connect(practice_keys)
 call_deferred("start_practice")
func start_practice() -> void:
 if is_instance_valid(screen):screen.queue_free();await process_frame
 screen=Main.instantiate();root.add_child(screen);await process_frame
 var game=screen.game
 game.depart("banker",["ADA","SAM","JO","LOU","PAT"],5,{"oxen":4,"food":500,"clothing":5,"bullet_boxes":2,"medicine":2})
 screen.departure_view.hide()
 game.route_path=game.route.main_path_to("the_dalles");game.route_path.append("columbia_raft")
 game.state.merge({"day":135,"landmark":"columbia_raft","next_landmark":"columbia_raft","miles":1818,"leg_length":0,"leg_miles":0},true)
 game._arrive_landmark(true,false);screen._refresh()
 root.title="Westward, Probably · Rafting practice · F6 restarts"
func practice_keys() -> void:
 var pressed: bool=Input.is_physical_key_pressed(KEY_F6)
 if pressed and not restart_down and not restarting and is_instance_valid(screen):
  restart_down=true;restarting=true;await start_practice();restarting=false
 elif not pressed:restart_down=false
