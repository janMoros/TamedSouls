extends Area2D

var is_inside = false
var player
const SPAWN_POINT_PRICE = 500
const HEAL_PRICE = 50
const ESTUS_PRICE = 300

var state = "hp" # or "respawn" or "estus"

func _physics_process(delta):
	if is_inside: # ho separo per fer menys comprovacions al llarg del temps
		if not player.is_being_hit and not player.is_attacking and not player.is_dead:
			if Input.is_action_just_pressed("ui_interact"): 
				match state:
					"hp": 
						if player.souls - HEAL_PRICE >= 0 and player.hp < player.max_hp:
							player.spend_souls(HEAL_PRICE)
							player.heal(player.max_hp)
					"estus":
						if player.souls - ESTUS_PRICE >= 0 and player.estus < player.max_estus: 
							player.spend_souls(ESTUS_PRICE)
							player.refill_estus()
					"respawn":
						if player.souls - SPAWN_POINT_PRICE >= 0:
							player.spend_souls(SPAWN_POINT_PRICE)
							print(Save.save_data(player.hp,player.estus,player.sta,player.souls,player.cages_cleared,player.time)) #ojut el position
							#Global.player_save_position = Vector2(global_position.x, global_position.y - 64)
							
							get_parent().get_parent().save_from_campfire(global_position)
							
							print("data saved")
			
			if Input.is_action_just_pressed("ui_right_stick_up"): 
				match state:
					"estus":
						state = "hp"
						$hp.visible = true
						$respawn.visible = false
						$estus.visible = false
					"respawn":
						state = "estus"
						$hp.visible = false
						$respawn.visible = false
						$estus.visible = true
			
			if Input.is_action_just_pressed("ui_right_stick_down"): 
				match state:
					"hp":
						state = "estus"
						$hp.visible = false
						$respawn.visible = false
						$estus.visible = true
					"estus":
						state = "respawn"
						$hp.visible = false
						$respawn.visible = true
						$estus.visible = false
			
		
func _on_Campfire_body_entered(body):
	if body.is_in_group("player"):
		is_inside = true
		player = body
		match state:
			"hp": 
				$hp.visible = true
				$respawn.visible = false
				$estus.visible = false
			"respawn": 
				$hp.visible = false
				$respawn.visible = true
				$estus.visible = false
			"estus": 
				$hp.visible = false
				$respawn.visible = false
				$estus.visible = true
		
		if Global.controller_connected:
			$hp/B.visible = true
			$hp/B_key.visible = false
			$respawn/B.visible = true
			$respawn/B_key.visible = false
			$estus/B.visible = true
			$estus/B_key.visible = false
		else:
			$hp/B.visible = false
			$hp/B_key.visible = true
			$respawn/B.visible = false
			$respawn/B_key.visible = true
			$estus/B.visible = false
			$estus/B_key.visible = true

func _on_Campfire_body_exited(body):
	if body.is_in_group("player"):
		is_inside = false
		
		$hp.visible = false
		$respawn.visible = false
		$estus.visible = false
