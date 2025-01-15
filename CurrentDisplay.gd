extends Label

func _ready():
	$SnakeSprite.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var snake_head = get_tree().current_scene.map.get_node("SnakeHead")
	if snake_head:
		text = str(snake_head.score)
