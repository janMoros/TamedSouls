extends Area2D

export var SPEED = 450
var motion = Vector2()
var direction = 1
export var DMG = 1
var launcher

func set_fireball_direction(dir):
	direction = dir
	if dir == -1:
		$AnimatedSprite.flip_h = false
		$AnimatedSprite.position.x *= -1

func _physics_process(delta):
	motion.x = SPEED * delta * direction
	translate(motion) # Mou directament, ignorant col·lisions (signal on_body_entered)
	$AnimatedSprite.play("fireball")



func _on_body_entered(body):
	if body in get_tree().get_nodes_in_group("enemies") \
	or body in get_tree().get_nodes_in_group("player"):
		body.hit(DMG,"Magic",direction)
	queue_free()
