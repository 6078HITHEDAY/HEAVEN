extends Node2D

const CONFIG_PATH = "user://audio_settings.cfg"
const CONFIG_GROUP = "AudioSettings"

func _ready() -> void:
	load_audio_settings()

func _on_texture_button_pressed() -> void:
	save_audio_settings()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")

func save_audio_settings() -> bool:
	var config = ConfigFile.new()
	
	config.set_value(CONFIG_GROUP, "master_volume", $"TabContainer/游玩/Master".value)
	config.set_value(CONFIG_GROUP, "music_volume", $"TabContainer/游玩/MUSIC".value)
	config.set_value(CONFIG_GROUP, "sfx_volume", $"TabContainer/游玩/SFX".value)
	
	var error = config.save(CONFIG_PATH)
	if error != OK:
		push_warning("Failed to save audio settings. Error code: %s" % error)
	return error == OK

func load_audio_settings() -> void:
	var config = ConfigFile.new()
	config.load(CONFIG_PATH)
	
	var master_vol = config.get_value(CONFIG_GROUP, "master_volume", 1.0)
	var music_vol = config.get_value(CONFIG_GROUP, "music_volume", 1.0)
	var sfx_vol = config.get_value(CONFIG_GROUP, "sfx_volume", 1.0)
	
	$"TabContainer/游玩/Master".value = master_vol
	$"TabContainer/游玩/MUSIC".value = music_vol
	$"TabContainer/游玩/SFX".value = sfx_vol
	
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), master_vol)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("MUSIC"), music_vol)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), sfx_vol)

func _on_master_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)

func _on_music_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("MUSIC"), value)

func _on_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), value)
