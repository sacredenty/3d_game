extends Control

signal new_game_started()

const GAME_SCENE := preload("res://scenes/3d_main.tscn")
const AUTO_SAVE_PATH := "user://three_d_progress.json"
const SAVE_SLOT_COUNT := 3

var continue_button: Button
var load_button: Button
var new_game_button: Button
var audio_toggle_button: Button
var menu_status: Label

func _ready() -> void:
	AudioDirector.play_title_theme()
	_build_menu()
	_refresh_menu()

func _build_menu() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("17251f")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var glow := ColorRect.new()
	glow.anchor_left = 0.5
	glow.anchor_top = 0.5
	glow.anchor_right = 0.5
	glow.anchor_bottom = 0.5
	glow.offset_left = -290
	glow.offset_top = -255
	glow.offset_right = 290
	glow.offset_bottom = 255
	glow.color = Color("263d32")
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 520)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("24372f")
	panel_style.border_color = Color("b99a69")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 32
	panel_style.content_margin_right = 32
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	var eyebrow := _make_label("A GREENVALE ADVENTURE", 14, Color("b9d1c0"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(eyebrow)
	var title := _make_label("CHRONO\nCHRONICLES", 38, Color("f4e3b8"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var subtitle := _make_label("A turn-based journey through forest and stone", 14, Color("d5ddcf"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(subtitle)
	var divider := ColorRect.new()
	divider.custom_minimum_size.y = 2
	divider.color = Color("88744e")
	content.add_child(divider)

	continue_button = _make_menu_button("Continue")
	continue_button.pressed.connect(_on_continue_pressed)
	content.add_child(continue_button)
	load_button = _make_menu_button("Load Game")
	load_button.pressed.connect(_on_load_pressed)
	content.add_child(load_button)
	new_game_button = _make_menu_button("New Game")
	new_game_button.pressed.connect(_on_new_game_button)
	content.add_child(new_game_button)

	audio_toggle_button = _make_menu_button("")
	audio_toggle_button.pressed.connect(_toggle_audio)
	content.add_child(audio_toggle_button)

	menu_status = _make_label("", 13, Color("f3d890"))
	menu_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_status.custom_minimum_size.y = 34
	content.add_child(menu_status)
	var controls := _make_label("WASD / Arrows to move  ·  E to interact", 12, Color("aebdaf"))
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(controls)
	_refresh_audio_button()

func _refresh_menu() -> void:
	var latest_save := _latest_save_path()
	continue_button.disabled = latest_save.is_empty()
	load_button.disabled = not _has_loadable_save()
	if continue_button.disabled and load_button.disabled:
		menu_status.text = "Start a new adventure to begin."
	elif continue_button.disabled:
		menu_status.text = "Save slots are available to load."
	else:
		menu_status.text = "Continue: %s" % _save_display_name(latest_save)
	if not continue_button.disabled:
		continue_button.grab_focus()
	elif not load_button.disabled:
		load_button.grab_focus()
	else:
		new_game_button.grab_focus()

func _has_loadable_save() -> bool:
	for slot_index in range(SAVE_SLOT_COUNT):
		var path := "%s_slot_%d.json" % [AUTO_SAVE_PATH.get_basename(), slot_index + 1]
		if FileAccess.file_exists(path):
			return true
	return false

func _latest_save_path() -> String:
	var save_paths: Array[String] = [AUTO_SAVE_PATH]
	for slot_index in range(SAVE_SLOT_COUNT):
		save_paths.append("%s_slot_%d.json" % [AUTO_SAVE_PATH.get_basename(), slot_index + 1])
	var latest_path := ""
	var latest_modified := -1
	for path in save_paths:
		if not FileAccess.file_exists(path):
			continue
		var modified := FileAccess.get_modified_time(path)
		if modified > latest_modified:
			latest_modified = modified
			latest_path = path
	return latest_path

func _save_display_name(path: String) -> String:
	if path == AUTO_SAVE_PATH:
		return "latest adventure"
	for slot_index in range(SAVE_SLOT_COUNT):
		var slot_path := "%s_slot_%d.json" % [AUTO_SAVE_PATH.get_basename(), slot_index + 1]
		if path == slot_path:
			return "Save Slot %d" % (slot_index + 1)
	return "saved adventure"

func _on_continue_pressed() -> void:
	var latest_save := _latest_save_path()
	if latest_save.is_empty():
		_refresh_menu()
		return
	_launch_game("continue", latest_save)

func _on_load_pressed() -> void:
	if not _has_loadable_save():
		_refresh_menu()
		return
	_launch_game("load_slots")

func _on_new_game_button() -> void:
	new_game_started.emit()
	_launch_game("new_game")

func _toggle_audio() -> void:
	AudioDirector.toggle_audio()
	_refresh_audio_button()

func _refresh_audio_button() -> void:
	if audio_toggle_button != null:
		audio_toggle_button.text = "Audio: On" if AudioDirector.audio_enabled else "Audio: Off"

func _launch_game(start_mode: String, save_path: String = AUTO_SAVE_PATH) -> void:
	var game := GAME_SCENE.instantiate()
	game.set("initial_mode", start_mode)
	game.set("progress_save_path", save_path)
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	queue_free()

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 42)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 16)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("536f59")
	normal.border_color = Color("9fb58a")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("698a68")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color("fff0d0"))
	return button
