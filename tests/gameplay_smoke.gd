extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_path := "user://gameplay_smoke_save.json"
	_remove_test_file(save_path)
	var game: Node = load("res://scenes/game.tscn").instantiate()
	game.set("progress_save_path", save_path)
	root.add_child(game)
	await process_frame

	var player: CharacterBody2D = game.get("player")
	_check(game.get("creation_layer").visible, "A new game should begin with hero creation")
	var interact_during_creation := InputEventKey.new()
	interact_during_creation.physical_keycode = KEY_E
	interact_during_creation.pressed = true
	game.call("_unhandled_input", interact_during_creation)
	_check(not game.get("dialogue_active"), "World interactions should be blocked during hero creation")
	game.get("hero_class_picker").select(1)
	game.call("_on_hero_class_selected", 1)
	_check(game.get("hero_vitality") >= 8 and game.get("hero_vitality") <= 12, "Mage vitality rolls should match its class range")
	_check(game.get("hero_spirit") >= 14 and game.get("hero_spirit") <= 18, "Mage spirit rolls should match its class range")
	game.get("hero_class_picker").select(0)
	game.call("_on_hero_class_selected", 0)
	_check(game.get("hero_strength") >= 13 and game.get("hero_strength") <= 17, "Warrior strength rolls should match its class range")
	game.get("hero_name_input").text = "   "
	game.call("_confirm_hero_creation")
	_check(game.get("creation_layer").visible, "Hero creation should require a non-empty name")
	game.get("hero_name_input").text = "Ari"
	game.call("_confirm_hero_creation")
	_check(not game.get("creation_layer").visible, "Confirming hero creation should begin the adventure")
	_check(game.get("hero_name") == "Ari", "The chosen hero name should be applied")
	_check(game.get("hero_class") == "Warrior", "The chosen hero class should be applied")
	var rolled_vitality: int = game.get("hero_vitality")
	var rolled_strength: int = game.get("hero_strength")
	var rolled_spirit: int = game.get("hero_spirit")
	var rolled_agility: int = game.get("hero_agility")
	_check(game.get("new_game_button").visible, "New Game should be available before quest completion")
	game.call("_confirm_new_game")
	_check(game.get("new_game_dialog").visible, "Starting over should ask for confirmation")
	game.get("new_game_dialog").canceled.emit()
	game.get("new_game_dialog").hide()
	_check(game.get("quest_step") == 0 and game.get("hero_name") == "Ari", "Canceling New Game should preserve the current run")
	_check(game.get("quest_step") == 0, "New game should start with the village objective")
	_check(game.get("world_tiles").get_used_cells().size() == 1500, "The overworld should use the complete tile atlas")
	player.global_position = game.get("npc").global_position
	game.call("_talk_to_mira")
	_check(game.get("quest_step") == 1, "Talking to Mira should unlock the first forest objective")
	_check(game.get("potions") == 1, "Mira should equip the player with a potion")
	_interact_at(game, player, Vector2(1120, 800))
	_check(not game.get("in_cave"), "The cave should stay sealed until the forest adventure is complete")
	_check(not game.get("cave_seal").disabled, "An incomplete adventure should keep the cave physically sealed")
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
	_check(game.get("player_hp") == game.call("max_hp"), "Defeat should restore the player at the village")

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
	_check(shade_magic_damage >= 45 and shade_magic_damage <= 57, "Ember should deal bonus damage to the shade")
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
	var hp_after_battle := int(shade_battle.get("player_hp"))
	var mp_after_battle := int(shade_battle.get("player_mp"))
	shade_battle.call("_finish", "victory")
	shade_battle.result_button.emit_signal("pressed")
	_check(not game.get("battle_active"), "Closing battle results should resume world movement")
	_check(game.get("quest_step") == 2, "Defeating the shade should lead back to Mira")
	_check(game.get("player_experience") == 45, "Shade and discovery XP should carry over after leveling")
	_check(game.get("player_level") == 2, "Shade XP should level the player")
	_check(game.get("player_hp") == hp_after_battle, "Leveling up should preserve battle HP rather than fully heal")
	_check(game.get("player_mp") == mp_after_battle, "Leveling up should preserve battle MP rather than fully restore it")
	_check(game.get("player_hp") < game.call("max_hp"), "Taking damage before leveling should remain visible afterward")
	_check(game.get("player_mp") < game.call("max_mp"), "Spending MP before leveling should remain visible afterward")
	_check(game.call("max_hp") == 48 + rolled_vitality * 4 + 20, "Vitality should determine HP growth on level-up")
	_check(game.call("max_mp") == 6 + rolled_spirit * 2 + 6, "Spirit should determine MP growth on level-up")

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
	_check(wolf_attack_damage >= 47 and wolf_attack_damage <= 69, "Physical attacks should exploit the wolf's weakness")
	wolf_battle.call("_finish", "victory")
	wolf_battle.result_button.emit_signal("pressed")
	_check(game.get("quest_step") == 4, "Defeating the wolf should lead back to Mira")
	_check(game.get("player_experience") == 80, "The second fight should award its distinct XP reward")
	player.global_position = game.get("npc").global_position
	game.call("_talk_to_mira")
	_check(game.get("quest_step") == 5, "Reporting to Mira should complete the adventure")
	_check(game.get("gold") == 240, "The two quests and optional cache should grant their rewards")
	_check(game.get("new_game_button").visible, "Completed adventure should offer a new game")
	_check(game.get("cave_seal").disabled, "Completing the adventure should open the cave passage")

	_interact_at(game, player, Vector2(1120, 800))
	_check(game.get("in_cave"), "The completed adventure should unlock the optional cave")
	_check(player.global_position.is_equal_approx(Vector2(1080, 800)), "Entering the cave should place the hero inside its entrance")
	player.global_position = Vector2(920, 800)
	game.call("_process", 0.0)
	_check(game.get("battle_active"), "Approaching the cave treasure should trigger its guardian")
	var guardian_battle: Node = game.get("battle_instance")
	_check(guardian_battle.get("enemy_name") == "Cave Sentinel", "The cave should have its own guardian encounter")
	_check(guardian_battle.get("intent_label").text == "Intent: Heavy slam", "The sentinel should telegraph its opening slam")
	guardian_battle.call("_flee")
	guardian_battle.get("result_button").emit_signal("pressed")
	_check(game.get("in_cave") and not game.get("cave_guardian_defeated"), "Fleeing should leave the guardian available inside the cave")
	_check(not game.get("encounter_started"), "Fleeing should allow the cave guardian to be challenged again")
	player.global_position = Vector2(920, 800)
	game.call("_process", 0.0)
	guardian_battle = game.get("battle_instance")
	guardian_battle.call("_finish", "defeat")
	guardian_battle.get("result_button").emit_signal("pressed")
	_check(not game.get("in_cave") and not game.get("cave_guardian_defeated"), "Losing should return the hero to town without clearing the cave")
	_check(player.global_position.is_equal_approx(Vector2(250, 448)), "A cave defeat should send the hero back to the village")
	_interact_at(game, player, Vector2(1120, 800))
	player.global_position = Vector2(920, 800)
	game.call("_process", 0.0)
	guardian_battle = game.get("battle_instance")
	_check(guardian_battle.get("enemy_name") == "Cave Sentinel", "The guardian should be encounterable again after recovering")
	_check(guardian_battle.get("intent_label").text == "Intent: Heavy slam", "A new guardian battle should reset its intent")
	guardian_battle.call("_attack")
	guardian_battle.call("_guard")
	_check(guardian_battle.get("enemy_warding"), "The sentinel should raise a ward on its ward turn")
	_check(guardian_battle.get("intent_label").text.begins_with("Enemy warded"), "The UI should show the sentinel's active ward")
	guardian_battle.call("_attack")
	_check(not guardian_battle.get("enemy_warding"), "The sentinel's ward should absorb one player hit")
	_check(guardian_battle.get("battle_log").text.contains("ward absorbs"), "The battle log should explain the ward's damage reduction")
	guardian_battle.call("_finish", "victory")
	guardian_battle.get("result_button").emit_signal("pressed")
	_check(game.get("cave_guardian_defeated"), "Winning should persist the guardian's defeat")
	var spirit_before_treasure: int = game.get("hero_spirit")
	var max_mp_before_treasure: int = game.call("max_mp")
	game.set("player_mp", max_mp_before_treasure - 10)
	_interact_at(game, player, Vector2(840, 800))
	_check(game.get("cave_treasure_claimed"), "The crystal heart should be claimable after defeating its guardian")
	_check(game.get("hero_spirit") == mini(spirit_before_treasure + 2, 30), "The crystal heart should permanently improve Spirit")
	_check(game.get("player_mp") == mini(max_mp_before_treasure - 10 + 4, game.call("max_mp")), "The crystal heart should also restore some MP")
	var spirit_after_treasure: int = game.get("hero_spirit")
	_interact_at(game, player, Vector2(840, 800))
	_check(game.get("hero_spirit") == spirit_after_treasure, "The cave treasure should only be claimed once")
	_interact_at(game, player, Vector2(1080, 800))
	_check(not game.get("in_cave"), "The cave exit should return the hero to the forest")
	_interact_at(game, player, Vector2(1120, 800))
	_check(game.get("in_cave") and game.get("cave_guardian_defeated"), "Re-entering the cave should preserve its cleared state")
	_interact_at(game, player, Vector2(1080, 800))

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
	_check(resumed_game.get("player_level") == 4, "Cave victory should award enough XP to reach level four")
	_check(resumed_game.get("player_experience") == 65, "Cave victory XP should persist after restarting")
	_check(resumed_game.get("potions") == 2, "Potion count should persist after restarting")
	_check(resumed_game.get("hero_name") == "Ari", "Hero name should persist after restarting")
	_check(resumed_game.get("hero_class") == "Warrior", "Hero class should persist after restarting")
	_check(resumed_game.get("hero_vitality") == rolled_vitality, "Rolled hero stats should persist after restarting")
	_check(resumed_game.get("hero_strength") == rolled_strength, "Hero strength should persist after restarting")
	_check(resumed_game.get("hero_spirit") == spirit_after_treasure, "Crystal Heart Spirit should persist after restarting")
	_check(resumed_game.get("hero_agility") == rolled_agility, "Hero agility should persist after restarting")
	_check(resumed_game.get("cave_guardian_defeated"), "Cave guardian defeat should persist after restarting")
	_check(resumed_game.get("cave_treasure_claimed"), "Cave treasure claim should persist after restarting")
	_check(not resumed_game.get("in_cave"), "The saved hero should return outside the cave")
	_check(resumed_game.get("salve_collected"), "Collected potion should persist after restarting")
	_check(resumed_game.get("cache_opened"), "Opened cache should persist after restarting")
	_check(resumed_game.get("waystone_discovered"), "Waystone discovery should persist after restarting")
	_check(not resumed_game.get("exploration_markers").get("salve").visible, "Saved pickups should remain absent from the world")
	resumed_game.get("new_game_dialog").hide()
	resumed_game.get("new_game_dialog").confirmed.emit()
	_check(resumed_game.get("creation_layer").visible, "New Game should open hero creation")
	resumed_game.get("hero_name_input").text = "New Hero"
	resumed_game.call("_confirm_hero_creation")
	_check(resumed_game.get("quest_step") == 0, "Confirmed new game should reset quest progress")
	_check(resumed_game.get("gold") == 0, "Confirmed new game should reset gold")
	_check(resumed_game.get("player_hp") == resumed_game.call("max_hp"), "New hero should start at full HP")
	_check(resumed_game.get("player_mp") == resumed_game.call("max_mp"), "New hero should start at full MP")
	_check(resumed_game.get("player_level") == 1, "Confirmed new game should reset level")
	_check(resumed_game.get("player_experience") == 0, "Confirmed new game should reset XP")
	_check(resumed_game.get("potions") == 0, "Confirmed new game should reset potions")
	_check(not resumed_game.get("salve_collected"), "New game should reset exploration discoveries")
	_check(not resumed_game.get("cave_guardian_defeated"), "New Game should reset cave progress")
	_check(not resumed_game.get("cave_treasure_claimed"), "New Game should reset the cave treasure")
	resumed_game.queue_free()
	await process_frame

	for old_version in [1, 2, 3, 4, 5, 6, 7, 8]:
		var old_save := FileAccess.open(save_path, FileAccess.WRITE)
		var old_save_data := {
			"version": old_version,
			"quest_step": 2 if old_version < 3 else 5,
			"gold": 75,
			"player_hp": 100,
			"player_mp": 30,
			"player_level": 1,
			"player_experience": 0,
			"potions": 0,
			"salve_collected": false,
			"cache_opened": false,
			"waystone_discovered": false
		}
		if old_version >= 5:
			old_save_data.merge({
				"hero_name": "Legacy Hero",
				"hero_class": "Mage",
				"hero_vitality": 9,
				"hero_strength": 7,
				"hero_spirit": 16,
				"hero_agility": 10
			}, true)
		if old_version >= 6:
			old_save_data.merge({"position_x": 250.0, "position_y": 448.0}, true)
		if old_version >= 7:
			old_save_data.merge({
				"in_cave": false,
				"cave_guardian_defeated": false,
				"cave_treasure_claimed": false
			}, true)
		if old_version >= 8:
			old_save_data.merge({
				"equipment_inventory": ["Traveler's Blade", "Wanderer's Coat"],
				"equipped_weapon": "Traveler's Blade",
				"equipped_armor": "Wanderer's Coat"
			}, true)
		old_save.store_string(JSON.stringify(old_save_data))
		old_save.close()
		var migrated_game: Node = load("res://scenes/game.tscn").instantiate()
		migrated_game.set("progress_save_path", save_path)
		root.add_child(migrated_game)
		await process_frame
		_check(migrated_game.get("quest_step") == (3 if old_version < 3 else 5), "Save migration should preserve or continue completed quest progress")
		_check(migrated_game.get("gold") == 75, "Migration should preserve existing rewards")
		_check(not migrated_game.get("salve_collected"), "Older saves should default exploration rewards to unclaimed")
		_check(migrated_game.get("hero_name") == ("Legacy Hero" if old_version >= 5 else "Adventurer"), "Save migration should preserve or default the hero name")
		_check(migrated_game.get("hero_class") == ("Mage" if old_version >= 5 else "Warrior"), "Save migration should preserve or default the hero class")
		_check(not migrated_game.get("in_cave"), "Older saves should default to outside the cave")
		_check(not migrated_game.get("cave_guardian_defeated"), "Older saves should default cave progress to uncleared")
		_check(not migrated_game.get("cave_treasure_claimed"), "Older saves should default cave treasure to unclaimed")
		_check(migrated_game.get("equipped_slots").get("weapon") == "Traveler's Blade", "Older saves should receive starter weapon equipment")
		_check(migrated_game.get("equipped_slots").get("armor") == "Wanderer's Coat", "Older saves should receive starter armor")
		_check(migrated_game.get("equipped_slots").get("legs") == "Traveler's Trousers", "Older saves should receive starter leg equipment")
		_check(migrated_game.get("equipped_slots").get("feet") == "Trail Boots", "Older saves should receive starter footwear")
		migrated_game.queue_free()
		await process_frame

	var class_battle: Node = load("res://scenes/battle.tscn").instantiate()
	root.add_child(class_battle)
	await process_frame
	class_battle.call("start_battle",
		"Forest Shade", 500, Vector2i(1, 1), 0, Color("647b9a"), "fire",
		PackedStringArray(["Quick strike"]), 100, 30, 1, 0,
		"Ember", "Mage", 10, 7, 18, 10
	)
	var mage_hp_before: int = class_battle.get("enemy_hp")
	class_battle.call("_cast_magic")
	_check(mage_hp_before - int(class_battle.get("enemy_hp")) >= 84, "Mage Ember should benefit from high Spirit and its class talent")
	_check(class_battle.get("player_status").text.begins_with("Ember  ·  Mage"), "Battle UI should show the hero identity and class")
	class_battle.call("_finish", "flee")
	class_battle.queue_free()
	await process_frame

	var rogue_battle: Node = load("res://scenes/battle.tscn").instantiate()
	root.add_child(rogue_battle)
	await process_frame
	rogue_battle.call("start_battle",
		"Forest Shade", 500, Vector2i(1, 1), 0, Color("647b9a"), "fire",
		PackedStringArray(["Quick strike"]), 100, 30, 1, 0,
		"Swift", "Rogue", 12, 12, 10, 18
	)
	_check(rogue_battle.call("_dodge_chance") == 36, "Rogue Agility should grant a capped chance to evade attacks")
	rogue_battle.call("_finish", "flee")
	rogue_battle.queue_free()
	await process_frame

	var ui_test_path := "user://gameplay_save_ui.json"
	_remove_test_file(ui_test_path)
	for slot_index in range(3):
		_remove_test_file("user://gameplay_save_ui_slot_%d.json" % (slot_index + 1))
	var save_ui_game: Node = load("res://scenes/game.tscn").instantiate()
	save_ui_game.set("progress_save_path", ui_test_path)
	root.add_child(save_ui_game)
	await process_frame
	var save_ui_player: CharacterBody2D = save_ui_game.get("player")
	save_ui_game.get("hero_name_input").text = "Slot Hero"
	save_ui_game.call("_confirm_hero_creation")
	save_ui_game.set("hero_class", "Rogue")
	save_ui_game.set("quest_step", 3)
	save_ui_game.set("gold", 64)
	save_ui_player.global_position = Vector2(908, 452)
	var save_load_button := _find_button(save_ui_game, "Save / Load")
	_check(save_load_button != null, "The HUD should expose the Save / Load menu")
	save_load_button.emit_signal("pressed")
	_check(save_ui_game.get("save_load_layer").visible, "Save/Load should open its modal menu")
	_check(save_ui_game.get("save_slot_load_buttons")[0].disabled, "Empty slots should not be loadable")
	save_ui_game.get("save_slot_rows")[0].get_child(1).emit_signal("pressed")
	_check(FileAccess.file_exists("user://gameplay_save_ui_slot_1.json"), "Saving should create a slot file")
	_check(not save_ui_game.get("save_slot_load_buttons")[0].disabled, "Saved slots should become loadable")
	_check(save_ui_game.get("save_slot_labels")[0].text.contains("Slot Hero the Rogue"), "Slot summaries should identify the saved hero")
	save_ui_game.set("gold", 777)
	save_ui_player.global_position = Vector2(1000, 500)
	save_ui_game.get("save_slot_rows")[1].get_child(1).emit_signal("pressed")
	save_ui_game.get("save_slot_rows")[0].get_child(2).emit_signal("pressed")
	_check(not save_ui_game.get("save_load_layer").visible, "Loading should close the slot menu")
	_check(save_ui_game.get("gold") == 64, "Loading should restore the saved game state")
	_check(save_ui_game.get("hero_name") == "Slot Hero", "Loading should restore the hero identity")
	_check(save_ui_player.global_position.is_equal_approx(Vector2(908, 452)), "Loading should restore the saved world position")
	_check(save_ui_game.get("progress_save_path") == "user://gameplay_save_ui_slot_1.json", "Future auto-saves should follow the loaded slot")
	save_ui_game.call("_open_save_load_ui")
	save_ui_game.get("save_slot_rows")[0].get_child(1).emit_signal("pressed")
	_check(save_ui_game.get("save_overwrite_dialog").visible, "Overwriting a used slot should ask for confirmation")
	save_ui_game.get("save_overwrite_dialog").canceled.emit()
	save_ui_game.get("save_overwrite_dialog").hide()
	_check(save_ui_game.get("pending_save_slot") == -1, "Canceling overwrite should not leave a pending slot")
	save_ui_game.call("_confirm_new_game")
	_check(not save_ui_game.get("new_game_dialog").visible, "New Game should not interrupt the save/load menu")
	save_ui_game.call("_close_save_load_ui")
	save_ui_game.call("_confirm_new_game")
	_check(save_ui_game.get("new_game_dialog").visible, "New Game should be available during an unfinished adventure")
	save_ui_game.get("new_game_dialog").hide()
	save_ui_game.get("new_game_dialog").confirmed.emit()
	_check(save_ui_game.get("creation_layer").visible, "Confirming New Game should open hero creation")
	_check(save_ui_game.get("quest_step") == 0 and save_ui_game.get("gold") == 0, "New Game should reset unfinished quest progress")
	save_ui_game.get("hero_name_input").text = "Fresh Start"
	save_ui_game.call("_confirm_hero_creation")
	_check(save_ui_game.get("hero_name") == "Fresh Start", "New Game should start with the newly created hero")
	_check(FileAccess.file_exists("user://gameplay_save_ui_slot_2.json"), "Starting a new game should preserve other save slots")
	_check(save_ui_game.get("equipment_inventory").size() == 4, "New Game should reset equipment to all starter gear")
	save_ui_game.set("gold", 1000)
	save_ui_player.global_position = save_ui_game.get("merchant").global_position
	save_ui_game.call("_update_prompt")
	_check(save_ui_game.get("prompt_label").text == "E  Trade with Rowan", "The village should have a dedicated shopkeeper prompt")
	var trade_event := InputEventKey.new()
	trade_event.physical_keycode = KEY_E
	trade_event.pressed = true
	save_ui_game.call("_unhandled_input", trade_event)
	_check(save_ui_game.get("shop_layer").visible, "Interacting with Rowan should open the shop")
	_check(not save_ui_player.get("movement_enabled"), "The shop should pause player movement")
	save_ui_game.call("_buy_shop_item", "Potion")
	_check(save_ui_game.get("potions") == 1 and save_ui_game.get("gold") == 980, "Buying a potion should charge gold and add one potion")
	save_ui_game.call("_sell_shop_item", "Potion")
	_check(save_ui_game.get("potions") == 0 and save_ui_game.get("gold") == 990, "Selling a potion should remove one and pay its sell price")
	save_ui_game.call("_buy_shop_item", "Iron Sword")
	save_ui_game.call("_buy_shop_item", "Oak Staff")
	save_ui_game.call("_buy_shop_item", "Leather Armor")
	save_ui_game.call("_buy_shop_item", "Leather Cap")
	save_ui_game.call("_buy_shop_item", "Bracers")
	save_ui_game.call("_buy_shop_item", "Silk Gloves")
	save_ui_game.call("_buy_shop_item", "Iron Greaves")
	save_ui_game.call("_buy_shop_item", "Swift Boots")
	_check(save_ui_game.get("equipment_inventory").has("Iron Sword"), "Purchased equipment should enter the inventory")
	save_ui_game.call("_equip_item", "Iron Sword")
	_check(save_ui_game.get("equipped_slots").get("weapon") == "Iron Sword", "Equipping a new weapon should occupy the single weapon slot")
	_check(save_ui_game.get("equipment_inventory").has("Traveler's Blade"), "The starter weapon should remain owned, not count as a second equipped weapon")
	_check(save_ui_game.get("equipped_slots").get("weapon") != "Traveler's Blade", "Only one weapon can be equipped at once")
	save_ui_game.call("_equip_item", "Oak Staff")
	save_ui_game.call("_equip_item", "Leather Armor")
	save_ui_game.call("_equip_item", "Leather Cap")
	save_ui_game.call("_equip_item", "Bracers")
	save_ui_game.call("_equip_item", "Silk Gloves")
	save_ui_game.call("_equip_item", "Iron Greaves")
	save_ui_game.call("_equip_item", "Swift Boots")
	var gold_before_blocked_sale: int = save_ui_game.get("gold")
	save_ui_game.call("_sell_shop_item", "Oak Staff")
	_check(save_ui_game.get("gold") == gold_before_blocked_sale, "Equipped gear should not be sellable")
	save_ui_game.call("_equip_item", "Iron Sword")
	save_ui_game.call("_sell_shop_item", "Oak Staff")
	_check(not save_ui_game.get("equipment_inventory").has("Oak Staff"), "Unequipped gear should be sellable")
	_check(save_ui_game.get("gold") == gold_before_blocked_sale + 50, "Selling equipment should grant its listed value")
	_check(save_ui_game.get("equipped_slots").get("weapon") == "Iron Sword", "Only the selected weapon should remain equipped")
	_check(save_ui_game.get("equipped_slots").get("armor") == "Leather Armor", "Body armor should occupy its own equipment slot")
	for slot in ["head", "arms", "hands", "legs", "feet"]:
		_check(not str(save_ui_game.get("equipped_slots").get(slot, "")).is_empty(), "%s equipment should occupy its own slot" % slot)
	save_ui_game.call("_close_shop")
	_check(save_ui_player.get("movement_enabled"), "Closing the shop should restore movement")
	save_ui_game.call("_start_battle", "shade")
	var gear_battle: Node = save_ui_game.get("battle_instance")
	_check(gear_battle.get("weapon_attack_bonus") == 9, "Equipped weapon, arms, and feet gear should affect physical damage")
	_check(gear_battle.get("weapon_magic_bonus") == 3, "Equipped hands gear should affect Ember damage")
	_check(gear_battle.get("armor_defense") == 9, "Equipped armor across all slots should reduce incoming damage")
	var gear_battle_hp := int(gear_battle.get("player_hp"))
	gear_battle.set("enemy_hp", 500)
	gear_battle.call("_attack")
	_check(int(gear_battle.get("enemy_hp")) <= 500 - 27, "All equipped physical bonuses should apply to attacks")
	_check(gear_battle_hp - int(gear_battle.get("player_hp")) <= 16, "All equipped armor slots should reduce damage received")
	gear_battle.call("_flee")
	gear_battle.get("result_button").emit_signal("pressed")
	var equipment_save_path := str(save_ui_game.get("progress_save_path"))
	save_ui_game.queue_free()
	await process_frame
	var equipment_loaded_game: Node = load("res://scenes/game.tscn").instantiate()
	equipment_loaded_game.set("progress_save_path", equipment_save_path)
	root.add_child(equipment_loaded_game)
	await process_frame
	_check(equipment_loaded_game.get("equipped_slots").get("weapon") == "Iron Sword", "The single equipped weapon should persist after loading")
	_check(equipment_loaded_game.get("equipped_slots").get("armor") == "Leather Armor", "Equipped body armor should persist after loading")
	_check(equipment_loaded_game.get("equipped_slots").get("head") == "Leather Cap", "Head equipment should persist after loading")
	_check(equipment_loaded_game.get("equipped_slots").get("arms") == "Bracers", "Arm equipment should persist after loading")
	_check(equipment_loaded_game.get("equipped_slots").get("hands") == "Silk Gloves", "Hand equipment should persist after loading")
	_check(equipment_loaded_game.get("equipped_slots").get("legs") == "Iron Greaves", "Leg equipment should persist after loading")
	_check(equipment_loaded_game.get("equipped_slots").get("feet") == "Swift Boots", "Foot equipment should persist after loading")
	_check(not equipment_loaded_game.get("equipment_inventory").has("Oak Staff"), "Sold equipment should stay sold after loading")
	_check(equipment_loaded_game.get("gold") == 465, "Shop transactions should persist after loading")
	equipment_loaded_game.queue_free()
	await process_frame
	_remove_test_file(ui_test_path)
	for slot_index in range(3):
		_remove_test_file("user://gameplay_save_ui_slot_%d.json" % (slot_index + 1))

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

func _remove_test_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_check(remove_error == OK, "Test file should be removed: %s" % path)
