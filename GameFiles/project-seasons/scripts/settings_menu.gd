extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	custom_minimum_size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	$Panel/VBoxContainer/CloseSetting.pressed.connect(_on_closeSetting_button_pressed)
	$Panel/VBoxContainer/HomeScreen.pressed.connect(_on_homeScreen_button_pressed)
	$Panel/VBoxContainer/Quit.pressed.connect(_on_quit_button_pressed)
	$Panel/VBoxContainer/FullScreen.pressed.connect(_on_fullscreen_toggle_pressed)
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		$Panel/VBoxContainer/FullScreen.button_pressed = 1
	$Panel/VBoxContainer/MuteButton.pressed.connect(_on_mute_toggle_pressed)
	$Panel/VBoxContainer/ZoomButton.pressed.connect(_on_zoom_button_pressed)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_closeSetting_button_pressed():
	queue_free()
	
func _on_zoom_button_pressed():
	var popup = $Panel/VBoxContainer/ZoomButton.get_popup()
	var i = 0
	while i < popup.item_count:
		popup.set_item_checked(i, false)
		i+=1
	popup.set_item_checked(GlobalLevel.zoom-1, true)
	await get_tree().process_frame
	popup.position = $Panel/VBoxContainer/ZoomButton.get_screen_position()
	var stretch = ProjectSettings.get_setting("display/window/stretch/scale")
	popup.position.x += $Panel/VBoxContainer/ZoomButton.size.x * stretch
	var z = await popup.id_pressed + 1
	if z != GlobalLevel.zoom and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		GlobalLevel.zoom = z
		get_window().size = ((Vector2i(1152, 648)*z))
		#await get_tree().process_frame 
		get_window().content_scale_factor = z
		ProjectSettings.set_setting("display/window/stretch/scale", z)

func _on_homeScreen_button_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
	
func cal(a : Vector2i, b : Vector2i) -> Vector2:
	return Vector2(((float) (a.x)/(float)(b.x)), ((float) (a.y)/(float)(b.y)))
	
func cal2(a : Vector2i, b : Vector2) -> Vector2:
	return Vector2((float) (a.x*b.x), (float) (a.y*b.y))
	
func _on_fullscreen_toggle_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size((Vector2i(1152, 648)* ProjectSettings.get_setting("display/window/stretch/scale")))
		get_window().content_scale_factor = ProjectSettings.get_setting("display/window/stretch/scale")
	else: 
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		var screen_size = DisplayServer.screen_get_size( DisplayServer.window_get_current_screen())
		get_window().content_scale_factor = (cal(screen_size, Vector2i(1152, 648))).x
		
		
func _on_mute_toggle_pressed():
	if AudioServer.get_bus_index("Master") == -1:
		return
	if AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")):
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	else: 
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_closeSetting_button_pressed()
