extends TileMap

enum layers{
	level0 = 0,
	level1 = 1,
	level2 = 2,
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

var noise : FastNoiseLite = FastNoiseLite.new()
var rng = RandomNumberGenerator.new()
var circle_enemy_node : Node2D = null
var circle_enemy = preload("res://circle_enemy.tscn")
var circle_enemy_pos = Vector2i(-99,99)


const main_source = 1
var initalplaced = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	noise.set_seed(rng.randi_range(-100,100))
	place_platform()
	place_boundaries_and_enemy()
	
func place_boundaries_and_enemy():
	var offsets = [
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(1, 0),
		Vector2i(-1, 0),
		
		Vector2i(0, -2),
		Vector2i(0, 2),
		Vector2i(2, 0),
		Vector2i(-2, 0),
		
		Vector2i(-1, -1),
		Vector2i(1, 1),
		Vector2i(-1, 1),
		Vector2i(1, -1),
	]

	for spot in get_used_cells(layers.level0):
		var noisey = noise.get_noise_1d(randi())
		if noisey > 0.3 && !circle_enemy_node:
			if not is_within_3x3($SnakeHead.position, spot):
				place_circle_enemy(spot)
		for offset in offsets:
			var current_spot = spot + offset
			#this spot is empty
			if get_cell_source_id(layers.level0, current_spot) == -1:
				set_cell(layers.level0, current_spot, main_source, boundary_atlas_pos)
	
	#In case circle enemy wasnt placed
	if !circle_enemy_node:
		place_circle_enemy(get_used_cells(layers.level0)[0])


func place_circle_enemy(spot: Vector2i):
	circle_enemy_pos = spot
	circle_enemy_node = circle_enemy.instantiate()
	circle_enemy_node.get_node("Circle/GlowSprite").play()
	var pos = map_to_local(spot)
	#Visual Transform
	pos.y = pos.y - 3
	circle_enemy_node.position = pos
	add_child(circle_enemy_node)

func is_within_3x3(player_position: Vector2i, check_position: Vector2) -> bool:
	return abs(player_position.x - check_position.x) <= 1 and abs(player_position.y - check_position.y) <= 1
	
func place_platform():
	var section_size = 3
	var width = 7
	var height = 7
	for y in range(0, height, section_size):
		for x in range(0, width, section_size):
			place_3x3_section(Vector2i(x - 4, y - 3))

func place_3x3_section(pos):
	for dy in range(0, 3, 2):  # Step by 2 to place 2x2 subsections
		for dx in range(0, 3, 2):
			if pos.x in [-4, 3] or pos.y in [-3, 4]:
				if noise.get_noise_1d(randi()) > -0.1:  # Adjust threshold as needed
					place_2x2_section(pos + Vector2i(dx, dy))
			else:
				place_2x2_section(pos + Vector2i(dx, dy))

func place_2x2_section(pos):
	for dy in range(2):
		for dx in range(2):
			set_cell(layers.level0, pos + Vector2i(dx, dy), main_source, black_block_atlas_pos)

func new_circle_enemy():
	remove_child(circle_enemy_node)
	circle_enemy_node = null

	for spot in get_used_cells(layers.level0):
		if !get_cell_tile_data(layers.level0, spot).get_custom_data_by_layer_id(0):
			var noisey = noise.get_noise_1d(randi())
			if noisey > 0.3 && !circle_enemy_node && not is_within_3x3($SnakeHead.position, spot):
				place_circle_enemy(spot)

	#In case circle enemy wasnt placed
	var poss_spot = 0 
	while !circle_enemy_node:
		var spot = get_used_cells(layers.level0)[poss_spot]
		if !get_cell_tile_data(layers.level0, spot).get_custom_data_by_layer_id(0):
			place_circle_enemy(spot)
