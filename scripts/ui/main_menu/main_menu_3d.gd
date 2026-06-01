extends Node3D

@onready var directional_light = $DirectionalLight3D
@onready var skip_button = $CanvasLayer/SkipButton
var tween: Tween

func _ready():
	if directional_light == null:
		directional_light = get_node("DirectionalLight3D")
	if directional_light == null:
		push_error("DirectionalLight3D node not found!")
		return
	
	start_light_tween()

func start_light_tween():
	tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	
	var initial_rotation = Vector3(0, 60, 0)
	var target_rotation = Vector3(0, 360, 0)
	
	directional_light.rotation_degrees = initial_rotation
	tween.tween_property(directional_light, "rotation_degrees", target_rotation, 10.0)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

func skip_light_animation():
	if tween != null and tween.is_valid():
		tween.kill()
		directional_light.rotation_degrees = Vector3(0, 360, 0)
