extends Node2D

func _ready() -> void:
	$AnimationPlayer.play("sparkle")

func _on_area_2d_body_entered(body: Node2D) -> void:
	print(body.is_in_group("player"))
	if (body.is_in_group("player")):
		body.victory_shrink()
