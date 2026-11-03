extends CanvasLayer

signal transition_complete(from_zone: String, to_zone: String)

@onready var background_fade = $BackgroundFade
@onready var zone_name_display = $ZoneNameDisplay
@onready var progress_container = $ProgressContainer/ProgressFill

var is_transitioning: bool = false
var from_zone: String = ""
var to_zone: String = ""

func _process(delta: float) -> void:
	if is_transitioning and background_fade.color.a > 0:
		background_fade.color.a -= delta * 2.0
		if background_fade.color.a < 0:
			background_fade.color.a = 0

func start_zone_transition(from: String, to: String) -> void:
	is_transitioning = true
	from_zone = from
	to_zone = to
	
	background_fade.color = Color(0, 0, 0, 1.0)
	zone_name_display.text = "Transitioning from %s to %s..." % [from.capitalize(), to.capitalize()]
	progress_container.value = 0

func update_progress(value: float) -> void:
	if progress_container != null:
		progress_container.value = value

func complete_transition() -> void:
	is_transitioning = false
	background_fade.color = Color(0, 0, 0, 0)
	zone_name_display.text = "Arrived in %s" % to_zone.capitalize()
	
	await get_tree().create_timer(1.5).timeout
	
	transition_complete.emit(from_zone, to_zone)
