extends Node

const TITLE_THEME: AudioStreamWAV = preload("res://assets/audio/title_theme.wav")
const GREENVALE_THEME: AudioStreamWAV = preload("res://assets/audio/greenvale_theme.wav")
const BATTLE_THEME: AudioStreamWAV = preload("res://assets/audio/battle_theme.wav")
const EFFECTS := {
	"attack": preload("res://assets/audio/attack.wav"),
	"magic": preload("res://assets/audio/magic.wav"),
	"hit": preload("res://assets/audio/hit.wav"),
	"potion": preload("res://assets/audio/potion.wav"),
	"victory": preload("res://assets/audio/victory.wav")
}
const MUSIC_LOOP_SAMPLES := 176400
const EFFECT_PLAYER_COUNT := 4
const SETTINGS_PATH := "user://settings.cfg"

var music_player: AudioStreamPlayer
var effect_players: Array[AudioStreamPlayer] = []
var effect_player_index: int = 0
var current_theme: String = ""
var audio_enabled: bool = true

func _ready() -> void:
	_load_audio_setting()
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -13.0
	add_child(music_player)
	for track in [TITLE_THEME, GREENVALE_THEME, BATTLE_THEME]:
		track.loop_mode = AudioStreamWAV.LOOP_FORWARD
		track.loop_begin = 0
		track.loop_end = MUSIC_LOOP_SAMPLES
	for _index in range(EFFECT_PLAYER_COUNT):
		var player := AudioStreamPlayer.new()
		player.volume_db = -8.0
		add_child(player)
		effect_players.append(player)
	_apply_audio_setting()

func _exit_tree() -> void:
	music_player.stop()
	music_player.stream = null
	for player in effect_players:
		player.stop()
		player.stream = null

func play_title_theme() -> void:
	_play_theme("title", TITLE_THEME)

func play_greenvale_theme() -> void:
	_play_theme("greenvale", GREENVALE_THEME)

func play_battle_theme() -> void:
	_play_theme("battle", BATTLE_THEME)

func set_audio_enabled(enabled: bool) -> void:
	if audio_enabled == enabled:
		return
	audio_enabled = enabled
	_apply_audio_setting()
	var settings := ConfigFile.new()
	var load_error := settings.load(SETTINGS_PATH)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_error("Could not read audio settings: %s" % error_string(load_error))
		return
	settings.set_value("audio", "enabled", audio_enabled)
	var save_error := settings.save(SETTINGS_PATH)
	if save_error != OK:
		push_error("Could not save audio settings: %s" % error_string(save_error))

func toggle_audio() -> void:
	set_audio_enabled(not audio_enabled)

func _load_audio_setting() -> void:
	var settings := ConfigFile.new()
	var load_error := settings.load(SETTINGS_PATH)
	if load_error == OK:
		audio_enabled = bool(settings.get_value("audio", "enabled", true))
	elif load_error != ERR_FILE_NOT_FOUND:
		push_error("Could not read audio settings: %s" % error_string(load_error))

func _apply_audio_setting() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		push_error("Could not find the Master audio bus.")
		return
	AudioServer.set_bus_mute(master_bus, not audio_enabled)
	if audio_enabled and not current_theme.is_empty() and not music_player.playing:
		music_player.play()
	elif not audio_enabled:
		music_player.stop()
		for player in effect_players:
			player.stop()

func _play_theme(theme_name: String, stream: AudioStreamWAV) -> void:
	if current_theme == theme_name and music_player.playing:
		return
	current_theme = theme_name
	music_player.stream = stream
	if audio_enabled:
		music_player.play()

func play_effect(effect_name: String) -> void:
	if not audio_enabled:
		return
	if not EFFECTS.has(effect_name):
		push_error("Unknown audio effect: %s" % effect_name)
		return
	var player := effect_players[effect_player_index]
	effect_player_index = (effect_player_index + 1) % effect_players.size()
	player.stream = EFFECTS[effect_name]
	player.play()
