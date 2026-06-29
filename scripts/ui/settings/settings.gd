extends Node2D

var settings := RhythmSettings.new()

@onready var master_slider: HSlider = $"TabContainer/游玩/Master"
@onready var music_slider: HSlider = $"TabContainer/游玩/MUSIC"
@onready var sfx_slider: HSlider = $"TabContainer/游玩/SFX"
@onready var note_speed_slider: HSlider = $"TabContainer/游玩/NoteSpeed"
@onready var audio_offset_slider: HSlider = $"TabContainer/游玩/AudioOffset"
@onready var judgement_offset_slider: HSlider = $"TabContainer/游玩/JudgementOffset"
@onready var player_name_edit: LineEdit = $"TabContainer/账户与统计/VSeparator/LineEdit"

func _ready() -> void:
	_configure_volume_slider(master_slider)
	_configure_volume_slider(music_slider)
	_configure_volume_slider(sfx_slider)
	_configure_slider(note_speed_slider, RhythmSettings.MIN_NOTE_SPEED, RhythmSettings.MAX_NOTE_SPEED, RhythmSettings.NOTE_SPEED_STEP)
	_configure_slider(audio_offset_slider, RhythmSettings.MIN_OFFSET_MS, RhythmSettings.MAX_OFFSET_MS, RhythmSettings.OFFSET_STEP_MS)
	_configure_slider(judgement_offset_slider, RhythmSettings.MIN_OFFSET_MS, RhythmSettings.MAX_OFFSET_MS, RhythmSettings.OFFSET_STEP_MS)
	load_settings()
	_connect_setting_signals()

func _on_texture_button_pressed() -> void:
	save_settings()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")

func save_settings() -> bool:
	_sync_settings_from_controls()
	return settings.save()

func load_settings() -> void:
	settings.load()
	_sync_controls_from_settings()
	settings.apply_audio()

func _on_master_value_changed(value: float) -> void:
	settings.master_volume = value
	settings.apply_audio()

func _on_music_value_changed(value: float) -> void:
	settings.music_volume = value
	settings.apply_audio()

func _on_sfx_value_changed(value: float) -> void:
	settings.sfx_volume = value
	settings.apply_audio()

func _on_setting_changed(_value: Variant = null) -> void:
	_sync_settings_from_controls()

func _configure_volume_slider(slider: HSlider) -> void:
	_configure_slider(slider, RhythmSettings.MIN_VOLUME_PERCENT, RhythmSettings.MAX_VOLUME_PERCENT, RhythmSettings.VOLUME_STEP)

func _configure_slider(slider: HSlider, min_value: float, max_value: float, step: float) -> void:
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.allow_greater = false
	slider.allow_lesser = false

func _connect_setting_signals() -> void:
	var sliders: Array[HSlider] = [
		master_slider,
		music_slider,
		sfx_slider,
		note_speed_slider,
		audio_offset_slider,
		judgement_offset_slider,
	]
	
	for slider in sliders:
		slider.value_changed.connect(_on_setting_changed)
	
	player_name_edit.text_changed.connect(_on_setting_changed)

func _sync_settings_from_controls() -> void:
	settings.master_volume = master_slider.value
	settings.music_volume = music_slider.value
	settings.sfx_volume = sfx_slider.value
	settings.note_speed = note_speed_slider.value
	settings.audio_offset_ms = audio_offset_slider.value
	settings.judgement_offset_ms = judgement_offset_slider.value
	settings.player_name = player_name_edit.text.strip_edges()

func _sync_controls_from_settings() -> void:
	master_slider.set_value_no_signal(settings.master_volume)
	music_slider.set_value_no_signal(settings.music_volume)
	sfx_slider.set_value_no_signal(settings.sfx_volume)
	note_speed_slider.set_value_no_signal(settings.note_speed)
	audio_offset_slider.set_value_no_signal(settings.audio_offset_ms)
	judgement_offset_slider.set_value_no_signal(settings.judgement_offset_ms)
	player_name_edit.text = settings.player_name
