extends Control

var settings_scene = preload("res://scenes/SettingsMenu.tscn")

var input_locked = false

func _ready():
	# Connect button signal
	$StartButton.pressed.connect(_on_start_button_pressed)
	$SettingsButton.pressed.connect(_on_settings_button_pressed)
	$TutorialButton.pressed.connect(_on_tutorial_button_pressed)
	

func _on_start_button_pressed():
	# Change to your first level or level select
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
	# Or for testing, just print:
	# print("Starting game!")

func _on_settings_button_pressed():
	if input_locked:
		return
		
	input_locked = true
	
	var settings = settings_scene.instantiate()
	settings.tree_exited.connect(_on_settings_closed)
	add_child(settings)

func _on_settings_closed():
	input_locked = false

func _on_tutorial_button_pressed():
	get_tree().change_scene_to_file("res://scenes/tutorial_lvl.tscn")
