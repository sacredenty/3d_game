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
	_check(game.get("world_tiles").get_used_cells().size() == 1500, "The overworld should use the complete tile atlas")
	player.global_position = game.get("npc").global_position
	game.call("_talk_to_mira")
	_check(game.get("quest_step") == 1, "Talking to Mira should unlock the first forest objective")
	_check(game.get("potions") == 1, "Mira should equip the player with a potion")
	game.call("_advance_dialogue")
	game.call("_advance_dialogue")

	_interact_at(game, player, Vector2(880, 448))
	_check(game.get("salve_collected"), "The trail potion should be collected")
	_check(game.get("potions") == 2, "The trail potion should increase the inventory")
	_interact_at(game, player, Vector2(1210, 390))
	_check(game.get("cache_opened"), "The optional supply cache should be opened")
	_check(game.get("gold") == 40, "The supply cache should award 40 gold")
	_interact_at(game, player, Vector2(1150, 570))
	_check(game.get("waystone_discovered"), "The ancient waystone should count as a discovery")
	_check(game.get("player_experience") == 25, "The waystone should award its discovery XP")
	var gold_after_cache: int = game.get("gold")
	_interact_at(game, player, Vector2(1210, 390))
	_check(game.get("gold") == gold_after_cache, "The cache reward should only be claimed once")
	game.set("player_hp", 45)
	game.set("player_mp", 3)
	_interact_at(game, player, Vector2(1220, 660))
	_check(game.get("player_hp") == game.call("max_hp"), "The campfire should fully restore HP")
	_check(game.get("player_mp") == game.call("max_mp"), "The campfire should fully restore MP")
	_check(not game.get("exploration_markers").get("salve").visible, "Collected potion should disappear from the world")
	_check(not game.get("exploration_markers").get("cache").visible, "Opened cache should disappear from the world")
	_check(not game.get("exploration_markers").get("waystone").visible, "Discovered waystone should disappear from the world")

	game.call("_start_battle", "shade")
	var flee_battle: Node = game.get("battle_instance")
	flee_battle.call("_flee")
	flee_battle.get("result_button").emit_signal("pressed")
	_check(game.get("quest_step") == 1, "Fleeing should leave the quest in progress")
	_check(not game.get("encounter_started"), "Fleeing should allow another encounter attempt")
	game.call("_start_battle", "shade")
	var defeat_battle: Node = game.get("battle_instance")
	defeat_battle.call("_finish", "defeat")
	defeat_battle.get("result_button").emit_signal("pressed")
	_check(game.get("quest_step") == 1, "Defeat should not advance the quest")
	_check(game.get("player_hp") == 100, "Defeat should restore the player at the village")

	game.call("_start_battle", "shade")
	var shade_battle: Node = game.get("battle_instance")
	_check(shade_battle.get("enemy_name") == "Forest Shade", "The first encounter should use the shade battle setup")
	_check(shade_battle.get("weakness") == "fire", "The shade should be weak to fire")
	_check(shade_battle.get("intent_label").text == "Intent: Heavy strike", "The battle should telegraph the shade's heavy attack")
	shade_battle.set("enemy_hp", 500)
	shade_battle.call("_update_ui")
	var shade_hp_before_magic: int = shade_battle.get("enemy_hp")
	shade_battle.call("_cast_magic")
	var shade_magic_damage: int = shade_hp_before_magic - int(shade_battle.get("enemy_hp"))
	_check(shade_magic_damage >= 51 and shade_magic_damage <= 54, "Ember should deal bonus damage to the shade")
	_check(shade_battle.get("intent_label").text == "Intent: Shadow swipe", "The shade should show its next intent after acting")
	var attack_button := _find_button(shade_battle, "Attack")
	if attack_button != null:
		var first_enemy_hp: int = shade_battle.get("enemy_hp")
		attack_button.emit_signal("pressed")
		_check(shade_battle.get("enemy_hp") < first_enemy_hp, "The reusable battle Attack button should damage the enemy")
	else:
		_check(false, "Battle should display an Attack button")
	var first_mp: int = shade_battle.get("player_mp")
	shade_battle.call("_cast_magic")
	_check(shade_battle.get("player_mp") == first_mp - 8, "Ember should spend 8 MP")
	var first_potions: int = shade_battle.get("potions")
	shade_battle.set("player_hp", mini(shade_battle.get("player_hp"), 90))
	shade_battle.call("_use_potion")
	_check(shade_battle.get("potions") == first_potions - 1, "Potion should restore HP and consume a charge")
	var guarded_hp: int = shade_battle.get("player_hp")
	shade_battle.call("_guard")
	_check(guarded_hp - shade_battle.get("player_hp") <= 10, "Guard should reduce the next enemy hit")
	shade_battle.call("_finish", "victory")
	shade_battle.result_button.emit_signal("pressed")
	_check(not game.get("battle_active"), "Closing battle results should resume world movement")
	_check(game.get("quest_step") == 2, "Defeating the shade should lead back to Mira")
	_check(game.get("player_experience") == 45, "Shade and discovery XP should carry over after leveling")
	_check(game.get("player_level") == 2, "Shade XP should level the player")
	_check(game.get("player_hp") == 120, "Leveling should increase and restore maximum HP")
	_check(game.get("player_mp") == 36, "Leveling should increase and restore maximum MP")

	player.global_position = game.get("npc").global_position
	game.call("_talk_to_mira")
	_check(game.get("quest_step") == 3, "Returning to Mira should unlock the southern trail")
	_check(game.get("gold") == 115, "The first quest should grant its reward exactly once")
	_check(game.get("potions") == 2, "Mira should provide a potion without removing trail supplies")
	game.call("_advance_dialogue")
	game.call("_advance_dialogue")
	player.global_position = Vector2(1360, 704)
	game.call("_process", 0.0)
	_check(game.get("battle_active"), "Reaching the southern clearing should start the second fight")
	var wolf_battle: Node = game.get("battle_instance")
	_check(wolf_battle.get("enemy_name") == "Bramble Wolf", "The second encounter should use a distinct enemy")
	_check(wolf_battle.get("enemy_max_hp") == 164, "The second enemy should have its own combat stats")
	_check(wolf_battle.get("weakness") == "physical", "The wolf should be weak to physical attacks")
	_check(wolf_battle.get("intent_label").text == "Intent: Quick bite", "The wolf should telegraph its opening move")
	_check(wolf_battle.get("enemy_art").texture != null, "Each battle enemy should have visible artwork")
	var wolf_hp_before_attack: int = wolf_battle.get("enemy_hp")
	wolf_battle.call("_attack")
	var wolf_attack_damage: int = wolf_hp_before_attack - int(wolf_battle.get("enemy_hp"))
	_check(wolf_attack_damage >= 32 and wolf_attack_damage <= 42, "Physical attacks should exploit the wolf's weakness")
	wolf_battle.call("_finish", "victory")
	wolf_battle.result_button.emit_signal("pressed")
	_check(game.get("quest_step") == 4, "Defeating the wolf should lead back to Mira")
	_check(game.get("player_experience") == 80, "The second fight should award its distinct XP reward")
	player.global_position = game.get("npc").global_position
	game.call("_talk_to_mira")
	_check(game.get("quest_step") == 5, "Reporting to Mira should complete the adventure")
	_check(game.get("gold") == 240, "The two quests and optional cache should grant their rewards")
	_check(game.get("new_game_button").visible, "Completed adventure should offer a new game")
	var saved_hp: int = game.get("player_hp")
	var saved_mp: int = game.get("player_mp")

	game.queue_free()
	await process_frame
	var resumed_game: Node = load("res://scenes/game.tscn").instantiate()
	resumed_game.set("progress_save_path", save_path)
	root.add_child(resumed_game)
	await process_frame
	_check(resumed_game.get("quest_step") == 5, "Adventure completion should persist after restarting")
	_check(resumed_game.get("gold") == 240, "All gold rewards should persist after restarting")
	_check(resumed_game.get("player_hp") == saved_hp, "HP should persist after restarting")
	_check(resumed_game.get("player_mp") == saved_mp, "MP should persist after restarting")
	_check(resumed_game.get("player_level") == 3, "Level should persist after restarting")
	_check(resumed_game.get("player_experience") == 80, "XP should persist after restarting")
	_check(resumed_game.get("potions") == 2, "Potion count should persist after restarting")
	_check(resumed_game.get("salve_collected"), "Collected potion should persist after restarting")
	_check(resumed_game.get("cache_opened"), "Opened cache should persist after restarting")
	_check(resumed_game.get("waystone_discovered"), "Waystone discovery should persist after restarting")
	_check(not resumed_game.get("exploration_markers").get("salve").visible, "Saved pickups should remain absent from the world")
	resumed_game.get("new_game_dialog").confirmed.emit()
	_check(resumed_game.get("quest_step") == 0, "Confirmed new game should reset quest progress")
	_check(resumed_game.get("gold") == 0, "Confirmed new game should reset gold")
	_check(resumed_game.get("player_hp") == 100, "Confirmed new game should restore starting HP")
	_check(resumed_game.get("player_mp") == 30, "Confirmed new game should restore starting MP")
	_check(resumed_game.get("player_level") == 1, "Confirmed new game should reset level")
	_check(resumed_game.get("player_experience") == 0, "Confirmed new game should reset XP")
	_check(resumed_game.get("potions") == 0, "Confirmed new game should reset potions")
	_check(not resumed_game.get("salve_collected"), "New game should reset exploration discoveries")
	resumed_game.queue_free()
	await process_frame

	for old_version in [1, 2, 3]:
		var old_save := FileAccess.open(save_path, FileAccess.WRITE)
		old_save.store_string(JSON.stringify({
			"version": old_version,
			"quest_step": 2 if old_version < 3 else 5,
			"gold": 75,
			"player_hp": 100,
			"player_mp": 30,
			"player_level": 1,
			"player_experience": 0,
			"potions": 0
		}))
		old_save.close()
		var migrated_game: Node = load("res://scenes/game.tscn").instantiate()
		migrated_game.set("progress_save_path", save_path)
		root.add_child(migrated_game)
		await process_frame
		_check(migrated_game.get("quest_step") == (3 if old_version < 3 else 5), "Save migration should preserve or continue completed quest progress")
		_check(migrated_game.get("gold") == 75, "Migration should preserve existing rewards")
		_check(not migrated_game.get("salve_collected"), "Older saves should default exploration rewards to unclaimed")
		migrated_game.queue_free()
		await process_frame

	if FileAccess.file_exists(save_path):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		_check(remove_error == OK, "Test save file should be removed")
	quit(failures)

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _find_button(parent: Node, text: String) -> Button:
	for button in parent.find_children("*", "Button", true, false):
		if button.text == text:
			return button
	return null

func _interact_at(game: Node, player: CharacterBody2D, position: Vector2) -> void:
	player.global_position = position
	game.call("_interact_with_world")
	if game.get("dialogue_active"):
		game.call("_advance_dialogue")
