extends CanvasLayer

@onready var start_button = $Control/MarginContainer/VBoxContainer/Button
@onready var quit_button = $Control/MarginContainer/VBoxContainer/Button3

@export var game_manager_scene: PackedScene
@export var level_scene: PackedScene

func _ready() -> void:
	start_button.connect("pressed", _start_game)
	quit_button.connect("pressed", _quit)

func _start_game() -> void:
	if not game_manager_scene or not level_scene:
		push_error("GameManager or Level scene is not assigned!")
		return

	# Instance the GameManager
	var game_manager_instance = game_manager_scene.instantiate()
	if game_manager_instance:
		get_tree().get_root().add_child(game_manager_instance)

		# Instance the Level and add it as a child of GameManager
		var level_instance = level_scene.instantiate()
		if level_instance:
			game_manager_instance.add_child(level_instance)
			game_manager_instance.set("level", level_instance)
		else:
			push_error("Failed to instance Level scene!")

	# Hide the start screen
	queue_free()

func _quit() -> void:
	get_tree().quit()
