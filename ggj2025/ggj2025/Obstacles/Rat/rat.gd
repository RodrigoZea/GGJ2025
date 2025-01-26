extends CharacterBody2D

var speed: float = 10.0 # Strength of the push
var chase_speed : float = 20.0
var influence_distance: float = 50.0 # Maximum distance for the mouse to influence the bubble
var movement: int = 5
var duration: float = 0.5

var moved_by_player := false
var target : Node2D = null

#func _ready():
	#up()

func _physics_process(delta):
	# Get the current mouse position in global coordinates
	var mouse_pos = get_global_mouse_position()

	# Calculate mouse movement direction (delta)
	var mouse_delta = $CollisionShape2D.global_position - mouse_pos

	# Only apply the push if the mouse is within the influence distance
	if mouse_delta.length() > 0 and $CollisionShape2D.global_position.distance_to(mouse_pos) <= influence_distance:
		# Push bubble based on the direction of mouse movement
		velocity += mouse_delta * speed * delta  # Scale push by speed and delta
		moved_by_player = true

	if velocity.length() != 0:
		movement = 0
		duration = 0
	else:
		movement = 5
		duration = 0.5
		moved_by_player = false

	# Apply deceleration to slow down the bubble over time
	if (moved_by_player):
		velocity = velocity.move_toward(Vector2.ZERO, speed * 10 * delta)
	else:
		if (target != null):
			#var new_position = target.global_position - global_position
			velocity = global_position.direction_to(target.global_position) * (chase_speed)

	# Move the CharacterBody2D using the updated velocity
	move_and_slide()

func down():
	var tween1 = create_tween()
	tween1.tween_property(self, "global_position:y", -movement, duration).as_relative()
	tween1.tween_callback(up)

func up():
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", movement, duration).as_relative()
	tween.tween_callback(down)

func _on_balloon_area_entered(area: Area2D) -> void:
	if (area.is_in_group("pipes")):
		queue_free()

func _on_search_radius_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player")):
		target = body

func _on_hurt_box_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player")):
		body.die()