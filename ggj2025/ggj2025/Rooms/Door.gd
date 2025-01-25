extends Area2D
class_name Door
var owner_room_id: int = -1
var connected_room_id: int = -1

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node):
	if body.name == "Player":
		# We can tell the game manager or the player that we've
		# moved from 'owner_room_id' to 'connected_room_id'
		var manager = get_node("/root/GameManager")  # example
		manager.on_player_door_transition(owner_room_id, connected_room_id)
