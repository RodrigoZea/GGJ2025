extends CharacterBody2D

# Movement parameters
var speed: float = 5.0 # Strength of the push
var influence_distance: float = 50.0 # Maximum distance for the mouse to influence the bubble
var last_mouse_pos: Vector2 = Vector2.ZERO

@export var shrinking_factor := 0.05

func _ready():
	# Initialize last mouse position
	last_mouse_pos = get_global_mouse_position()

func _physics_process(delta):
	if (scale.length() < 0.6):
		die()
	
	shrinking(delta)
	
	# Get the current mouse position in global coordinates
	var mouse_pos = get_global_mouse_position()

	# Calculate mouse movement direction (delta)
	var mouse_delta = global_position - mouse_pos

	# Only apply the push if the mouse is within the influence distance
	if mouse_delta.length() > 0 and global_position.distance_to(mouse_pos) <= influence_distance:
		# Push bubble based on the direction of mouse movement
		velocity += mouse_delta * speed * delta  # Scale push by speed and delta

	# Apply deceleration to slow down the bubble over time
	velocity = velocity.move_toward(Vector2.ZERO, speed * 10 * delta)

	# Move the CharacterBody2D using the updated velocity
	move_and_slide()

	# Pass normalized mouse position and time to the shader
	var viewport_size = get_viewport().size
	var normalized_mouse_pos = mouse_pos / Vector2(viewport_size)
	#$Sprite2D.material.set_shader_parameter("mouse_position", normalized_mouse_pos)
	#$Sprite2D.material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)

	# Save the current mouse position for the next frame
	last_mouse_pos = mouse_pos

	# Debugging info
	#print("Mouse Delta: ", mouse_delta)
	#print("Velocity: ", velocity)
	#print("Global Position: ", global_position)
	#print("Distance to Mouse: ", global_position.distance_to(mouse_pos))
	print(scale.length())
	
func shrinking(delta) -> void:
	scale = Vector2(scale.x - shrinking_factor * delta, scale.y - shrinking_factor * delta)

func expand(expand_factor: float) -> void:
	scale = Vector2(expand_factor, expand_factor)

func die() -> void:
	queue_free()
