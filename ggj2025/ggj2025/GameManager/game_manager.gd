extends Node2D

@onready var camera = $Camera2D
@onready var generator = get_tree().get_first_node_in_group("Generator")
@onready var transition_timer = $TransitionTimer
@export var character_scene: PackedScene
var current_room_id: int = -1
var player
var visited_rooms: Dictionary = {}
var can_transition_to_room = true
signal room_changed

func _ready():
	var start_id = _get_starting_room_id()
	current_room_id = start_id
	GameManager.visited_rooms = { 0: true } 
	transition_timer.connect("timeout", _on_timer_timeout)
	
	if character_scene:
		var character_instance = character_scene.instantiate() as Node2D
		add_child(character_instance) 
		player = character_instance
		character_instance.position = _get_room_center(current_room_id)
		
	_center_camera_on_room(start_id)

func _on_timer_timeout() -> void:
	can_transition_to_room = true

func on_player_door_transition(from_room_id: int, to_room_id: int) -> void:
	if not can_transition_to_room:
		return
	
	if current_room_id == to_room_id:
		return
		
	set_current_room(to_room_id)
	_offset_player_position(from_room_id, to_room_id)
	_center_camera_on_room(to_room_id)
	can_transition_to_room = false
	transition_timer.start()

func set_current_room(room_id: int):
	current_room_id = room_id
	visited_rooms[room_id] = true
	emit_signal("room_changed", room_id)

func _offset_player_position(from_room_id: int, to_room_id: int) -> void:	
	var assigned_rooms = generator.assigned_rooms
	if not assigned_rooms.has(from_room_id) or not assigned_rooms.has(to_room_id):
		return

	var from_room = assigned_rooms[from_room_id]
	var to_room = assigned_rooms[to_room_id]
	var from_gx = from_room["grid_x"]
	var from_gy = from_room["grid_y"]
	var to_gx = to_room["grid_x"]
	var to_gy = to_room["grid_y"]

	var move_bubble = 150
	var offset = Vector2.ZERO
	if to_gx > from_gx:  # Moving right
		offset = Vector2(move_bubble, 0)
	elif to_gx < from_gx:  # Moving left
		offset = Vector2(-move_bubble, 0)
	elif to_gy > from_gy:  # Moving down
		offset = Vector2(0, move_bubble)
	elif to_gy < from_gy:  # Moving up
		offset = Vector2(0, -move_bubble)

	player.position += offset

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
