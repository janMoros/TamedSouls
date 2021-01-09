extends Area2D

func _on_something_exited(thing):
	if thing in get_tree().get_nodes_in_group("player"):
		thing.die()
	else:
		if not (thing in get_tree().get_nodes_in_group("enemies") and thing.is_dead):
			thing.queue_free()
