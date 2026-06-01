extends Control
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _playAnim(text: String):
	animation_player.play(text)
func _ready() -> void:
	_playAnim("rt") 


func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn") 
