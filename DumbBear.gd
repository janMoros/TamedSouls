extends KinematicBody2D

var motion = Vector2()
export var MAX_SPEED = 400
export var G = 10
export var JUMP_FORCE = -400
export var ACC = 50
export var DMG = 1
const UP = Vector2(0,-1)

var direction = 1
var is_dead = false

export (int) var hp = 1

onready var max_hp = hp

func die(): # Realment treiem vida ara
	hp -= 1
	$HPBar.value = hp * 100 / max_hp
	print(hp,max_hp)
	if hp <= 0: # Die
		is_dead = true
		motion = Vector2(0,0)
		$AnimatedSprite.play("dead")
		if direction == 1:
			$AnimatedSprite.rotation_degrees = -160
		else:
			$AnimatedSprite.rotation_degrees = 160
		position = Vector2(position.x, position.y + 15)
		$CollisionShape2D.set_deferred("disabled", true) # Important fer-ho deferred
		$DespawnTimer.start()

func _physics_process(delta):
	if not is_dead:
		motion.y += G
		if direction == 1:
			motion.x = min(motion.x + ACC, MAX_SPEED)
			$AnimatedSprite.flip_h = false 
		else:
			motion.x = max(motion.x - ACC, -MAX_SPEED) 
			$AnimatedSprite.flip_h = true 
		
		$AnimatedSprite.play("walk")
		
		motion = move_and_slide(motion, UP)
	
	if is_on_wall():
		direction *= -1
		$RayCast2D.position.x *= -1
		
	if !$RayCast2D.is_colliding():
		direction *= -1
		$RayCast2D.position.x *= -1
		
	if get_slide_count() > 0:
			for i in range(get_slide_count()):
				if "Player" in get_slide_collision(i).collider.name:
					#get_slide_collision(i).collider.die()
					get_slide_collision(i).collider.hit(DMG)
func _on_Despawn_timeout():
	queue_free()
