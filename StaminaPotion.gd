extends Area2D

const RECOVERING_PWR = 5

func _on_HealthPotion_body_entered(body):
	if body.is_in_group("player"):
		if body.sta < body.max_sta:
			body.recover_sta(RECOVERING_PWR)
			queue_free()
