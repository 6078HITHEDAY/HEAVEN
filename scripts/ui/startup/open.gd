extends Control
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D 
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 播放动画
func _playAnim(text: String):
	animation_player.play(text)

# 场景初始化
func _ready() -> void:
	audio_player.play()  # 播放音频
	_playAnim("logo1")  # 播放动画

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://scenes/ui/start_menu/start_menu_3d.tscn")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/start_menu/start_menu_3d.tscn")
