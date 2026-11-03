# Zone System Integration Test Script
# Run this in Godot's built-in console or terminal after loading the game

print("=== ZONE SYSTEM INTEGRATION TEST ===\n")

# Test 1: Check if world map scene exists
print("Test 1: Checking World Map Scene...")
world_map_scene = preload("res://scenes/world_map.tscn")
if world_map_scene != null:
    print("✓ World Map scene found!")
else:
    print("✗ World Map scene NOT found!")

# Test 2: Check if zone_manager autoload exists
print("\nTest 2: Checking ZoneManager Autoload...")
zone_manager = get_node_or_null("/root/ZoneManager")
if zone_manager != null:
    print("✓ ZoneManager autoload found!")
    print(f"  Current zone: {zone_manager.current_zone}")
else:
    print("✗ ZoneManager autoload NOT found!")

# Test 3: Check if game_scene has world map integration
print("\nTest 3: Checking Game Scene Integration...")
game_scene = get_tree().current_scene
if game_scene != null:
    if hasattr(game_scene, "_open_world_map"):
        print("✓ _open_world_map() function found!")
    else:
        print("✗ _open_world_map() function NOT found!")
    
    if hasattr(game_scene, "world_map_instance"):
        print("✓ world_map_instance variable found!")
    else:
        print("✗ world_map_instance variable NOT found!")
else:
    print("✗ Could not access game scene!")

# Test 4: Check zone data in ZoneManager
print("\nTest 4: Checking Zone Data...")
if zone_manager != null:
    zones = ["village", "forest", "cave", "castle"]
    for zone in zones:
        if zone_manager.get_zone_data(zone):
            print(f"✓ Zone '{zone}' data found!")
        else:
            print(f"✗ Zone '{zone}' data NOT found!")

# Test 5: Check input handling
print("\nTest 5: Checking Input Handling...")
if game_scene != null:
    if hasattr(game_scene, "_unhandled_input"):
        print("✓ _unhandled_input() function found!")
        print("  (ESC/M/W keys should toggle world map)")
    else:
        print("✗ _unhandled_input() function NOT found!")

print("\n=== TEST COMPLETE ===")
print("\nTo test manually:")
print("1. Press M to open the journal/map")
print("2. Look for '🗺️ World Map' button at bottom of journal")
print("3. Click it or press W to open world map")
print("4. Select a zone to travel there")
print("5. Press ESC/M again to return to game")
