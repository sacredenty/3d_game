extends Control

class_name ActionMenu

const KEY_A = 65
const KEY_NUMPAD1 = 96
const KEY_Z = 90
const KEY_NUMPAD2 = 103
const KEY_I = 73
const KEY_NUMPAD3 = 108
const KEY_G = 71
const KEY_NUMPAD4 = 109
const KEY_Q = 81
const KEY_ESCAPE = 65359

@onready var attack_button: Button = null
@onready var magic_button: Button = null
@onready var item_button: Button = null
@onready var guard_button: Button = null
@onready var flee_button: Button = null

var is_processing: bool = false

func _ready() -> void:
	attack_button.pressed.connect(_on_attack_pressed)
	magic_button.pressed.connect(_on_magic_pressed)
	item_button.pressed.connect(_on_item_pressed)
	guard_button.pressed.connect(_on_guard_pressed)
	flee_button.pressed.connect(_on_flee_pressed)

func _input(event: InputEvent) -> void:
	if is_processing or not visible:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_A, KEY_NUMPAD1:
				execute_action("attack")
			KEY_Z, KEY_NUMPAD2:
				execute_action("magic")
			KEY_I, KEY_NUMPAD3:
				execute_action("item")
			KEY_G, KEY_NUMPAD4:
				execute_action("guard")
			KEY_Q, KEY_ESCAPE:
				execute_action("flee")

func execute_action(action_name: String) -> void:
	is_processing = true
	
	match action_name:
		"attack":
			attack_button.emit_signal("pressed")
		"magic":
			magic_button.emit_signal("pressed")
		"item":
			item_button.emit_signal("pressed")
		"guard":
			guard_button.emit_signal("pressed")
		"flee":
			flee_button.emit_signal("pressed")

func _on_attack_pressed() -> void:
	is_processing = false
	if CombatSystem != null and is_instance_valid(CombatSystem):
		var combat = CombatSystem as CombatSystem
		combat.execute_action(0)

func _on_magic_pressed() -> void:
	is_processing = false
	if CombatSystem != null and is_instance_valid(CombatSystem):
		var combat = CombatSystem as CombatSystem
		combat.execute_action(1)

func _on_item_pressed() -> void:
	is_processing = false
	if CombatSystem != null and is_instance_valid(CombatSystem):
		var combat = CombatSystem as CombatSystem
		combat.execute_action(2)

func _on_guard_pressed() -> void:
	is_processing = false
	if CombatSystem != null and is_instance_valid(CombatSystem):
		var combat = CombatSystem as CombatSystem
		combat.execute_action(3)

func _on_flee_pressed() -> void:
	is_processing = false
	if CombatSystem != null and is_instance_valid(CombatSystem):
		var combat = CombatSystem as CombatSystem
		combat.execute_action(4)

func process_input() -> void:
	pass
