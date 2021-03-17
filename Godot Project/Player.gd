extends KinematicBody2D

var motion = Vector2()
const MAX_SPEED = 400
const G = 10
const JUMP_FORCE = -400
const ACC = 50
const UP = Vector2(0,-1) # Vector que apunta cap a dalt
const RESPAWN_PRICE = 250

var is_attacking = false # L'acció de beure estus entra aquí també
var is_dead = false
var is_contact_on_CD = false
var is_being_hit = false
var is_in_deathScreen = false

export (NodePath) var SpawnPath  

const FIREBALL = preload("res://Fireball.tscn")
const ARROW = preload("res://Arrow.tscn")

export var max_hp = 10.0
export var max_sta = 10.0
export var max_estus = 5
onready var hp = max_hp
onready var sta = max_sta
onready var estus = max_estus

var souls = 1000 # Quan hi hagi sistema de guardat, treure'l d'allà


const MAGIC_STA = 3
const RANGED_STA = 2
const MELEE_STA = 1

export var MELEE_DMG = 1

var state = "Melee" # or "Magic" or "Ranged"

var SaveData
var start_position

var cages_cleared = 0

var barrier

var time = 0

func _ready():
	$CanvasLayer/FadeOut/AnimationPlayer.play("fade_out")
	if SaveData != null:
		hp = SaveData["hp"]
		estus = SaveData["estus"]
		sta = SaveData["sta"]
		souls = SaveData["souls"]
		cages_cleared = SaveData["cages_cleared"]
		time = SaveData["time"]
	if start_position != null:
		global_position = start_position
		
	barrier = $"../Barrier"

func _process(delta): # aquest s'executa si o si 60 cops per segon
	if not is_dead:
		time += delta
		var seconds = fmod(time,60)
		var minutes = time / 60
		$CanvasLayer/TimerGUI/Label.text = "%02d:%02d" % [minutes, seconds]

func _physics_process(_delta):
	motion.y += G
	
	if not "test" in get_parent().name:
		if $Camera2D.limit_left < global_position.x - 464:
			$Camera2D.limit_left = global_position.x - 464 # ojut el hardcore
			barrier.global_position.x = global_position.x - 464 - 5
	
	if not is_dead:
		#if Input.is_action_pressed("ui_back_to_menu"):
		if Input.is_action_just_pressed("ui_back_to_menu"):
			get_tree().change_scene("res://Menu.tscn")
		
		var friction = false
		if Input.is_action_pressed("ui_right"):
			motion.x = min(motion.x+ACC,MAX_SPEED)
			$Sprite.flip_h = false;
			if is_attacking == false && is_being_hit == false:
				$Sprite.play("run")
				if sign($Position2D.position.x) == -1: # Si és negativa (a l'esq del pj)
					$Position2D.position.x *= -1       # Li canvia el signe (*-1)
					$MeleeRayCast.cast_to.x *= -1 # M'aprofito perquè sempre estaran igual
				# Funciona perquè el pj està centrat

		elif Input.is_action_pressed("ui_left"):
			motion.x = max(motion.x-ACC,-MAX_SPEED)
			$Sprite.flip_h = true;
			if is_attacking == false && is_being_hit == false:
				$Sprite.play("run")
				if sign($Position2D.position.x) == 1: # Si és positiva (a la dre del pj)
					$Position2D.position.x *= -1       # Li canvia el signe (*-1)
					$MeleeRayCast.cast_to.x *= -1

		else:
			if is_attacking == false && is_being_hit == false:
				$Sprite.play("idle")
			friction = true
		
		
		
		if is_on_floor():
			if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_a_button"):
				motion.y = JUMP_FORCE
			if friction:
				motion.x = lerp(motion.x,0,0.2) # linear interpolation
				# Anem de motion.x a 0 un 20% cada frame
		else: 
			if is_attacking == false && is_being_hit == false:
				if motion.y < 0:
					$Sprite.play("jump")
				else:
					$Sprite.play("fall")	
			if friction:
				motion.x = lerp(motion.x,0,0.05)
		# Perquè funcioni is_on_floor (a dalt), se li ha de passar a move_and_slide
		# Un vector apuntant cap a dalt perquè sàpiga en quina direcció està el terra
		# move_and_slide retorna la posició després de fer el moviment, havent calculat col·lisions
		#motion = move_and_slide(motion, UP) # Aquest mètode (de kb2D) ja té en compte delta
		
		if Input.is_action_just_pressed("ui_fire") && is_attacking == false:
			# $StaRegen.start() # Tornar a començar 
			match state:
				"Magic":
					if sta - MAGIC_STA >= 0:
						$StaRegen.start() # Tornar a començar 
						sta -= MAGIC_STA
						$CanvasLayer/GUI.update_sta(sta)
						
						is_attacking = true
						$Sprite.play("shoot")
						
						var fireball = FIREBALL.instance() # Creació de l'objecte! (com new de C)
						
						fireball.launcher = "player"
						
						if sign($Position2D.position.x) == 1:
							fireball.set_fireball_direction(1)
						else:
							fireball.set_fireball_direction(-1)

						get_parent().add_child(fireball)
						
						fireball.position = $Position2D.global_position
				"Ranged":
					if sta - RANGED_STA >= 0:
						$StaRegen.start() # Tornar a començar 
						sta -= RANGED_STA
						$CanvasLayer/GUI.update_sta(sta)
						
						is_attacking = true
						$Sprite.play("shoot") # PROVISIONAL
						
						var arrow = ARROW.instance() # Creació de l'objecte
						
						arrow.launcher = "player"
						
						if sign($Position2D.position.x) == 1:
							arrow.set_arrow_direction(1)
						else:
							arrow.set_arrow_direction(-1)

						get_parent().add_child(arrow)
						
						arrow.position = $Position2D.global_position
				"Melee":
					if sta - MELEE_STA >= 0:
						$StaRegen.start() # Tornar a començar 
						sta -= MELEE_STA
						$CanvasLayer/GUI.update_sta(sta)
						
						is_attacking = true
						$Sprite.play("melee")

						if $MeleeRayCast.is_colliding():
							var col = $MeleeRayCast.get_collider()
							if col in get_tree().get_nodes_in_group("enemies"):
								col.hit(MELEE_DMG,"Melee", sign($Position2D.position.x))

		if Input.is_action_just_pressed("ui_drinkEstus")\
		 && is_attacking == false && is_being_hit == false:
			if estus - 1 >= 0 and hp < max_hp: #ojut
				estus -= 1
				$CanvasLayer/GUI.update_estus(estus)
				is_attacking = true
				$Sprite.play("drink")
				heal(5)
		
		
		if Input.is_action_just_pressed("ui_chngModeRight"):
			match state:
				"Magic":
					state = "Ranged"
				"Ranged":
					state = "Melee"
				"Melee":
					state = "Magic"
		
		if Input.is_action_just_pressed("ui_chngModeLeft"):
			match state:
				"Magic":
					state = "Melee"
				"Ranged":
					state = "Magic"
				"Melee":
					state = "Ranged"
		
		
		########################################################################
		##############################DEBUG#####################################
		if OS.is_debug_build() and Input.is_action_just_pressed("debug_save"):
			Save.save_data(hp,estus,sta,souls,cages_cleared,time)
			print("data saved")
		########################################################################
		########################################################################
		
		
		#if get_slide_count() > 0:
		#	for i in range(get_slide_count()):
		#		if get_slide_collision(i).collider in get_tree().get_nodes_in_group("enemies"):
		#			die()
		
		#if Input.is_action_just_pressed("ui_respawn"): [de moment desactivo el respawn durant el joc]
		#	respawn()

		$Label.text = state
		
	elif is_in_deathScreen: # Si està mort I a la deathScreen
		$CanvasLayer/ColorRect.visible = true
		
		if Global.controller_connected:
			$CanvasLayer/ColorRect/CanPay/Start.visible = true
			$CanvasLayer/ColorRect/CanPay.text = "HAS MORT\n\nPREM   ·   PER REVIURE\n[250 ÀNIMES]\n"
			$CanvasLayer/ColorRect/CantPay/Start.visible = true
			$CanvasLayer/ColorRect/CantPay.text = "HAS MORT\n\nNO TENS LES 250 ÀNIMES \nNECESSÀRIES PER REVIURE\n\nPREM   ·   PER \nMORIR DEFINITIVAMENT"
		else:
			$CanvasLayer/ColorRect/CanPay/Start.visible = false
			$CanvasLayer/ColorRect/CanPay.text = "HAS MORT\n\nPREM ENTER PER REVIURE\n[250 ÀNIMES]\n"
			$CanvasLayer/ColorRect/CantPay/Start.visible = false
			$CanvasLayer/ColorRect/CantPay.text = "HAS MORT\n\nNO TENS LES 250 ÀNIMES \nNECESSÀRIES PER REVIURE\n\nPREM ENTER PER \nMORIR DEFINITIVAMENT\n"

		
		if souls - RESPAWN_PRICE >= 0:
			$CanvasLayer/ColorRect/CanPay.visible = true
			$CanvasLayer/ColorRect/CantPay.visible = false
			
			if Input.is_action_just_pressed("ui_respawn"):
				spend_souls(RESPAWN_PRICE)
				var temp_data =  Save.load_data()
				if typeof(temp_data) != TYPE_DICTIONARY: # si no s'ha carregat bé
					SaveData["souls"] = souls
					SaveData["time"] = time
					Save.save_dict_data(SaveData) # Guardem el que hem carregat al principi
					print(SaveData)
				else:
					temp_data["souls"] = souls
					temp_data["time"] = time
					Save.save_dict_data(temp_data)
				
				respawn()
		else:
			$CanvasLayer/ColorRect/CanPay.visible = false
			$CanvasLayer/ColorRect/CantPay.visible = true
			if Input.is_action_just_pressed("ui_respawn"):
				Save.delete_data()
				get_tree().quit(0)
		
	else: # Si està mort pero no a la deathScreen. 
		# Fricció perquè no es mogui infinitament pel knockback
		if motion.x > 0:
			motion.x -= 2
		elif motion.x < 0:
			motion.x += 2
		
	motion = move_and_slide(motion, UP)
	if get_slide_count() > 0:
		for i in range(get_slide_count()):
			if get_slide_collision(i).collider in get_tree().get_nodes_in_group("instakill") and not is_dead:
				die()

func respawn():
#	is_dead = false
#	is_in_deathScreen = false
#	$CanvasLayer/ColorRect.visible = false
#	$CollisionShape2D.rotation_degrees = 0
	get_tree().reload_current_scene()

func die():
	if is_dead == false: # Per si es repeteix la crida
		
		is_dead = true
		motion = Vector2(0,0)
		$Sprite.play("dead")
		position = Vector2(position.x, position.y + 24)
		$CollisionShape2D.rotation_degrees = 90
		$DeadTimer.start()
		#$CollisionShape2D.set_deferred("disabled", true)

func hit(dmg,type,direction, from_boss=false):
	if not is_dead: # not is_contact_on_CD and not is_dead: [HO DEIXO AIXI DE MOMENT SENSE ELIMINAR
		is_contact_on_CD = true                            # L'ESTRUCTURA DEL CD PER SI CAL + TARD]
		is_being_hit = true
		$ContactCD.start()
		$Sprite.play("hit")
		
		
		if type == "Jump":
			# commented for god mode
			hp -= dmg
			
			if hp > 0:
				$CanvasLayer/GUI.update_hp(hp)
				motion.x = Global.KNOCKBACK_X * direction * 7
				motion.y = Global.KNOCKBACK_Y
			else:
				$CanvasLayer/GUI.update_hp(0)
				motion.x = Global.KNOCKBACK_X * direction
				die()
				
			
		else:
			# commented for god mode
			hp -= dmg * Global.modifyer(type,state)
			
			if hp > 0:
				$CanvasLayer/GUI.update_hp(hp)
			else:
				$CanvasLayer/GUI.update_hp(0)
				die()
			
			if from_boss:
				motion.x = Global.KNOCKBACK_X * direction * 5
				motion.y = Global.KNOCKBACK_Y * 3
			else:	
				motion.x = Global.KNOCKBACK_X * direction
				motion.y = Global.KNOCKBACK_Y

func heal(points):
	hp = min(hp + points, max_hp)
	$CanvasLayer/GUI.update_hp(hp)

func recover_sta(points):
	sta = min(sta + points, max_sta)
	$CanvasLayer/GUI.update_sta(sta)

func refill_estus():
	estus = max_estus
	$CanvasLayer/GUI.update_estus(estus)

func spend_souls(num): # Return 0 if possible, -1 if not
	if souls - num >= 0:
		souls -= num
		$CanvasLayer/GUI.update_souls(souls)
		return 0
	else:
		return -1

func recieve_souls(num):
	souls += num
	$CanvasLayer/GUI.update_souls(souls)

func _on_Sprite_animation_finished():	
	is_attacking = false
	is_being_hit = false

func _on_DeadTimer_timeout():
	#respawn()
	is_in_deathScreen = true

func _on_ContactCD_timeout():
	is_contact_on_CD = false

func _on_StaRegen_timeout():
	if sta + 0.75 <= max_sta: # Ojut el hardcode
		sta = sta + 0.75
		$CanvasLayer/GUI.update_sta(sta)



func _on_FadeOut_animation_finished(anim_name):
	$CanvasLayer/FadeOut.hide()
