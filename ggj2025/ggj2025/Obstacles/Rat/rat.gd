extends CharacterBody2D

var speed: float = 10.0 # Strength of the push
var influence_distance: float = 50.0 # Maximum distance for the mouse to influence the bubble
var movement: int = 5
var duration: float = 0.5

func _ready():
	up()

func _physics_process(delta):
	# Get the current mouse position in global coordinates
	var mouse_pos = get_global_mouse_position()

	# Calculate mouse movement direction (delta)
	var mouse_delta = $CollisionShape2D.global_position - mouse_pos

	# Only apply the push if the mouse is within the influence distance
	if mouse_delta.length() > 0 and $CollisionShape2D.global_position.distance_to(mouse_pos) <= influence_distance:
		# Push bubble based on the direction of mouse movement
		velocity += mouse_delta * speed * delta  # Scale push by speed and delta
	
	if velocity.length() != 0:
		movement = 0
		duration = 0
	else:
		movement = 5
		duration = 0.5

	# Apply deceleration to slow down the bubble over time
	velocity = velocity.move_toward(Vector2.ZERO, speed * 10 * delta)

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
	
func _on_area_2d_area_entered(area: Area2D) -> void:
	print(area.is_in_group("pipes"))
	if (area.is_in_group("pipes")):
		queue_free()
