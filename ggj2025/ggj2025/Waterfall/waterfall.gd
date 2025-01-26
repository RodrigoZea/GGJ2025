extends Node2D

func _ready() -> void:
	$AnimationPlayer.play("on")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player")):
		body.die()