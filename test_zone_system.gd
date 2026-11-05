extends SceneTree

func _init():
	print("=== ZONE SYSTEM INTEGRATION TEST ===\n")
	# Test 1: Check if world map scene exists
	print("Test 1: Checking World Map Scene...")
	var world_map_scene = load("res://scenes/world_map.tscn")
	if world_map_scene != null:
		print("✓ World Map scene found!")
	else:
		print("✗ World Map scene NOT found!")
	# Test 2: Check if zone_manager autoload exists
	print("\nTest 2: Checking ZoneManager Autoload...")
	var zone_manager = get_root().get_node_or_null("/root/ZoneManager")
	if zone_manager != null:
		print("✓ ZoneManager autoload found!")
		print("  Current zone: %s" % zone_manager.current_zone)
	else:
		print("✗ ZoneManager autoload NOT found!")
	# Test 3: Check if game_scene has world map integration
	print("\nTest 3: Checking Game Scene Integration...")
	var game_scene = current_scene
	if game_scene != null:
		if game_scene.has_method("_open_world_map"):
			print("✓ _open_world_map() function found!")
		else:
			print("✗ _open_world_map() function NOT found!")
		if "world_map_instance" in game_scene:
			print("✓ world_map_instance variable found!")
		else:
			print("✗ world_map_instance variable NOT found!")
	else:
		print("✗ Could not access game scene!")
	# Test 4: Check zone data in ZoneManager
	print("\nTest 4: Checking Zone Data...")
	if zone_manager != null:
		var zones = ["village", "forest", "cave", "castle"]
		for zone in zones:
			if zone_manager.get_zone_data(zone):
				print("✓ Zone '%s' data found!" % zone)
			else:
				print("✗ Zone '%s' data NOT found!" % zone)
	# Test 5: Check input handling
	print("\nTest 5: Checking Input Handling...")
	if game_scene != null:
		if game_scene.has_method("_unhandled_input"):
			print("✓ _unhandled_input() function found!")
			print("  (ESC/M/W keys should toggle world map)")
		else:
			print("✗ _unhandled_input() function NOT found!")
	print("\n=== TEST COMPLETE ===")
	quit()
