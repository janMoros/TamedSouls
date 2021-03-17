extends Sprite

const SPEED = 10
const MARGIN = 5
var target

func _physics_process(delta):
	target = get_global_mouse_position().x
	
	var dist_x = target - global_position.x
	
	if dist_x < -MARGIN: # a l'esquerra
		global_position.x -= SPEED
	elif dist_x > MARGIN: # a la dreta
		global_position.x += SPEED
	# else == 0, no cal fer res
