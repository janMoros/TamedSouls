extends Node

export (String, FILE, "*.tscn") var world_scene
export (String, FILE, "*.tscn") var menu_scene

# Called when the node enters the scene tree for the first time.
func _ready():
	$Node/HSplit/CenterRow/Buttons/Short.grab_focus()


func _on_Button_pressed(name):
	$FadeIn/AnimationPlayer.play("fade_in")
	$FadeIn.show()
	print(name)
	match name:
		"short":
			Global.world_size = 100
		"mid":
			Global.world_size = 200
		"long":
			Global.world_size = 300
	Save.delete_data()
	
func _on_AnimationPlayer_animation_finished(anim_name):
	get_tree().change_scene(world_scene)


func _on_Back_pressed():
	get_tree().change_scene(menu_scene)
