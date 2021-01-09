extends Area2D

var is_inside = false
var is_opened = false
var player
const PRICE = 420

func _physics_process(delta):
	if is_inside and not is_opened:
		if Input.is_action_just_pressed("ui_interact") and\
		 not player.is_being_hit and not player.is_attacking and not player.is_dead: 
			if player.souls - PRICE >= 0:
				player.spend_souls(PRICE)
				$Cage.visible = false
				$AnimatedSprite.play("dance")
				$DespawnTimer.start()
				$Label.visible = false
				is_opened = true
				player.cages_cleared += 1
				# Guardar a algun lloc que aquest ja ha sigut rescatat (per posar-ho dps a save.dat)
				
func _on_Cage_body_entered(body):
	if not is_opened:
		if body.is_in_group("player"):
			is_inside = true
			$Label.visible = true
			player = body


func _on_Cage_body_exited(body):
	if not is_opened:
		if body.is_in_group("player"):
			is_inside = false
			$Label.visible = false


func _on_DespawnTimer_timeout():
	queue_free()
