extends Node2D

func _ready():
	# Connect button signal
	$Level1.pressed.connect(_on_start_button_pressed)
	$Tutorial.pressed.connect(_tutorial)
	
func _tutorial():
	get_tree().change_scene_to_file("res://scenes/tutorial_lvl.tscn")

func _on_start_button_pressed():
	print(GlobalLevel.completedLevel)
	if GlobalLevel.completedLevel >= 0:
		GlobalLevel.level = 1
		get_tree().change_scene_to_file("res://scenes/levels.tscn")
