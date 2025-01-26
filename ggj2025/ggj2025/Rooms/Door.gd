extends Area2D
class_name Door
var owner_room_id: int = -1
var connected_room_id: int = -1

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node):
	if body.is_in_group("Player"):
		print_debug("Door triggered from %d to %d" % [owner_room_id, connected_room_id])
		GameManager.on_player_door_transition(owner_room_id, connected_room_id)
