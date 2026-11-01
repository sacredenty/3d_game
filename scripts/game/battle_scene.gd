extends Node

signal finished(outcome: String, hp: int, mp: int, potion_count: int, experience: int)

var enemy_name: String = "Shade"
var enemy_max_hp: int = 112
var enemy_hp: int = 112
var enemy_damage: Vector2i = Vector2i(10, 15)
var victory_experience: int = 80
var enemy_color := Color("647b9a")
var weakness: String = "fire"
var intent_pattern: PackedStringArray = PackedStringArray(["Heavy strike", "Shadow swipe", "Shadow swipe"])
var intent_index: int = 0
var enemy_warding: bool = false
var player_hp: int = 100
var player_mp: int = 30
var player_level: int = 1
var potions: int = 0
var hero_name: String = "Adventurer"
var hero_class: String = "Warrior"
var hero_vitality: int = 13
var hero_strength: int = 10
var hero_spirit: int = 12
var hero_agility: int = 10
var weapon_attack_bonus: int = 0
var weapon_magic_bonus: int = 0
var armor_defense: int = 0
var guarding: bool = false
var active: bool = false
var battle_outcome: String = ""

var layer: CanvasLayer
var enemy_hp_bar: ProgressBar
var enemy_title: Label
var battle_title: Label
var intent_label: Label
var weakness_label: Label
var enemy_art: TextureRect
var player_status: Label
var battle_log: Label
var potion_button: Button
var magic_button: Button
var actions: HBoxContainer
var result_button: Button

func _ready() -> void:
	_build_ui()

func start_battle(
		foe_name: String,
		foe_hp: int,
		foe_damage: Vector2i,
		xp_reward: int,
		foe_color: Color,
		foe_weakness: String,
		foe_intents: PackedStringArray,
		current_hp: int,
		current_mp: int,
		level: int,
		potion_count: int,
		combatant_name: String,
		combatant_class: String,
		vitality: int,
		strength: int,
		spirit: int,
		agility: int,
		attack_bonus: int = 0,
		magic_bonus: int = 0,
		defense_bonus: int = 0
) -> void:
	enemy_name = foe_name
	enemy_max_hp = foe_hp
	enemy_hp = foe_hp
	enemy_damage = foe_damage
	victory_experience = xp_reward
	enemy_color = foe_color
	weakness = foe_weakness
	intent_pattern = foe_intents
	intent_index = 0
	enemy_warding = false
	player_hp = current_hp
	player_mp = current_mp
	player_level = level
	potions = potion_count
	hero_name = combatant_name
	hero_class = combatant_class
	hero_vitality = vitality
	hero_strength = strength
	hero_spirit = spirit
	hero_agility = agility
	weapon_attack_bonus = attack_bonus
	weapon_magic_bonus = magic_bonus
	armor_defense = defense_bonus
	active = true
	battle_outcome = ""
	enemy_art.texture = _make_enemy_texture(enemy_color)
	battle_title.text = "CAVE ENCOUNTER" if enemy_name == "Cave Sentinel" else "FOREST ENCOUNTER"
	_update_ui()
	battle_log.text = "Choose an action. Watch the enemy's intent."
	actions.show()
	result_button.hide()
	layer.show()

func _build_ui() -> void:
	layer = CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(screen)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.03, 0.06, 0.08, 0.84)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(backdrop)

	var panel := PanelContainer.new()
	panel.position = Vector2(160, 68)
	panel.size = Vector2(640, 464)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("24372f")
	panel_style.border_color = Color("b99a69")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	screen.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	panel.add_child(content)
	battle_title = _make_label("", 13, Color("c1d0c0"))
	content.add_child(battle_title)
	player_status = _make_label("", 15, Color("c1d0c0"))
	player_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(player_status)
	enemy_art = TextureRect.new()
	enemy_art.custom_minimum_size = Vector2(96, 80)
	enemy_art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	enemy_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	content.add_child(enemy_art)
	enemy_title = _make_label("", 21, Color("f3d890"))
	enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(enemy_title)
	intent_label = _make_label("", 14, Color("f3c17b"))
	intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(intent_label)
	weakness_label = _make_label("", 13, Color("b8d7e8"))
	weakness_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(weakness_label)
	enemy_hp_bar = _make_bar(Color("d16c62"))
	enemy_hp_bar.custom_minimum_size.y = 22
	content.add_child(enemy_hp_bar)
	battle_log = _make_label("", 15, Color("fff0d0"))
	battle_log.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_log.custom_minimum_size.y = 58
	content.add_child(battle_log)

	actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	var attack_button := _make_button("Attack")
	attack_button.pressed.connect(_attack)
	actions.add_child(attack_button)
	magic_button = _make_button("Magic (8 MP)")
	magic_button.pressed.connect(_cast_magic)
	actions.add_child(magic_button)
	var guard_button := _make_button("Guard")
	guard_button.pressed.connect(_guard)
	actions.add_child(guard_button)
	potion_button = _make_button("Potion")
	potion_button.pressed.connect(_use_potion)
	actions.add_child(potion_button)
	var flee_button := _make_button("Flee")
	flee_button.pressed.connect(_flee)
	actions.add_child(flee_button)

	result_button = _make_button("Return to the forest")
	result_button.custom_minimum_size = Vector2(220, 42)
	result_button.pressed.connect(_leave_battle)
	content.add_child(result_button)
	layer.hide()

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
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
	button.custom_minimum_size = Vector2(110, 42)
	button.add_theme_font_size_override("font_size", 14)
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

func _unhandled_input(event: InputEvent) -> void:
	if not active or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1, KEY_A:
			_attack()
		KEY_2, KEY_M:
			_cast_magic()
		KEY_3, KEY_G:
			_guard()
		KEY_4, KEY_P:
			_use_potion()
		KEY_5, KEY_F, KEY_ESCAPE:
			_flee()
		_:
			return
	get_viewport().set_input_as_handled()

func _attack() -> void:
	if not active:
		return
	var damage := randi_range(18, 25) + (hero_strength - 10) * 2 \
		+ (player_level - 1) * 3 + weapon_attack_bonus
	if hero_class == "Warrior":
		damage += 4
	damage = maxi(damage, 1)
	var damage_result := _damage_enemy(damage, "physical", "You attack %s for %d damage")
	_action_message(damage_result)
	_after_player_action()

func _cast_magic() -> void:
	if not active or player_mp < 8:
		return
	player_mp -= 8
	var damage := 18 + hero_spirit * 2 + (player_level - 1) * 4 + weapon_magic_bonus
	if hero_class == "Mage":
		damage += 8
	var damage_result := _damage_enemy(damage, "fire", "Ember hits %s for %d damage")
	_action_message("%s (-8 MP)" % damage_result)
	_after_player_action()

func _guard() -> void:
	if not active:
		return
	guarding = true
	_action_message("You guard against the next attack.")
	_after_player_action()

func _use_potion() -> void:
	var maximum_hp := 48 + hero_vitality * 4 + (player_level - 1) * 20
	if not active or potions <= 0 or player_hp >= maximum_hp:
		return
	var restored := mini(35, maximum_hp - player_hp)
	player_hp += restored
	potions -= 1
	_action_message("You recover %d HP with a potion." % restored)
	_after_player_action()

func _flee() -> void:
	if not active:
		return
	active = false
	battle_outcome = "flee"
	actions.hide()
	battle_log.text = "You retreat from %s. Your quest is still waiting." % enemy_name
	result_button.text = "Retreat to the forest"
	result_button.show()

func _action_message(message: String) -> void:
	battle_log.text = message
	_update_ui()

func _after_player_action() -> void:
	if enemy_hp == 0:
		_finish("victory")
		return
	var damage := randi_range(enemy_damage.x, enemy_damage.y) + (player_level - 1) * 2
	var intent := _current_intent()
	if intent == "Stone ward":
		enemy_warding = true
		battle_log.text += "\n%s raises a stone ward. Its next hit will be reduced." % enemy_name
		if not intent_pattern.is_empty():
			intent_index = (intent_index + 1) % intent_pattern.size()
		_update_ui()
		return
	if intent.begins_with("Heavy"):
		damage = ceili(damage * 1.65)
	damage = maxi(damage - armor_defense, 1)
	if guarding:
		damage = ceili(damage * (0.25 if hero_class == "Warrior" else 0.4))
		guarding = false
	var evaded := randi_range(1, 100) <= _dodge_chance()
	if evaded:
		battle_log.text += "\n%s uses %s, but you evade it!" % [enemy_name, intent.to_lower()]
	else:
		player_hp = maxi(player_hp - damage, 0)
		battle_log.text += "\n%s uses %s for %d damage." % [enemy_name, intent.to_lower(), damage]
	if not intent_pattern.is_empty():
		intent_index = (intent_index + 1) % intent_pattern.size()
	_update_ui()
	if player_hp == 0:
		_finish("defeat")

func _finish(outcome: String) -> void:
	active = false
	battle_outcome = outcome
	actions.hide()
	match outcome:
		"victory":
			battle_log.text = "%s is defeated! You earned %d XP." % [enemy_name, victory_experience]
		"defeat":
			battle_log.text = "You were defeated by %s. Mira will help you recover." % enemy_name
	result_button.text = "Return to the forest" if outcome == "victory" else "Recover at the village"
	result_button.show()

func _leave_battle() -> void:
	layer.hide()
	finished.emit(battle_outcome, player_hp, player_mp, potions, victory_experience if battle_outcome == "victory" else 0)

func _update_ui() -> void:
	if enemy_hp_bar == null:
		return
	enemy_hp_bar.value = float(enemy_hp) / float(enemy_max_hp) * 100.0
	player_status.text = "%s  ·  %s LV %d  ·  HP %d/%d  ·  MP %d/%d" % [
		hero_name,
		hero_class,
		player_level,
		player_hp,
		48 + hero_vitality * 4 + (player_level - 1) * 20,
		player_mp,
		6 + hero_spirit * 2 + (player_level - 1) * 6
	]
	potion_button.text = "Potion (%d)" % potions
	potion_button.disabled = potions <= 0 or player_hp >= 48 + hero_vitality * 4 + (player_level - 1) * 20
	magic_button.disabled = player_mp < 8
	magic_button.text = "Magic (8 MP)" if player_mp >= 8 else "Magic (need MP)"
	if enemy_title != null:
		enemy_title.text = "%s  ·  %d HP" % [enemy_name, enemy_hp]
	if intent_label != null:
		intent_label.text = "Enemy warded  ·  Intent: %s" % _current_intent() if enemy_warding \
			else "Intent: %s" % _current_intent()
	if weakness_label != null:
		weakness_label.text = "Weak to Ember" if weakness == "fire" else "Weak to physical attacks"

func _current_intent() -> String:
	if intent_pattern.is_empty():
		return "Strike"
	return intent_pattern[intent_index]

func _damage_enemy(base_damage: int, damage_kind: String, message_format: String) -> String:
	var damage := base_damage
	var weakness_message := ""
	if weakness == damage_kind:
		damage = ceili(damage * 1.5)
		weakness_message = " Weakness!"
	if enemy_warding:
		damage = ceili(damage * 0.5)
		enemy_warding = false
		weakness_message += " The ward absorbs part of the blow."
	enemy_hp = maxi(enemy_hp - damage, 0)
	return "%s.%s" % [message_format % [enemy_name, damage], weakness_message]

func _dodge_chance() -> int:
	return mini(hero_agility * 2, 40) if hero_class == "Rogue" else 0

func _make_enemy_texture(color: Color) -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	if enemy_name == "Bramble Wolf":
		image.fill_rect(Rect2i(4, 12, 19, 9), color)
		image.fill_rect(Rect2i(18, 8, 10, 11), color.lightened(0.08))
		image.fill_rect(Rect2i(24, 13, 7, 5), color.lightened(0.12))
		image.fill_rect(Rect2i(19, 5, 4, 6), color.darkened(0.12))
		image.fill_rect(Rect2i(25, 6, 4, 5), color.darkened(0.12))
		image.fill_rect(Rect2i(6, 19, 4, 9), color.darkened(0.2))
		image.fill_rect(Rect2i(15, 19, 4, 9), color.darkened(0.2))
		image.fill_rect(Rect2i(23, 18, 4, 10), color.darkened(0.2))
		image.fill_rect(Rect2i(2, 11, 5, 3), color.darkened(0.15))
		image.fill_rect(Rect2i(24, 11, 2, 2), Color("fff3bf"))
		return ImageTexture.create_from_image(image)
	image.fill_rect(Rect2i(5, 6, 22, 18), color.darkened(0.18))
	image.fill_rect(Rect2i(8, 3, 16, 20), color)
	image.fill_rect(Rect2i(3, 12, 6, 10), color.darkened(0.1))
	image.fill_rect(Rect2i(23, 10, 6, 12), color.darkened(0.1))
	image.fill_rect(Rect2i(9, 21, 14, 6), color.darkened(0.3))
	image.fill_rect(Rect2i(10, 12, 4, 3), Color("f3d987"))
	image.fill_rect(Rect2i(19, 12, 4, 3), Color("f3d987"))
	image.fill_rect(Rect2i(11, 13, 2, 2), Color("fff3bf"))
	image.fill_rect(Rect2i(20, 13, 2, 2), Color("fff3bf"))
	image.fill_rect(Rect2i(9, 27, 4, 4), color.lightened(0.15))
	image.fill_rect(Rect2i(19, 27, 4, 4), color.lightened(0.15))
	return ImageTexture.create_from_image(image)
