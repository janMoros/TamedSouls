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

export (int) var hp = 1
onready var max_hp = hp

var is_being_hit = false
var is_attacking = false
var is_idle = false

#var state = "Melee" # or "Magic" or "Ranged"
export(String, "Melee", "Magic", "Ranged") var state = "Melee"

const ARROW = preload("res://Arrow.tscn")
const FIREBALL = preload("res://Fireball.tscn")

var MeleeObjective : Object

var player_position = Vector2()
var player_state = "Melee"

func _ready():
	if MAX_SPEED == 0:   # TEMPORAL PER DIFERENCIAR ENEMICS ESTÀTICS
		is_idle = true
		$AnimatedSprite.position.y = $AnimatedSprite.position.y + 3 # OJUT
	
	if direction == -1:
		$RayCast2D.position.x *= -1
		$MeleeRayCast.cast_to.x *= -1
		$Position2D.position.x *= -1
		$RangedRayCast.cast_to.x *= -1
		$RangedRayCast.position.x *= -1
		$MagicRayCast.cast_to.x *= -1
		$MagicRayCast.position.x *= -1
		$AnimatedSprite.flip_h = true 
		
func hit(dmg):
	hp -= dmg
	$HPBar.value = hp * 100 / max_hp
		
	is_being_hit = true
	$AnimatedSprite.play("hit")
	
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
		
		get_tree().call_group("player","recieve_souls",soul_value)

func _physics_process(delta):
	if not is_dead:
#		if hp > 20 * max_hp / 100:
#			$HPBar.modulate = "8cff23"
#		else:
#			$HPBar.modulate = "ff0000"
		if not is_idle: # CAOS
			if is_on_wall(): # QUE TOT VAGI EN FUNCIÓ DE DIRECTION! i canviar la direction només quan interessi, no aqui
				direction *= -1
				$RayCast2D.position.x *= -1
				$MeleeRayCast.cast_to.x *= -1
				$Position2D.position.x *= -1
				$RangedRayCast.cast_to.x *= -1
				$RangedRayCast.position.x *= -1
				$MagicRayCast.cast_to.x *= -1
				$MagicRayCast.position.x *= -1
				
			if !$RayCast2D.is_colliding():
				direction *= -1
				$RayCast2D.position.x *= -1
				$MeleeRayCast.cast_to.x *= -1
				$Position2D.position.x *= -1
				$RangedRayCast.cast_to.x *= -1
				$RangedRayCast.position.x *= -1
				$MagicRayCast.cast_to.x *= -1
				$MagicRayCast.position.x *= -1
		
		if not is_attacking:
			
			player_position = get_tree().get_nodes_in_group("player")[0].global_position
			player_state = get_tree().get_nodes_in_group("player")[0].state
			
			match player_state: ################################################ TEMP: CANVIA DIRECTAMENT QUAN HO FA EL JUGADOR
				"Melee":
					state = "Ranged"
				"Ranged":
					state = "Magic"
				"Magic":
					state = "Melee"
			
			if is_idle:
				$AnimatedSprite.play("idle")
			elif not is_being_hit: # Separat del is_attacking per ser com el PJ
				motion.y += G
				
				################# PATROL
				if direction == 1:
					motion.x = min(motion.x + ACC, MAX_SPEED)
					$AnimatedSprite.flip_h = false 
				else:
					motion.x = max(motion.x - ACC, -MAX_SPEED) 
					$AnimatedSprite.flip_h = true 
				
				$AnimatedSprite.play("walk")
			
			var will_melee_this_frame = false
			if $MeleeRayCast.is_colliding():
				MeleeObjective = $MeleeRayCast.get_collider()
				if MeleeObjective in get_tree().get_nodes_in_group("player"):
					state = "Melee"
					is_attacking = true
					will_melee_this_frame = true
					$AnimatedSprite.play("attack")
					MeleeObjective.hit(MELEE_DMG)
			
			var will_shoot_this_frame = false
			if not will_melee_this_frame and $RangedRayCast.is_colliding():
				
				var RangedObjective = $RangedRayCast.get_collider()
				if RangedObjective in get_tree().get_nodes_in_group("player"):
					state = "Ranged"
					is_attacking = true
					will_shoot_this_frame = true
					$AnimatedSprite.play("shoot")
					motion = Vector2(0,0)
					
					var arrow = ARROW.instance() # Creació de l'objecte
					
					if sign($Position2D.position.x) == 1:
						arrow.set_arrow_direction(1)
					else:
						arrow.set_arrow_direction(-1)

					get_parent().add_child(arrow)
					
					arrow.position = $Position2D.global_position
					
			
			if not will_melee_this_frame and not will_shoot_this_frame and $MagicRayCast.is_colliding():
				
				var MagicObjective = $MagicRayCast.get_collider()
				if MagicObjective in get_tree().get_nodes_in_group("player"):
					state = "Magic"
					is_attacking = true
					$AnimatedSprite.play("shoot")
					motion = Vector2(0,0)
					
					
					var fireball = FIREBALL.instance() # Creació de l'objecte! (com new de C)
					
					if sign($Position2D.position.x) == 1:
						fireball.set_fireball_direction(1)
					else:
						fireball.set_fireball_direction(-1)

					get_parent().add_child(fireball)
					
					fireball.position = $Position2D.global_position
		
		if is_being_hit or is_idle:
			motion = Vector2(0,0)
		motion = move_and_slide(motion, UP)
	
	$Label.text = state
	
	
	############################### COLLISION DAMAGE ###########################
	#if get_slide_count() > 0:
	#		for i in range(get_slide_count()):
	#			if "Player" in get_slide_collision(i).collider.name:
	#				#get_slide_collision(i).collider.die()
	#				get_slide_collision(i).collider.hit(DMG)
	############################################################################

# TODO: on_animation_finished: state = "Walking"

func _on_Despawn_timeout():
	queue_free()


func _on_animation_finished():
	is_attacking = false
	is_being_hit = false
