extends Node

class_name AssetManager

# Cache for loaded textures
var texture_cache: Dictionary = {}

func load_texture(path: String) -> Texture2D:
	var key = "res://" + path
	if key in texture_cache:
		return texture_cache[key]
	
	var tex := load(path)
	texture_cache[key] = tex
	return tex

func get_character_sprite(char_type: String) -> Texture2D:
	match char_type.to_lower():
		"warrior": return load_texture("characters/warrior.png")
		"mage": return load_texture("characters/mage.png")
		"thief": return load_texture("characters/thief.png")
		"monk": return load_texture("characters/monk.png")
	return null

func get_environment_tile(tile_type: String) -> Texture2D:
	match tile_type.to_lower():
		"grass": return load_texture("environments/grass.png")
		"dirt": return load_texture("environments/dirt.png")
		"water": return load_texture("environments/water.png")
		"tree": return load_texture("environments/tree.png")
		"rock": return load_texture("environments/rock.png")
	return null

func get_ui_element(ui_type: String) -> Texture2D:
	match ui_type.to_lower():
		"button": return load_texture("ui/button.png")
		"icon_attack": return load_texture("ui/icon_attack.png")
		"icon_magic": return load_texture("ui/icon_magic.png")
		"icon_item": return load_texture("ui/icon_item.png")
		"icon_guard": return load_texture("ui/icon_guard.png")
		"icon_flee": return load_texture("ui/icon_flee.png")
	return null
