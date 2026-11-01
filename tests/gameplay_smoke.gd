extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_path := "user://gameplay_smoke_save.json"
	var game: Node = load("res://scenes/game.tscn").instantiate()
	game.set("progress_save_path", save_path)
	root.add_child(game)
	await process_frame

	var player: CharacterBody2D = game.get("player")
	_check(game.get("quest_step") == 0, "New game should start with the village objective")
	var ground: TileMapLayer = game.get("world_tiles")
	_check(ground.get_used_cells().size() == 1500, "The overworld should use the complete tile atlas")
	_check(player.get_node("CharacterSprite").texture.get_size() == Vector2(24, 32), "Player should use pixel-art sprite frames")
	_check(game.get("npc").get_node("CharacterSprite").texture.get_size() == Vector2(24, 32), "NPC should use pixel art")
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
	game.call("_flee")
	_check(not game.get("battle_active") and game.get("battle_fled"), "Flee should end combat without a victory")
	game.call("_leave_battle")
	_check(game.get("quest_step") == 1, "Fleeing should leave the quest in progress")
	game.call("_start_battle")
	game.set("enemy_hp", 1000)
	game.call("_update_battle_hud")
	game.call("_cast_magic")
	game.call("_cast_magic")
	game.call("_cast_magic")
	_check(game.get("player_mp") == 6, "Each Ember cast should cost exactly 8 MP")
	var enemy_hp_before_empty_cast: int = game.get("enemy_hp")
	game.call("_cast_magic")
	_check(game.get("player_mp") == 6, "Magic should not cast without enough MP")
	_check(game.get("enemy_hp") == enemy_hp_before_empty_cast, "An unaffordable spell should not damage the enemy")
	game.call("_finish_battle", false)
	game.call("_leave_battle")
	_check(game.get("quest_step") == 1, "Defeat should not complete the quest")
	_check(game.get("player_hp") == 100, "Defeat should return the player to the village at full HP")
	_check(game.get("player_mp") == 30, "Defeat should restore starting MP at the village")

	player.global_position = Vector2(1330, 448)
	game.call("_process", 0.0)
	_check(game.get("battle_active"), "Entering the clearing should start the encounter")
	var attack_button: Button
	for button in game.find_children("*", "Button", true, false):
		if button.text == "Attack":
			attack_button = button
			break
	_check(attack_button != null, "Battle should display a working Attack button")
	var initial_enemy_hp: int = game.get("enemy_hp")
	attack_button.emit_signal("pressed")
	_check(game.get("enemy_hp") < initial_enemy_hp, "The Attack button should damage the enemy")
	var initial_mp: int = game.get("player_mp")
	initial_enemy_hp = game.get("enemy_hp")
	for button in game.find_children("*", "Button", true, false):
		if button.text == "Magic (8 MP)":
			button.emit_signal("pressed")
			break
	_check(game.get("player_mp") == initial_mp - 8, "Magic should spend its MP cost")
	_check(game.get("enemy_hp") < initial_enemy_hp, "Magic should damage the enemy")
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
	_check(game.get("player_level") == 2, "Earning 80 XP should grant the first level")
	_check(game.get("player_experience") == 20, "XP above the level threshold should carry over")
	_check(game.get("player_hp") == 120, "Leveling should increase and restore maximum HP")
	_check(game.get("player_mp") == 36, "Leveling should increase and restore maximum MP")
	_check(not game.get("battle_active"), "The world should resume after the battle")
	var saved_hp: int = game.get("player_hp")
	var saved_mp: int = game.get("player_mp")

	game.queue_free()
	await process_frame
	var resumed_game: Node = load("res://scenes/game.tscn").instantiate()
	resumed_game.set("progress_save_path", save_path)
	root.add_child(resumed_game)
	await process_frame
	_check(resumed_game.get("quest_step") == 2, "Completed quest should persist after restarting")
	_check(resumed_game.get("gold") == 75, "Gold should persist after restarting")
	_check(resumed_game.get("player_hp") == saved_hp, "HP should persist after restarting")
	_check(resumed_game.get("player_mp") == saved_mp, "MP should persist after restarting")
	_check(resumed_game.get("player_level") == 2, "Level should persist after restarting")
	_check(resumed_game.get("player_experience") == 20, "XP should persist after restarting")
	_check(resumed_game.get("potions") == 0, "Potion count should persist after restarting")
	_check(resumed_game.get("new_game_button").visible, "Completed save should offer a new game")
	resumed_game.call("_confirm_new_game")
	_check(resumed_game.get("new_game_dialog").visible, "Starting a new game should request confirmation")
	resumed_game.get("new_game_dialog").confirmed.emit()
	_check(resumed_game.get("quest_step") == 0, "Confirmed new game should reset quest progress")
	_check(resumed_game.get("gold") == 0, "Confirmed new game should reset gold")
	_check(resumed_game.get("player_hp") == 100, "Confirmed new game should restore starting HP")
	_check(resumed_game.get("player_mp") == 30, "Confirmed new game should restore starting MP")
	_check(resumed_game.get("player_level") == 1, "Confirmed new game should reset level")
	_check(resumed_game.get("player_experience") == 0, "Confirmed new game should reset XP")
	_check(resumed_game.get("potions") == 0, "Confirmed new game should reset potions")
	resumed_game.queue_free()
	await process_frame
	var fresh_game: Node = load("res://scenes/game.tscn").instantiate()
	fresh_game.set("progress_save_path", save_path)
	root.add_child(fresh_game)
	await process_frame
	_check(fresh_game.get("quest_step") == 0, "New game state should persist after restarting")
	_check(fresh_game.get("gold") == 0, "Reset gold should persist after restarting")
	_check(fresh_game.get("player_level") == 1, "Reset level should persist after restarting")
	fresh_game.queue_free()
	await process_frame

	var save_file := FileAccess.open(save_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify({
		"version": 1,
		"quest_step": 1,
		"gold": 12,
		"player_hp": 70,
		"potions": 1
	}))
	save_file.close()
	var migrated_game: Node = load("res://scenes/game.tscn").instantiate()
	migrated_game.set("progress_save_path", save_path)
	root.add_child(migrated_game)
	await process_frame
	_check(migrated_game.get("quest_step") == 1, "Version 1 saves should retain quest progress")
	_check(migrated_game.get("gold") == 12, "Version 1 saves should retain gold")
	_check(migrated_game.get("player_hp") == 70, "Version 1 saves should retain HP")
	_check(migrated_game.get("potions") == 1, "Version 1 saves should retain potions")
	_check(migrated_game.get("player_level") == 1, "Version 1 saves should migrate to level 1")
	_check(migrated_game.get("player_experience") == 0, "Version 1 saves should migrate with no XP")
	_check(migrated_game.get("player_mp") == 30, "Version 1 saves should receive starting MP")
	migrated_game.queue_free()
	await process_frame
	var absolute_save_path := ProjectSettings.globalize_path(save_path)
	if FileAccess.file_exists(save_path):
		var remove_error := DirAccess.remove_absolute(absolute_save_path)
		_check(remove_error == OK, "Test save file should be removed")
	quit(failures)

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
