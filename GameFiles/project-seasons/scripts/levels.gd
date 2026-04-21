extends Node2D

var settings_scene = preload("res://scenes/SettingsMenu.tscn")
var input_locked = false

const TILE_SIZE = 32  # our sprites are 32x32
var seasons_array = ["Winter", "Spring", "Summer", "Fall"]

# various trackers
var player_locked = false
var current_stage = GlobalLevel.level
var total_stages = GlobalLevel.levels
var player_pos = Vector2i(0, 0)
var step_counter = 0
var change_frequency = 4
var has_honey = false
var wind_direction = Vector2i(1, 0)  # right by default
var season = ""

# object refrences
var player_sprite = null
var tutorial_panel = null
var boxes = []
var waters = []
var waterspos = []
var sinkholes = []
var sinkholetracker = []
var sinkholespos = []
var bees = []
var beehives = []
var beehivespos = []

func _ready():
	setup_ui()
	load_stage(current_stage)

func setup_ui():
	# centers camera and properly scales game
	var camera = Camera2D.new()
	camera.name = "Camera"
	camera.position = Vector2(128, 96)  # centers on a 7x5 grid (can change later)
	camera.zoom = Vector2(2.5, 2.5)  # made tiles bigger cause it felt too small
	add_child(camera)
	
	# UI layer
	var ui = CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	
	# put the UI elements of the hints all on the right side so they do not cover the game screen
	var right_panel = Panel.new()
	right_panel.name = "RightPanel"
	right_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	right_panel.offset_left = -400  # 400 pixels wide
	right_panel.offset_top = 0
	right_panel.offset_right = 0
	right_panel.offset_bottom = 0
	ui.add_child(right_panel)
	
	# tutorial text goes at the top of the right panel
	var text_container = MarginContainer.new()
	text_container.name = "TextContainer"
	text_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	text_container.offset_left = 10
	text_container.offset_right = -10
	text_container.offset_top = 20
	text_container.offset_bottom = 300
	right_panel.add_child(text_container)
	
	var label = Label.new()
	label.name = "TutorialText"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 16)
	text_container.add_child(label)
	
	# HUD Container goes in the middle of right panel
	var hud = VBoxContainer.new()
	hud.name = "HUD"
	hud.position = Vector2(20, 320)
	right_panel.add_child(hud)
	
	var settings_button = Button.new()
	settings_button.name = "SettingsButton"
	settings_button.text = "⚙"
	settings_button.tooltip_text = "Settings"
	settings_button.custom_minimum_size = Vector2(40, 40)

	# Just position it manually inside the 400px panel
	settings_button.position = Vector2(340, 10)

	settings_button.pressed.connect(_on_settings_pressed)

	right_panel.add_child(settings_button)
	
	# step counter
	var step_label = Label.new()
	step_label.name = "StepCounter"
	step_label.text = "Steps: 0"
	step_label.add_theme_font_size_override("font_size", 20)
	hud.add_child(step_label)
	
	# spacing for UI elements
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	hud.add_child(spacer1)
	
	#season label
	var season_label = Label.new()
	season_label.name = "CurrentSeason"
	season_label.text = season
	season_label.add_theme_font_size_override("font_size", 20)
	hud.add_child(season_label)
	
	#element spacing
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	hud.add_child(spacer2)
	
	# season change tracker (seasons changing not actually implemented for tutorial)
	var freq_label = Label.new()
	freq_label.name = "ChangeFrequency"
	freq_label.text = "Season changes in: 4"
	freq_label.add_theme_font_size_override("font_size", 20)
	hud.add_child(freq_label)
	
	# spacing for UI elements
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	hud.add_child(spacer3)
	
	# wind direction indicator
	var wind_label = Label.new()
	wind_label.name = "WindDirection"
	wind_label.text = "Wind: ×"
	#←, ↑, ↓, → or × for values
	wind_label.add_theme_font_size_override("font_size", 24)
	wind_label.visible = true
	hud.add_child(wind_label)
	
	tutorial_panel = text_container

func _on_settings_pressed():
	if input_locked:
		return
		
	input_locked = true
	
	var settings = settings_scene.instantiate()
	settings.tree_exited.connect(_on_settings_closed)
	$UI.add_child(settings)

func _on_settings_closed():
	input_locked = false

func load_stage(stage_num: int):
	# clears the previous level
	clear_level()
	
	# resets states for new lvl
	step_counter = 0
	player_locked = false
	has_honey = false
	#player_sprite.texture = load("res://assets/sprites/snail.png")
	
	match stage_num:
		1:
			season = "Winter" 
			#call switch season at the end of setup so season gets set up correctly
			load_level_one()
			switch_season()
		2:
			#temporary
			season = "Fall" 
			#call switch season at the end of setup so season gets set up correctly
			load_level_two()
			switch_season()
		3:
			season = "Summer"
			load_level_three()
			switch_season()
		4:
			season = "Fall"
			load_level_four()
			switch_season()
#		5:
#			load_stage_5()
#		6:
#			load_stage_6()
#		7:
#			load_stage_7()
	update_hud()


func clear_level():
	# remove all child nodes except UI and camera for the reset
	for child in get_children():
		if child.name != "UI" and child.name != "Camera":
			child.queue_free()
	
	boxes.clear()
	waters.clear()
	waterspos.clear()
	sinkholes.clear()
	sinkholetracker.clear()
	bees.clear()
	beehives.clear()
	beehivespos.clear()
	player_sprite = null

func create_map(layout: Array):
	var rows = layout.size()
	var cols = layout[0].length()
	
	# adds the outer walls around the lvls
	# top & bottom
	for x in range(cols + 2):
		create_tile(Vector2i(x, 0), 'E')
		create_tile(Vector2i(x, rows + 1), 'E')
	
	# left & right
	for y in range(rows + 2):
		create_tile(Vector2i(0, y), 'E')
		create_tile(Vector2i(cols + 1, y), 'E')
	
	# creates the lvl content
	for y in range(rows):
		for x in range(cols):
			var tile = layout[y][x]
			var grid_pos = Vector2i(x + 1, y + 1)  # offset to account for walls
			
			if tile == 'p':
				player_pos = grid_pos
				create_tile(grid_pos, 'g')  # grass under player
				spawn_player(grid_pos)
			elif tile == 'm':
				create_tile(grid_pos, 'g')  # grass under box
				spawn_box(grid_pos)
			elif tile == 'B':
				create_tile(grid_pos, 'g')  # grass under bee
				create_tile(grid_pos, 'B')
			else:
				create_tile(grid_pos, tile)
	var camera = get_viewport().get_camera_2d()
	#camera hints: moving right with camera is +++x
	# moving down with camera is ---y
	camera.position = Vector2(32 * cols + 64, rows* 32.0 + 64)/2
	#camera.zoom = Vector2(2, 2)
	var t = min(12.0/cols, 6.0/rows)
	t = pow(t, 0.75)
	camera.zoom = Vector2(2.0 * t, 2.0 * t)

func create_tile(grid_pos: Vector2i, tile_type: String):
	var sprite = Sprite2D.new()
	sprite.position = Vector2(grid_pos) * TILE_SIZE
	sprite.centered = false  # DON'T center. Centering causes weird gaps
	
	match tile_type:
		'g':
			sprite.texture = load("res://assets/sprites/grass.png")
		'w':
			sprite.texture = load("res://assets/sprites/wall.png")
		'W':
			sprite.texture = load("res://assets/sprites/water.png")
			waters.append(sprite)
			waterspos.append(grid_pos)
		'i':
			sprite.texture = load("res://assets/sprites/ice.png")
			waters.append(sprite)
			waterspos.append(grid_pos)
		's':
			sprite.texture = load("res://assets/sprites/sinkhole.png")
			sinkholes.append(sprite)
			sinkholespos.append(grid_pos)
			sinkholetracker.append(0)
		'H': 
			sprite.texture = load("res://assets/sprites/sinkhole_warning.png")
			sinkholes.append(sprite)
			sinkholespos.append(grid_pos)
			sinkholetracker.append(1)
		'h': 
			sprite.texture = load("res://assets/sprites/sinkhole_start.png")
			sinkholes.append(sprite)
			sinkholespos.append(grid_pos)
			sinkholetracker.append(2)
		'b':
			sprite.texture = load("res://assets/sprites/beehive.png")
			beehives.append(sprite)
			beehivespos.append(grid_pos)
		'B':
			sprite.texture = load("res://assets/sprites/bee.png")
			bees.append(sprite)
		'G':
			sprite.texture = load("res://assets/sprites/goal.png")
		'E':
			sprite.texture = load("res://assets/sprites/outer_wall.png")
	
	add_child(sprite)

func spawn_player(grid_pos: Vector2i):
	player_sprite = Sprite2D.new()
	player_sprite.texture = load("res://assets/sprites/snail.png")
	player_sprite.position = Vector2(grid_pos) * TILE_SIZE
	player_sprite.centered = false
	player_sprite.name = "Player"
	player_sprite.z_index = 10  # renders the player on top of everything so the player is always visible
	add_child(player_sprite)

func spawn_box(grid_pos: Vector2i):
	var box = Sprite2D.new()
	box.texture = load("res://assets/sprites/movable_box.png")
	box.position = Vector2(grid_pos) * TILE_SIZE
	box.centered = false
	box.set_meta("grid_pos", grid_pos)
	box.set_meta("immovable", false)
	box.name = "Box"
	box.z_index = 6  # renders boxes above tiles but below player
	boxes.append(box)
	add_child(box)

func update_hud():
	$UI/RightPanel/HUD/StepCounter.text = "Steps: %d" % step_counter
	var steps_until_change = change_frequency - (step_counter % change_frequency)
	$UI/RightPanel/HUD/CurrentSeason.text = season
	$UI/RightPanel/HUD/ChangeFrequency.text = "Season changes in: %d" % steps_until_change

func _unhandled_input(event):
	if input_locked:
		return
	
	var direction = Vector2i.ZERO
	
	if player_locked == true:
		direction = Vector2i(0, 0)
	elif event.is_action_pressed("ui_up"):
		direction = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down"):
		direction = Vector2i(0, 1)
	elif event.is_action_pressed("ui_left"):
		direction = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right"):
		direction = Vector2i(1, 0)
		
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_H:
			if ($UI.visible):
				$UI.hide()
			else:
				$UI.show()
		elif event.pressed and event.keycode == KEY_R:
			player_death("Restarting", player_pos)
		elif event.pressed and event.keycode == KEY_W:
			direction = Vector2i(0, -1)
		elif event.pressed and event.keycode == KEY_A:
			direction = Vector2i(-1, 0)
		elif event.pressed and event.keycode == KEY_S:
			direction = Vector2i(0, 1)
		elif event.pressed and event.keycode == KEY_D:
			direction = Vector2i(1, 0)
		elif event.pressed and event.keycode == KEY_ESCAPE:
			_on_settings_pressed()

	if direction != Vector2i.ZERO:
		try_move_player(direction)

func try_move_player(direction: Vector2i):
	$UI/RightPanel/TextContainer/TutorialText.hide()
	var new_pos = player_pos + direction
	var box_at_pos = get_box_at(new_pos)
	# check what type of tile is at new position
	if (get_tile_at(new_pos) == 'E' or player_locked): return
	if ((get_tile_at(new_pos) != 'w') or (has_honey and get_tile_at(new_pos) == 'w')):
		if season == "Fall" and direction == wind_direction:
			var boost_pos = new_pos + wind_direction
			# check if boost position has a box (not sure how we want to handle this yet)
			var boost_box = get_box_at(boost_pos)
			if box_at_pos:
				if (box_at_pos.get_meta("immovable") == false):
					if try_push_box(box_at_pos, direction):
						move_player(new_pos)
					return
			else:
				var tileat = get_tile_at(new_pos)
				match tileat:
					'B':
						if (step_counter%4 != 3):
							player_death("Stung by a bee!", new_pos)
						return
					'w':
						if(can_move_to(new_pos)):
							move_player(new_pos)
			if boost_box:
				if (boost_box.get_meta("immovable")):
					move_player(boost_pos, true)
					return
				else:
					if (try_push_box(boost_box, direction)):
						move_player(boost_pos)
						return
					elif can_move_to(new_pos):
						move_player(new_pos)
						return
			elif can_move_to(boost_pos):
				move_player(boost_pos, true)
				return
			if (get_tile_at(boost_pos) == 'w' or get_tile_at(boost_pos) == 'E'):
				if (can_move_to(new_pos)):
					move_player(new_pos)
		elif (season != "Fall" or direction != wind_direction):
			if (box_at_pos):
				if (box_at_pos.get_meta("immovable")):
					move_player(new_pos)
					return
				elif try_push_box(box_at_pos, direction):
					move_player(new_pos)
					return
			elif (can_move_to(new_pos)):
				move_player(new_pos)
				return
	
	
func can_move_to(grid_pos: Vector2i) -> bool:
	var tile = get_tile_at(grid_pos)
	if tile == 'E': return false
	# can't walk through walls
	if tile == 'w':
		if has_honey:
			has_honey = false
			player_sprite.texture = load("res://assets/sprites/snail.png")
			return true
		return false
	
	# water kills you when not about to turn to ice
	if (tile == 'W' and season == "Fall" and step_counter%4 == 3):
		return true
	if (tile == 'W' and season != "Winter"):
		player_death("You drowned!", grid_pos)
		return false
	
	# bees sting you to death
	if tile == 'B' and season == "Spring" and step_counter%4 != 3:
		player_death("Ouch! Stung by a bee!", grid_pos)
		return false
	
	# beehive gives honey
	if tile == 'b':
		has_honey = true
		player_sprite.texture = load("res://assets/sprites/snail_honey.png")
	
	# sinkholes kill you
	if tile == 's':
		player_death("You fell into a sinkhole!", grid_pos)
		return false
	
	return true

func get_tile_at(grid_pos: Vector2i) -> String:
	# checks tiles by position
	var world_pos = Vector2(grid_pos) * TILE_SIZE
	
	for child in get_children():
		if child is Sprite2D and child.name != "Player" and not child.name.begins_with("Box"):
			if child.position.distance_to(world_pos) < 5:
				# determine type
				var texture_path = child.texture.resource_path
				if "outer_wall" in texture_path:
					return 'E'
				elif "wall" in texture_path:
					return 'w'
				elif "water" in texture_path:
					return 'W'
				elif "ice" in texture_path:
					return 'i'
				elif "sinkhole.png" in texture_path:
					return 's'
				elif "sinkhole_warning.png" in texture_path:
					return 'H'
				elif "sinkhole_start.png" in texture_path:
					return 'h'
				elif "bee.png" in texture_path:  # bee.png not beehive
					return 'B'
				elif "beehive" in texture_path:
					return 'b'
				elif "goal" in texture_path:
					return 'G'	
	
	return 'g'

func get_box_at(grid_pos: Vector2i):
	var tempboxes = []
	for box in boxes:
		if box.get_meta("grid_pos") == grid_pos:
			tempboxes.append(box)
	for b in tempboxes:
		if b.get_meta("immovable") == true:
			continue
		else:
			return b
	if tempboxes.size() == 1:
		return tempboxes[0]
	return null
	
	
func get_immovable_box_at(grid_pos: Vector2i):
	var tempboxes = []
	for box in boxes:
		if box.get_meta("grid_pos") == grid_pos:
			tempboxes.append(box)
	for b in tempboxes:
		if b.get_meta("immovable") == true:
			return b
	return null

func try_push_box(box, direction: Vector2i) -> bool:
	var box_pos = box.get_meta("grid_pos")
	var new_box_pos = box_pos + direction
	
	# can box be pushed there
	var tile = get_tile_at(new_box_pos)
	
	if (get_box_at(new_box_pos) != null):
		box.set_meta("grid_pos", new_box_pos)
		animate_move(box, new_box_pos)
		return true

	if tile == 'W' or tile == 's':
		box.set_meta("grid_pos", new_box_pos)
		box.set_meta("immovable", true)
		box.texture = load("res://assets/sprites/immovable_box.png")
		box.z_index = 4 # render below moveable boxes
		animate_move(box, new_box_pos)
		return true
	
	# can't push if there's a wall or another box
	if tile == 'w' or get_box_at(new_box_pos) or tile == 'b' or tile == 'E':
		return false
	
	# can't push immovable boxes
	if box.get_meta("immovable", false):
		return false
	
	# actually moves the box
	box.set_meta("grid_pos", new_box_pos)
	animate_move(box, new_box_pos)
	return true

func move_player(new_pos: Vector2i, increment_steps: bool = true):
	player_pos = new_pos
	animate_move(player_sprite, new_pos)
	
	if increment_steps:
		step_counter += 1
		if step_counter % change_frequency == 0:
			switch_season()
		update_hud()
	
	# ALWAYS check if reached goal after moving
	# player must LAND on goal to win
	if get_tile_at(new_pos) == 'G':
		player_locked = true
		await get_tree().create_timer(0.5).timeout
		on_goal_reached()

func highlight_hud_element(element_name: String):
	var element = $UI/RightPanel/HUD.get_node(element_name)
	var original_color = element.modulate
	
	# flashes yellow to grab attention
	for i in range(3):
		element.modulate = Color(1, 1, 0)  # Yellow
		await get_tree().create_timer(0.3).timeout
		element.modulate = original_color
		await get_tree().create_timer(0.3).timeout

func animate_move(sprite: Sprite2D, grid_pos: Vector2i):
	var target_pos = Vector2(grid_pos) * TILE_SIZE
	var tween = create_tween()
	tween.tween_property(sprite, "position", target_pos, 0.2)

func player_death(death_message: String, death_pos: Vector2i):
	$UI/RightPanel/TextContainer/TutorialText.show()
	$UI/RightPanel/TextContainer/TutorialText.text = death_message
	$UI/RightPanel/TextContainer/TutorialText.add_theme_font_size_override("font_size", 24)
	$UI/RightPanel/TextContainer/TutorialText.add_theme_color_override("font_color", Color(1, 0, 0))
	# temporarily disable input
	set_process_unhandled_input(false)
	
	# flash player red for death
	if player_sprite:
		var target_pos = Vector2(death_pos) * TILE_SIZE
		if (death_pos != player_pos):
			var tween = create_tween()
			tween.tween_property(player_sprite, "position", target_pos, 0.2)
		var original_modulate = player_sprite.modulate
		player_sprite.modulate = Color(1, 0, 0)  # Red
		await get_tree().create_timer(0.5).timeout
		player_sprite.modulate = original_modulate

	
	# wait a moment
	await get_tree().create_timer(0.5).timeout
	
	# reload current stage
	load_stage(current_stage)
	
	# re-enable input
	set_process_unhandled_input(true)

func on_goal_reached():
	GlobalLevel.completedLevel = current_stage
	if current_stage == total_stages:
		await fade_to_black()
		# go to level select (not yet implemented)
		get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
	else:
		# fade to black and load next stage
		await fade_to_black()
		current_stage += 1
		load_stage(current_stage)
		await fade_from_black()

func fade_to_black():
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	$UI.add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 1), 0.5)
	await tween.finished
	
	await get_tree().create_timer(1).timeout
	fade.queue_free()

func fade_from_black():
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	$UI.add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 0), 0.5)
	await tween.finished
	
	fade.queue_free()
	
func switch_season():
	var next = false
	var prev = season
	if step_counter != 0:
		for i in seasons_array:
			if next:
				season = i
				break
			if season == i:
				next = true
		if prev == season:
			season = "Winter"
	if season == "Winter":
		#do winter stuff
		$UI/RightPanel/HUD/WindDirection.text = "Wind: ×"
		for tile in waters:
			tile.texture = load("res://assets/sprites/ice.png")
	elif season == "Spring":
		#do spring stuff
		for tile in waters:
			tile.texture = load("res://assets/sprites/water.png")
		for t in waterspos:
			if (get_box_at(t)):
				get_box_at(t).set_meta("immovable", true)
				get_box_at(t).texture = load("res://assets/sprites/immovable_box.png")
		for i in beehives.size():
			if (get_tile_at(beehivespos[i] + Vector2i(0, 1)) == 'g'):
				create_tile(beehivespos[i] + Vector2i(0, 1), 'B')
			if (get_tile_at(beehivespos[i] + Vector2i(0, -1)) == 'g'):
				create_tile(beehivespos[i] + Vector2i(0, -1), 'B')
			if (get_tile_at(beehivespos[i] + Vector2i(-1, 0)) == 'g'):
				create_tile(beehivespos[i] + Vector2i(-1, 0), 'B')
			if (get_tile_at(beehivespos[i] + Vector2i(1, 0)) == 'g'):
				create_tile(beehivespos[i] + Vector2i(1, 0), 'B')
		if (get_tile_at(player_pos) == 'B'):
			player_death("You got stung!", player_pos)
		if (get_tile_at(player_pos) == 'W'  and get_immovable_box_at(player_pos) == null):
			player_death("You drowned!", player_pos)
	elif season == "Summer":
		#do summer stuff
		for i in sinkholes.size():
			if step_counter != 0:
				if (sinkholetracker[i] == 1):
					sinkholes[i].texture = load("res://assets/sprites/sinkhole.png")
					sinkholetracker[i] = 0
					if (get_immovable_box_at(sinkholespos[i]) == null):
						for b in boxes:
							if (b.get_meta("grid_pos") == sinkholespos[i]):
								b.set_meta("immovable", true)
								b.texture = load("res://assets/sprites/immovable_box.png")
								b.z_index = 4
					if (get_tile_at(player_pos) == 's' and get_immovable_box_at(player_pos) == null):
						player_death("You fell into a sinkhole!", player_pos)
				elif (sinkholetracker[i] == 2):
					sinkholes[i].texture = load("res://assets/sprites/sinkhole_warning.png")
					sinkholetracker[i] = 1
		for bee in bees:
			bee.queue_free()
		bees.clear()
	elif season == "Fall":
		#do fall stuff
		#←, ↑, ↓, → or × for values
		if (wind_direction == Vector2i(1, 0)):
			$UI/RightPanel/HUD/WindDirection.text = "Wind: →"
		if (wind_direction == Vector2i(-1, 0)):
			$UI/RightPanel/HUD/WindDirection.text = "Wind: ←"
		if (wind_direction == Vector2i(0, -1)):
			$UI/RightPanel/HUD/WindDirection.text = "Wind: ↑"
		if (wind_direction == Vector2i(0, 1)):
			$UI/RightPanel/HUD/WindDirection.text = "Wind: ↓"
	if season != "Fall":
		$UI/RightPanel/HUD/WindDirection.text = "Wind: ×"

#LEVEL BUILDING KEY:
# p = player
# g = grass
# m = moveable block
# w = wall
# W = water
# i = ice
# s = sinkhole (will kill you immediately)
# H = sinkhole warning (will convert next summer)
# h = sinkhole start (will convert in 2 summers)
# b = beehive
# B = bee
# G = goal


func load_level_one():
	wind_direction = Vector2i(1, 0)
	var layout = [
		"wggggwggbggg",
		"ggmgggwggggg",
		"ggghgWHWgggb",
		"gpgHgwgWggHg",
		"gggmggwgggHh",
		"bgggggwgggwG"
	]
	create_map(layout)

func load_level_two():
	wind_direction = Vector2i(1, 0)
	season = "Summer"
	var layout = [
		"bgsssgggggg",
		"ggsssggggbg",
		"pgsWwHgwwww",
		"ggsssggmwww",
		"ggsssgggssG"
	]
	create_map(layout)
	
func load_level_three():
	wind_direction = Vector2i(1, 0)
	var layout = [
		"ggmWWgggggswwbWggg",
		"hwhwswwwwwmwsgWggh",
		"pgbggsswWmHgbswhwG",
		"gwgwgsswmWgHwwwwgW",
		"gmsmgwswbWwgsgghgg",
		"gggggswwWwsgggwsss"
	]
	create_map(layout)
	
func load_level_four():
	wind_direction = Vector2i(0, 1)  # wind blows downward for Fall
	var layout = [
		"pggsggggwgggb",
		"ggggggmmwgggw",
		"ssssssWWwgwwh",
		"ggggwwWWggwhh",
		"bbbbgWgggwhhG"
	]
	create_map(layout)
