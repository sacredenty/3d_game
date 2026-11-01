extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/systems/overworld/player_controller.gd")
const WORLD_SIZE := Vector2(1600.0, 960.0)
const TILE_SIZE := 32
const VILLAGE_EDGE := 640.0
const FOREST_GATE := 720.0
const CLEARING_POSITION := Vector2(1330.0, 448.0)
const PLAYER_MAX_HP := 100
const ENEMY_MAX_HP := 82

var player: CharacterBody2D
var npc: StaticBody2D
var tree_positions: Array[Vector2] = []
var quest_step: int = 0
var dialogue_lines: Array[String] = []
var dialogue_index: int = 0
var dialogue_active: bool = false
var battle_active: bool = false
var battle_won: bool = false
var encounter_started: bool = false
var player_hp: int = PLAYER_MAX_HP
var enemy_hp: int = ENEMY_MAX_HP
var potions: int = 1
var gold: int = 0
var guarding: bool = false

var hud_layer: CanvasLayer
var objective_label: Label
var hp_bar: ProgressBar
var gold_label: Label
var prompt_panel: PanelContainer
var prompt_label: Label
var dialogue_panel: PanelContainer
var dialogue_label: Label
var dialogue_hint: Label
var battle_overlay: ColorRect
var enemy_hp_bar: ProgressBar
var battle_log: Label
var potion_button: Button
var battle_result_button: Button

func _ready() -> void:
	_build_world()
	_build_player()
	_build_npc()
	_build_interface()
	queue_redraw()

func _draw() -> void:
	for y in range(int(WORLD_SIZE.y / TILE_SIZE)):
		for x in range(int(WORLD_SIZE.x / TILE_SIZE)):
			var tile_x := x * TILE_SIZE
			var tile_y := y * TILE_SIZE
			var forest := tile_x >= VILLAGE_EDGE
			var color := Color("70985b") if not forest else Color("476f48")
			var variation := float((x * 19 + y * 31) % 7) * 0.008
			color = color.lightened(variation) if (x + y) % 2 == 0 else color.darkened(variation)
			draw_rect(Rect2(tile_x, tile_y, TILE_SIZE, TILE_SIZE), color)
			draw_rect(Rect2(tile_x, tile_y, TILE_SIZE, TILE_SIZE), Color(0.08, 0.13, 0.08, 0.08), false)

	_draw_path()
	_draw_houses()
	_draw_trees()
	_draw_landmarks()

func _draw_path() -> void:
	draw_rect(Rect2(0, 400, 1120, 112), Color("b99a69"))
	draw_rect(Rect2(0, 400, 1120, 8), Color("d0b782"))
	draw_rect(Rect2(0, 504, 1120, 8), Color("92764f"))
	draw_rect(Rect2(1072, 400, 112, 220), Color("b99a69"))
	draw_rect(Rect2(1072, 400, 112, 8), Color("d0b782"))
	draw_circle(CLEARING_POSITION, 132.0, Color("81925a"))
	draw_circle(CLEARING_POSITION, 112.0, Color("b99a69"))
	draw_circle(CLEARING_POSITION, 104.0, Color("c2a676"))

func _draw_houses() -> void:
	_draw_house(Rect2(96, 176, 176, 144), Color("d6bd8b"), Color("754b43"))
	_draw_house(Rect2(384, 208, 144, 112), Color("c8b17c"), Color("596b55"))
	draw_rect(Rect2(305, 344, 74, 54), Color("a99163"))
	draw_rect(Rect2(314, 351, 56, 47), Color("705448"))

func _draw_house(bounds: Rect2, wall_color: Color, roof_color: Color) -> void:
	draw_rect(bounds, wall_color)
	var roof := PackedVector2Array([
		Vector2(bounds.position.x - 18, bounds.position.y + 12),
		Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.position.y - 58),
		Vector2(bounds.end.x + 18, bounds.position.y + 12)
	])
	draw_colored_polygon(roof, roof_color)
	draw_rect(Rect2(bounds.position.x + 20, bounds.end.y - 62, 42, 62), Color("59443a"))
	draw_rect(Rect2(bounds.end.x - 58, bounds.position.y + 38, 34, 34), Color("9bc3bd"))

func _draw_trees() -> void:
	for tree_position in tree_positions:
		draw_circle(tree_position + Vector2(5, 12), 25.0, Color(0.08, 0.15, 0.08, 0.24))
		draw_rect(Rect2(tree_position.x - 6, tree_position.y + 6, 12, 24), Color("684c38"))
		draw_circle(tree_position + Vector2(0, -6), 24.0, Color("315b3b"))
		draw_circle(tree_position + Vector2(-12, 1), 15.0, Color("3c7045"))
		draw_circle(tree_position + Vector2(12, 2), 15.0, Color("3b6b42"))
		draw_circle(tree_position + Vector2(-5, -12), 10.0, Color("527d4d"))

func _draw_landmarks() -> void:
	draw_circle(CLEARING_POSITION, 52.0, Color(0.9, 0.79, 0.49, 0.12))
	draw_circle(Vector2(1330, 448), 9.0, Color("d5bd79"))
	draw_circle(Vector2(1330, 448), 4.0, Color("fff0b5"))
	draw_rect(Rect2(594, 386, 14, 132), Color("70543a"))
	draw_rect(Rect2(616, 386, 14, 132), Color("70543a"))
	draw_rect(Rect2(594, 396, 36, 12), Color("9a7548"))
	draw_rect(Rect2(594, 496, 36, 12), Color("9a7548"))

func _build_world() -> void:
	tree_positions.clear()
	_add_rect_obstacle(Vector2(-18, WORLD_SIZE.y * 0.5), Vector2(36, WORLD_SIZE.y + 72))
	_add_rect_obstacle(Vector2(WORLD_SIZE.x + 18, WORLD_SIZE.y * 0.5), Vector2(36, WORLD_SIZE.y + 72))
	_add_rect_obstacle(Vector2(WORLD_SIZE.x * 0.5, -18), Vector2(WORLD_SIZE.x + 72, 36))
	_add_rect_obstacle(Vector2(WORLD_SIZE.x * 0.5, WORLD_SIZE.y + 18), Vector2(WORLD_SIZE.x + 72, 36))
	for x in range(72, 1560, 104):
		for y in range(90, 900, 104):
			var position := Vector2(x + (y % 3) * 13, y)
			if _is_path_position(position) or _is_building_position(position):
				continue
			if x < VILLAGE_EDGE and (x + y) % 3 != 0:
				continue
			tree_positions.append(position)
			_add_circle_obstacle(position + Vector2(0, 15), 13.0)

	_add_rect_obstacle(Vector2(184, 250), Vector2(150, 100))
	_add_rect_obstacle(Vector2(456, 258), Vector2(130, 80))
	_add_rect_obstacle(Vector2(342, 370), Vector2(68, 42))

func _is_path_position(position: Vector2) -> bool:
	if position.x < 1140.0 and position.y > 368.0 and position.y < 544.0:
		return true
	return position.distance_to(CLEARING_POSITION) < 150.0

func _is_building_position(position: Vector2) -> bool:
	return Rect2(72, 120, 224, 220).has_point(position) \
		or Rect2(360, 165, 192, 180).has_point(position) \
		or Rect2(296, 328, 102, 82).has_point(position)

func _add_rect_obstacle(position: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = position
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_circle_obstacle(position: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.position = position
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _build_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(250, 448)
	player.set_script(PLAYER_SCRIPT)
	player.set("move_speed", 175.0)
	player.set("movement_enabled", true)
	var shape := CapsuleShape2D.new()
	shape.radius = 10.0
	shape.height = 30.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	player.add_child(collision)

	var shadow := ColorRect.new()
	shadow.position = Vector2(-13, 4)
	shadow.size = Vector2(26, 10)
	shadow.color = Color(0.08, 0.12, 0.08, 0.42)
	player.add_child(shadow)
	_add_sprite_rect(player, Vector2(-9, -18), Vector2(18, 19), Color("d5b34f"))
	_add_sprite_rect(player, Vector2(-7, -27), Vector2(14, 13), Color("e6c19a"))
	_add_sprite_rect(player, Vector2(-8, -29), Vector2(16, 7), Color("574435"))
	_add_sprite_rect(player, Vector2(-9, -2), Vector2(7, 12), Color("45556a"))
	_add_sprite_rect(player, Vector2(2, -2), Vector2(7, 12), Color("45556a"))

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_SIZE.x)
	camera.limit_bottom = int(WORLD_SIZE.y)
	player.add_child(camera)
	add_child(player)

func _build_npc() -> void:
	npc = StaticBody2D.new()
	npc.name = "Mira"
	npc.position = Vector2(344, 448)
	var shape := CircleShape2D.new()
	shape.radius = 13.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	npc.add_child(collision)
	_add_sprite_rect(npc, Vector2(-9, -17), Vector2(18, 20), Color("5984a3"))
	_add_sprite_rect(npc, Vector2(-7, -27), Vector2(14, 13), Color("e9c79e"))
	_add_sprite_rect(npc, Vector2(-8, -29), Vector2(16, 6), Color("493c36"))
	add_child(npc)

func _add_sprite_rect(parent: Node2D, offset: Vector2, size: Vector2, color: Color) -> void:
	var rect := ColorRect.new()
	rect.position = offset
	rect.size = size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)

func _build_interface() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(screen)

	var hud := _make_panel(screen, Rect2(18, 18, 430, 124))
	var hud_content := VBoxContainer.new()
	hud_content.add_theme_constant_override("separation", 6)
	hud.add_child(hud_content)
	var title := _make_label("CHRONO CHRONICLES  /  GREENVALE", 18, Color("f4e3b8"))
	hud_content.add_child(title)
	objective_label = _make_label("", 15, Color("e8eddb"))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_content.add_child(objective_label)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	hud_content.add_child(stats)
	var hp_text := _make_label("HP", 14, Color("f4e3b8"))
	stats.add_child(hp_text)
	hp_bar = _make_bar(Color("70c17b"))
	hp_bar.custom_minimum_size = Vector2(170, 18)
	stats.add_child(hp_bar)
	gold_label = _make_label("0 G", 14, Color("f0cf75"))
	stats.add_child(gold_label)

	var controls := _make_panel(screen, Rect2(720, 18, 258, 76))
	var controls_label := _make_label("WASD / Arrows  Move\nE  Talk / interact", 14, Color("e8eddb"))
	controls.add_child(controls_label)

	prompt_panel = _make_panel(screen, Rect2(310, 540, 340, 48))
	prompt_label = _make_label("", 15, Color("fff0c8"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_panel.add_child(prompt_label)

	dialogue_panel = _make_panel(screen, Rect2(22, 424, 936, 156))
	var dialogue_content := VBoxContainer.new()
	dialogue_content.add_theme_constant_override("separation", 8)
	dialogue_panel.add_child(dialogue_content)
	dialogue_label = _make_label("", 18, Color("fff0d0"))
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size.y = 76
	dialogue_content.add_child(dialogue_label)
	dialogue_hint = _make_label("E  Continue", 13, Color("b9d1c0"))
	dialogue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialogue_content.add_child(dialogue_hint)
	dialogue_panel.hide()

	_build_battle_interface(screen)
	_update_hud()

func _build_battle_interface(screen: Control) -> void:
	battle_overlay = ColorRect.new()
	battle_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_overlay.color = Color(0.03, 0.06, 0.08, 0.82)
	battle_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(battle_overlay)
	battle_overlay.hide()

	var panel := _make_panel(battle_overlay, Rect2(245, 112, 470, 380))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	panel.add_child(content)
	content.add_child(_make_label("A WILD SHADE APPEARS", 20, Color("f3d890")))
	content.add_child(_make_label("Forest clearing  /  One enemy", 13, Color("c1d0c0")))
	enemy_hp_bar = _make_bar(Color("d16c62"))
	enemy_hp_bar.custom_minimum_size.y = 22
	content.add_child(enemy_hp_bar)
	battle_log = _make_label("The shade blocks the path.", 15, Color("fff0d0"))
	battle_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_log.custom_minimum_size.y = 44
	content.add_child(battle_log)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	var attack_button := _make_button("Attack")
	attack_button.pressed.connect(_attack)
	actions.add_child(attack_button)
	var guard_button := _make_button("Guard")
	guard_button.pressed.connect(_guard)
	actions.add_child(guard_button)
	potion_button = _make_button("Potion (1)")
	potion_button.pressed.connect(_use_potion)
	actions.add_child(potion_button)

	battle_result_button = _make_button("Return to the village")
	battle_result_button.pressed.connect(_leave_battle)
	battle_result_button.hide()
	content.add_child(battle_result_button)

func _make_panel(parent: Control, rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("24372f")
	style.border_color = Color("b99a69")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("18241f")
	background.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(124, 42)
	button.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("536f59")
	normal.border_color = Color("9fb58a")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("698a68")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color("fff0d0"))
	return button

func _process(_delta: float) -> void:
	if player == null:
		return
	_update_prompt()
	if quest_step == 1 and not encounter_started and player.global_position.distance_to(CLEARING_POSITION) < 76.0:
		_start_battle()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and not battle_active:
		if dialogue_active:
			_advance_dialogue()
		elif player.global_position.distance_to(npc.global_position) < 76.0:
			_talk_to_mira()
		get_viewport().set_input_as_handled()

func _update_prompt() -> void:
	if battle_active or dialogue_active:
		prompt_panel.hide()
		return
	if player.global_position.distance_to(npc.global_position) < 76.0:
		prompt_label.text = "E  Talk to Mira"
		prompt_panel.show()
	elif quest_step == 1 and player.global_position.distance_to(CLEARING_POSITION) < 210.0:
		prompt_label.text = "The forest clearing is just ahead..."
		prompt_panel.show()
	else:
		prompt_panel.hide()

func _talk_to_mira() -> void:
	if quest_step == 0:
		dialogue_lines = [
			"Mira: The forest path has gone quiet. Something has driven the shades out of the old clearing.",
			"Could you check the clearing east of here? Take this potion. I will keep the village safe."
		]
		quest_step = 1
		potions = 1
	elif quest_step == 1:
		dialogue_lines = ["Mira: Follow the dirt path east. The clearing is beyond the old gate."]
	else:
		dialogue_lines = ["Mira: Greenvale is peaceful again. Thank you, friend."]
	dialogue_index = 0
	dialogue_active = true
	dialogue_panel.show()
	_show_dialogue_line()
	_update_hud()

func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		dialogue_active = false
		dialogue_panel.hide()
	else:
		_show_dialogue_line()

func _show_dialogue_line() -> void:
	dialogue_label.text = dialogue_lines[dialogue_index]
	dialogue_hint.text = "E  Continue  (%d/%d)" % [dialogue_index + 1, dialogue_lines.size()]

func _start_battle() -> void:
	encounter_started = true
	battle_active = true
	battle_won = false
	enemy_hp = ENEMY_MAX_HP
	player.set("movement_enabled", false)
	battle_log.text = "A shade lunges from the trees! Choose an action."
	battle_result_button.hide()
	_set_battle_actions_visible(true)
	battle_overlay.show()
	_update_battle_hud()

func _attack() -> void:
	if not battle_active:
		return
	var damage := randi_range(17, 25)
	enemy_hp = maxi(enemy_hp - damage, 0)
	battle_log.text = "You strike the shade for %d damage." % damage
	_update_battle_hud()
	if enemy_hp == 0:
		_finish_battle(true)
	else:
		_enemy_turn()

func _guard() -> void:
	if not battle_active:
		return
	guarding = true
	battle_log.text = "You brace yourself for the shade's attack."
	_enemy_turn()

func _use_potion() -> void:
	if not battle_active or potions <= 0 or player_hp >= PLAYER_MAX_HP:
		return
	var restored := mini(35, PLAYER_MAX_HP - player_hp)
	player_hp += restored
	potions -= 1
	battle_log.text = "You use a potion and recover %d HP." % restored
	_update_battle_hud()
	_enemy_turn()

func _enemy_turn() -> void:
	var damage := randi_range(9, 15)
	if guarding:
		damage = ceili(damage * 0.5)
		guarding = false
	player_hp = maxi(player_hp - damage, 0)
	battle_log.text += "\nThe shade hits you for %d damage." % damage
	_update_battle_hud()
	_update_hud()
	if player_hp == 0:
		_finish_battle(false)

func _finish_battle(victory: bool) -> void:
	battle_active = false
	battle_won = victory
	_set_battle_actions_visible(false)
	if victory:
		battle_log.text = "The shade dissolves into the forest light. The path is safe!"
		battle_result_button.text = "Return to the village"
	else:
		battle_log.text = "You fall back from the clearing. Mira helps you recover."
		battle_result_button.text = "Recover and try again"
	battle_result_button.show()

func _leave_battle() -> void:
	battle_overlay.hide()
	if battle_won:
		quest_step = 2
		gold += 75
	else:
		player_hp = PLAYER_MAX_HP
		encounter_started = false
	player.set("movement_enabled", true)
	_update_hud()
	if battle_won:
		_show_completion_message()

func _show_completion_message() -> void:
	dialogue_lines = ["Mira: You made it back! Here is 75 gold for helping our village."]
	dialogue_index = 0
	dialogue_active = true
	dialogue_panel.show()
	_show_dialogue_line()

func _set_battle_actions_visible(visible: bool) -> void:
	var actions := battle_overlay.get_node_or_null("PanelContainer/VBoxContainer/HBoxContainer")
	if actions != null:
		actions.visible = visible

func _update_hud() -> void:
	if objective_label == null:
		return
	match quest_step:
		0:
			objective_label.text = "Objective: Speak with Mira near the village gate."
		1:
			objective_label.text = "Objective: Follow the eastern path and clear the forest clearing."
		_:
			objective_label.text = "Quest complete: The forest path is safe. Explore Greenvale!"
	hp_bar.value = float(player_hp) / PLAYER_MAX_HP * 100.0
	gold_label.text = "%d G" % gold

func _update_battle_hud() -> void:
	enemy_hp_bar.value = float(enemy_hp) / ENEMY_MAX_HP * 100.0
	potion_button.text = "Potion (%d)" % potions
	potion_button.disabled = potions <= 0 or player_hp >= PLAYER_MAX_HP
