extends CharacterBody3D

@export var move_speed: float = 5.5
@export var jump_velocity: float = 4.8
@export var max_health: float = 100.0
@export var attack_damage: float = 35.0
@export var attack_range: float = 2.8
@export var movement_enabled: bool = true

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var health: float
var invulnerability: float = 0.0
var attack_cooldown: float = 0.0
var potions: int = 2
var gems: int = 0
var coins: int = 0

func _ready() -> void:
	if health <= 0.0:
		health = max_health
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if not movement_enabled:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)

	if direction.length() > 0.0:
		direction = direction.normalized()
		look_at(global_position + direction, Vector3.UP)

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	if attack_cooldown > 0.0:
		attack_cooldown = max(0.0, attack_cooldown - delta)

	move_and_slide()

	if invulnerability > 0.0:
		invulnerability = max(0.0, invulnerability - delta)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var parent := get_parent()
	var key: int = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	if (event.is_action_pressed("interact") or key == KEY_E) and parent.has_method("_handle_player_interaction"):
		parent._handle_player_interaction()
	elif key == KEY_I and parent.has_method("_open_inventory"):
		parent._open_inventory()
	elif key == KEY_M and parent.has_method("_open_map_journal"):
		parent._open_map_journal()
	elif key == KEY_H:
		_use_potion()

func _perform_attack() -> void:
	if attack_cooldown > 0.0:
		return

	attack_cooldown = 0.45
	var closest_target: Node3D = null
	var closest_distance: float = INF

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("take_damage") and enemy.get("alive") == true:
			var distance := global_position.distance_to(enemy.global_position)
			if distance <= attack_range and distance < closest_distance:
				closest_distance = distance
				closest_target = enemy

	if closest_target != null:
		closest_target.take_damage(attack_damage)

func _use_potion() -> void:
	if potions <= 0:
		if get_parent() and get_parent().has_method("_set_status_message"):
			get_parent()._set_status_message("No potions remaining.")
		return
	potions -= 1
	heal(30.0)
	if get_parent() and get_parent().has_method("_set_status_message"):
		get_parent()._set_status_message("Potion used.")
		if get_parent().has_method("_save_progress"):
			get_parent()._save_progress()

func take_damage(amount: float) -> void:
	if invulnerability > 0.0:
		return
	health = max(0.0, health - amount)
	invulnerability = 0.35
	if get_parent() and get_parent().has_method("_set_status_message"):
		get_parent()._set_status_message("You took damage!")
	if health <= 0.0:
		respawn()

func heal(amount: float) -> void:
	health = min(max_health, health + amount)

func respawn() -> void:
	global_position = Vector3(0.0, 1.0, 0.0)
	health = max_health
