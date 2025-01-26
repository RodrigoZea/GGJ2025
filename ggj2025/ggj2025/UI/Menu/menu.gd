extends CanvasLayer

@onready var start_button = $Control/MarginContainer/VBoxContainer/Button
@onready var quit_button = $Control/MarginContainer/VBoxContainer/Button3

@export var game_manager_scene: PackedScene
@export var level_scene: PackedScene
@export var level_generator_scene: PackedScene

func _ready() -> void:
	start_button.connect("pressed", _start_game)
	quit_button.connect("pressed", _quit)

func _start_game() -> void:
	if not game_manager_scene or not level_scene or not level_generator_scene:
		push_error("GameManager or Level scene is not assigned!")
		return

	var level_generator = level_generator_scene.instantiate()
	if level_generator:
		get_tree().get_root().add_child(level_generator)
	
	var level_instance = level_scene.instantiate()
	if level_instance:
		get_tree().get_root().add_child(level_instance)
	else:
		push_error("Failed to instance Level scene!")

	# Instance the GameManager
	var game_manager_instance = game_manager_scene.instantiate()
	if game_manager_instance:
		get_tree().get_root().add_child(game_manager_instance)

	# Hide the start screen
	queue_free()

func _quit() -> void:
	get_tree().quit()
