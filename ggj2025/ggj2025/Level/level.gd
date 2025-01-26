extends Node2D

signal reset_complete

func reset() -> void:
	# Reset Minimap
	var minimap = $CanvasLayer/Control/Minimap
	if minimap:
		minimap.reset()
		
	emit_signal("reset_complete")
