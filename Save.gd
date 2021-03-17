extends Node

const SAVE_DIR = "user://saves/"

var save_path = SAVE_DIR + "Save.dat"

var ranking_path = "user://ranking.dat"

func save_data(hp,estus,sta,souls,cages,time):
	var data = {
		"hp" : hp,
		"estus" : estus,
		"sta" : sta,
		"souls" : souls,
		"cages_cleared": cages,
		"time": time
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


func load_ranking():
	var file = File.new()
	if file.file_exists(ranking_path):
		var error = file.open(ranking_path, File.READ)
		if error == OK:
			var data = file.get_var()
			file.close()
			return data
		else:
			return error
	else: 
		return -1

func add_ranking_position(lenght, player_name, time, souls):
	var current = load_ranking()
	
	var new_entry = {"Name": player_name, "Time": time, "Souls": souls}
	print("New entry! ", new_entry)
	
	if typeof(current) != TYPE_DICTIONARY: # Error o no existeix
		current = { lenght: [new_entry] } # el creem amb el nou
	else:
		if lenght in current:
			var i = 0
			var new_position = 0
			var inserted = false 
			
			for entry in current[lenght]:
				if entry["Time"] > time:
					current[lenght].insert(i, new_entry)
					inserted = true
					break
				i += 1
			
			if not inserted:
				current[lenght].append(new_entry)
			
			while len(current[lenght]) > 5:
				current[lenght].pop_back()
		else:
			current[lenght] = [new_entry]
	
	var file = File.new()
	var error = file.open(ranking_path, File.WRITE)
	if error == OK:
		file.store_var(current)
		file.close()
	else: 
		print("ERROR: ", error)
	
	return error
