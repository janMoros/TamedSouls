extends MarginContainer

export var max_hp = 10
export var max_sta = 10
export var max_estus = 5

var souls = 1000 # Quan hi hagi sistema de guardat, treure'l d'allà

#onready var lifeNum = $HBoxContainer/Bars/LifeBar/Count/Background/Number
onready var lifeBar = $HBoxContainer/Bars/LifeBar/Gauge
#onready var staNum = $HBoxContainer/Bars/EnergyBar/Count/Background/Number
onready var staBar = $HBoxContainer/Bars/EnergyBar/Gauge

onready var SoulCount = $"HBoxContainer/Bars/Souls&Estus/Souls"

onready var Estus = $"HBoxContainer/Bars/Souls&Estus/Estus"

func _ready():
#	lifeNum.text = str(max_hp)
#	lifeNum.text = str(max_sta)
	var SaveData = Save.load_data()
	
	if typeof(SaveData) != TYPE_DICTIONARY: # O hi ha hagut un error o no existeix
		Estus.text = "x"+str(max_estus)
		SoulCount.text = str(souls)
	else: 
		Estus.text = "x"+str(SaveData["estus"])
		SoulCount.text = str(SaveData["souls"])
		lifeBar.value = SaveData["hp"] * 100 / max_hp
		staBar.value = SaveData["sta"] * 100 / max_sta

func update_hp(new_value):
	#lifeNum.text = str(new_value)
	lifeBar.value = new_value * 100 / max_hp
	if new_value > max_hp * 0.2:
		lifeBar.modulate = "43ff00"
	else:
		lifeBar.modulate = "ff0000"

func update_sta(new_value):
	#staNum.text = str(new_value)
	staBar.value = new_value * 100 / max_sta
	
func update_estus(new_value):
	Estus.text = "x"+str(new_value)

func update_souls(new_value):
	SoulCount.text = str(new_value)
