extends Node2D

func _ready() -> void:
	print("=== MOVEMENT TEST START ===")
	
	# Load main scene to get access to overworld
	var main_scene = preload("res://scenes/main/main_scene.tscn")
	if main_scene == null:
		print("ERROR: MainScene not found!")
		return
	
	var main_node = main_scene.instantiate()
	add_child(main_node)
	
	await get_tree().process_frame
	
	var sprite_path = "/root/MovementTester/MainScene/OverworldLevel/PlayerController/Sprite2D"
	var sprite = get_node_or_null(sprite_path)
	
	if not is_instance_valid(sprite):
		print("ERROR: Player sprite not found at:", sprite_path)
		return
	
	print("\nInitial position:", sprite.position)
	print("Sprite texture loaded:", sprite.texture != null)

	await get_tree().process_frame
	
	# Test movement - directly modify position (bypassing input system)
	for i in range(5):
		sprite.position.x += 16
		print("After move right #", i+1, ":", sprite.position)
	
	for i in range(5):
		sprite.position.y += 16
		print("After move up #", i+1, ":", sprite.position)
	
	print("\n=== MOVEMENT TEST COMPLETE ===")
