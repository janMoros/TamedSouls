extends Area2D

const HEALING_PWR = 5

func _on_HealthPotion_body_entered(body):
	if body.is_in_group("player"):
		if body.hp < body.max_hp:
			body.heal(HEALING_PWR)
			queue_free()
