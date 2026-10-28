extends Node

class_name CombatSystem

enum Action { ATTACK, MAGIC, ITEM, GUARD, FLEE }

@export_group("Combat Settings")
var player_party: Array[Character] = []
var enemies: Array[Enemy] = []
var is_player_turn: bool = true
var battle_ended: bool = false

signal turn_changed(actor_name: String)
signal battle_won()
signal battle_lost()
signal action_executed(action: Action, target: Character?, damage: float?)

# Turn order queue
var turn_queue: Array[Character] = []

func start_battle(player_chars: Array[Character], enemy_chars: Array[Enemy]) -> void:
	player_party = player_chars
	enemies = enemy_chars
	
	# Build initial turn queue based on turn order values
	turn_queue.clear()
	
	for char in player_party:
		if char and char.is_alive():
			turn_queue.append(char)
	
	for enemy in enemies:
		if enemy and enemy.is_alive():
			turn_queue.append(enemy)
	
	# Sort by turn order (higher acts first)
	turn_queue.sort_custom(_compare_turn_order)
	
	is_player_turn = true
	battle_ended = false

func _compare_turn_order(a, b) -> bool:
	return a.get_final_stat("atk") / a.get_final_stat("def") > \
		   b.get_final_stat("atk") / b.get_final_stat("def")

func get_next_actor() -> Character:
	if turn_queue.is_empty():
		return null
	
	var actor = turn_queue.pop_front()
	
	# Check if still alive, requeue if needed
	if not actor or not actor.is_alive():
		return get_next_actor()
	
	turn_changed.emit(actor.name)
	return actor

func execute_action(action: Action, target: Character?, damage: float?) -> void:
	action_executed.emit(action, target, damage)
	
	match action:
		Action.ATTACK:
			if is_player_turn and target:
				var attacker = get_active_player()
				if attacker:
					var dmg = calculate_attack_damage(attacker, target)
					target.take_damage(dmg, "neutral")
					check_battle_end()
		
		Action.MAGIC:
			if is_player_turn and target:
				var attacker = get_active_player()
				if attacker:
					var element = _get_random_element()
					var dmg = calculate_magic_damage(attacker, target, element)
					target.take_damage(dmg, element)
					check_battle_end()
		
		Action.ITEM:
			if is_player_turn:
				# Item usage handled by UI/controller
				pass
		
		Action.GUARD:
			if is_player_turn:
				var attacker = get_active_player()
				if attacker:
					attacker.set_guarding(true)
		
		Action.FLEE:
			battle_ended = true
			battle_lost.emit()

func calculate_attack_damage(attacker: Character, defender: Character) -> float:
	var base_dmg = attacker.get_final_stat("atk") * 1.5
	var def_reduction = defender.get_final_stat("def") * 0.3
	
	# Critical hit chance (5% base + equipment bonus)
	var crit_chance = 0.05 + attacker.equipment.get("weapon", null).bonus_atk if attacker.equipment.get("weapon") else 0.05
	var is_crit = randf() < crit_chance
	
	var final_dmg = max(base_dmg - def_reduction, 1.0)
	if is_crit:
		final_dmg *= 2.0
	
	return final_dmg

func calculate_magic_damage(attacker: Character, defender: Character, element: String) -> float:
	var base_dmg = attacker.get_final_stat("mag") * 3.0
	var def_reduction = defender.get_final_stat("def") * 0.2
	
	# Elemental resistance
	var resistance_mult = defender.resistances.get(element, 1.0)
	
	var final_dmg = max(base_dmg - def_reduction, 1.0) * resistance_mult
	return final_dmg

func _get_random_element() -> String:
	var elements = ["fire", "ice", "lightning", "wind", "earth", "water"]
	return elements[randi() % elements.size()]

func get_active_player() -> Character:
	for char in player_party:
		if char and char.is_alive():
			return char
	return null

func enemy_turn() -> void:
	is_player_turn = false
	
	var alive_enemies = []
	for enemy in enemies:
		if enemy and enemy.is_alive():
			alive_enemies.append(enemy)
	
	if alive_enemies.is_empty():
		battle_won.emit()
		return
	
	# Simple AI: pick random alive enemy, attack player
	var attacker = alive_enemies[randi() % alive_enemies.size()]
	var target = get_active_player()
	
	if target and not target.is_alive():
		target = player_party[0]  # Attack first living party member
	
	if target:
		var dmg = calculate_attack_damage(attacker, target)
		target.take_damage(dmg, "neutral")
		check_battle_end()

func check_battle_end() -> void:
	var alive_players = 0
	for char in player_party:
		if char and char.is_alive():
			alive_players += 1
	
	var alive_enemies_count = 0
	for enemy in enemies:
		if enemy and enemy.is_alive():
			alive_enemies_count += 1
	
	if alive_players == 0:
		battle_lost.emit()
	elif alive_enemies_count == 0:
		battle_won.emit()

func reset_battle() -> void:
	player_party.clear()
	enemies.clear()
	turn_queue.clear()
	is_player_turn = true
	battle_ended = false
