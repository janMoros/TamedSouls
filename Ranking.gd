extends Node

export (String, FILE, "*.tscn") var menu_scene

# Called when the node enters the scene tree for the first time.
func _ready():
	var short_out = ""
	var mid_out = ""
	var long_out = ""
	
	var ranking = Save.load_ranking()
	
	if typeof(ranking) != TYPE_DICTIONARY:
		short_out = "Encara no hi ha entrades"
		mid_out = "Encara no hi ha entrades"
		long_out = "Encara no hi ha entrades"
	
	else:
		print(ranking)
		if "Short" in ranking:
			for entry in ranking["Short"]:
				var time = entry["Time"]
				var seconds = fmod(time,60)
				var minutes = time / 60
				var time_text = "%02d:%02d" % [minutes, seconds]
				short_out += "%s %s %d à.\n" % [entry["Name"], time_text, entry["Souls"]]
		else:
			short_out = "Encara no hi ha entrades"
		
		if "Mid" in ranking:
			for entry in ranking["Mid"]:
				var time = entry["Time"]
				var seconds = fmod(time,60)
				var minutes = time / 60
				var time_text = "%02d:%02d" % [minutes, seconds]
				mid_out += "%s %s %d à.\n" % [entry["Name"], time_text, entry["Souls"]]
		else:
			mid_out = "Encara no hi ha entrades"
		
		if "Long" in ranking:
			for entry in ranking["Long"]:
				var time = entry["Time"]
				var seconds = fmod(time,60)
				var minutes = time / 60
				var time_text = "%02d:%02d" % [minutes, seconds]
				long_out += "%s %s %d à.\n" % [entry["Name"], time_text, entry["Souls"]]
		else:
			long_out = "Encara no hi ha entrades"
	
	$Node/HSplit/CenterRow/Buttons/HBoxContainer/Curt/Llista.text = short_out
	$Node/HSplit/CenterRow/Buttons/HBoxContainer/Mig/Llista2.text = mid_out
	$Node/HSplit/CenterRow/Buttons/HBoxContainer/Llarg/Llista3.text = long_out
	
	$Node/HSplit/CenterRow/Buttons/Node2/Back.grab_focus()

func _on_Back_pressed():
	get_tree().change_scene(menu_scene)
