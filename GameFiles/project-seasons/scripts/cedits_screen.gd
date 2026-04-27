#cedits_screen.gd
extends Control

func _ready():
	setup_credits()
	start_fade_sequence()

func setup_credits():
	# Set black background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Create center container
	var center_container = VBoxContainer.new()
	center_container.set_anchors_preset(Control.PRESET_CENTER)
	center_container.position = Vector2(-200, -200)  # Offset to center the content
	center_container.custom_minimum_size = Vector2(400, 400)
	add_child(center_container)
	
	# Add "Produced by" title
	var title = Label.new()
	title.text = "Produced by"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	center_container.add_child(title)
	
	# Add spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 40)
	center_container.add_child(spacer1)
	
	# Add producer names
	var names = [
		"Nicolas Brion",
		"Christopher Ferer",
		"William Merrix",
		"Annie Sardouk",
		"Caleb Sbani"
	]
	
	for name in names:
		var name_label = Label.new()
		name_label.text = name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 24)
		center_container.add_child(name_label)
		
		# Add small spacing between names
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 15)
		center_container.add_child(spacer)

func start_fade_sequence():
	# Wait 10 seconds
	await get_tree().create_timer(10.0).timeout
	
	# Fade to black (fade out the entire screen)
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 1), 2.0)
	await tween.finished
	
	# Go to main menu or title screen
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
