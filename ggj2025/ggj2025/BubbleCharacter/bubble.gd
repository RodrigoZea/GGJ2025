extends CharacterBody2D

# Movement parameters
var speed: float = 5.0 # Strength of the push
var influence_distance: float = 50.0 # Maximum distance for the mouse to influence the bubble
var last_mouse_pos: Vector2 = Vector2.ZERO
@onready var animation_tree = $AnimationTree
@export var shrinking_factor := 0.05
@onready var sprite2d = $Sprite2D
@onready var collision_shape = $CollisionShape2D
var idle_sprite = preload("res://Assets/Sprites/happy-bubble.png")
var moving_sprite = preload("res://Assets/Sprites/happiest-bubble.png")
var can_move = true 
var gm
signal popped

func _ready():
	# Initialize last mouse position
	last_mouse_pos = get_global_mouse_position()	

func set_gm(gm_node) -> void:
	gm = gm_node
	gm.connect("room_changed", _player_room_changed)

func _physics_process(delta):
	if not can_move:
		_reset_velocity() 
		return
	
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
	
	$AnimatedSprite2D.material.set_shader_parameter("progress", fmod(Time.get_ticks_msec() / 1000.0, 1.0))
	#print(int(Time.get_ticks_msec() / 1000.0) % 1)
	_update_sprite()
	_update_sprite_position(mouse_pos)
	# Save the current mouse position for the next frame
	last_mouse_pos = mouse_pos

	# Debugging info
	#print("Mouse Delta: ", mouse_delta)
	#print("Velocity: ", velocity.length())
	#print("Global Position: ", global_position)
	#print("Distance to Mouse: ", global_position.distance_to(mouse_pos))
	#print(scale.length())
	
func shrinking(delta) -> void:
	scale = Vector2(scale.x - shrinking_factor * delta, scale.y - shrinking_factor * delta)

func expand(expand_factor: float) -> void:
	scale = Vector2(expand_factor, expand_factor)

func _player_room_changed(new_room_id: int) -> void:
	_reset_velocity() 

func _reset_velocity() -> void:
	velocity = Vector2.ZERO
	move_and_slide()

func die() -> void:
	$Sprite2D.visible = false
	animation_tree["parameters/conditions/dead"] = true
	can_move = false
	_reset_velocity() 

func end_bubble() -> void:
	emit_signal("popped")
	visible = false
	
func show_fail_screen() -> void:
	print("SHOW END SCREEN")
	
func show_victory_screen() -> void:
	print("SHOW VICTORY SCREEN")

func _update_sprite() -> void:
	if velocity.length() > 0.3:
		sprite2d.texture = moving_sprite
	else:
		sprite2d.texture = idle_sprite

# Update Sprite2D position relative to mouse
func _update_sprite_position(mouse_pos: Vector2) -> void:
	var bubble_radius = collision_shape.shape.radius * 0.4
	var bubble_center = global_position

	# Calculate the desired offset for the sprite
	var desired_offset = mouse_pos - bubble_center

	# Clamp the offset to the circle radius
	if desired_offset.length() > bubble_radius:
		desired_offset = desired_offset.normalized() * bubble_radius

	# Set the sprite's new position
	sprite2d.position = desired_offset
