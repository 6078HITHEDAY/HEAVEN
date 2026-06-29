extends Node3D

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/cube_playfield.tscn")

func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")
