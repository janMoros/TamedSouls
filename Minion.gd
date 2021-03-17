extends KinematicBody2D

var motion = Vector2(0,0)
export var MAX_SPEED = 250
export var G = 10
export var JUMP_FORCE = -400
export var ACC = 50
export var MELEE_DMG = 1
export var RANGED_DMG = 2
export var MAGIC_DMG = 3
export var soul_value = 100
const UP = Vector2(0,-1)

export var direction = 1
var is_dead = false

var max_hp = 1
var hp
var max_sta = 3
var sta

var is_being_hit = false
var is_attacking = false

var state = "Melee"

const MELEE_STA = 1

var MeleeObjective : Object

var player_position = Vector2()

var x_dist = 0

var is_positioned = false

func _ready():
	if direction == -1:
		$MeleeRayCast.cast_to.x *= -1
		$Position2D.position.x *= -1
		$AnimatedSprite.flip_h = true 
	
	hp = max_hp
	sta = max_sta
	
func hit(dmg,type,direction):

	hp -= dmg * Global.modifyer(type,state)
		
	is_being_hit = true
	$AnimatedSprite.play("hit")
	
	if hp <= 0: # Die
		is_dead = true
		motion = Vector2(0,0)
		$AnimatedSprite.play("dead")
		if direction == 1:
			$AnimatedSprite.rotation_degrees = 160
		else:
			$AnimatedSprite.rotation_degrees = -160

		$CollisionShape2D.rotation_degrees = 90
		$AnimatedSprite.position.y = 4
		
		#$CollisionShape2D.set_deferred("disabled", true) # Important fer-ho deferred
		set_collision_mask_bit(0, false)
		set_collision_layer_bit(0, false)
		set_collision_mask_bit(2, true)
		set_collision_layer_bit(2, true)
		$DespawnTimer.start()
		
		get_tree().call_group("player","recieve_souls",soul_value)
	#else:
	if not is_positioned:
		motion.x = Global.KNOCKBACK_X * direction
		motion.y = Global.KNOCKBACK_Y
	else:
		motion.x = Global.KNOCKBACK_X * direction
		motion.y = Global.KNOCKBACK_Y * 0.7
		#is_positioned = false

func _physics_process(delta):
	motion.y += G
	if not is_dead:
		if not is_attacking and not is_being_hit:
			player_position = get_tree().get_nodes_in_group("player")[0].global_position
			
			x_dist = player_position.x - global_position.x
			
			is_positioned = false
			########### MOVEMENT
			if x_dist > 0: # Positiu -> player a la dreta de l'enemic
				if direction == -1:
					change_direction()
			else:
				if direction == 1:
					change_direction()
			
			if is_on_floor():
				if direction == 1:
					motion.x = min(motion.x + ACC, MAX_SPEED)
				else:
					motion.x = max(motion.x - ACC, -MAX_SPEED) 

			$AnimatedSprite.play("walk")
			
			if $FloorRayCast.is_colliding() and get_slide_count() > 0:
				for i in range(get_slide_count()):
					var collision = get_slide_collision(i)
					if collision.collider != null and "Player" in collision.collider.name:
						motion = motion.bounce(collision.normal)
						motion.y *= 2
						motion.x *= 2
			
			########### ATTACK
			if $MeleeRayCast.is_colliding():
				MeleeObjective = $MeleeRayCast.get_collider()
				if MeleeObjective in get_tree().get_nodes_in_group("player") and (sta - MELEE_STA >= 0):
					$StaRegen.start()
					sta -= MELEE_STA
					is_attacking = true
					$AnimatedSprite.play("attack")
					#motion = Vector2(0,0)
					motion.x = 0
					MeleeObjective.hit(MELEE_DMG,"Melee",direction)
					
			if direction == 1:
				$AnimatedSprite.flip_h = false
			else:
				$AnimatedSprite.flip_h = true 
	else:
		if motion.x > 0:
			motion.x -= 2
		elif motion.x < 0:
			motion.x += 2
	motion = move_and_slide(motion, UP)


func change_direction():
	direction *= -1
	$MeleeRayCast.cast_to.x *= -1
	$Position2D.position.x *= -1

func _on_Despawn_timeout():
	queue_free()


func _on_animation_finished():
	is_attacking = false
	is_being_hit = false


func _on_StaRegen_timeout():
	if sta + 1 <= max_sta: # Ojut el hardcode
		sta = sta + 1
