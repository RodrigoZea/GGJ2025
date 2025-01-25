extends Node2D

func disable_exit(direction: String) -> void:
	match direction: 
		"up":
			if $Base/DoorUp:
				$Base/DoorUp.visible = false
		"down":
			if $Base/DoorDown:
				$Base/DoorDown.visible = false
		"left":
			if $Base/DoorLeft:
				$Base/DoorLeft.visible = false
		"right":
			if $Base/DoorRight:
				$Base/DoorRight.visible = false
		_:
			pass
