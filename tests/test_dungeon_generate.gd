extends Node
func _ready():
    var dg = preload("res://scripts/systems/dungeons/dungeon_generator.gd").new()
    dg.generate_dungeon()
    print("Rooms: %s" % dg.rooms.size())
    for r in dg.rooms:
        print(r)
    get_tree().quit()
