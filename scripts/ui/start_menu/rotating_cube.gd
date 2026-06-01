extends MeshInstance3D

# 旋转参数 - 平滑慢速旋转
var rotation_speed = Vector3.ZERO
var max_speed = 1.2  # 最大旋转速度
var acceleration_factor = 0.2  # 加速度因子

func _ready():
	# 初始化随机旋转
	randomize_rotation()

func _process(delta):
	# 更新旋转（带加速度变化）
	var rotation_acceleration = Vector3(
		randf_range(-1, 1),
		randf_range(-1, 1),
		randf_range(-1, 1)
	) * acceleration_factor * delta
	
	rotation_speed += rotation_acceleration
	rotation_speed = rotation_speed.clamp(
		Vector3.ONE * -max_speed, 
		Vector3.ONE * max_speed
	)
	
	# 应用旋转
	rotate_object_local(Vector3.RIGHT, rotation_speed.x * delta)
	rotate_object_local(Vector3.UP, rotation_speed.y * delta)
	rotate_object_local(Vector3.BACK, rotation_speed.z * delta)

func randomize_rotation():
	rotation_speed = Vector3(
		randf_range(-max_speed, max_speed),
		randf_range(-max_speed, max_speed),
		randf_range(-max_speed, max_speed)
	)
