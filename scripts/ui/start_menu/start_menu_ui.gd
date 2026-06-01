extends Control

@onready var button = $StartButton
@onready var tween: Tween

func _ready():
	button.focus_mode = Control.FOCUS_NONE  # 改为无焦点模式
	
	# 创建 Tween 并开始闪烁动画
	tween = create_tween()
	tween.set_loops()  # 设置为无限循环
	tween.tween_property(button, "modulate:a", 0.1, 0.7)  # 淡出到 10% 透明度
	tween.tween_property(button, "modulate:a", 1.0, 0.8)  # 淡入到 100% 透明度

func _on_start_button_pressed():
	# 停止闪烁动画
	if tween:
		tween.kill()
	
	# 创建新的 Tween 来移动按钮到右侧
	var slide_tween = create_tween()
	slide_tween.tween_property(button, "position:x", 1090, 0.3)  # 在0.3秒内移动到右侧
	slide_tween.tween_callback(_change_scene)  # 动画完成后切换场景

func _change_scene():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")
