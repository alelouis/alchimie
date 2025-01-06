extends Node2D

# Preload the scene or texture you want to spawn
@onready var element_scene = preload("res://element.tscn")
@onready var particle_scene = preload("res://ParticleEffect.tscn")

signal elementGained

var can_input = true
var can_space = true

var rng = RandomNumberGenerator.new()

var n_rows = 11
var max_rows = n_rows - 3
var n_cols = 8
var elements = {}
var element_spacing = 100.0
var fadeout_time = 0.1
var fall_time = 0.2
var move_time = 0.2
var spawn_time = 0.1

var pending_start_row = 0
var pending_start_col = 3

# Current pending positions
var pending_one_row = null
var pending_one_col = null
var pending_two_row = null
var pending_two_col = null
var pending_rotation = 0

func _ready() -> void:
	spawn_elements_on_grid(false)
	spawn_pending()

func _process(delta: float) -> void:
	pass

func _input(event):
	# Check if the event is a key press
	if event is InputEventKey and event.pressed and can_input:
		match event.keycode:
			KEY_R:
				can_input = false
				rotate_pending()
				can_input = true
			KEY_J:
				can_input = false
				move_pending('left')
				can_input = true
			KEY_L:
				can_input = false
				move_pending('right')
				can_input = true
			KEY_SPACE:
				if can_space:
					can_input = false
					can_space = false
					await fall(true)
					await spawn_pending()
					can_input = true
					var cc = find_all_connected_components(elements)
					while cc.size() > 0:
						for c in cc:
							var spawn_position = find_lowest_then_leftmost(c)
							var element_value = elements[[c[0][0], c[0][1]]].element_value
							await delete_elements(c)
							await spawn_element_at_row_col(spawn_position[0], spawn_position[1], true, element_value+1)
							await fall(false)
						cc = find_all_connected_components(elements)
					can_space = true


# Utility
	
func row_to_y(row):
	var marker = get_node("GridBottom")
	return marker.position.y + element_spacing * row 

func col_to_x(col):
	var marker = get_node("GridBottom")
	return marker.position.x + element_spacing * (col - n_cols/2.0) - element_spacing / 2.0

func find_lowest_then_leftmost(rc_array):
	var max_row = -1
	for rc in rc_array:
		var row = rc[0]
		if row >= max_row:
			max_row = row
			
	var min_col = n_cols
	for rc in rc_array:
		var row = rc[0]
		var col = rc[1]
		if col <= min_col and row == max_row:
			min_col = col
	return [max_row, min_col]

# Spawing

func spawn_pending():
	pending_rotation = 0
	pending_one_row = pending_start_row
	pending_one_col = pending_start_col
	pending_two_row = pending_start_row
	pending_two_col = pending_start_col + 1
	spawn_element_at_row_col(pending_one_row, pending_one_col, false, rng.randi_range(0, 3))
	spawn_element_at_row_col(pending_two_row, pending_two_col, false, rng.randi_range(0, 3))

func spawn_element_at_row_col(row, col, wait, element_value):
	var x = col_to_x(col)
	var y = row_to_y(row)
	elements[[row, col]] = await spawn_element_at_position(Vector2(x, y), wait, element_value)

func spawn_elements_on_grid(wait):
	var marker = get_node("GridBottom")
	for row in range(n_rows):
		var y = row_to_y(row)
		for col in range(n_cols):
			var x = col_to_x(col)
			if row < max_rows:
				elements[[row, col]] = null
			else:
				elements[[row, col]] = await spawn_element_at_position(Vector2(x, y), wait, (col + row)%4)

func spawn_element_at_position(position: Vector2, wait, element_value):
	var element_instance = element_scene.instantiate()
	element_instance.position = position
	element_instance.modulate.a = 0
	element_instance.element_value = element_value
	element_instance.z_index = sqrt(position.x**2 + position.y**2)
	add_child(element_instance)
	var tween = create_tween()
	tween.tween_property(element_instance, "modulate:a", 1.0, spawn_time)
	if wait:
		await tween.finished
	return element_instance

# Deletion

func delete_element(row, col) -> void:
	if elements[[row, col]]:
		var tween = create_tween()
		tween.tween_property(elements[[row, col]], "rotation", deg_to_rad(5), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(elements[[row, col]], "rotation", deg_to_rad(0), 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(elements[[row, col]], "modulate:a", 0.0, 0.1)
		
		
		var particles = particle_scene.instantiate()
		elements[[row, col]].add_child(particles)
		particles.position += Vector2(element_spacing, element_spacing)
		
		emit_signal("elementGained", elements[[row, col]].element_value)
		
		tween.tween_callback(func():
			elements[[row, col]].queue_free()
			elements[[row, col]] = null
		)
		await tween.finished

func delete_elements(rc_array) -> void:
	for i in range(rc_array.size() - 1):
		delete_element(rc_array[i][0], rc_array[i][1])
	await delete_element(rc_array[-1][0], rc_array[-1][1])

# Movement

func move_pending(direction):
	var old_pending_one_row = pending_one_row
	var old_pending_one_col = pending_one_col
	var old_pending_two_row = pending_two_row
	var old_pending_two_col = pending_two_col
	
	if direction == 'left':
		if min(pending_one_col-1, pending_two_col-1) >= 0:
			pending_one_col -= 1
			pending_two_col -= 1
		
	if direction == 'right':
		if max(pending_one_col+1, pending_two_col+1) < n_cols:
			pending_one_col += 1
			pending_two_col += 1
	
	# Move elements	
	move_piece_to(old_pending_one_row, old_pending_one_col, pending_one_row, pending_one_col)
	move_piece_to(old_pending_two_row, old_pending_two_col, pending_two_row, pending_two_col)
	
	# Switch elements
	var element_one = elements[[old_pending_one_row, old_pending_one_col]]
	var element_two = elements[[old_pending_two_row, old_pending_two_col]]
	elements[[old_pending_one_row, old_pending_one_col]] = null
	elements[[old_pending_two_row, old_pending_two_col]] = null
	elements[[pending_one_row, pending_one_col]] = element_one
	elements[[pending_two_row, pending_two_col]] = element_two

func rotate_pending():
	pending_rotation = (pending_rotation + 1) % 4
	
	var old_pending_one_row = pending_one_row
	var old_pending_one_col = pending_one_col
	var old_pending_two_row = pending_two_row
	var old_pending_two_col = pending_two_col
	
	# Get new positions after rotation
	if pending_rotation == 0:
		pending_one_row -= 1
		pending_two_col += 1
	if pending_rotation == 1:
		pending_two_row += 1
		pending_two_col -= 1
	if pending_rotation == 2:
		pending_two_row -= 1
		pending_one_col += 1
	if pending_rotation == 3:
		pending_one_row += 1
		pending_one_col -= 1
		
	# Move elements
	move_piece_to(old_pending_one_row, old_pending_one_col, pending_one_row, pending_one_col)
	move_piece_to(old_pending_two_row, old_pending_two_col, pending_two_row, pending_two_col)
	
	# Switch elements
	var element_one = elements[[old_pending_one_row, old_pending_one_col]]
	var element_two = elements[[old_pending_two_row, old_pending_two_col]]
	elements[[old_pending_one_row, old_pending_one_col]] = null
	elements[[old_pending_two_row, old_pending_two_col]] = null
	elements[[pending_one_row, pending_one_col]] = element_one
	elements[[pending_two_row, pending_two_col]] = element_two

func move_piece_to(from_row, from_col, to_row, to_col):
	var tween = create_tween()
	var x = col_to_x(to_col)
	var y = row_to_y(to_row)
	tween.tween_property(elements[[from_row, from_col]], "position", Vector2(x, y), move_time).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

func fall(spawn):
	var falling = {}
	for k in elements.keys():
		var row = k[0]
		var col = k[1]
		if elements[[row, col]] != null:
			for row_under in range(row + 1, n_rows):
				if elements[[row_under, col]] == null:
					if [row, col] in falling:
						falling[[row, col]][0] += 1
					else:
						falling[[row, col]] = [1, elements[[row, col]]]
	
	if not spawn:
		falling.erase([pending_one_row, pending_one_col])
		falling.erase([pending_two_row, pending_two_col])
		
	var fall_count = 0
	for f in falling.keys():
		fall_count += 1
		var row = f[0]
		var col = f[1]
		var target_row = row + falling[f][0]
		var tween = create_tween()
		var x = col_to_x(col)
		var y = row_to_y(target_row)
		tween.tween_property(elements[[row, col]], "position", Vector2(x, y), fall_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		elements[[row, col]].z_index = sqrt(x**2 + y**2)
		if fall_count == falling.size():
			await tween.finished
	
	# Deleting old positions
	for f in falling.keys():
		var row = f[0]
		var col = f[1]
		elements[[row, col]] = null
	
	# Filling new positions
	for f in falling.keys():
		var row = f[0]
		var col = f[1]
		var target_row = row + falling[f][0]
		elements[[target_row, col]] = falling[f][1]
	
	return falling

# Logic

func get_neighbors(pos: Array, grid_dict: Dictionary) -> Array:
	var neighbors = []
	# Check all 4 directions (up, right, down, left)
	var directions = [
		[0, 1],   # right
		[0, -1],  # left
		[1, 0],   # down
		[-1, 0]   # up
	]
	
	for dir in directions:
		var neighbor_pos = [pos[0] + dir[0], pos[1] + dir[1]]
		if grid_dict.has(neighbor_pos):
			neighbors.append(neighbor_pos)
	
	return neighbors

func find_connected_group(pos: Array, value: int, grid_dict: Dictionary, visited: Dictionary) -> Array:
	var group = []
	var stack = [pos]
	
	while stack:
		var current_pos = stack.pop_back()
		var current_key = str(current_pos)
		
		if visited.has(current_key):
			continue
			
		visited[current_key] = true
		group.append(current_pos)
		
		# Check all neighbors
		for neighbor_pos in get_neighbors(current_pos, grid_dict):
			if not visited.has(neighbor_pos) and grid_dict[neighbor_pos] != null and grid_dict[neighbor_pos].element_value == value:
				stack.append(neighbor_pos)
	
	return group

func find_all_connected_components(grid_dict: Dictionary) -> Array:
	var components = []
	var visited = {}
	
	# Convert grid_dict keys from strings back to arrays
	var positions = []
	for pos in grid_dict.keys():
		positions.append(pos)
	
	# Iterate through all positions
	for pos in positions:
		var pos_key = str(pos)
		if not visited.has(pos_key) and grid_dict[pos] != null:
			var value = grid_dict[pos].element_value
			var connected_group = find_connected_group(pos, value, grid_dict, visited)
			if connected_group.size() > 2:
				components.append(connected_group)
	
	return components
