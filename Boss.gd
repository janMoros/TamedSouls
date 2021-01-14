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

export var max_hp = 2
var hp
export var max_sta = 10.0
var sta

var is_being_hit = false
var is_attacking = false
var is_idle = false
var is_alarmed = false
var is_shield_active = false

#var state = "Melee" # or "Magic" or "Ranged"
export(String, "Melee", "Magic", "Ranged") var state = "Melee"

const ARROW = preload("res://Arrow.tscn")
const FIREBALL = preload("res://Fireball.tscn")

const MAGIC_STA = 3
const RANGED_STA = 2
const MELEE_STA = 1
const SHIELD_STA = 8

var MeleeObjective : Object

var player_position = Vector2()
var player_state = "Melee"
var x_dist = 0

var is_positioned = false

var is_about_to_fall = false

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
	
	hp = max_hp
	sta = max_sta
	
func hit(dmg,type,direction):
	if not is_shield_active: # Pels atacs melee del PJ
		hp -= dmg * Global.modifyer(type,state)
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
		#else:
		if not is_positioned:
			motion.x = Global.KNOCKBACK_X * direction
			motion.y = Global.KNOCKBACK_Y
		else:
			motion.x = Global.KNOCKBACK_X * direction
			motion.y = Global.KNOCKBACK_Y * 0.7
			#is_positioned = false

func _physics_process(delta):
	if not is_dead:
#		if hp > 20 * max_hp / 100:
#			$HPBar.modulate = "8cff23"
#		else:
#			$HPBar.modulate = "ff0000"
		
		#if not is_idle: # CAOS
		#	if is_on_wall() or !$RayCast2D.is_colliding(): 
		# QUE TOT VAGI EN FUNCIÓ DE DIRECTION! i canviar la direction només quan interessi, no aqui
		#		change_direction()
		
		if not is_attacking and not is_being_hit and not is_alarmed:
			player_position = get_tree().get_nodes_in_group("player")[0].global_position
			player_state = get_tree().get_nodes_in_group("player")[0].state
			
			# L'estat de l'enemic canvia només aquí (on posteriorment hi haurà la IA que decidirà).
			# Per això, només cal que el nivell afecti aquí.
			match player_state: ################################################ TEMP: CANVIA DIRECTAMENT QUAN HO FA EL JUGADOR
				"Melee":
					if state != "Ranged":
						state = "Ranged"
						is_positioned = false
				"Ranged":
					if state != "Magic":
						state = "Magic"
						is_positioned = false
				"Magic":
					state = "Melee"
			
			x_dist = player_position.x - global_position.x

			match state:
				"Melee":
					is_positioned = false
					########### MOVEMENT
					if x_dist > 0: # Positiu -> player a la dreta de l'enemic
						if direction == -1:
							change_direction()
					else:
						if direction == 1:
							change_direction()
					
					if direction == 1:
						motion.x = min(motion.x + ACC, MAX_SPEED)
					else:
						motion.x = max(motion.x - ACC, -MAX_SPEED) 
					
					if is_on_wall() or (!$RayCast2D.is_colliding() and is_on_floor()):
						motion = Vector2(0,0)
						$AnimatedSprite.play("idle")
					else:
						$AnimatedSprite.play("walk")
					
					########### ATTACK
					if not is_shield_active and $MeleeRayCast.is_colliding():
						MeleeObjective = $MeleeRayCast.get_collider()
						if MeleeObjective in get_tree().get_nodes_in_group("player") and (sta - MELEE_STA >= 0):
							$StaRegen.start()
							sta -= MELEE_STA
							is_attacking = true
							$AnimatedSprite.play("attack")
							#motion = Vector2(0,0)
							motion.x = 0
							MeleeObjective.hit(MELEE_DMG,"Melee",direction)
				"Ranged":
					########### MOVEMENT (de moment, que vagi a full cap a la dreta, parlar amb el Jorge)
					if not is_positioned:
						var prev_dir = direction
						if direction == -1:
							change_direction()
						
						# Sí o sí direction serà 1 (dreta)
						motion.x = min(motion.x + ACC, MAX_SPEED)
						$AnimatedSprite.play("walk")
						
						if prev_dir == 1:
							if is_on_wall() or (!$RayCast2D.is_colliding() and is_on_floor()):
								motion = Vector2(0,0)
								is_positioned = true
						
					else: # Si ja està a posició, rotar en funció del player
						if x_dist > 0: # Positiu -> player a la dreta de l'enemic
							if direction == -1:
								change_direction()
						else:
							if direction == 1:
								change_direction()
								
						$AnimatedSprite.play("idle")
					
					
					########### ATTACK
					if not is_shield_active and $RangedRayCast.is_colliding():
						var RangedObjective = $RangedRayCast.get_collider()
						if RangedObjective in get_tree().get_nodes_in_group("player") and (sta - RANGED_STA >= 0):
							$StaRegen.start()
							sta -= RANGED_STA
							is_attacking = true
							$AnimatedSprite.play("shoot")
							#motion = Vector2(0,0)
							motion.x = 0
							
							var arrow = ARROW.instance() # Creació de l'objecte
							
							arrow.launcher = "enemy"
							
							if sign($Position2D.position.x) == 1:
								arrow.set_arrow_direction(1)
							else:
								arrow.set_arrow_direction(-1)

							get_parent().add_child(arrow)
							
							arrow.position = $Position2D.global_position
				"Magic":
					########### MOVEMENT (de moment, va a full cap a la dreta)
					if not is_positioned:
						var prev_dir = direction
						if direction == -1:
							change_direction()
						
						# Sí o sí direction serà 1 (dreta)
						motion.x = min(motion.x + ACC, MAX_SPEED)
						$AnimatedSprite.play("walk")
						
						if prev_dir == 1:
							if is_on_wall() or (!$RayCast2D.is_colliding() and is_on_floor()):
								motion = Vector2(0,0)
								is_positioned = true
						
					else: # Si ja està a posició, rotar en funció del player
						
						if x_dist > 0: # Positiu -> player a la dreta de l'enemic
							if direction == -1:
								change_direction()
						else:
							if direction == 1:
								change_direction()
								
						$AnimatedSprite.play("idle")
			
					########### ATTACK
					if not is_shield_active and $MagicRayCast.is_colliding():
						var MagicObjective = $MagicRayCast.get_collider()
						if MagicObjective in get_tree().get_nodes_in_group("player") and (sta - MAGIC_STA >= 0):
							$StaRegen.start()
							sta -= MAGIC_STA
							
							is_attacking = true
							$AnimatedSprite.play("shoot")
							#motion = Vector2(0,0)
							motion.x = 0
							
							var fireball = FIREBALL.instance() # Creació de l'objecte! (com new de C)
							
							fireball.launcher = "enemy"
							
							if sign($Position2D.position.x) == 1:
								fireball.set_fireball_direction(1)
							else:
								fireball.set_fireball_direction(-1)

							get_parent().add_child(fireball)
							
							fireball.position = $Position2D.global_position
			
			if direction == 1:
				$AnimatedSprite.flip_h = false
			else:
				$AnimatedSprite.flip_h = true 
		
		# OJUT que està fora del check de is_being hit
		if is_positioned and !is_on_floor() and !is_about_to_fall: # Si marca com posicionat però no toca el terra
			is_about_to_fall = true
		
		if is_about_to_fall:
			motion.x = max(motion.x - ACC, -MAX_SPEED*0.5) # Intentar salvar-se anant a l'esquerra
		
		if is_on_floor() and is_about_to_fall:
			is_about_to_fall = false
			is_positioned = false
		
		motion.y += G
		#if is_being_hit or is_idle:
		if is_idle or is_alarmed:
			motion = Vector2(0,0)
		motion = move_and_slide(motion, UP)
		if get_slide_count() > 0:
			for i in range(get_slide_count()):
				if get_slide_collision(i).collider in get_tree().get_nodes_in_group("instakill") and not is_dead:
					hit(1000, "Melee", 1)
		
	$StateLabel.text = state
	$Label2.text = str(sta)
	#print($AnimatedSprite.get_animation())
	#print(is_attacking)
	
	############################### COLLISION DAMAGE ###########################
	#if get_slide_count() > 0:
	#		for i in range(get_slide_count()):
	#			if "Player" in get_slide_collision(i).collider.name:
	#				#get_slide_collision(i).collider.die()
	#				get_slide_collision(i).collider.hit(DMG)
	############################################################################
	
	########### PATROL MOVEMENT ################################################
#	if is_idle:
#		$AnimatedSprite.play("idle")
#	elif not is_being_hit:
#
#		if is_on_wall() or !$RayCast2D.is_colliding():
#			change_direction()
#
#		if direction == 1:
#			motion.x = min(motion.x + ACC, MAX_SPEED)
#		else:
#			motion.x = max(motion.x - ACC, -MAX_SPEED) 
#
#		$AnimatedSprite.play("walk")
	############################################################################

# TODO: on_animation_finished: state = "Walking"


func change_direction():
	direction *= -1
	$RayCast2D.position.x *= -1
	$MeleeRayCast.cast_to.x *= -1
	$Position2D.position.x *= -1
	$RangedRayCast.cast_to.x *= -1
	$RangedRayCast.position.x *= -1
	$MagicRayCast.cast_to.x *= -1
	$MagicRayCast.position.x *= -1

func _on_Despawn_timeout():
	queue_free()


func _on_animation_finished():
	is_attacking = false
	is_being_hit = false
	is_alarmed = false


func _on_StaRegen_timeout():
	if sta + 1 <= max_sta: # Ojut el hardcode
		sta = sta + 1


func _on_Shield_area_entered(area):
	if area.is_in_group("projectile"):
		area.queue_free()


func _on_ShieldTimer_timeout():
	is_shield_active = false
	$Shield.visible = false
	#$Shield/CollisionShape2D.disabled = true
	$Shield/CollisionShape2D.set_deferred("disabled",true)


func _on_VisionCone_area_entered(area):
	if not is_dead and area.is_in_group("projectile") and not is_shield_active:
		if area.launcher == "player":
			if (sta - SHIELD_STA >= 0):
				$StaRegen.start()
				sta -= SHIELD_STA
				is_shield_active = true
				$Shield/Timer.start()
				$Shield.visible = true
				#$Shield/CollisionShape2D.disabled = true
				$Shield/CollisionShape2D.set_deferred("disabled",true)
