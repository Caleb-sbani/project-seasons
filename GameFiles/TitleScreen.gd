extends Control

func _ready():
	# Connect button signal
	$StartButton.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed():
	# Change to your first level or level select
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
	# Or for testing, just print:
	# print("Starting game!")
