extends Sprite

var y_position = 64
const DMG = 5

onready var player = get_tree().get_nodes_in_group("player")[0]

const SPEED = 4
const MARGIN = 5

func _ready():
	Global.lightning_target = self
	global_position.y = y_position
	$AnimationPlayer.play("loading")
	global_position.x = player.global_position.x
	
func _physics_process(delta):
	#global_position.x = get_global_mouse_position().x
	#var target = get_global_mouse_position().x
	var target = player.global_position.x
	
	var dist_x = target - global_position.x
	
	if dist_x < -MARGIN: # a l'esquerra
		global_position.x -= SPEED
	elif dist_x > MARGIN: # a la dreta
		global_position.x += SPEED
	# else == 0, no cal fer res
	


func _on_animation_finished(anim_name):
	if Global.lightning != null:
		Global.lightning.global_zap(global_position, 48) # Offset
		for body in $Area2D.get_overlapping_bodies():
			if body.has_method("hit") and !body.is_in_group("boss"):
				body.hit(DMG, "Magic", 1) # 1 -> Direction (Dreta)
	$AnimationPlayer.play(anim_name)

