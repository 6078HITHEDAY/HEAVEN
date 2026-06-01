extends CanvasLayer

@warning_ignore("unused_signal")
signal skip_animations_requested

@onready var buttons = [$about, $quit, $select, $setup]
@onready var skip_button = $SkipButton
@onready var tween: Tween
var light_animation_node: Node3D  # 引用第一个脚本的节点

func _ready():
	# 获取根节点 Control
	light_animation_node = get_parent()

	skip_button.visible = true
	fade_buttons_with_delays()

func fade_buttons_with_delays():
	for button in buttons:
		if button and button != skip_button:
			button.modulate.a = 0
	
	tween = create_tween()
	
	var delays = [2.00, 3.05, 1.10, 1.50]
	var fade_duration = 0.8
	
	for i in range(buttons.size()):
		if buttons[i] and buttons[i] != skip_button:
			tween.tween_callback(fade_in.bind(buttons[i], fade_duration)).set_delay(delays[i])

func fade_in(button: Button, duration: float):
	var single_tween = create_tween()
	single_tween.tween_property(button, "modulate:a", 1.0, duration)

func _on_skip_button_pressed():
	skip_animations()
	# 通知第一个脚本跳过动画
	if light_animation_node and light_animation_node.has_method("skip_light_animation"):
		light_animation_node.skip_light_animation()

func skip_animations():
	if tween and tween.is_valid():
		tween.kill()
	
	for button in buttons:
		if button and button != skip_button:
			button.modulate.a = 1.0
	
	skip_button.visible = false
	skip_button.disabled = true

# 其他按钮处理函数
func _on_about_pressed() -> void:
	skip_animations()
	if light_animation_node and light_animation_node.has_method("skip_light_animation"):
		light_animation_node.skip_light_animation()
	get_tree().change_scene_to_file("res://scenes/ui/about/about.tscn")

func _on_select_pressed() -> void:
	skip_animations()
	if light_animation_node and light_animation_node.has_method("skip_light_animation"):
		light_animation_node.skip_light_animation()
	get_tree().change_scene_to_file("res://scenes/ui/select/select.tscn")

func _on_quit_pressed() -> void:
	skip_animations()
	if light_animation_node and light_animation_node.has_method("skip_light_animation"):
		light_animation_node.skip_light_animation()
	get_tree().quit()

func _on_setup_pressed() -> void:
	skip_animations()
	if light_animation_node and light_animation_node.has_method("skip_light_animation"):
		light_animation_node.skip_light_animation()
	get_tree().change_scene_to_file("res://scenes/ui/settings/settings.tscn")
