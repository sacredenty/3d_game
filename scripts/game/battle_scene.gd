extends Node

signal finished(outcome: String, hp: int, mp: int, potion_count: int, experience: int, gold: int)

var enemy_name: String = "Shade"
var enemy_max_hp: int = 112
var enemy_hp: int = 112
var enemy_damage: Vector2i = Vector2i(10, 15)
var victory_experience: int = 80
var victory_gold: int = 0
var enemy_color := Color("647b9a")
var weakness: String = "fire"
var intent_pattern: PackedStringArray = PackedStringArray(["Heavy strike", "Shadow swipe", "Shadow swipe"])
var intent_index: int = 0
var enemy_warding: bool = false
var additional_enemy: Dictionary = {}
var target_index: int = 0
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
var enemy_target_buttons: HBoxContainer
var primary_target_button: Button
var additional_target_button: Button
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
		defense_bonus: int = 0,
		additional_foe: Dictionary = {},
		gold_reward: int = 0
) -> void:
	enemy_name = foe_name
	enemy_max_hp = foe_hp
	enemy_hp = foe_hp
	enemy_damage = foe_damage
	victory_experience = xp_reward
	victory_gold = gold_reward
	enemy_color = foe_color
	weakness = foe_weakness
	intent_pattern = foe_intents
	intent_index = 0
	enemy_warding = false
	additional_enemy = {}
	target_index = 0
	if not additional_foe.is_empty():
		additional_enemy = additional_foe.duplicate(true)
		additional_enemy["max_hp"] = int(additional_foe["hp"])
		additional_enemy["intent_index"] = 0
		additional_enemy["warding"] = false
		victory_experience += int(additional_foe.get("xp", 0))
		victory_gold += int(additional_foe.get("gold", 0))
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
	enemy_art.texture = _make_enemy_texture(enemy_color, enemy_name)
	AudioDirector.play_battle_theme()
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
	panel.position = Vector2(160, 50)
	panel.size = Vector2(640, 500)
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
	enemy_target_buttons = HBoxContainer.new()
	enemy_target_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_target_buttons.add_theme_constant_override("separation", 8)
	content.add_child(enemy_target_buttons)
	primary_target_button = _make_button("")
	primary_target_button.custom_minimum_size = Vector2(200, 34)
	primary_target_button.pressed.connect(_select_enemy.bind(0))
	enemy_target_buttons.add_child(primary_target_button)
	additional_target_button = _make_button("")
	additional_target_button.custom_minimum_size = Vector2(200, 34)
	additional_target_button.pressed.connect(_select_enemy.bind(1))
	enemy_target_buttons.add_child(additional_target_button)
	intent_label = _make_label("", 14, Color("f3c17b"))
	intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(intent_label)
	weakness_label = _make_label("", 13, Color("b8d7e8"))
	weakness_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(weakness_label)
	enemy_hp_bar = _make_bar(Color("d16c62"))
	enemy_hp_bar.custom_minimum_size.y = 22
	content.add_child(enemy_hp_bar)
	enemy_target_buttons.hide()
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
	AudioDirector.play_effect("attack")
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
	AudioDirector.play_effect("magic")
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
	AudioDirector.play_effect("hit")
	guarding = true
	_action_message("You guard against the next attack.")
	_after_player_action()

func _use_potion() -> void:
	var maximum_hp := 48 + hero_vitality * 4 + (player_level - 1) * 20
	if not active or potions <= 0 or player_hp >= maximum_hp:
		return
	AudioDirector.play_effect("potion")
	var restored := mini(35, maximum_hp - player_hp)
	player_hp += restored
	potions -= 1
	_action_message("You recover %d HP with a potion." % restored)
	_after_player_action()

func _flee() -> void:
	if not active:
		return
	AudioDirector.play_effect("hit")
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
	if not _enemy_is_alive(0) and not _enemy_is_alive(1):
		_finish("victory")
		return
	for foe_index in range(2 if not additional_enemy.is_empty() else 1):
		if not _enemy_is_alive(foe_index):
			continue
		_enemy_turn(foe_index)
		if player_hp == 0:
			break
	if target_index == 0 and not _enemy_is_alive(0) and _enemy_is_alive(1):
		target_index = 1
	elif target_index == 1 and not _enemy_is_alive(1) and _enemy_is_alive(0):
		target_index = 0
	_update_ui()
	if player_hp == 0:
		_finish("defeat")

func _enemy_turn(foe_index: int) -> void:
	var intent := _intent_for(foe_index)
	var foe_name := _enemy_name_for(foe_index)
	if intent == "Stone ward" or intent == "Shell guard":
		_set_enemy_warding(foe_index, true)
		battle_log.text += "\n%s raises its guard. Its next hit will be reduced." % foe_name
		_advance_enemy_intent(foe_index)
		return
	var damage_range: Vector2i = enemy_damage if foe_index == 0 else additional_enemy["damage"]
	var damage := randi_range(damage_range.x, damage_range.y) + (player_level - 1) * 2
	if intent.begins_with("Heavy"):
		damage = ceili(damage * 1.65)
	damage = maxi(damage - armor_defense, 1)
	if guarding:
		damage = ceili(damage * (0.25 if hero_class == "Warrior" else 0.4))
		guarding = false
	if randi_range(1, 100) <= _dodge_chance():
		battle_log.text += "\n%s uses %s, but you evade it!" % [foe_name, intent.to_lower()]
	else:
		player_hp = maxi(player_hp - damage, 0)
		AudioDirector.play_effect("hit")
		battle_log.text += "\n%s uses %s for %d damage." % [foe_name, intent.to_lower(), damage]
		if intent == "Cinder bolt":
			var drained_mp := mini(player_mp, 4)
			player_mp -= drained_mp
			if drained_mp > 0:
				battle_log.text += " It drains %d MP." % drained_mp
	_advance_enemy_intent(foe_index)

func _finish(outcome: String) -> void:
	active = false
	battle_outcome = outcome
	if outcome == "victory":
		AudioDirector.play_effect("victory")
	actions.hide()
	match outcome:
		"victory":
			battle_log.text = "%s defeated! You earned %d XP and found %d G." % [
				"Your foes are" if not additional_enemy.is_empty() else enemy_name + " is",
				victory_experience,
				victory_gold
			]
		"defeat":
			battle_log.text = "You were defeated by %s. Mira will help you recover." % _enemy_name_for(target_index)
	result_button.text = "Return to the forest" if outcome == "victory" else "Recover at the village"
	result_button.show()

func _leave_battle() -> void:
	layer.hide()
	finished.emit(
		battle_outcome,
		player_hp,
		player_mp,
		potions,
		victory_experience if battle_outcome == "victory" else 0,
		victory_gold if battle_outcome == "victory" else 0
	)

func _update_ui() -> void:
	if enemy_hp_bar == null:
		return
	var selected_hp := _enemy_hp_for(target_index)
	var selected_max_hp := _enemy_max_hp_for(target_index)
	enemy_hp_bar.value = float(selected_hp) / float(selected_max_hp) * 100.0
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
		enemy_title.text = "%s  ·  %d / %d HP" % [
			_enemy_name_for(target_index), selected_hp, selected_max_hp
		]
		primary_target_button.text = "1: %s  ·  %d HP" % [enemy_name, enemy_hp]
		primary_target_button.disabled = not _enemy_is_alive(0)
		additional_target_button.visible = not additional_enemy.is_empty()
		if not additional_enemy.is_empty():
			additional_target_button.text = "2: %s  ·  %d HP" % [
				str(additional_enemy["name"]), int(additional_enemy["hp"])
			]
			additional_target_button.disabled = not _enemy_is_alive(1)
		enemy_target_buttons.visible = not additional_enemy.is_empty()
		enemy_art.texture = _make_enemy_texture(
			_enemy_color_for(target_index), _enemy_name_for(target_index)
		)
	if intent_label != null:
		intent_label.text = "Enemy warded  ·  Intent: %s" % _current_intent() if _is_enemy_warding(target_index) \
			else "Intent: %s" % _current_intent()
	if weakness_label != null:
		weakness_label.text = "Weak to Ember" if _enemy_weakness_for(target_index) == "fire" \
			else "Weak to physical attacks"

func _current_intent() -> String:
	return _intent_for(target_index)

func _intent_for(foe_index: int) -> String:
	var pattern: PackedStringArray = intent_pattern if foe_index == 0 else additional_enemy.get(
		"intents", PackedStringArray()
	)
	var index := intent_index if foe_index == 0 else int(additional_enemy.get("intent_index", 0))
	if pattern.is_empty():
		return "Strike"
	return pattern[index]

func _enemy_is_alive(foe_index: int) -> bool:
	return enemy_hp > 0 if foe_index == 0 else (
		not additional_enemy.is_empty() and int(additional_enemy.get("hp", 0)) > 0
	)

func _enemy_name_for(foe_index: int) -> String:
	return enemy_name if foe_index == 0 else str(additional_enemy.get("name", "Enemy"))

func _enemy_hp_for(foe_index: int) -> int:
	return enemy_hp if foe_index == 0 else int(additional_enemy.get("hp", 0))

func _enemy_max_hp_for(foe_index: int) -> int:
	return enemy_max_hp if foe_index == 0 else int(additional_enemy.get("max_hp", 1))

func _enemy_weakness_for(foe_index: int) -> String:
	return weakness if foe_index == 0 else str(additional_enemy.get("weakness", "physical"))

func _enemy_color_for(foe_index: int) -> Color:
	return enemy_color if foe_index == 0 else additional_enemy.get("color", Color("647b9a"))

func _is_enemy_warding(foe_index: int) -> bool:
	return enemy_warding if foe_index == 0 else bool(additional_enemy.get("warding", false))

func _set_enemy_warding(foe_index: int, value: bool) -> void:
	if foe_index == 0:
		enemy_warding = value
	else:
		additional_enemy["warding"] = value

func _advance_enemy_intent(foe_index: int) -> void:
	var pattern: PackedStringArray = intent_pattern if foe_index == 0 else additional_enemy.get(
		"intents", PackedStringArray()
	)
	if pattern.is_empty():
		return
	if foe_index == 0:
		intent_index = (intent_index + 1) % pattern.size()
	else:
		additional_enemy["intent_index"] = (
			int(additional_enemy.get("intent_index", 0)) + 1
		) % pattern.size()

func _select_enemy(foe_index: int) -> void:
	if not active or not _enemy_is_alive(foe_index):
		return
	target_index = foe_index
	_update_ui()

func _damage_enemy(base_damage: int, damage_kind: String, message_format: String) -> String:
	var damage := base_damage
	var weakness_message := ""
	var target_name := _enemy_name_for(target_index)
	if _enemy_weakness_for(target_index) == damage_kind:
		damage = ceili(damage * 1.5)
		weakness_message = " Weakness!"
	if _is_enemy_warding(target_index):
		damage = ceili(damage * 0.5)
		_set_enemy_warding(target_index, false)
		weakness_message += " The ward absorbs part of the blow."
	if target_index == 0:
		enemy_hp = maxi(enemy_hp - damage, 0)
	else:
		additional_enemy["hp"] = maxi(int(additional_enemy["hp"]) - damage, 0)
	return "%s.%s" % [message_format % [target_name, damage], weakness_message]

func _dodge_chance() -> int:
	return mini(hero_agility * 2, 40) if hero_class == "Rogue" else 0

func _make_enemy_texture(_color: Color, foe_name: String = "") -> Texture2D:
	var asset_name := "forest_shade"
	match foe_name:
		"Bramble Wolf":
			asset_name = "bramble_wolf"
		"Ashwing":
			asset_name = "ashwing"
		"Thornback":
			asset_name = "thornback"
		"Cave Sentinel":
			asset_name = "cave_sentinel"
	var texture := load("res://assets/art/%s.svg" % asset_name) as Texture2D
	if texture == null:
		push_error("Could not load enemy artwork for %s" % foe_name)
	return texture
