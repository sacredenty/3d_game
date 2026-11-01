extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame

	var player: CharacterBody2D = game.get("player")
	_check(game.get("quest_step") == 0, "New game should start with the village objective")
	var starting_x: float = player.global_position.x
	Input.action_press("move_right")
	for frame in range(20):
		await physics_frame
	Input.action_release("move_right")
	_check(player.global_position.x > starting_x, "Player should move using the configured controls")
	player.global_position = game.get("npc").global_position
	game.call("_update_prompt")
	_check(game.get("prompt_panel").visible, "The nearby NPC should show an interaction prompt")
	var interact := InputEventKey.new()
	interact.physical_keycode = KEY_E
	interact.pressed = true
	game.call("_unhandled_input", interact)
	_check(game.get("dialogue_active"), "Pressing interact near Mira should start dialogue")

	_check(game.get("quest_step") == 1, "Talking to Mira should unlock the forest objective")
	game.call("_advance_dialogue")
	game.call("_advance_dialogue")
	_check(not game.get("dialogue_active"), "Dialogue should close after its final line")

	game.call("_start_battle")
	var attack_button: Button
	for button in game.find_children("*", "Button", true, false):
		if button.text == "Attack":
			attack_button = button
			break
	_check(attack_button != null, "Battle should display a working Attack button")
	var initial_enemy_hp: int = game.get("enemy_hp")
	attack_button.emit_signal("pressed")
	_check(game.get("enemy_hp") < initial_enemy_hp, "The Attack button should damage the enemy")
	var initial_potions: int = game.get("potions")
	for button in game.find_children("*", "Button", true, false):
		if button.text == "Potion (1)":
			button.emit_signal("pressed")
			break
	_check(game.get("potions") == initial_potions - 1, "The potion action should consume its charge")
	var hp_before_guard: int = game.get("player_hp")
	for button in game.find_children("*", "Button", true, false):
		if button.text == "Guard":
			button.emit_signal("pressed")
			break
	_check(hp_before_guard - game.get("player_hp") <= 8, "Guard should reduce the next enemy hit")

	var turns := 0
	while game.get("battle_active") and turns < 10:
		game.call("_attack")
		turns += 1
	_check(game.get("battle_won"), "The player should be able to defeat the clearing enemy")
	_check(game.get("player_hp") > 0, "The player should survive a normal winning fight")

	game.call("_leave_battle")
	_check(game.get("quest_step") == 2, "Victory should complete the quest")
	_check(game.get("gold") == 75, "Victory should award the promised gold")
	_check(not game.get("battle_active"), "The world should resume after the battle")

	game.queue_free()
	await process_frame
	quit(failures)

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
