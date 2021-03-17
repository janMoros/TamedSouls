extends Node

const SAVE_DIR = "user://saves/"
var save_path = SAVE_DIR + "Save.dat"

export (String, FILE, "*.tscn") var world_scene
export (String, FILE, "*.tscn") var new_world_menu
export (String, FILE, "*.tscn") var controls_scene
export (String, FILE, "*.tscn") var ranking_scene

var scene_to_load

func _ready():
	$Node/HSplit/CenterRow/Buttons/NewGame.grab_focus()
	var file = File.new()
	if not file.file_exists(save_path):
		$Node/HSplit/CenterRow/Buttons/Continue.disabled = true


func _on_NewGame_pressed():
	scene_to_load = new_world_menu
	get_tree().change_scene(scene_to_load)
	#$FadeIn/AnimationPlayer.play("fade_in")
	#$FadeIn.show()


func _on_Continue_pressed():
	scene_to_load = world_scene
	$FadeIn/AnimationPlayer.play("fade_in")
	$FadeIn.show()


func _on_Ranking_pressed():
	scene_to_load = ranking_scene
	get_tree().change_scene(scene_to_load)


func _on_Exit_pressed():
	get_tree().quit(0)

func _on_Boss_pressed():
	get_tree().change_scene("res://World_test.tscn")


func _on_AnimationPlayer_animation_finished(anim_name):
	get_tree().change_scene(scene_to_load)
