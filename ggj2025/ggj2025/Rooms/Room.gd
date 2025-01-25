extends Node2D

func disable_exit(direction: String) -> void:
	match direction: 
		"up":
			if $Base/DoorUp != null and $Base/DoorUp/DoorCollision != null:
				$Base/DoorUp.visible = false
				$Base/DoorUp/DoorCollision.disabled = true
		"down":
			if $Base/DoorDown != null and $Base/DoorDown/DoorCollision != null:
				$Base/DoorDown.visible = false
				$Base/DoorDown/DoorCollision.disabled = true
		"left":
			if $Base/DoorLeft != null and $Base/DoorLeft/DoorCollision != null:
				$Base/DoorLeft.visible = false
				$Base/DoorLeft/DoorCollision.disabled = true
		"right":
			if $Base/DoorRight != null and $Base/DoorRight/DoorCollision != null:
				$Base/DoorRight.visible = false
				$Base/DoorRight/DoorCollision.disabled = true
		_:
			pass
