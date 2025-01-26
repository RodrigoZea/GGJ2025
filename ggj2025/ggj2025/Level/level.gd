extends Node2D

signal reset_complete

func reset() -> void:
	# Reset LevelGenerator
	var level_generator = $LevelGenerator
	if level_generator:
		level_generator.reset()
	
	# Reset Minimap
	var minimap = $CanvasLayer/Control/Minimap
	if minimap:
		minimap.reset()
		
	emit_signal("reset_complete")
