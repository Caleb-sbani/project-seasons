extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	custom_minimum_size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	$Panel/VBoxContainer/CloseSetting.pressed.connect(_on_closeSetting_button_pressed)
	$Panel/VBoxContainer/HomeScreen.pressed.connect(_on_homeScreen_button_pressed)
	$Panel/VBoxContainer/Quit.pressed.connect(_on_quit_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_closeSetting_button_pressed():
	queue_free()

func _on_homeScreen_button_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
