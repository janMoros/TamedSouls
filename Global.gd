extends Node

################################ CONSTANTS

##### MOD_ATTCK_DEFNS = modifier

const MOD_MELEE_MAGIC = 1.5
const MOD_MELEE_RANGED = 0.5
const MOD_MELEE_MELEE = 1

const MOD_RANGED_MAGIC = 0.5
const MOD_RANGED_RANGED = 1
const MOD_RANGED_MELEE = 1.5

const MOD_MAGIC_MAGIC = 1
const MOD_MAGIC_RANGED = 1.5
const MOD_MAGIC_MELEE = 0.5

#### ELEMENTS TILEMAP 

const PLAYER_ID = 0
const ENEMY_ID = 1
const CAMPFIRE_ID = 2
const CAGE_ID = 3
const STAMP_ID = 4

#### OTHER

const KNOCKBACK_X = 200
const KNOCKBACK_Y = -100

################################ VARIABLES

var controller_connected = false

var world_size

var boss_room_limits = []

var lightning_target

var lightning

var final_time

var final_souls

################################ FUNCTIONS

func modifyer(atk,def):
	var mod
	match atk:
			"Melee":
				match def:
					"Melee":
						mod = Global.MOD_MELEE_MELEE
					"Ranged":
						mod = Global.MOD_MELEE_RANGED
					"Magic":
						mod = Global.MOD_MELEE_MAGIC
			"Ranged":
				match def:
					"Melee":
						mod = Global.MOD_RANGED_MELEE
					"Ranged":
						mod = Global.MOD_RANGED_RANGED
					"Magic":
						mod = Global.MOD_RANGED_MAGIC
			"Magic":
				match def:
					"Melee":
						mod = Global.MOD_MAGIC_MELEE
					"Ranged":
						mod = Global.MOD_MAGIC_RANGED
					"Magic":
						mod = Global.MOD_MAGIC_MAGIC
	return mod
