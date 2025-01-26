extends Node2D

func _ready():
	up()

func down():
	var tween1 = create_tween()
	tween1.tween_property(self, "global_position:y", -5, 0.5).as_relative()
	tween1.tween_callback(up)

func up():
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", 5, 0.5).as_relative()
	tween.tween_callback(down)
