extends Node2D

var _on_cooldown = false

@export var expand_factor := 1.3

func _ready() -> void:
	$AnimationPlayer.play("idle")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player") && !_on_cooldown):
		body.expand(expand_factor)
		_on_cooldown = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if (_on_cooldown):
		_on_cooldown = false
