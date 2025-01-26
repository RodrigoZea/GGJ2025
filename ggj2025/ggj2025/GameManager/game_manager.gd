extends Node2D

@onready var camera = $Camera2D
@onready var generator = get_tree().get_first_node_in_group("Generator")
@onready var minimap = get_tree().get_first_node_in_group("Minimap")
@onready var transition_timer = $TransitionTimer
@onready var level = get_tree().get_first_node_in_group("Level")
@onready var retry_button = $CanvasLayer/GameOverOverlay/ColorRect/MarginContainer/VBoxContainer/Button
@export var character_scene: PackedScene

var current_room_id: int = -1
var player
var visited_rooms: Dictionary = {}
var can_transition_to_room = true
signal room_changed

func _ready():
	var start_id = _get_starting_room_id()
	current_room_id = start_id
	visited_rooms = { 0: true } 
	level.connect("reset_complete", _on_level_reset_complete)
	transition_timer.connect("timeout", _on_timer_timeout)
	var spawn_position = _retrieve_spawn_position(start_id)
	
	if character_scene:
		var character_instance = character_scene.instantiate() as Node2D
		get_tree().get_root().add_child(character_instance) 
		player = character_instance
		character_instance.set_gm(self)
		character_instance.position = spawn_position
		print("character spawned at: ", character_instance.position)
		
	print("room center: ", _get_room_center(current_room_id))
	
		
	player.connect("popped", _on_game_over)
	player.connect("victory", _show_victory_screen)
	retry_button.connect("pressed", _retry)
	_center_camera_on_room(start_id, false)
	minimap.set_gm(self)

func _on_game_over() -> void:
	$CanvasLayer/GameOverOverlay/ColorRect/MarginContainer/VBoxContainer/GameOverLabel.text = "GAME OVER"
	$CanvasLayer/GameOverOverlay/ColorRect/MarginContainer/VBoxContainer/Button.text = "RETRY"
	$CanvasLayer/GameOverOverlay.visible = true

func _on_victory() -> void:
	$CanvasLayer/GameOverOverlay/ColorRect/MarginContainer/VBoxContainer/GameOverLabel.set_text("YOU HAVE ESCAPED")
	$CanvasLayer/GameOverOverlay/ColorRect/MarginContainer/VBoxContainer/Button.set_text("START OVER")
	$CanvasLayer/GameOverOverlay.visible = true
	
func _show_victory_screen() -> void:
	$CanvasLayer/AnimationPlayer.play("fade_in_victory_screen")

func _retry() -> void:
	level.reset()
	reset()

func reset():
	print("Resetting GameManager...")

	# Reset room state
	current_room_id = -1
	visited_rooms.clear()
	can_transition_to_room = true
	$CanvasLayer/GameOverOverlay.visible = false  # Hide the Game Over overlay
	$CanvasLayer/VictoryScreen.hide()
	$AudioStreamPlayer2D.play(0.0)
	
	# Reset the player
	if player:
		player.queue_free()
		player = null

	if generator:
		generator.reset()

	if level:
		level.reset()		

func _on_level_reset_complete() -> void:
	print("Level reset complete.")

	# Get the starting room's ID
	var start_id = _get_starting_room_id()
	current_room_id = start_id
	visited_rooms[current_room_id] = true

	# Retrieve the starting room instance
	var spawn_position = _retrieve_spawn_position(start_id)

	# Reinitialize the player
	if character_scene:
		var character_instance = character_scene.instantiate() as Node2D
		get_tree().get_root().add_child(character_instance)
		player = character_instance
		player.position = spawn_position
		player.set_gm(self)
		# Reconnect player signals
		player.connect("popped", _on_game_over)
		player.connect("victory", _show_victory_screen)

	# Reset camera position
	_center_camera_on_room(current_room_id, false)


func _retrieve_spawn_position(start_id) -> Vector2:
	var spawn_position = Vector2.ZERO
	if generator.assigned_rooms.has(start_id):
		var starting_room = generator.assigned_rooms[start_id].get("room_instance")
		if starting_room:
			var spawn_point = starting_room.get_node_or_null("SpawnPoint")
			if spawn_point:
				spawn_position = spawn_point.global_position
	else:
		spawn_position = _get_room_center(start_id)
		
	return spawn_position

	# Reinitialize the player
	if character_scene:
		var character_instance = character_scene.instantiate() as Node2D
		level.add_child(character_instance)
		player = character_instance
		player.position = spawn_position

		# Reconnect player signals
		player.connect("popped", _on_game_over)
		player.connect("victory", _show_victory_screen)

	# Reset camera position
	_center_camera_on_room(current_room_id, false)


func _on_timer_timeout() -> void:
	can_transition_to_room = true

func on_player_door_transition(from_room_id: int, to_room_id: int) -> void:
	if not can_transition_to_room:
		return
	
	if current_room_id == to_room_id:
		return
		
	set_current_room(to_room_id)
	_offset_player_position(from_room_id, to_room_id)
	_center_camera_on_room(to_room_id, true)
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

func _center_camera_on_room(room_id: int, tween_move: bool) -> void:
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
		if tween_move:
			var tween = create_tween()
			tween.tween_property(camera, "position", room_center, 0.5)
		else:
			camera.position = room_center

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
