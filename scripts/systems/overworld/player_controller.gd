extends CharacterBody2D

@export var move_speed: float = 100.0
@export var tile_size: int = 32

var overworld_map: OverworldMap = null

func _ready() -> void:
	overworld_map = get_node_or_null("../OverworldMap")

func _physics_process(delta: float) -> void:
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

func _on_overworld_map_player_moved(new_position: Vector2i) -> void:
	var target_x = new_position.x * tile_size + tile_size / 2
	var target_y = new_position.y * tile_size + tile_size / 2
	position = Vector2(target_x, target_y)
