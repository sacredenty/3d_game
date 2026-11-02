extends SceneTree
func _init():
    var s = load("res://scripts/systems/dungeons/dungeon_generator.gd")
    if s:
        print("Loaded OK")
    else:
        print("Load failed")
    quit()
