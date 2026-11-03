extends Node2D

signal portal_opened(zone_name: String)

@onready var sprite = $Sprite
var is_active: bool = true
var zone_name: String = ""

func _ready() -> void:
	# Zone name will be set by parent scene
	pass

func activate_zone(zone: String):
	is_active = true
	zone_name = zone
	sprite.color = Color(1, 0.8, 0.6)
	
func deactivate():
	is_active = false
	sprite.color = Color(0.5, 0.3, 0.2)

func _input(event: InputEvent) -> void:
	if not is_active or not event.is_action_pressed("interact"):
		return
	
	portal_opened.emit(zone_name)
