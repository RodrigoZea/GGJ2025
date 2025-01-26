extends Node2D

@onready var camera = $Camera2D
@onready var generator = get_tree().get_first_node_in_group("Generator")

@export var character_scene: PackedScene
var current_room_id: int = -1


func _ready():
	var start_id = _get_starting_room_id()
	current_room_id = start_id
	
	if character_scene:
		var character_instance = character_scene.instantiate() as Node2D
		add_child(character_instance) 
		character_instance.position = _get_room_center(current_room_id)
		
	_center_camera_on_room(start_id)

func on_player_door_transition(from_room_id: int, to_room_id: int) -> void:
	if current_room_id == to_room_id:
		return
		
	current_room_id = to_room_id
	_center_camera_on_room(to_room_id)

func _center_camera_on_room(room_id: int) -> void:
	var assigned_rooms = generator.assigned_rooms
	var tw = generator.tile_width
	var th = generator.tile_height

	if not assigned_rooms.has(room_id):
		push_warning("No assigned room with ID: %d" % room_id)
		return

	var info = assigned_rooms[room_id] 
	var gx = info["grid_x"]
	var gy = info["grid_y"]

	var room_center = Vector2(gx * tw, gy * th)
	
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "position", room_center, 0.5)

func _get_room_center(room_id: int) -> Vector2:
	var assigned_rooms = generator.assigned_rooms
	var tw = generator.tile_width
	var th = generator.tile_height

	if assigned_rooms.has(room_id):
		var gx = assigned_rooms[room_id]["grid_x"]
		var gy = assigned_rooms[room_id]["grid_y"]
		return Vector2(gx * tw + tw * 0.5, gy * th + th * 0.5)
	return Vector2.ZERO

func _get_starting_room_id() -> int:
	var nodes = generator.node_list
	for node_info in nodes:
		if node_info["type"] == "Starting":
			return int(node_info["id"])
	return 0  
