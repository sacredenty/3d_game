extends CharacterBody2D

@export var speed: float = 100.0

func _physics_process(delta):
	var velocity = Vector2.ZERO
	
	# Direct key code checks (more reliable than InputMap actions)
	if Input.is_key_pressed(KEY_RIGHT):
		velocity.x = speed * delta
	elif Input.is_key_pressed(KEY_LEFT):
		velocity.x = -speed * delta
	
	if Input.is_key_pressed(KEY_UP):
		velocity.y = -speed * delta
	elif Input.is_key_pressed(KEY_DOWN):
		velocity.y = speed * delta
	
	move_and_slide()
