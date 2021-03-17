extends KinematicBody2D

const G = 10
var motion = Vector2()
const UP = Vector2(0,-1) # Vector que apunta cap a dalt

#const theta0 = PI/4 # 60º 


var JUMP_DMG = 1
var is_jumping = false

func _process(delta):
	motion.y += G
	
	if Input.is_action_pressed("debug_up"):
		is_jumping = true
		var player_position = get_tree().get_nodes_in_group("player")[0].global_position
		var x_dist = player_position.x - global_position.x
		
		motion = Vector2(x_dist*0.75, -400)
		
		"""
		if x_dist >= 0:
			var vel0 = x_dist / ( cos(theta0) * sqrt((x_dist * tan(theta0)) / (G/2)))
			motion = Vector2(vel0*cos(theta0), vel0*sin(theta0))
		else:
			var vel0 = x_dist / ( cos(theta0) * sqrt((-x_dist * tan(theta0)) / (G/2)))
			#print(vel0)
			motion = Vector2(vel0*cos(theta0), vel0*sin(theta0))
		"""
	var is_floor_player = false
	if get_slide_count() > 0 and is_jumping:
		for i in range(get_slide_count()):
			if "Player" in get_slide_collision(i).collider.name and is_jumping:
				var player_position = get_tree().get_nodes_in_group("player")[0].global_position
				var x_dist = player_position.x - global_position.x
				var direction = -1
				if x_dist > 0:
					direction = 1 
				get_slide_collision(i).collider.hit(JUMP_DMG, "Jump", direction)
				is_floor_player = true
				is_jumping = false
	
	if is_on_floor() and not is_floor_player:
		is_jumping = false
		motion.x = 0
	
	motion = move_and_slide(motion, UP)
