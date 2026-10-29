extends Node

class_name CombatSystem

enum Action { ATTACK = 0, MAGIC = 1, ITEM = 2, GUARD = 3, FLEE = 4 }

signal turn_changed(actor_name: String)
signal battle_won()
signal battle_lost()
signal action_executed(action: Action, target: Character?, damage: float?)

var player_chars: Array[Character] = []
var enemy_chars: Array[Enemy] = []
var current_turn_actor: String = ""
var is_player_turn: bool = true
var battle_ended: bool = false

func initialize() -> void:
	player_chars.clear()
	enemy_chars.clear()
	battle_ended = false
	is_player_turn = true
	
	if GameManager != null:
		var party_data = GameManager.get_party_members()
		for char_data in party_data:
			var char := Character.new(char_data)
			char.char_class = char_data.get("char_class", "warrior")
			player_chars.append(char)
	
	if EncounterSystem != null:
		var enemy_data = EncounterSystem.get_encounter_data()
		for enemy_data in enemy_data:
			var enemy := Enemy.new(enemy_data)
			enemy.enemy_type = enemy_data.get("type", "slime")
			enemy_chars.append(enemy)

func execute_action(action: Action, target: Character?, damage: float?) -> void:
	match action:
		Action.ATTACK:
			execute_attack(target, damage)
		Action.MAGIC:
			execute_magic(target, damage)
		Action.ITEM:
			execute_item(target, damage)
		Action.GUARD:
			execute_guard()
		Action.FLEE:
			execute_flee()

func execute_attack(target: Character?, damage: float?) -> void:
	if target == null and player_chars.size() > 0:
		target = player_chars[0]
	
	for i in range(player_chars.size()):
		var attacker = player_chars[i]
		if not attacker.is_alive():
			continue
		
		var actual_damage = damage if damage != null else calculate_attack_damage(attacker, target)
		
		if target:
			target.take_damage(actual_damage)
			print("Attack:", attacker.name, "->", target.name, "Damage:", actual_damage)
			action_executed.emit(Action.ATTACK, target, actual_damage)
		else:
			for j in range(enemy_chars.size()):
				var enemy = enemy_chars[j]
				if enemy.is_alive():
					enemy.take_damage(actual_damage)
					print("Attack:", attacker.name, "->", enemy.name, "Damage:", actual_damage)
					action_executed.emit(Action.ATTACK, enemy, actual_damage)

func calculate_attack_damage(attacker: Character, target: Character?) -> float:
	var base_dmg = attacker.attack_power * 1.5
	if target == null:
		base_dmg *= 0.8
	
	var variance = randf_range(0.9, 1.1)
	return clampf(base_dmg * variance, 1.0, attacker.attack_power * 2.0)

func execute_magic(target: Character?, damage: float?) -> void:
	if target == null and player_chars.size() > 0:
		target = player_chars[0]
	
	for i in range(player_chars.size()):
		var caster = player_chars[i]
		if not caster.is_alive():
			continue
		
		var spell_power = caster.magic_power * 2.5 if caster.magic_power else caster.attack_power * 1.8
		var actual_damage = damage if damage != null else clampf(spell_power, 10.0, 30.0)
		
		if target:
			target.take_damage(actual_damage)
			print("Magic:", caster.name, "->", target.name, "Damage:", actual_damage)
			action_executed.emit(Action.MAGIC, target, actual_damage)
		else:
			for j in range(enemy_chars.size()):
				var enemy = enemy_chars[j]
				if enemy.is_alive():
					enemy.take_damage(actual_damage)
					print("Magic:", caster.name, "->", enemy.name, "Damage:", actual_damage)
					action_executed.emit(Action.MAGIC, enemy, actual_damage)

func execute_item(target: Character?, damage: float?) -> void:
	if target == null and player_chars.size() > 0:
		target = player_chars[0]
	
	for i in range(player_chars.size()):
		var user = player_chars[i]
		if not user.is_alive():
			continue
		
		var heal_amount = 25.0 if damage != null else 30.0
		user.heal(heal_amount)
		
		print("Item:", user.name, "Healed by", heal_amount)
		action_executed.emit(Action.ITEM, user, -heal_amount)

func execute_guard() -> void:
	for i in range(player_chars.size()):
		var char = player_chars[i]
		if not char.is_alive():
			continue
		
		char.set_defense(char.defense * 1.5 if char.defense else 2.0)
		print("Guard:", char.name, "Defense increased")

func execute_flee() -> void:
	var success_chance = 0.7
	if EncounterSystem != null and EncounterSystem.is_boss_encounter():
		success_chance = 0.3
	
	if randf() < success_chance:
		print("Fled successfully!")
		get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))
	else:
		print("Failed to flee!")

func enemy_turn() -> void:
	is_player_turn = false
	
	if enemy_chars.is_empty():
		end_battle(true)
		return
	
	var active_enemy = null
	for i in range(enemy_chars.size()):
		var enemy = enemy_chars[i]
		if enemy.is_alive():
			active_enemy = enemy
			break
	
	if not active_enemy:
		end_battle(true)
		return
	
	await get_tree().create_timer(1.0).timeout
	
	match randi() % 3:
		0:
			active_enemy.take_damage_from_attack(player_chars[0] if player_chars.size() > 0 else null)
		1:
			active_enemy.use_magic(player_chars[0] if player_chars.size() > 0 else null)
		2:
			active_enemy.heal(15.0)

func end_battle(won: bool) -> void:
	battle_ended = true
	
	if won:
		battle_won.emit()
	else:
		battle_lost.emit()

func _process(delta: float) -> void:
	pass
