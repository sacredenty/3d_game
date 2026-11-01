extends CharacterBody2D

class_name NPCController

@export var move_speed: float = 40.0
@export var patrol_distance: int = 3
var current_direction: Vector2i = Vector2i.RIGHT
var change_direction_timer: float = 0.0

func _physics_process(delta: float) -> void:
	change_direction_timer += delta
	
	if change_direction_timer >= 2.0:
		change_direction_timer = 0.0
		current_direction = get_next_direction()
	
	velocity = Vector2(current_direction) * move_speed
	move_and_slide()

func get_next_direction() -> Vector2i:
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	return directions[randi_range(0, directions.size() - 1)]

func _on_npc_controller_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not body.is_in_group("player"):
		current_direction = -current_direction