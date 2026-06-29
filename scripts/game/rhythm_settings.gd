class_name RhythmSettings
extends RefCounted

const CONFIG_PATH = "user://settings.cfg"
const CONFIG_GROUP = "Settings"

const DEFAULT_VOLUME_PERCENT = 100.0
const DEFAULT_PLAYER_NAME = ""
const DEFAULT_NOTE_SPEED = 5.0
const DEFAULT_AUDIO_OFFSET_MS = 0.0
const DEFAULT_JUDGEMENT_OFFSET_MS = 0.0

const MIN_VOLUME_PERCENT = 0.0
const MAX_VOLUME_PERCENT = 100.0
const VOLUME_STEP = 1.0
const MIN_NOTE_SPEED = 1.0
const MAX_NOTE_SPEED = 10.0
const NOTE_SPEED_STEP = 0.1
const MIN_OFFSET_MS = -300.0
const MAX_OFFSET_MS = 300.0
const OFFSET_STEP_MS = 1.0
const MUTED_VOLUME_DB = -80.0

var master_volume: float = DEFAULT_VOLUME_PERCENT
var music_volume: float = DEFAULT_VOLUME_PERCENT
var sfx_volume: float = DEFAULT_VOLUME_PERCENT
var note_speed: float = DEFAULT_NOTE_SPEED
var audio_offset_ms: float = DEFAULT_AUDIO_OFFSET_MS
var judgement_offset_ms: float = DEFAULT_JUDGEMENT_OFFSET_MS
var player_name: String = DEFAULT_PLAYER_NAME

func save() -> bool:
	var config = ConfigFile.new()
	
	config.set_value(CONFIG_GROUP, "master_volume", master_volume)
	config.set_value(CONFIG_GROUP, "music_volume", music_volume)
	config.set_value(CONFIG_GROUP, "sfx_volume", sfx_volume)
	config.set_value(CONFIG_GROUP, "note_speed", note_speed)
	config.set_value(CONFIG_GROUP, "audio_offset_ms", audio_offset_ms)
	config.set_value(CONFIG_GROUP, "judgement_offset_ms", judgement_offset_ms)
	config.set_value(CONFIG_GROUP, "player_name", player_name.strip_edges())
	
	var error = config.save(CONFIG_PATH)
	if error != OK:
		push_warning("Failed to save settings. Error code: %s" % error)
	return error == OK

func load() -> void:
	var config = ConfigFile.new()
	var error = config.load(CONFIG_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("Failed to load settings. Error code: %s" % error)
	
	master_volume = _read_volume_percent(config, "master_volume")
	music_volume = _read_volume_percent(config, "music_volume")
	sfx_volume = _read_volume_percent(config, "sfx_volume")
	note_speed = _read_float(config, "note_speed", DEFAULT_NOTE_SPEED, MIN_NOTE_SPEED, MAX_NOTE_SPEED)
	audio_offset_ms = _read_float(config, "audio_offset_ms", DEFAULT_AUDIO_OFFSET_MS, MIN_OFFSET_MS, MAX_OFFSET_MS)
	judgement_offset_ms = _read_float(config, "judgement_offset_ms", DEFAULT_JUDGEMENT_OFFSET_MS, MIN_OFFSET_MS, MAX_OFFSET_MS)
	player_name = str(config.get_value(CONFIG_GROUP, "player_name", DEFAULT_PLAYER_NAME))

func apply_audio() -> void:
	_apply_bus_volume(&"Master", master_volume)
	_apply_bus_volume(&"MUSIC", music_volume)
	_apply_bus_volume(&"SFX", sfx_volume)

func _read_volume_percent(config: ConfigFile, key: String) -> float:
	return _read_float(config, key, DEFAULT_VOLUME_PERCENT, MIN_VOLUME_PERCENT, MAX_VOLUME_PERCENT)

func _read_float(config: ConfigFile, key: String, default_value: float, min_value: float, max_value: float) -> float:
	var value = config.get_value(CONFIG_GROUP, key, default_value)
	return clampf(float(value), min_value, max_value)

func _apply_bus_volume(bus_name: StringName, volume_percent: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("Audio bus '%s' does not exist." % bus_name)
		return
	
	var linear_volume = clampf(volume_percent / MAX_VOLUME_PERCENT, 0.0, 1.0)
	var volume_db = MUTED_VOLUME_DB if linear_volume == 0.0 else linear_to_db(linear_volume)
	AudioServer.set_bus_volume_db(bus_index, volume_db)
