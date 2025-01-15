extends Node2D

var map : Node2D = null
var map_scene = preload("res://drop_map.tscn")

func reload_tilemap():
	map.queue_free()
	map = map_scene.instantiate()
	add_child(map)

# Called when the node enters the scene tree for the first time.
func _ready():
	map = map_scene.instantiate()
	add_child(map)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
