extends Node2D

const TILE_MIDPOINT  = 18 

const NE = Vector2(1,-0.5) 
const SE = Vector2(1, 0.5)
const SW = Vector2(-1, 0.5) 
const NW = Vector2(-1, -0.5)

const NEdist = NE * 16
const SEdist = SE * 16
const SWdist = SW * 16
const NWdist = NW * 16

const jump_dists = {
	NE: NEdist + Vector2(0,-0.75) * 16,
	SE: SEdist + Vector2(0,-0.75) * 16,
	SW: SWdist + Vector2(0,-0.75) * 16,
	NW: NWdist + Vector2(0,-0.75) * 16
}

const dists = {
	NE: NEdist,
	SE: SEdist,
	SW: SWdist,
	NW: NWdist
}

const right_translations = {
	NE: SE,
	SE: SW,
	SW: NW,
	NW: NE
}

const blue_block_atlas_pos = Vector2i(0, 0)
const red_block_atlas_pos = Vector2i(1, 0)
const green_block_atlas_pos = Vector2i(2, 0)
const white_block_atlas_pos = Vector2i(3, 0)
const black_block_atlas_pos = Vector2i(4, 0)
const yellow_block_atlas_pos = Vector2i(5, 0)
const purple_top_block_atlas_pos = Vector2i(6, 0)
const orange_bottom_block_atlas_pos = Vector2i(7, 0)
const boundary_atlas_pos = Vector2i(8, 0)
const snake_block_atlas_pos = Vector2i(9, 0)
const food_block_atlas_pos = Vector2i(10, 0)

const block_colors = {
	NE: red_block_atlas_pos,
	SE: blue_block_atlas_pos,
	SW: yellow_block_atlas_pos,
	NW: green_block_atlas_pos
}

const left_translations = {
	NE: NW,
	SE: NE,
	SW: SE,
	NW: SW
}

var move_speed = 0.85

const dying_speed = 0.50
enum deathType{
	oob = 1,
	crash = 2,
}

const drifting = false

@onready var last_direction_input = NE
@onready var last_direction_motion = NE
@onready var drag_start_position = Vector2.ZERO
@onready var is_dragging = false
@onready var moving = false
@onready var next_position = Vector2.ZERO
@onready var last_position = Vector2.ZERO
@onready var char_layer = 0
@onready var lose : int = 0
@onready var next_pos_tile_coords = Vector2i(-1, 0)

var current_tile_move_duration = Vector2.ZERO
var increase_snake_length = false
var was_inreased = false
var jumped = false
var jump_lockout = 0.0
var snake_part = preload("res://snake_body.tscn")
var snake_die = preload("res://SnakeDie.tscn")

@onready var snake_body = []
@onready var body_positions = []
@onready var written_tiles = []
@onready var current_tilemap = get_parent()
@onready var camera: Camera2D = get_parent().get_node("PlayerCam")
@onready var score = 1
@onready var move_multi = 1.5
@onready var movement_animation = create_tween()


func _process(delta):
	if $SnakeSprite:
		update_animation()

func _physics_process(delta):
	jump_lockout -= delta
	camera.position = position

	if !lose:
		if !moving:
			move_snake_body()
		if last_direction_input != last_direction_motion && !increase_snake_length:
			if jumped:
				set_next_tile_clear(block_colors[last_direction_input])
			else:
				set_next_tile(block_colors[last_direction_input])
			written_tiles.append(next_position)
		elif jumped:
			if increase_snake_length:
				set_next_tile_clear(food_block_atlas_pos)
			else:
				set_next_tile_clear(white_block_atlas_pos)
			written_tiles.append(next_position)

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			drag_start_position = event.position
		else:
			var drag_vector = event.position - drag_start_position
			if drag_vector.length() < 10:  # Ignore small movements
				jumped = true;
	elif event is InputEventScreenDrag:
		detect_drag_direction(event.position)
	
	match Input.get_vector("NorthWest", "SouthEast", "NorthEast", "SouthWest"):
		Vector2(0,-1):
			last_direction_input = NE
		Vector2(1,0):
			#motion = right_translations[last_direction_motion]
			last_direction_input = SE
		Vector2(0,1):
			last_direction_input = SW
		Vector2(-1,0):
			last_direction_input = NW
			#motion = left_translations[last_direction_motion]
	if Input.is_action_pressed("Jump"):
		if jump_lockout <= 0:
			jumped = true
			jump_lockout = current_tile_move_duration * 0.05

func detect_drag_direction(current_position: Vector2):
	var drag_vector = current_position - drag_start_position
	if drag_vector.length() > 10:  # Ignore small movements
		var angle = drag_vector.angle()
		
		# Adjust quadrants as per your requirement
		if angle >= 0 and angle < PI / 2:
			last_direction_input = SE
		elif angle >= PI / 2 and angle < PI:
			last_direction_input = SW
		elif angle >= -PI and angle < -PI / 2:
			last_direction_input = NW
		else:
			last_direction_input = NE

func move_snake_body():
	moving = true
	if jumped:
		jumped = false
		return jump()

	last_direction_motion = last_direction_input
	last_position = next_position
	body_positions.append(last_position)
	next_position = position + (dists[last_direction_input])
	next_pos_tile_coords = current_tilemap.local_to_map(next_position)
	
	check_current_tile()
	
	current_tile_move_duration = move_speed / move_multi
	movement_animation = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	movement_animation.tween_property(self, "position", next_position, current_tile_move_duration)
	movement_animation.tween_callback(move_false)

	for i in range(snake_body.size()):
		movement_animation.tween_property(snake_body[i], "position", next_position, current_tile_move_duration) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	movement_animation.tween_callback(free_pos)
	
	
	check_next_tile()

func jump():
	last_position = next_position
	body_positions.append(last_position)
	var jump_position = position + jump_dists[last_direction_motion] 
	next_position = position + dists[last_direction_motion] + dists[last_direction_input]
	last_direction_motion = last_direction_input
	
	next_pos_tile_coords = current_tilemap.local_to_map(next_position)
	check_current_tile()
	
	current_tile_move_duration = move_speed / move_multi
	movement_animation = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	movement_animation.tween_property(self, "position", jump_position, current_tile_move_duration) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	movement_animation.tween_callback(debugger)
	movement_animation.tween_property(self, "position", next_position, current_tile_move_duration)  \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)
	movement_animation.tween_callback(move_false)

	for i in range(snake_body.size()):
		movement_animation.tween_property(snake_body[i], "position", jump_position, current_tile_move_duration/2) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		
		movement_animation.tween_property(snake_body[i], "position", next_position, current_tile_move_duration/2) \
			.set_trans(Tween.TRANS_QUAD) \
			.set_ease(Tween.EASE_IN)
	movement_animation.tween_callback(free_pos)
	
	check_next_tile()

func debugger():
	pass

func free_pos():
	var new_free_pos = body_positions.pop_front();
	while written_tiles.has(new_free_pos):
		written_tiles.erase(new_free_pos)
	current_tilemap.set_cell(
		char_layer,
		current_tilemap.local_to_map(new_free_pos),
		current_tilemap.main_source,
		current_tilemap.black_block_atlas_pos
	)

func move_false():
	if lose:
		match lose:
			1:
				movement_animation.stop()
				var dying_tween = create_tween().set_parallel(true)
				dying_tween.tween_property(self, "position", next_position + Vector2(0, 7), dying_speed/2)
				dying_tween.chain().tween_property(self, "position", next_position + Vector2(0, -100), dying_speed)
				for part in snake_body:
					dying_tween.parallel().tween_property(part, "position", part.position + Vector2(0, -100), dying_speed)
				dying_tween.chain().tween_callback(get_tree().current_scene.reload_tilemap)
			2:
				var snake_explode = snake_die.instantiate()
				snake_explode.position = $SnakeSprite.position
				$SnakeSprite.queue_free()
				snake_explode.emitting = true
				add_child(snake_explode)
				if snake_body.size() > 0:
					for part in snake_body:
						var part_sprite = part.get_node('SnakeSprite')
						var snake_part_explode = snake_die.instantiate()
						snake_part_explode.position = part_sprite.position
						part_sprite.queue_free()
						snake_part_explode.emitting = true
						part.add_child(snake_part_explode)
					snake_body[-1].get_node('Explosion').connect("finished", get_tree().current_scene.reload_tilemap)
	else:
		moving = false

func reset():
	await get_tree().create_timer(1).timeout
	get_tree().reload_current_scene

func set_tile_color(tile_pos : Vector2, atlas_pos : Vector2, source : int = 1):
	current_tilemap.set_cell(char_layer, tile_pos, source, atlas_pos)
	
func set_next_tile(atlas_pos : Vector2):
	set_tile_color(next_pos_tile_coords, atlas_pos)

func set_next_tile_clear(atlas_pos : Vector2):
	set_tile_color(next_pos_tile_coords, atlas_pos, 2)

func check_current_tile():
	if increase_snake_length:
		written_tiles.append(last_position)
		increase_snake_length = false
		var new_snake_part : Node2D = snake_part.instantiate()
		new_snake_part.z_index = 1
		new_snake_part.position = last_position
		current_tilemap.add_child(new_snake_part)
		snake_body.append(new_snake_part)
		score += 1
		move_multi = move_multi + 0.1
		was_inreased = true
	for pos in body_positions:
		if pos not in written_tiles:
			set_tile_color(current_tilemap.local_to_map(pos), current_tilemap.snake_block_atlas_pos)

func check_next_tile():
	var projected_tile : TileData = current_tilemap.get_cell_tile_data(char_layer, next_pos_tile_coords)
	if projected_tile.get_custom_data_by_layer_id(0):
		set_physics_process(false)
		lose = deathType.oob
	elif next_position in (body_positions.slice(1, body_positions.size()) if body_positions.size() != 2 else body_positions):
		set_physics_process(false)
		lose = deathType.crash
	elif next_pos_tile_coords == current_tilemap.circle_enemy_pos:
		increase_snake_length = true
		current_tilemap.new_circle_enemy()
		set_next_tile(current_tilemap.food_block_atlas_pos)
	else:
		set_next_tile(current_tilemap.white_block_atlas_pos)

func update_animation():
	var angle = rad_to_deg(last_direction_input.angle() if drifting else last_direction_motion.angle())
	var slice_dir : int = floor(angle / 90)
	
	
	$SnakeSprite.set_speed_scale(move_multi)
	match slice_dir:
		-1:
			$SnakeSprite.play("NE")
		-2:
			$SnakeSprite.play_backwards("SW")
		1:
			$SnakeSprite.play_backwards("NE")
		0:
			$SnakeSprite.play("SW")
	
	for part in snake_body:
		var sprite = part.get_node('SnakeSprite')
		sprite.speed_scale = move_multi
		match slice_dir:
			-1:
				sprite.play("NE")
			-2:
				sprite.play_backwards("SW")
			1:
				sprite.play_backwards("NE")
			0:
				sprite.play("SW")


