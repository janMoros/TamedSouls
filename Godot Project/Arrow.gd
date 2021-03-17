extends Area2D

const SPEED = 550
const RANGE = 200
var motion = Vector2()
var direction = 1
export var DMG = 1
const G = 0.5
var movement = 0
var launcher

func set_arrow_direction(dir):
	direction = dir
	if dir == -1:
		$Sprite.flip_h = true
		$Sprite.rotation_degrees = -45
		$Sprite.position.x *= -1

func _physics_process(delta):
	motion.x = SPEED * delta * direction
	movement += motion.x
	if movement >= RANGE or movement <= -RANGE:
		motion.y += G
	translate(motion) # Mou directament, ignorant col·lisions (signal on_body_entered)
	#$AnimatedSprite.play("fireball")



func _on_body_entered(body):
	if body in get_tree().get_nodes_in_group("enemies") \
	or body in get_tree().get_nodes_in_group("player"): # Amb el \ ho llegeix junt
		body.hit(DMG,"Ranged",direction)
	queue_free()
