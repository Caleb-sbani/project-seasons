extends Node2D

func _ready():
	# Connect button signal
	$Level1.pressed.connect(_on_start_button_pressed.bind(1))
	$Level2.pressed.connect(_on_start_button_pressed.bind(2))
	$Level3.pressed.connect(_on_start_button_pressed.bind(3))
	$Level4.pressed.connect(_on_start_button_pressed.bind(4))
	$Level5.pressed.connect(_on_start_button_pressed.bind(5))
	$Tutorial.pressed.connect(_tutorial)
	
func _tutorial():
	get_tree().change_scene_to_file("res://scenes/tutorial_lvl.tscn")

func _on_start_button_pressed(level: int):
	#print(GlobalLevel.completedLevel)
	GlobalLevel.level = level
	get_tree().change_scene_to_file("res://scenes/levels.tscn")
