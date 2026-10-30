extends CharacterBody2D

class_name NPCController

@export var move_speed: float = 40.0
@export var patrol_distance: int = 3
var current_direction: Vector2i = Vector2i.RIGHT
var position_offset: int = 1
var change_direction_timer: float = 0.0
var target_position: Vector2i

func _ready() -> void:
	target_position = get_target_position()

func _physics_process(delta: float) -> void:
	change_direction_timer += delta
	
	if change_direction_timer >= 2.0 or not is_on_floor():
		change_direction_timer = 0.0
		current_direction = get_next_direction()
	
	var input_velocity = Vector2.ZERO
	
	# Check for arrow keys and WASD
	if Input.is_key_pressed(KEY_RIGHT):
		input_velocity.x = move_speed * delta
	elif Input.is_key_pressed(KEY_LEFT):
		input_velocity.x = -move_speed * delta
	
	if Input.is_key_pressed(KEY_UP):
		input_velocity.y = -move_speed * delta
	elif Input.is_key_pressed(KEY_DOWN):
		input_velocity.y = move_speed * delta
	
	velocity = input_velocity
	move_and_slide()
	
	if is_on_floor():
		target_position = get_target_position()

func get_next_direction() -> Vector2i:
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	return directions[position_offset % 4]

func get_target_position() -> Vector2i:
	var player = get_node_or_null("../PlayerController")
	if is_instance_valid(player):
		var player_pos = player.position
		var tile_x = int(player_pos.x / 32)
		var tile_y = int(player_pos.y / 32)
		return Vector2i(tile_x, tile_y)
	
	return Vector2i(1, 1)

func _on_npc_controller_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not body.is_in_group("player"):
		current_direction = -current_direction