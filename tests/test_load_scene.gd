extends SceneTree
func _init():
    var packed = load("res://scenes/dungeons/dungeon_scene.tscn")
    if packed:
        print("Scene loaded OK")
    else:
        print("Scene load failed")
    quit()
