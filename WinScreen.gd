extends ColorRect

# Called when the node enters the scene tree for the first time.
func _ready():
	$MarginContainer/VBoxContainer/HBoxContainer/LineEdit.grab_focus()



func _on_Button_pressed():
	#save.savehighscore
	
	var player_name = $MarginContainer/VBoxContainer/HBoxContainer/LineEdit.get_text()
	if player_name == "":
		player_name = "-sense nom-"
	
	var length
	match Global.world_size:
		100: length = "Short"
		200: length = "Mid"
		300: length = "Long"
		_: length = "Short" # Default
	
	Save.add_ranking_position(length, player_name, Global.final_time, Global.final_souls)
	
	get_tree().change_scene("res://Ranking.tscn")
