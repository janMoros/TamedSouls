extends MarginContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connecta el signal des de Input que indica si hi ha un canvi en la connexió del controller
	Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")
	var joypads = Input.get_connected_joypads()
	if joypads.empty():
		$HBoxContainer/Bars/keyboard.visible = true
		$HBoxContainer/Bars/controller.visible = false
		Global.controller_connected = false
		print("no controller")
	else:
		$HBoxContainer/Bars/keyboard.visible = false
		$HBoxContainer/Bars/controller.visible = true
		Global.controller_connected = true
		print("yes controller")
	

func _on_joy_connection_changed(device_id, connected):
	if connected:
		$HBoxContainer/Bars/keyboard.visible = false
		$HBoxContainer/Bars/controller.visible = true
		Global.controller_connected = true
		print("controller connected")
	else:
		$HBoxContainer/Bars/keyboard.visible = true
		$HBoxContainer/Bars/controller.visible = false
		Global.controller_connected = false
		print("controller disconnected")
