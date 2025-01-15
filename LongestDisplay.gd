extends Label
@onready var main = get_tree().current_scene
@onready var snake_head = null
@onready var highscore = 0

func _ready():
	$SnakeSprite.play()
	$SnakeSprite2.play()
	$SnakeSprite3.play()
	$SnakeSprite4.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var snake_head = get_tree().current_scene.map.get_node("SnakeHead")
	if snake_head && snake_head.score > highscore:
		highscore = snake_head.score
	text = str(highscore)
