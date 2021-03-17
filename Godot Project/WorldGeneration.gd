extends Node

const SAVE_DIR = "user://saves/"

var save_path = SAVE_DIR + "Tilemaps.dat"

const PLAYER = preload("res://Player.tscn")
const ENEMY = preload("res://Bear.tscn")
const CAMPFIRE = preload("res://Campfire.tscn")
const CAGE = preload("res://Cage.tscn")
#const STAMP = preload("res://Portal.tscn") #OJUT
const STAMP = preload("res://Boss.tscn")

const CELL_SIZE = 64
const TOP_OFFSET = 5

const START_POS = Vector2(0,4)

const LEN_INIT = 10

const MIN_LEN = 2
const MAX_LEN = 7

const MIN_VOID_X = 2
const MAX_VOID_X = 5 
const MAX_VOID_Y = 3
const MIN_VOID_Y = -2 

var WORLD_LEN = 300

const N_CAMPFIRES = 2
onready var N_CAGES = N_CAMPFIRES + 1

const MIN_SPAWN = 4
const SPAWN_CHANCE = 1.0 #OF ENEMIES IF PLATFORM SIZE > MIN_SPAWN

const GROUND = 7
const CEILING = 4

const HALLWAY_LEN = 20
const BOSS_ROOM_X = 13

var room_right
var room_left
var room_up
var room_down

var entrance_position

var rng = RandomNumberGenerator.new()

var platforms = []  # Llista de listes amb format [start_x, end_x, y]
var positives = 0
var negatives = 0

var loaded_data

var player_start_pos = Vector2(0,4)

var length # Of the generated world, as a string

# Called when the node enters the scene tree for the first time.
func _ready():
	#rng.set_seed(42077)
	#player_start_pos = call_deferred("generate_world")
	#return
	
	
	
	loaded_data = Save.load_data()
	if typeof(loaded_data) != TYPE_DICTIONARY: # O hi ha hagut un error o no existeix
		loaded_data = { # TODO: PASSAR AIXÒ A CONSTANTS 
			"hp" : 10,
			"estus" : 5,
			"sta" : 10,
			"souls" : 1000,
			"cages_cleared" : 0,
			"time" : 0
		}
		#print(Save.save_data(max_hp,max_estus,max_sta,global_position,souls))
		print(Save.save_dict_data(loaded_data))
		
		WORLD_LEN = Global.world_size + 20
		
		player_start_pos = call_deferred("generate_world")
		call_deferred("spawn_elements")
		call_deferred("set_borders")
		call_deferred("save_current_cells")

	else:
		call_deferred("load_cells")
		call_deferred("spawn_elements", false)
		call_deferred("set_borders")

func create_void(start_pos:Vector2, length):
	var pos = start_pos
	pos.x += length
	"""
	var positive = rng.randi_range(0,1)
	
	if positive == 1:
		pos.y += rng.randi_range(0, MAX_VOID_Y)
		positives += 1
	else:
		pos.y += rng.randi_range(MIN_VOID_Y, 0)
		negatives += 1
	return pos
	"""

	var top_limit = max(pos.y + MIN_VOID_Y, CEILING)
	var bot_limit = min(pos.y + MAX_VOID_X, GROUND)
	pos.y = rng.randi_range(top_limit, bot_limit)
	return pos


func create_platform(start_pos:Vector2, length):
	var pos = start_pos
	for i in range(length):
		$TileMap.set_cell(pos.x,pos.y,1)
		$TileMap.update_bitmask_area(Vector2(pos.x, pos.y))
		pos.x += 1
	
	platforms.append([start_pos.x, pos.x, pos.y])
	return pos


func generate_ground(bottom):
	#bottom += 1 
	for p in platforms:  # [start_x, end_x, y]
		for block in range(p[0], p[1]):
			for height in range(p[2] + 1, bottom + 1):
				if $TileMap.get_cell(block, height) == -1:
					$TileMap.set_cell(block, height, 1)
					$TileMap.update_bitmask_area(Vector2(block, height))
	
	for i in range(START_POS.x, platforms[-1][1]):
		$TileMap.set_cell(i, bottom + 1, 1)
		$TileMap.set_cell(i, bottom + 2, 1)
		$TileMap.set_cell(i, bottom + 3, 1)
		$TileMap.set_cell(i, bottom + 4, 1)
		$TileMap.update_bitmask_area(Vector2(i, bottom + 1))
		$TileMap.update_bitmask_area(Vector2(i, bottom + 3))
		if $TileMap.get_cell(i, bottom) == -1:
			$Spikes.set_cell(i*2, bottom*2 + 1, 1)
			$Spikes.set_cell(i*2 + 1, bottom*2 + 1, 1)
			$Spikes.update_bitmask_area(Vector2(i*2, bottom*2))

func generate_ceiling():
	"""
	for i in range(START_POS.x, platforms[-1][1]):
		$TileMap.set_cell(i, CEILING - 4, 1)
		$TileMap.set_cell(i, CEILING - 5, 1)
		$TileMap.set_cell(i, CEILING - 6, 1)
		$TileMap.set_cell(i, CEILING - 7, 1)
		$TileMap.update_bitmask_area(Vector2(i, CEILING - 4))
		$TileMap.update_bitmask_area(Vector2(i, CEILING - 6))
	"""
	#var first = all_platforms.pop_front()
	var heights = []
	var prev = platforms[0]
	
	for p in range(platforms.size()): # [start_x, end_x, y]
		
		if prev[2] < platforms[p][2]: # HAS JUMPED
			# Primer bloc de la plataforma a l'alçada de l'anterior
			$TileMap.set_cell(platforms[p][0], prev[2] - 4, 1)
			$TileMap.update_bitmask_area(Vector2(platforms[p][0], prev[2] - 4))
			heights.append(prev[2])
			# Resta de blocs de la plataforma menys l'últim a l'alçada d'aquesta
			for block in range(platforms[p][0] + 1, platforms[p][1] - 1):
				$TileMap.set_cell(block, platforms[p][2] - 4, 1)
				$TileMap.update_bitmask_area(Vector2(block, platforms[p][2] - 4))
				heights.append(platforms[p][2])

		else: # HAS FALLEN OR GONE STRAIGHT
			# Tots els blocs de la plataforma menys l'últim a l'alçada d'aquesta
			for block in range(platforms[p][0], platforms[p][1] - 1):
				$TileMap.set_cell(block, platforms[p][2] - 4, 1)
				$TileMap.update_bitmask_area(Vector2(block, platforms[p][2] - 4))
				heights.append(platforms[p][2])

		
		if p+1 < platforms.size():
			if platforms[p][2] > platforms[p+1][2]: # WILL FALL
				# Últim bloc de la plataforma i tots els del buit a l'alçada del següent
				for block in range(platforms[p][1] - 1, platforms[p+1][0]):
					$TileMap.set_cell(block, platforms[p+1][2] - 4, 1)
					$TileMap.update_bitmask_area(Vector2(block, platforms[p+1][2] - 4))
					heights.append(platforms[p+1][2])

			else: # WILL JUMP OR GO STRAIGHT
				# Últim bloc de la plataforma i tots els del buit a l'alaçda d'aquesta
				for block in range(platforms[p][1] - 1, platforms[p+1][0]):
					$TileMap.set_cell(block, platforms[p][2] - 4, 1)
					$TileMap.update_bitmask_area(Vector2(block, platforms[p][2] - 4))
					heights.append(platforms[p][2])

		prev = platforms[p]
	
	heights.append(platforms[platforms.size() - 1][2])
	
	var max_height = heights.min()
	print(max_height)
	for i in range(START_POS.x, platforms[-1][1]):
		for h in range(max_height - 8, heights[i] - 4):
				$TileMap.set_cell(i, h, 1)
				$TileMap.update_bitmask_area(Vector2(i, h))
				
		if i + 1 < heights.size():
			if heights[i - 1] < heights[i] and heights[i] > heights[i + 1]: # Si és un bloc sol que sobresurt
				$Spikes.set_cell(i*2, (heights[i]-4)*2 + 2, 1, false, true) # El true és per fer un flip_y
				$Spikes.set_cell(i*2 + 1, (heights[i]-4)*2 + 2, 1, false, true)
				$Spikes.update_bitmask_area(Vector2(i*2, (heights[i]-4)*2))
	
	return max_height
	"""
	for i in range(START_POS.x, platforms[-1][1]):
		if i < heights.size():
			$TileMap.set_cell(i, heights[i] - 5, 1)
			$TileMap.set_cell(i, heights[i] - 6, 1)
			$TileMap.set_cell(i, heights[i] - 7, 1)
			$TileMap.set_cell(i, heights[i] - 8, 1)
			$TileMap.update_bitmask_area(Vector2(i, heights[i] - 5))
			$TileMap.update_bitmask_area(Vector2(i, heights[i] - 7))
	"""	

func generate_wall(bottom, max_h):
	for i in range(START_POS.x - 8, START_POS.x):
		for h in range(max_h - 8, bottom + 5):
			$TileMap.set_cell(i, h, 1)
			$TileMap.update_bitmask_area(Vector2(i, h))
			
func clear_entrance(player_position, max_h):
	for i in range(player_position.x - 10, player_position.x + 12):
		for h in range(max_h - 16, player_position.y - 4):
			$TileMap.set_cell(i, h, 1)
			$TileMap.update_bitmask_area(Vector2(i, h))
	
	for h in range(max_h - 16, player_position.y - 1):
		$TileMap.set_cell(player_position.x, h, -1)
		$TileMap.update_bitmask_area(Vector2(player_position.x, h))

func position_campfires(all_platforms):
	# platform = [start_x, end_x, y]
	var campfire_indices = []
	var nPlatforms = all_platforms.size()
	for i in range(1, N_CAMPFIRES+1):
		var index = nPlatforms * i/(N_CAMPFIRES+1)
		var cf_platform = all_platforms[index]
		print("Campfire at platform ",index)
		campfire_indices.append(index)
		var campfire_position = Vector2()
		campfire_position.x = cf_platform[0] + (cf_platform[1] - cf_platform[0]) / 2  # Divisió entera
		campfire_position.y = cf_platform[2] - 1
		$Elements.set_cell(campfire_position.x, campfire_position.y, Global.CAMPFIRE_ID)
		$Elements.update_bitmask_area(Vector2(campfire_position.x, campfire_position.y))
		
	return campfire_indices

func position_cages(all_platforms, campfire_indices):
	var cage_indices = []
	var nPlatforms = all_platforms.size()
	
	var delimiters = [1] + campfire_indices + [nPlatforms-1] # 1 perquè a la 2a plataforma hi hagi un enemic
	#print(delimiters)
	for d in range(delimiters.size()):
		if delimiters[d] != delimiters[-1]:
			var new_cage_index = rng.randi_range(delimiters[d] + 1, delimiters[d+1] - 1)
			cage_indices.append(new_cage_index)
			print("Cage at platform ", new_cage_index)
			var cage_position = Vector2()
			var cage_platform = all_platforms[new_cage_index]
			cage_position.x = cage_platform[0] + (cage_platform[1] - cage_platform[0]) / 2  # Divisió entera
			cage_position.y = cage_platform[2] - 1
			$Elements.set_cell(cage_position.x, cage_position.y, Global.CAGE_ID)
			$Elements.update_bitmask_area(Vector2(cage_position.x, cage_position.y))
	return cage_indices

func position_enemies(all_platforms, campfire_indices, cage_indices):
	var enemy_indices = []
	for i in range(1, all_platforms.size() - 1): # -1 perquè la última forma part del passadís
		# platform = [start_x, end_x, y]
		var plat_size = all_platforms[i][1] - all_platforms[i][0]
		if plat_size >= MIN_SPAWN and !campfire_indices.has(i) and !cage_indices.has(i):
			var prob = rng.randf()
			if prob < SPAWN_CHANCE:
				enemy_indices.append(i)
				var enemy_position = Vector2()
				var enemy_platform = all_platforms[i]
				enemy_position.x = enemy_platform[0] + (enemy_platform[1] - enemy_platform[0]) / 2  # Divisió entera
				enemy_position.y = enemy_platform[2] - 1
				$Elements.set_cell(enemy_position.x, enemy_position.y, Global.ENEMY_ID)
				$Elements.update_bitmask_area(Vector2(enemy_position.x, enemy_position.y))
				
	print("Enemies at platforms ", enemy_indices)
	return enemy_indices

func generate_boss_room():
	# Passadís
	for i in range(platforms[-1][1] - 1, platforms[-1][1] + HALLWAY_LEN):
		# Sostre
		$TileMap.set_cell(i, platforms[-1][2] - 4, 1)
		$TileMap.set_cell(i, platforms[-1][2] - 5, 1)
		$TileMap.set_cell(i, platforms[-1][2] - 6, 1)
		$TileMap.set_cell(i, platforms[-1][2] - 7, 1)
		$TileMap.set_cell(i, platforms[-1][2] - 8, 1)
		$TileMap.set_cell(i, platforms[-1][2] - 9, 1)
		$TileMap.set_cell(i, platforms[-1][2] - 10, 1)
		$TileMap.set_cell(i, platforms[-1][2] - 11, 1)
		$TileMap.update_bitmask_area(Vector2(i, platforms[-1][2] - 4))
		$TileMap.update_bitmask_area(Vector2(i, platforms[-1][2] - 6))
		$TileMap.update_bitmask_area(Vector2(i, platforms[-1][2] - 8))
		$TileMap.update_bitmask_area(Vector2(i, platforms[-1][2] - 10))
		
		# Terra
		$TileMap.set_cell(i, platforms[-1][2], 1)
		$TileMap.set_cell(i, platforms[-1][2] + 1, 1)
		$TileMap.set_cell(i, platforms[-1][2] + 2, 1)
		$TileMap.set_cell(i, platforms[-1][2] + 3, 1)
		$TileMap.set_cell(i, platforms[-1][2] + 4, 1)
		$TileMap.set_cell(i, platforms[-1][2] + 5, 1)
		$TileMap.set_cell(i, platforms[-1][2] + 6, 1)
		$TileMap.update_bitmask_area(Vector2(i, platforms[-1][2] + 1))
		$TileMap.update_bitmask_area(Vector2(i, platforms[-1][2] + 3))
		$TileMap.update_bitmask_area(Vector2(i, platforms[-1][2] + 5))
	
	# Entrance Area2D
	var entrance_position_cell = Vector2(platforms[-1][1] + HALLWAY_LEN, platforms[-1][2] - 1)
	entrance_position = $TileMap.map_to_world(entrance_position_cell, true) # true->ignore half offset
	
	# Sala
	 # Terra i sostre
	for i in range(platforms[-1][1] + HALLWAY_LEN, 
				   platforms[-1][1] + HALLWAY_LEN + BOSS_ROOM_X):
		# Sostre
		$TileMap.set_cell(i, platforms[-1][2] - 4, 1)
		$TileMap.set_cell(i, platforms[-1][2] - 5, 1)
		$TileMap.set_cell(i, platforms[-1][2] - 6, 1)
		$TileMap.set_cell(i, platforms[-1][2] - 7, 1)
		$TileMap.update_bitmask_area(Vector2(i, platforms[-1][2] - 6))
		$TileMap.update_bitmask_area(Vector2(i, platforms[-1][2] - 4))
		
		# Terra
		$TileMap.set_cell(i, platforms[-1][2] + 3, 1)
		$TileMap.set_cell(i, platforms[-1][2] + 4, 1)
		$TileMap.set_cell(i, platforms[-1][2] + 5, 1)
		$TileMap.set_cell(i, platforms[-1][2] + 6, 1)
		$TileMap.update_bitmask_area(Vector2(i, platforms[-1][2] + 3))
		$TileMap.update_bitmask_area(Vector2(i, platforms[-1][2] + 5))
	 
	 # Paret del final
	for i in range(platforms[-1][1] + HALLWAY_LEN + BOSS_ROOM_X, platforms[-1][1] + HALLWAY_LEN + BOSS_ROOM_X + 5):
		for h in range(platforms[-1][2] - 8, platforms[-1][2] + 8):
			$TileMap.set_cell(i, h, 1)
			$TileMap.update_bitmask_area(Vector2(i, h))
	
	
	var room_up_cell = Vector2(0, platforms[-1][2] - 4)
	room_up = $TileMap.map_to_world(room_up_cell, true).y # true->ignore half offset
	var room_down_cell = Vector2(0, platforms[-1][2] + 3)
	room_down = $TileMap.map_to_world(room_down_cell, true).y # true->ignore half offset

	room_left = entrance_position.x
	room_right = entrance_position.x + BOSS_ROOM_X * CELL_SIZE
	
	var stamp_position_x = entrance_position_cell.x + BOSS_ROOM_X - 3
	$Elements.set_cell(stamp_position_x, room_down_cell.y - 1, Global.STAMP_ID)
	$Elements.update_bitmask_area(Vector2(stamp_position_x, room_down_cell.y - 1))
	
	Global.boss_room_limits = [room_left, room_right, room_up, room_down]
	
func generate_world():
	rng.randomize() # Setups a time-based seed to generator [set_seed(s) per posar-la manualment i que sigui igual sempre]
	#rng.set_seed(42077)
	
	var position = create_platform(START_POS, LEN_INIT)
	
	var player_position = START_POS
	#player_position.x += (position.x - START_POS.x) / 2  # Divisió entera
	player_position.x += 1
	player_position.y -= 1
	
	#position = create_void(position, MIN_VOID_X)
	position.x += MIN_VOID_X
	
	position = create_platform(position, MIN_SPAWN)
	
	var prev = 1 # 1=platform, 0=void
	
	var bottom  = position.y
	
	var len_aux
	while position.x < WORLD_LEN:
		if prev == 0: # if previous is void
				len_aux = rng.randi_range(MIN_LEN, MAX_LEN)
				position = create_platform(position, len_aux)
				
				if position.y > bottom:
					bottom = position.y
				
				prev = 1
		else: # if previous is platform
			len_aux = rng.randi_range(MIN_VOID_X, MAX_VOID_X)
			position = create_void(position, len_aux)
			prev = 0
	
	generate_ground(bottom)
	var max_h = generate_ceiling()
	generate_wall(bottom, max_h)
	clear_entrance(player_position, max_h)
	
	print("bottom: ", bottom)
	#print("Falls: ", positives)
	#print("Jumps: ", negatives)
	print("nr of platforms: ", platforms.size())
	
	#$Elements.set_cell(platforms[-1][1] - 1, platforms[-1][2] - 1, Global.STAMP_ID)
	#$Elements.update_bitmask_area(Vector2(platforms[-1][1] - 1, platforms[-1][2] - 1))
	
	$Elements.set_cell(player_position.x, player_position.y - 8, Global.PLAYER_ID)
	$Elements.update_bitmask_area(Vector2(player_position.x, player_position.y))
	
	var campfire_pltfrms = position_campfires(platforms)
	var cage_pltfrms = position_cages(platforms, campfire_pltfrms)
	var enemy_pltfrms = position_enemies(platforms,campfire_pltfrms,cage_pltfrms)
	generate_boss_room()
	#rng.set_seed(42077)
	#return player_position
	
func set_borders():
	var left_most
	var right_most
	var top_most
	var bottom_most 
	
	var is_first = true 
	
	for cell in $TileMap.get_used_cells():
		
		if is_first:
			left_most = cell.x
			top_most = cell.y
			right_most = cell.x + 1 # +1 perquè està en coordenades de la cel·la
			bottom_most = cell.y + 1
			is_first = false
		else:
			if cell.x < left_most:
				left_most = cell.x
			
			if cell.y < top_most:
				top_most = cell.y
			
			if cell.x + 1 > right_most:
				right_most = cell.x + 1
			
			if cell.y + 1 > bottom_most:
				bottom_most = cell.y + 1
				

	#print(left_most," ",right_most," ",top_most," ",bottom_most)
	
	var border_lenght = abs(left_most) + abs(right_most)
	var border_height = abs(top_most) + abs(bottom_most) + TOP_OFFSET
	
	$Borders.scale.x = border_lenght
	$Borders.scale.y = border_height
	
	#print(border_lenght, " ", border_height)
	
	$Borders.position.x = left_most * 64
	
	$Borders.position.y = (top_most - TOP_OFFSET) * 64
	
	#print($Borders.position)
	
func spawn_elements(new_world=true):
	var enemy_cells = []
	for cell in $Elements.get_used_cells():
		var index = $Elements.get_cell(cell.x,cell.y)
		match index:
			Global.PLAYER_ID:
				"""
				if new_world: 
					create_instance(cell,PLAYER,self,loaded_data,player_start_pos)
				else:
				"""
				create_instance(cell, PLAYER,self,loaded_data)
			Global.ENEMY_ID:
				#create_instance(cell,ENEMY,$Enemies)
				enemy_cells.append(cell) # Separat per assegurar-se que els enemics spawnejen més tard que el jugador.
			Global.CAMPFIRE_ID:
				create_instance(cell,CAMPFIRE,$Campfires)
			Global.CAGE_ID:
				create_instance(cell,CAGE,$Cages)
			Global.STAMP_ID:
				print("Boss position: ",$Elements.map_to_world(cell, true))
				create_instance(cell,STAMP,self)
	
	rng.set_seed(42077) # Sempre la mateixa perquè els enemics siguin iguals quan es recarregui l'escena.
						# Per a partides diferents els enemics ho seran també, i la llista no està ordenada per coordenades.
	var first_x = 9999999
	
	var lvls = []
	
	for cell in enemy_cells:
		lvls.append(rng.randi_range(1, 3))
		if cell[0] < first_x:
			first_x = cell[0]
	
	var j = 0
	for cell in enemy_cells:
		var lvl
		if cell[0] == first_x:
			lvl = 1
		else:
			lvl = lvls[j]
		create_instance(cell,ENEMY,$Enemies, null, lvl)
		j += 1
	
	$Elements.visible = false
	
	$BossRoomEntrance.position = entrance_position
	$BossRoomEntrance.position.x += 10
	
func create_instance(cell, scene, parent, save_data=null, lvl=null):
	# Cell marca la posició segons la cantonada de dalt a la dreta i els elements segons el centre
	var offset = Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0) 
	#$Elements.set_cell(cell.x, cell.y, -1) # Elimina la cell. (Crec que ara no ens interessa)
	var inst = scene.instance()
	inst.position = $Elements.map_to_world(cell) + offset
	
	
	if save_data != null:
		inst.SaveData = save_data
	if lvl != null:
		inst.lvl = lvl
	#if start_position != null:
		#inst.start_position = $Elements.map_to_world(Global.player_save_position) 
		
	parent.add_child(inst)


func save_from_campfire(cf_position):
	var pos = $Elements.world_to_map(cf_position)
	pos.y -= 1
	$Elements.set_cell(pos.x,pos.y,Global.PLAYER_ID)
	
	# Eliminem del tilemap tots aquells elements a la seva esquerra
	for cell in $Elements.get_used_cells():
		if cell.x < pos.x:
			$Elements.set_cell(cell.x, cell.y, -1)
	
	save_current_cells()

func load_cells():
	var file = File.new()
	if file.file_exists(save_path):
		var error = file.open(save_path, File.READ)
		if error == OK:
			var data = file.get_var()
			file.close()
			
			for cell in data["ground"]:
				$TileMap.set_cell(cell.x,cell.y,1)
				$TileMap.update_bitmask_area(Vector2(cell.x,cell.y))
			
			for cell in data["spikes"]:
				if $TileMap.get_cell(cell.x / 2, cell.y / 2 - 1) == 1: # Si té terra a sobre
					$Spikes.set_cell(cell.x,cell.y,1, false, true) # Posa l'spike girada
				else:
					$Spikes.set_cell(cell.x,cell.y,1)
				$Spikes.update_bitmask_area(Vector2(cell.x,cell.y))
			
			var player_cell = data["player"]
			$Elements.set_cell(player_cell.x, player_cell.y, Global.PLAYER_ID)
			$Elements.update_bitmask_area(Vector2(player_cell.x, player_cell.y))
			
			for cell in data["enemies"]:
				$Elements.set_cell(cell.x,cell.y,Global.ENEMY_ID)
				$Elements.update_bitmask_area(Vector2(cell.x,cell.y))
			
			for cell in data["campfires"]:
				$Elements.set_cell(cell.x,cell.y,Global.CAMPFIRE_ID)
				$Elements.update_bitmask_area(Vector2(cell.x,cell.y))
			
			for cell in data["cages"]:
				$Elements.set_cell(cell.x,cell.y,Global.CAGE_ID)
				$Elements.update_bitmask_area(Vector2(cell.x,cell.y))
			
			var stamp_cell = data["stamp"]
			$Elements.set_cell(stamp_cell.x, stamp_cell.y, Global.STAMP_ID)
			$Elements.update_bitmask_area(Vector2(stamp_cell.x, stamp_cell.y))
			
			entrance_position = data["entrance_position"]
			room_left = data["room_left"]
			room_right = data["room_right"]
			room_up = data["room_up"]
			room_down = data["room_down"]
			Global.boss_room_limits = [room_left, room_right, room_up, room_down]
			
			length = data["world_size"]
			match length:
				"Short": Global.world_size = 100
				"Mid": Global.world_size = 200
				"Long": Global.world_size = 300
				_: Global.world_size = 100
			print(length)
			print(Global.world_size)
		else:
			print(error)
			return error
	else: 
		return -1

func save_current_cells():
	var ground_cells = $TileMap.get_used_cells()
	var spike_cells = $Spikes.get_used_cells()
	
	var player_cell = $Elements.get_used_cells_by_id(Global.PLAYER_ID)[0]
	var enemy_cells = $Elements.get_used_cells_by_id(Global.ENEMY_ID)
	var campfire_cells = $Elements.get_used_cells_by_id(Global.CAMPFIRE_ID)
	var cage_cells = $Elements.get_used_cells_by_id(Global.CAGE_ID)
	var stamp_cell = $Elements.get_used_cells_by_id(Global.STAMP_ID)[0]
	
	match Global.world_size:
		100: length = "Short"
		200: length = "Mid"
		300: length = "Long"
		_: length = "Short" # Default
	
	var data = {
		"ground" : ground_cells,
		"spikes" : spike_cells,
		"player" : player_cell,
		"enemies" : enemy_cells,
		"campfires" : campfire_cells,
		"cages" : cage_cells,
		"stamp" : stamp_cell,
		"entrance_position" : entrance_position,
		"room_left" : room_left,
		"room_right" : room_right,
		"room_up" : room_up,
		"room_down" : room_down,
		"world_size" : length
	}
	
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


func setup_cells():	
	#var cells = $TileMap.get_used_cells()
	
	print($TileMap.world_to_map($Player.position))
	print($TileMap.get_cell(4,3))
	
	$TileMap.set_cell(0,0,1)
	$TileMap.update_bitmask_area(Vector2(0,0))
	
	$Spikes.set_cell(0,-1,1)
	$Spikes.set_cell(1,-1,1)
	$Spikes.update_bitmask_area(Vector2(0,-1))


func _on_BossRoomEntrance_body_entered(body):
	# camera limits = boss room limits (if that doesn't work because it's too small, add a fixed value to it, keeping it centered)
	if body in get_tree().get_nodes_in_group("player"):
		print("up: ", room_up, ",down: ", room_down, ",left: ", room_left, ",right: ", room_right)
		print($Player/Camera2D.global_position)
		
		$Player/Camera2D.limit_left = room_left
		$Player/Camera2D.limit_right = room_right + CELL_SIZE
		$Player/Camera2D.limit_top = room_up
		$Player/Camera2D.limit_bottom = room_down
		
		""" Seria força més elegant, però al posar current=false la camera no té temps de posar-se a la posició.
		var cam_pos_x = room_left + (room_right - room_left)/2
		var cam_pos_y = room_up + (room_down - room_up)/2
		
		$Player/Camera2D.global_position = Vector2(cam_pos_x, cam_pos_y)
		$Player/Camera2D.current = false
		print($Player/Camera2D.global_position)
		"""
		#$Barrier/CollisionShape2D.disabled = true
		$Barrier/CollisionShape2D.set_deferred("disabled",true)
		$Boss.state = "Jump"
		$Boss.hp = $Boss.starting_hp
		
		var entrance_position_cell = $TileMap.world_to_map(entrance_position)
		#$TileMap.map_to_world(entrance_position_cell, true)
		for j in range(entrance_position_cell.y - 2, entrance_position_cell.y + 1):
			$TileMap.set_cell(entrance_position_cell.x - 1, j, 1)
			#$TileMap.set_cell(entrance_position_cell.x - 2, j, 1)
			#$TileMap.set_cell(entrance_position_cell.x - 3, j, 1)
			$TileMap.update_bitmask_area(Vector2(entrance_position_cell.x - 2, j))
	
		$BossRoomEntrance/CollisionShape2D.set_deferred("disabled", true)

