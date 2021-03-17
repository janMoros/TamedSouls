extends KinematicBody2D

var motion = Vector2(0,0)
export var MAX_SPEED = 400
export var G = 10
export var JUMP_FORCE = -400
export var ACC = 50
export var MELEE_DMG = 1
export var RANGED_DMG = 2
export var MAGIC_DMG = 3
export var soul_value = 1000
const UP = Vector2(0,-1)

export var direction = 1
var is_dead = false

export var max_hp = 2
var hp
var starting_hp
export var max_sta = 10.0
var sta

var is_being_hit = false
var is_attacking = false
var is_idle = false

var state = "Wait" 
#var state = "Lightning" # "Jump" "Minions"

const MAGIC_STA = 3
const RANGED_STA = 2
const MELEE_STA = 1

var MeleeObjective : Object

var player_position = Vector2()
var x_dist = 0

var JUMP_DMG = 5
var is_jumping = false
var jump_order = false
var jump_timer = false

const MINION = preload("res://Minion.tscn")
var must_move = false 
var prev_dist = 0
const MAX_MINIONS = 7
var minion_order = false
var is_launching = false

const LIGHTNING = preload("res://DebugTesting/Lightning.tscn")
const TARGET = preload("res://LightningTarget.tscn")
var is_positioned = false
var can_zap_spawn = false # can spawn lightning and target?

var player

func _ready():
	if MAX_SPEED == 0:   # TEMPORAL PER DIFERENCIAR ENEMICS ESTÀTICS
		is_idle = true
		$AnimatedSprite.position.y = $AnimatedSprite.position.y + 3 # OJUT
	
	if direction == -1:
		$RayCast2D.position.x *= -1
		$MeleeRayCast.cast_to.x *= -1
		$Position2D.position.x *= -1
		$AnimatedSprite.flip_h = true 
		$WallRaycast.cast_to.x *= -1
		$MinionSpawn.position.x *= -1
		$FrontWallRaycast.cast_to.x *= -1
	
	sta = max_sta
	
	player = get_tree().get_nodes_in_group("player")[0]
	
	starting_hp = max_hp - 0.15 * max_hp * player.cages_cleared
	
	#hp = max_hp
	hp = starting_hp
	
func hit(dmg,type,direction):
	var fake_state
	match state:
		"Jump": fake_state = "Melee"
		"Minions": fake_state = "Magic"
		"Lightning": fake_state = "Magic"
		"Wait": fake_state = "Melee" # NO HAURIA DE PASSAR MAI
	
	hp -= dmg * Global.modifyer(type,fake_state)
	# $HPBar.value = hp * 100 / max_hp
		
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
		motion.x = Global.KNOCKBACK_X * direction
		motion.y = Global.KNOCKBACK_Y

func _physics_process(delta):
	motion.y += G
	if not is_dead:	
		$HPBar.value = hp * 100 / max_hp
		if not is_attacking and not is_being_hit:
			
			##### CANVI D'ESTAT SEGONS LA VIDA
			#if hp > 20 * max_hp / 100:
			
			if hp > starting_hp * 2/3:
				$HPBar.modulate = "#31a124"
				# El canvi a mode Jump es fa automàticament
			elif hp > starting_hp * 1/3:
				$HPBar.modulate = "#f39b2b"
				state = "Minions"
			elif state != "Lightning": # i hp < 1/3 de starting
				$HPBar.modulate = "#b00000"
				state = "Lightning"
				can_zap_spawn = true
			
			if OS.is_debug_build():
				if Input.is_action_just_pressed("debug_right"):
					""" 
					match state:
						"Wait": state = "Jump"
						"Jump": state = "Minions"
						"Minions": 
							state = "Lightning"
							can_zap_spawn = true
						"Lightning": state = "Wait"
					"""
					if hp > starting_hp * 2/3:
						hp = starting_hp
					elif hp > starting_hp * 1/3:
						hp = starting_hp * 2/3 + 1
						state = "Jump"
					else:
						hp = starting_hp * 1/3 + 1
				
				if Input.is_action_just_pressed("debug_left"):
					if hp < starting_hp * 1/3:
						hp = 0
					elif hp < starting_hp * 2/3:
						hp = starting_hp * 1/3 - 1
					else:
						hp = starting_hp * 2/3 - 1
				
			if Global.lightning_target != null and state != "Lightning":
				Global.lightning_target.queue_free()
				Global.lightning_target = null
			
			if Global.lightning != null and state != "Lightning":
				Global.lightning.queue_free()
				Global.lightning = null
			
			player_position = player.global_position
			x_dist = player_position.x - global_position.x
			
			match state:
				"Jump":
					
					is_positioned = false
					
					if x_dist < 0:
						#direction = -1
						if direction == 1:
							change_direction()
					else:
						#direction = 1
						if direction == -1:
							change_direction()
						
					
					#if Input.is_action_pressed("debug_up"):
					if jump_order:
						jump_order = false
						is_jumping = true
						motion = Vector2(x_dist*0.75, -400)
						$AnimatedSprite.play("jump")
					
					var can_do_damage = false
					if is_jumping and motion.y >= 0: # Si està a l'aire i movent-se cap avall
						$AnimatedSprite.play("fall")
						can_do_damage = true
					
					if get_slide_count() > 0 and can_do_damage:
						for i in range(get_slide_count()):
							var collision = get_slide_collision(i)
							if "Player" in collision.collider.name and can_do_damage:
								player_position = get_tree().get_nodes_in_group("player")[0].global_position
								x_dist = player_position.x - global_position.x
								var direction = -1
								if x_dist > 0:
									direction = 1 
								get_slide_collision(i).collider.hit(JUMP_DMG, "Jump", direction)
								is_jumping = false
								can_do_damage = false
								motion = motion.bounce(collision.normal)
								#motion.y *= 3
					
					
					#if is_on_floor() and not is_floor_player:
					if $RayCast2D.is_colliding():
						#print($RayCast2D.get_collider().name)
						if not is_jumping:
							motion.x = 0
							$AnimatedSprite.play("idle")
						if motion.y > 0:
							is_jumping = false
						if not jump_timer:
							$JumpTimer.start()
							jump_timer = true
				
				"Minions":
					
					is_positioned = false
					
					############################################# MOVEMENT #####
					if $WallRaycast.is_colliding() and $RayCast2D.is_colliding() and not must_move:
						if $WallRaycast.get_collider().name == "TileMap":
							motion = Vector2(0,0)
							
							if not is_attacking:
								$AnimatedSprite.play("idle")
							
							if x_dist >= 0 and prev_dist <= 0 or x_dist <= 0 and prev_dist >= 0:
								must_move = true
							
							prev_dist = x_dist
					else:
						must_move = false
						$AnimatedSprite.play("walk")
					
						if x_dist > 0: # Positiu -> player a la dreta de l'enemic
							if direction == -1:
								change_direction()
						else:
							if direction == 1:
								change_direction()
						
						if direction == 1:  # Es mou en direcció contrària a direction (camina endarrere)
							motion.x = max(motion.x - ACC, -MAX_SPEED)
						else:
							motion.x = min(motion.x + ACC, MAX_SPEED) 
					
					############################################# ATTACK #######
					if minion_order:
						minion_order = false
						is_attacking = true
						is_launching = true
						$AnimatedSprite.play("launch")
						# El llançament en si es fa a _on_animation_finished()
					
					if $MeleeRayCast.is_colliding():
						MeleeObjective = $MeleeRayCast.get_collider()
						if MeleeObjective in get_tree().get_nodes_in_group("player") and (sta - MELEE_STA >= 0):
							$StaRegen.start()
							sta -= MELEE_STA
							is_attacking = true
							$AnimatedSprite.play("attack")
							#motion = Vector2(0,0)
							motion.x = 0
							MeleeObjective.hit(MELEE_DMG,"Melee",direction,true) # true <= from_boss

				"Lightning":
					############################################# MOVEMENT #####
					if not is_positioned:
						var prev_dir = direction
						if direction == 1:
							change_direction()
						
						# Sí o sí direction serà -1 (esquerra)
						motion.x = max(motion.x - ACC, -MAX_SPEED)
						$AnimatedSprite.play("walk")
						
						if prev_dir == -1:
							if $FrontWallRaycast.is_colliding() and $RayCast2D.is_colliding():
								#if !($FrontWallRaycast.get_collider() in get_tree().get_nodes_in_group("player")):
								if $FrontWallRaycast.get_collider().name == "TileMap":
									motion = Vector2(0,0)
									is_positioned = true
							
					else: # Si ja està a posició, rotar en funció del player
						if can_zap_spawn:
							can_zap_spawn = false
							# Global.boss_room_limits = [room_left, room_right, room_up, room_down]
							var target = TARGET.instance() # Creació de l'objecte
							target.y_position = Global.boss_room_limits[3] # room_down
							get_parent().add_child(target)
							var lightning = LIGHTNING.instance()
							var aux_node = Node2D.new()
							aux_node.add_child(lightning)
							get_parent().add_child(aux_node)
							aux_node.position = Vector2(Global.boss_room_limits[0], Global.boss_room_limits[2] + 64) #left,up
							Global.lightning = lightning
						
						if x_dist > 0: # Positiu -> player a la dreta de l'enemic
							if direction == -1:
								change_direction()
						else:
							if direction == 1:
								change_direction()
								
						$AnimatedSprite.play("lightning")
					
					############################################# ATTACK #######
					if $MeleeRayCast.is_colliding():
						MeleeObjective = $MeleeRayCast.get_collider()
						if MeleeObjective.is_in_group("player") or MeleeObjective.is_in_group("minions"):
							if (sta - MELEE_STA >= 0):
								$StaRegen.start()
								sta -= MELEE_STA
								is_attacking = true
								$AnimatedSprite.play("attack")
								#motion = Vector2(0,0)
								motion.x = 0
								if MeleeObjective.is_in_group("player"):
									MeleeObjective.hit(MELEE_DMG,"Melee",direction,true) # true <= from_boss
								else:
									MeleeObjective.hit(MELEE_DMG,"Melee",direction)
					
			if direction == 1:
				$AnimatedSprite.flip_h = false
			else:
				$AnimatedSprite.flip_h = true 
		#if is_being_hit or is_idle:
		if is_idle:
			motion = Vector2(0,0)
	else: # if dead
		if Global.lightning_target != null:
			Global.lightning_target.queue_free()
			Global.lightning_target = null
		if Global.lightning != null:
			Global.lightning.queue_free()
			Global.lightning = null
		
		if motion.x > 0:
			motion.x -= 2
		elif motion.x < 0:
			motion.x += 2	
	
	motion = move_and_slide(motion, UP)
	
	$StateLabel.text = state
	#$Label2.text = str(sta)



func change_direction():
	direction *= -1
	$RayCast2D.position.x *= -1
	$MeleeRayCast.cast_to.x *= -1
	$Position2D.position.x *= -1
	$WallRaycast.cast_to.x *= -1
	$MinionSpawn.position.x *= -1
	$FrontWallRaycast.cast_to.x *= -1


func _on_Despawn_timeout():
	#queue_free()
	# FI DEL JOC -> ANIMACIÓ, RANKING, ESBORRAR PARTIDA, SORTIR AL MENU
	Global.final_souls = player.souls
	Global.final_time = player.time
	get_tree().change_scene("res://WinScreen.tscn")
	


func _on_animation_finished():
	if state == "Minions" and is_attacking and is_launching:
		var minion = MINION.instance() # Creació de l'objecte
						
		if sign($Position2D.position.x) == 1:
			minion.direction = 1
		else:
			minion.direction = -1

		get_parent().add_child(minion)
		
		minion.position = $MinionSpawn.global_position
		minion.motion = Vector2(x_dist * 0.75, -200)
	
	is_attacking = false
	is_being_hit = false
	is_launching = false
	
	

func _on_StaRegen_timeout():
	if sta + 1 <= max_sta: # Ojut el hardcode
		sta = sta + 1
	
	# Mesura guarra per evitar que es quedi penjat
	if is_being_hit:
		is_being_hit = false
	
func _on_JumpTimer_timeout():
	if is_on_floor():
		jump_order = true
	jump_timer = false


func _on_MinionTimer_timeout():
	if len(get_tree().get_nodes_in_group("minions")) < MAX_MINIONS:
		minion_order = true
