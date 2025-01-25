extends Node2D
class_name LevelGenerator

@export var room_pool: Dictionary

var assigned_rooms: Dictionary = {}
var adjacency_map: Dictionary = {}
var node_list: Array = []

# We'll define our "room grid size"
# If each room is 10x8 tiles, for instance, or if you want some spacing:
@export var tile_width: int = 200
@export var tile_height: int = 120

func _ready() -> void:
	var path = "res://Graphs/example_graph.json"
	generate_level(path)


func generate_level(json_path: String) -> void:
	var flow_data = _load_flow(json_path)
	if flow_data == {}:
		push_error("Failed to load flow or flow empty")
		return

	node_list = flow_data["nodes"]
	adjacency_map = _build_adjacency_map(flow_data["nodes"], flow_data["edges"])
	
	var order = _build_bfs_order()

	assigned_rooms.clear()
	
	var success = _assign_all_nodes(order, 0)
	if not success:
		push_error("Could not place all rooms without corridor. The constraints might be too tight!")
		return

	# 5. If successful, spawn the final scene
	var dungeon = _spawn_rooms()
	add_child(dungeon)


#
# STEP 1: LOAD JSON
#
func _load_flow(json_path: String) -> Dictionary:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		print("Failed to open file: %s" % json_path)
		return {}
	var json_text = file.get_as_text()
	file.close()
	
	var json_parser = JSON.new()
	var error = json_parser.parse(json_text)
	if error != OK:
		print("Failed to parse JSON: %s" % json_parser.get_error_message())
		return {}
	
	var root = json_parser.data
	if root.has("nodes") and root.has("edges"):
		if root["nodes"] is Array and root["edges"] is Array:
			return root
	
	print("Invalid JSON structure: 'nodes' or 'edges' are missing or not arrays.")
	return {}


#
# STEP 2: BUILD ADJACENCY
#
func _build_adjacency_map(nodes: Array, edges: Array) -> Dictionary:
	var adjacency = {}
	for n in nodes:
		var id_int = int(n["id"])
		adjacency[id_int] = []
	for e in edges:
		var from_id = int(e["from"])
		var to_id = int(e["to"])
		adjacency[from_id].append(to_id)
		adjacency[to_id].append(from_id)
	
	print_debug("Adjacency Map: ", adjacency)
	return adjacency


#
# STEP 3: BUILD BFS ORDER
#         (or random order if you want more variety)
#
func _build_bfs_order() -> Array:
	var visited = {}
	var queue = []
	var result = []
	
	var start_id = int(node_list[0]["id"])
	for info in node_list:
		if info["type"] == "Starting":
			start_id = int(info["id"])
			break
	
	queue.append(start_id)
	visited[start_id] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		result.append(current)
		for neigh in adjacency_map[current]:
			if not visited.has(neigh):
				visited[neigh] = true
				queue.append(neigh)

	# optional: shuffle for more random shapes
	# result.shuffle()
	
	return result


#
# STEP 4: BACKTRACKING TO ASSIGN NODES
#
func _assign_all_nodes(order: Array, index: int) -> bool:
	if index >= order.size():
		return true

	var current_node_id = order[index]
	var node_info = _get_node_info(current_node_id)
	if node_info == {}:
		return false

	var node_type = node_info["type"]
	if not room_pool.has(node_type):
		return false

	var candidates = room_pool[node_type]
	candidates.shuffle()

	# Try each possible room resource
	for candidate_room_data in candidates:
		# Instead of returning Vector2 pixel positions, we'll return possible grid coords
		var possible_grid_coords = _find_valid_grid_coords_for_node(current_node_id, candidate_room_data)
		for grid_coord in possible_grid_coords:
			# Assign
			assigned_rooms[current_node_id] = {
				"room_data": candidate_room_data,
				"grid_x": grid_coord.x,
				"grid_y": grid_coord.y
			}

			# Recurse
			if _assign_all_nodes(order, index + 1):
				return true

			# backtrack
			assigned_rooms.erase(current_node_id)

	return false


func _get_node_info(node_id: int) -> Dictionary:
	for n in node_list:
		if int(n["id"]) == node_id:
			return n
	return {}


#
# STEP 4A: FIND POSSIBLE GRID COORDS
# 
# For each neighbor that is already assigned, we figure out which grid coordinate
# would align the new node with the neighbor in up/down/left/right directions.
#
func _find_valid_grid_coords_for_node(current_node_id: int, candidate_room_data) -> Array:
	var assigned_neighbors = []
	for neigh in adjacency_map[current_node_id]:
		if assigned_rooms.has(neigh):
			assigned_neighbors.append(neigh)

	# If no neighbors assigned, just pick (0,0)
	if assigned_neighbors.is_empty():
		# But also check if (0,0) is already taken
		if _is_grid_occupied(0, 0):
			return []  # no valid coords
		else:
			return [Vector2i(0, 0)]
	
	# Gather sets of possible coords from each neighbor
	var positions_list = []
	for neighbor_id in assigned_neighbors:
		var neighbor_info = assigned_rooms[neighbor_id]
		var neighbor_room = neighbor_info["room_data"]
		var gx = neighbor_info["grid_x"]
		var gy = neighbor_info["grid_y"]

		var possible_from_this_neighbor = []

		# Example: neighbor is left => current must be to the right => (gx+1, gy)
		# But only if that grid cell isn't already used
		if neighbor_room.has_exit("right") and candidate_room_data.has_exit("left"):
			var right_cell = Vector2i(gx + 1, gy)
			if not _is_grid_occupied(right_cell.x, right_cell.y):
				possible_from_this_neighbor.append(right_cell)

		# neighbor is right => current is left => (gx-1, gy)
		if neighbor_room.has_exit("left") and candidate_room_data.has_exit("right"):
			var left_cell = Vector2i(gx - 1, gy)
			if not _is_grid_occupied(left_cell.x, left_cell.y):
				possible_from_this_neighbor.append(left_cell)

		# up/down similarly
		if neighbor_room.has_exit("down") and candidate_room_data.has_exit("up"):
			var down_cell = Vector2i(gx, gy + 1)
			if not _is_grid_occupied(down_cell.x, down_cell.y):
				possible_from_this_neighbor.append(down_cell)

		if neighbor_room.has_exit("up") and candidate_room_data.has_exit("down"):
			var up_cell = Vector2i(gx, gy - 1)
			if not _is_grid_occupied(up_cell.x, up_cell.y):
				possible_from_this_neighbor.append(up_cell)

		if possible_from_this_neighbor.is_empty():
			return []  # no valid coords from that neighbor => dead-end

		positions_list.append(possible_from_this_neighbor)

	# Intersect all sets
	var intersection = positions_list[0]
	for i in range(1, positions_list.size()):
		intersection = _intersect_positions_vector2i(intersection, positions_list[i])
		if intersection.is_empty():
			return []

	return intersection

func _is_grid_occupied(x: int, y: int) -> bool:
	# If any assigned node is already at (x,y), it's occupied
	for node_id in assigned_rooms.keys():
		var assigned = assigned_rooms[node_id]
		if assigned["grid_x"] == x and assigned["grid_y"] == y:
			return true
	return false

func _intersect_positions_vector2i(a: Array, b: Array) -> Array:
	var result = []
	for posA in a:
		for posB in b:
			if posA == posB:
				result.append(posA)
	return result


#
# STEP 5: SPAWN ROOMS AND REMOVE UNUSED EXITS
#
func _spawn_rooms() -> Node2D:
	var root = Node2D.new()
	root.name = "DungeonHolder"

	print("Assigned rooms:", assigned_rooms)

	for node_info in node_list:
		var int_id = int(node_info["id"])
		if not assigned_rooms.has(int_id):
			continue

		var rd = assigned_rooms[int_id]["room_data"]
		var gx = assigned_rooms[int_id]["grid_x"]
		var gy = assigned_rooms[int_id]["grid_y"]

		if rd == null:
			continue

		var instance = rd.scene.instantiate() as Node2D
		# Convert grid coords to pixel coords
		instance.position = Vector2(gx * tile_width, gy * tile_height)

		# Optional: store adjacency or node ID in the instance
		# instance.set_meta("node_id", int_id)

		# We'll add the instance first
		root.add_child(instance)
	# AFTER we've spawned everything, remove or disable unused exits
	_remove_unused_exits(root)

	return root


#
# Remove or hide doors leading nowhere
# We'll assume each instance (Room) has a script or method "disable_exit(direction)"
# that hides/closes the door in that direction.
# 
func _remove_unused_exits(dungeon_root: Node2D) -> void:
	# For each node, check adjacency. If no neighbor in a direction, we disable that exit.
	for node_info in node_list:
		var int_id = int(node_info["id"])
		if not assigned_rooms.has(int_id):
			continue

		var rd = assigned_rooms[int_id]["room_data"]  # The RoomData resource
		var gx = assigned_rooms[int_id]["grid_x"]
		var gy = assigned_rooms[int_id]["grid_y"]

		# find the child instance in dungeon_root
		# a simple approach: the nth child might not always match. 
		# We can store a dictionary of node_id -> instance references if needed.
		# For demonstration, we'll do a naive search:
		var instance: Node2D = null
		for child in dungeon_root.get_children():
			if child is Node2D:
				var cpos = child.position
				# compare with (gx, gy) converted
				if cpos == Vector2(gx * tile_width, gy * tile_height):
					instance = child
					break
		if instance == null:
			continue
			
		# Up neighbor
		var up_neighbor_id = _find_node_at_grid(gx, gy - 1)
		if up_neighbor_id < 0:
			# no neighbor => disable 'up'
			if instance.has_method("disable_exit"):
				instance.call("disable_exit", "up")
		else:
			# check if that neighbor has 'down'
			var neighbor_data = assigned_rooms[up_neighbor_id]["room_data"]
			if not neighbor_data.has_exit("down"):
				if instance.has_method("disable_exit"):
					instance.call("disable_exit", "up")

		# Down neighbor
		var down_neighbor_id = _find_node_at_grid(gx, gy + 1)
		if down_neighbor_id < 0:
			if instance.has_method("disable_exit"):
				instance.call("disable_exit", "down")
		else:
			var neighbor_data = assigned_rooms[down_neighbor_id]["room_data"]
			if not neighbor_data.has_exit("up"):
				if instance.has_method("disable_exit"):
					instance.call("disable_exit", "down")

		# Left neighbor
		var left_neighbor_id = _find_node_at_grid(gx - 1, gy)
		if left_neighbor_id < 0:
			if instance.has_method("disable_exit"):
				instance.call("disable_exit", "left")
		else:
			var neighbor_data = assigned_rooms[left_neighbor_id]["room_data"]
			if not neighbor_data.has_exit("right"):
				if instance.has_method("disable_exit"):
					instance.call("disable_exit", "left")

		# Right neighbor
		var right_neighbor_id = _find_node_at_grid(gx + 1, gy)
		if right_neighbor_id < 0:
			if instance.has_method("disable_exit"):
				instance.call("disable_exit", "right")
		else:
			var neighbor_data = assigned_rooms[right_neighbor_id]["room_data"]
			if not neighbor_data.has_exit("left"):
				if instance.has_method("disable_exit"):
					instance.call("disable_exit", "right")


# find which node is at grid_x, grid_y, or return -1 if none
func _find_node_at_grid(gx: int, gy: int) -> int:
	for node_id in assigned_rooms.keys():
		var info = assigned_rooms[node_id]
		if info["grid_x"] == gx and info["grid_y"] == gy:
			return node_id
	return -1
