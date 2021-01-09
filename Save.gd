extends Node

const SAVE_DIR = "user://saves/"

var save_path = SAVE_DIR + "Save.dat"

func save_data(hp,estus,sta,souls,cages):
	var data = {
		"hp" : hp,
		"estus" : estus,
		"sta" : sta,
		"souls" : souls,
		"cages_cleared": cages
	}
	print(data)
	var dir = Directory.new()
	if !dir.dir_exists(SAVE_DIR):
		dir.make_dir_recursive(SAVE_DIR)
	
	var file = File.new()
	var error = file.open(save_path, File.WRITE)
	if error == OK:
		file.store_var(data)
		file.close()
	else: 
		print(error)
	
	return error

func save_dict_data(data):
	var dir = Directory.new()
	if !dir.dir_exists(SAVE_DIR):
		dir.make_dir_recursive(SAVE_DIR)
	
	var file = File.new()
	var error = file.open(save_path, File.WRITE)
	if error == OK:
		file.store_var(data)
		file.close()
	else: 
		print(error)
	
	return error

func load_data():
	var file = File.new()
	if file.file_exists(save_path):
		var error = file.open(save_path, File.READ)
		if error == OK:
			var data = file.get_var()
			file.close()
			return data
		else:
			return error
	else: 
		return -1

func delete_data():
	var dir = Directory.new()
	dir.remove(save_path)
