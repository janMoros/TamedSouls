extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	$Player/Camera2D.limit_bottom = 128
	$Player/Camera2D.limit_left = -352
	$Player/Camera2D.limit_right = 608
	# [room_left, room_right, room_up, room_down]
	Global.boss_room_limits = [-382 + 64, 576, -323 - 64, 64]
	#if $Boss.state == "Wait":
	#	$Boss.state = "Jump"
