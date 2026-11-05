extends CharacterBody3D

signal defeated(enemy_id: int)

@export var max_health: float = 60.0
@export var move_speed: float = 1.8
@export var attack_damage: float = 12.0
@export var enemy_id: int = -1

var health: float
var base_position: Vector3
var patrol_angle: float = 0.0
var alive: bool = true
var body_material: StandardMaterial3D
var health_fill: MeshInstance3D
var health_bar_root: Node3D
var hurt_flash_timer: float = 0.0

func _ready() -> void:
	health = max_health
	base_position = global_position
	add_to_group("enemy")
	_build_visual()

func _physics_process(delta: float) -> void:
	if not alive:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var distance: float = to_player.length()

	if distance < 8.0 and distance > 0.1:
		var direction: Vector3 = to_player.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		if distance < 1.6 and player.has_method("take_damage"):
			player.take_damage(attack_damage * delta * 2.2)
	else:
		var patrol_target := base_position + Vector3(
			sin(Time.get_ticks_msec() * 0.001 + patrol_angle) * 2.8,
			0.0,
			cos(Time.get_ticks_msec() * 0.001 + patrol_angle) * 2.8
		)
		var to_target := patrol_target - global_position
		to_target.y = 0.0
		if to_target.length() > 0.25:
			velocity.x = to_target.normalized().x * move_speed * 0.6
			velocity.z = to_target.normalized().z * move_speed * 0.6
		else:
			patrol_angle += 0.7
			velocity = Vector3.ZERO

	if velocity.length() > 0.1:
		look_at(global_position + velocity.normalized(), Vector3.UP)

	move_and_slide()

func _process(delta: float) -> void:
	if health_bar_root == null:
		return
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		health_bar_root.look_at(camera.global_position, Vector3.UP)
	if health_fill != null:
		health_fill.scale.x = maxf(0.0, health / max_health)
	if hurt_flash_timer > 0.0:
		hurt_flash_timer = maxf(0.0, hurt_flash_timer - delta)
		if hurt_flash_timer == 0.0 and body_material != null:
			body_material.albedo_color = Color(0.82, 0.25, 0.25)

func take_damage(amount: float) -> void:
	if not alive:
		return

	health = maxf(0.0, health - amount)
	hurt_flash_timer = 0.14
	body_material.albedo_color = Color(1.0, 0.95, 0.72)
	_show_damage_number(amount)
	var parent := get_parent()
	if parent != null and parent.has_method("_set_status_message"):
		parent._set_status_message("Hit for %d damage." % int(amount))
	if health <= 0.0:
		alive = false
		defeated.emit(enemy_id)
		queue_free()

func _build_visual() -> void:
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.45
	body_mesh.height = 1.2
	body.mesh = body_mesh
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.82, 0.25, 0.25)
	body.material_override = body_material
	body.position.y = -0.4
	add_child(body)

	health_bar_root = Node3D.new()
	health_bar_root.position = Vector3(0.0, 0.9, 0.0)
	var bar_back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(1.1, 0.13, 0.06)
	bar_back.mesh = back_mesh
	var back_material := StandardMaterial3D.new()
	back_material.albedo_color = Color(0.12, 0.08, 0.08)
	bar_back.material_override = back_material
	health_bar_root.add_child(bar_back)

	health_fill = MeshInstance3D.new()
	var fill_mesh := BoxMesh.new()
	fill_mesh.size = Vector3(1.0, 0.085, 0.075)
	health_fill.mesh = fill_mesh
	var fill_material := StandardMaterial3D.new()
	fill_material.albedo_color = Color(0.86, 0.12, 0.1)
	health_fill.material_override = fill_material
	health_fill.position = Vector3(0.0, 0.0, -0.04)
	health_bar_root.add_child(health_fill)
	add_child(health_bar_root)

func _show_damage_number(amount: float) -> void:
	var damage_label := Label3D.new()
	damage_label.text = str(int(amount))
	damage_label.font_size = 48
	damage_label.pixel_size = 0.008
	damage_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	damage_label.modulate = Color(1.0, 0.88, 0.45)
	damage_label.position = Vector3(0.0, 1.5, 0.0)
	add_child(damage_label)
	var tween := create_tween()
	tween.tween_property(damage_label, "position:y", 2.5, 0.55)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(damage_label.queue_free)
