extends Area2D

export var dest = "World2"

func _ready():
	self.connect("body_entered",self,"_on_body_entered")

func _physics_process(delta):
	pass	

func _on_body_entered(body):
	if body.name == "Player":
		get_tree().change_scene("res://"+dest+".tscn")
