extends Resource
class_name RoomData

@export var room_type: String
@export var can_exit_up: bool = true
@export var can_exit_down: bool = true
@export var can_exit_left: bool = true
@export var can_exit_right: bool = true
@export var scene: PackedScene

func has_exit(direction: String) -> bool:
	match direction:
		"up": return can_exit_up
		"down": return can_exit_down
		"left": return can_exit_left
		"right": return can_exit_right
	return false
