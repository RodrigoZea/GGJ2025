extends Control
class_name Minimap

@export var map_scale := 12
@export var offset_x := 10
@export var offset_y := 10
@onready var generator = get_tree().get_first_node_in_group("Generator")

var min_gx: int = 999999
var min_gy: int = 999999

func _ready():
	#_compute_min_coords()
	call_deferred("_center_minimap")
	GameManager.connect("room_changed", _on_room_changed)
	queue_redraw()

func _center_minimap():
	# Calculate the size of the minimap
	var assigned_rooms = generator.assigned_rooms
	var max_gx = -INF
	var max_gy = -INF

	for node_id in assigned_rooms.keys():
		var gx = assigned_rooms[node_id]["grid_x"]
		var gy = assigned_rooms[node_id]["grid_y"]
		if gx > max_gx:
			max_gx = gx
		if gy > max_gy:
			max_gy = gy

	# Compute the minimap size
	var map_width = (max_gx - min_gx + 1) * map_scale
	var map_height = (max_gy - min_gy + 1) * map_scale

	# Set the minimap size
	size = Vector2(map_width, map_height)

	# Center the minimap within its parent
	var parent_control = get_parent() as Control
	if parent_control:
		var parent_size = parent_control.size
		position = (parent_size - size) * 0.5

		# DEBUG: Print all calculations
		print("Parent Control Size:", parent_size)
		print("Minimap Size:", size)
		print("Calculated Minimap Position:", position)
		
		
		print("Parent Control Size:", parent_control.size)
		print("Parent Control Anchors:", parent_control.anchor_top, parent_control.anchor_left, parent_control.anchor_bottom, parent_control.anchor_right)
	



func _compute_min_coords():
	var assigned_rooms = generator.assigned_rooms
	for node_id in assigned_rooms.keys():
		var gx = assigned_rooms[node_id]["grid_x"]
		var gy = assigned_rooms[node_id]["grid_y"]
		if gx < min_gx:
			min_gx = gx
		if gy < min_gy:
			min_gy = gy

func _on_room_changed(new_room_id: int):
	queue_redraw()

func _draw():
	# Gather references
	var assigned_rooms = generator.assigned_rooms
	var visited_rooms = GameManager.visited_rooms
	var adjacency_map = generator.adjacency_map
	var current_room_id = GameManager.current_room_id
	
	if not assigned_rooms.has(current_room_id):
		return

	# 1) Figure out neighbors-of-visited
	var neighbors_of_visited = _get_neighbors_of_visited(visited_rooms, adjacency_map)
	
	# 2) The active room's grid coords => interpret as the "center"
	var current_gx = assigned_rooms[current_room_id]["grid_x"]
	var current_gy = assigned_rooms[current_room_id]["grid_y"]

	# 3) We'll draw the center at half the minimap's width/height
	var half_w = size.x * 0.5
	var half_h = size.y * 0.5

	# 4) Draw only visited or neighbors-of-visited
	for node_id in assigned_rooms.keys():
		var is_visited = visited_rooms.get(node_id, false)
		var is_neighbor = neighbors_of_visited.has(node_id)
		
		# Hide completely if not visited and not neighbor
		if (not is_visited) and (not is_neighbor):
			continue
		
		var gx = assigned_rooms[node_id]["grid_x"]
		var gy = assigned_rooms[node_id]["grid_y"]

		# local offset from the active room
		var dx = gx - current_gx
		var dy = gy - current_gy

		# The cell position: we center the active room at (half_w, half_h)
		var cell_x = half_w + dx * map_scale + offset_x
		var cell_y = half_h + dy * map_scale + offset_y

		# Pick color for the node
		var color = _get_room_color(node_id, is_visited, is_neighbor, current_room_id)

		# Draw a small rectangle for this "cell"
		var cell_size = Vector2(map_scale - 1, map_scale - 1)
		draw_rect(Rect2(Vector2(cell_x, cell_y), cell_size), color)

func _get_neighbors_of_visited(visited_rooms: Dictionary, adjacency_map: Dictionary) -> Dictionary:
	var result = {}
	for vroom_id in visited_rooms.keys():
		if visited_rooms[vroom_id]:
			var neighbors = adjacency_map[vroom_id]
			for neigh_id in neighbors:
				if not visited_rooms.get(neigh_id, false):
					result[neigh_id] = true
	return result

func _get_room_color(node_id: int, is_visited: bool, is_neighbor: bool, current_room_id: int) -> Color:
	if node_id == current_room_id:
		return Color.WHITE  # current room
	elif is_visited:
		return Color.GRAY # visited
	elif is_neighbor:
		return Color.DIM_GRAY  # neighbor-of-visited
	return Color.BLACK
