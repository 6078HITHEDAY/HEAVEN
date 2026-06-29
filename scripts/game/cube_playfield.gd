extends Node3D

const OUTER_SIZE := 6.0
const CENTER_SIZE := 0.8
const PERFECT_WINDOW := 0.04
const GREAT_WINDOW := 0.08
const GOOD_WINDOW := 0.12
const MISS_WINDOW := 0.18
const NOTE_POOL_SIZE := 16
const EDGE_BREATHE_MIN := 1.5
const EDGE_BREATHE_MAX := 2.0
const EDGE_PULSE_PEAK := 3.0
const EDGE_PULSE_DURATION := 0.3
const EDGE_BREATHE_SPEED := 2.4
const CAMERA_ORBIT_SENSITIVITY := 0.006
const CAMERA_RAY_LENGTH := 100.0
const NOTE_SURFACE_TAP := "surface_tap"
const NOTE_SURFACE_HOLD := "surface_hold"
const NOTE_EDGE_SLIDE := "edge_slide"

const TEST_EVENTS := [
	{"type": NOTE_SURFACE_TAP, "time": 1.2, "face": "front", "uv": Vector2(0.5, 0.5), "travel_time": 1.0},
	{"type": NOTE_EDGE_SLIDE, "time": 2.1, "edge": "front_top", "t": 0.35, "bar_length": 0.8, "travel_time": 1.0},
	{"type": NOTE_SURFACE_TAP, "time": 3.0, "face": "right", "uv": Vector2(0.35, 0.55), "travel_time": 1.0},
	{"type": NOTE_SURFACE_HOLD, "time": 4.0, "end_time": 5.2, "face": "top", "uv": Vector2(0.65, 0.35), "travel_time": 1.0},
	{"type": NOTE_EDGE_SLIDE, "time": 6.0, "edge": "back_right", "t": 0.6, "bar_length": 1.25, "travel_time": 1.0},
	{"type": NOTE_SURFACE_HOLD, "time": 7.0, "end_time": 8.0, "face": "left", "uv": Vector2(0.5, 0.7), "travel_time": 1.0},
	{"type": NOTE_SURFACE_TAP, "time": 8.8, "face": "bottom", "uv": Vector2(0.6, 0.5), "travel_time": 1.0},
]

var song_time := 0.0
var score := 0
var combo := 0
var best_combo := 0
var spawned_notes: Array[Dictionary] = []
var active_notes: Array[Dictionary] = []
var note_pools: Dictionary = {}
var note_meshes: Dictionary = {}
var target_meshes: Dictionary = {}
var edge_material: ShaderMaterial
var edge_pulse_time := 0.0
var finished := false
var hit_input_down := false
var camera_dragging := false

@onready var camera: Camera3D = $Camera3D
@onready var emitter_core: Node3D = $EmitterCore
@onready var emission_particles: GPUParticles3D = $EmitterCore/EmissionParticles
@onready var outer_cube: MeshInstance3D = $OuterShell/OuterCube
@onready var touch_boundary: StaticBody3D = $OuterShell/TouchBoundary
@onready var notes_root: Node3D = $Notes
@onready var target_marker: MeshInstance3D = $TargetMarker
@onready var hud_label: Label = $HUD/Stats
@onready var feedback_label: Label = $HUD/Feedback

func _ready() -> void:
	edge_material = outer_cube.material_override as ShaderMaterial
	_build_note_pools()
	for event in TEST_EVENTS:
		spawned_notes.append(event.duplicate())
	feedback_label.text = "READY"
	_update_hud()

func _process(delta: float) -> void:
	if finished:
		return

	song_time += delta
	_update_edge_highlight(delta)
	_spawn_due_notes()
	_update_active_notes()
	_finish_held_notes()
	_miss_expired_notes()
	_update_hud()
	_finish_if_done()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and camera_dragging:
		_orbit_camera(event.relative.x)
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event)
		return

	if event.is_action_pressed("ui_accept"):
		hit_input_down = true
		_judge_nearest_note()
	elif event.is_action_released("ui_accept"):
		hit_input_down = false
		_release_held_notes()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/ui/select/select.tscn")

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		if _mouse_hits_touch_boundary(event.position):
			hit_input_down = true
			_judge_nearest_note()
		else:
			camera_dragging = true
			hit_input_down = false
	else:
		if camera_dragging:
			camera_dragging = false
			return
		hit_input_down = false
		_release_held_notes()

func _orbit_camera(relative_x: float) -> void:
	var offset := camera.global_position - global_position
	offset = offset.rotated(Vector3.UP, -relative_x * CAMERA_ORBIT_SENSITIVITY)
	camera.global_position = global_position + offset
	camera.look_at(global_position, Vector3.UP)

func _mouse_hits_touch_boundary(screen_position: Vector2) -> bool:
	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_end := ray_origin + camera.project_ray_normal(screen_position) * CAMERA_RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("collider") == touch_boundary

func _spawn_due_notes() -> void:
	var i := spawned_notes.size() - 1
	while i >= 0:
		var event := spawned_notes[i]
		if song_time >= float(event["time"]) - float(event["travel_time"]):
			_spawn_note(event)
			spawned_notes.remove_at(i)
		i -= 1

func _spawn_note(event: Dictionary) -> void:
	var note_type := String(event.get("type", NOTE_SURFACE_TAP))
	var note := _acquire_note(note_type)
	if note == null:
		return

	var start_position := _event_start_position(event)
	var target_position := _event_target_position(event)
	var note_basis := _event_basis(event, start_position, target_position)
	note.visible = true
	note.scale = Vector3.ONE
	note.global_transform = Transform3D(note_basis, start_position)
	emission_particles.global_transform = Transform3D(_basis_from_forward(target_position - start_position), start_position)
	emission_particles.restart()
	edge_pulse_time = EDGE_PULSE_DURATION

	var note_data := {
		"type": note_type,
		"time": float(event.get("time", 0.0)),
		"end_time": float(event.get("end_time", event.get("time", 0.0))),
		"travel_time": float(event.get("travel_time", 1.0)),
		"start_position": start_position,
		"target_position": target_position,
		"basis": note_basis,
		"node": note,
		"held": false,
		"start_judgement": "",
		"bar_length": float(event.get("bar_length", 1.0)),
	}
	active_notes.append(note_data)
	_update_target_marker(note_type, target_position, note_basis, float(note_data["bar_length"]))

func _update_active_notes() -> void:
	for note_data in active_notes:
		var note := note_data["node"] as MeshInstance3D
		var progress := 1.0 - ((float(note_data["time"]) - song_time) / float(note_data["travel_time"]))
		progress = clampf(progress, 0.0, 1.0)
		var note_position: Vector3 = note_data["start_position"].lerp(note_data["target_position"], progress)
		var pulse := 1.0 + sin(song_time * 14.0) * 0.08
		var note_type := String(note_data["type"])
		match note_type:
			NOTE_SURFACE_HOLD:
				_update_hold_note_visual(note_data, note, progress)
			NOTE_EDGE_SLIDE:
				note.global_transform = Transform3D(note_data["basis"], note_position)
				note.scale = Vector3(1.0, float(note_data["bar_length"]), 1.0) * pulse
			_:
				note.global_transform = Transform3D(note_data["basis"], note_position)
				note.scale = Vector3.ONE * pulse

func _update_edge_highlight(delta: float) -> void:
	if edge_material == null:
		return

	var breathe_t := (sin(song_time * EDGE_BREATHE_SPEED) + 1.0) * 0.5
	var breathe_energy := lerpf(EDGE_BREATHE_MIN, EDGE_BREATHE_MAX, breathe_t)
	var pulse_energy := 0.0
	if edge_pulse_time > 0.0:
		var pulse_t := edge_pulse_time / EDGE_PULSE_DURATION
		pulse_energy = lerpf(breathe_energy, EDGE_PULSE_PEAK, pulse_t)
		edge_pulse_time = maxf(edge_pulse_time - delta, 0.0)

	edge_material.set_shader_parameter("edge_emission", maxf(breathe_energy, pulse_energy))

func _miss_expired_notes() -> void:
	var i := active_notes.size() - 1
	while i >= 0:
		var note_data := active_notes[i]
		if _note_is_expired(note_data):
			_apply_judgement(i, "MISS", 0)
		i -= 1

func _judge_nearest_note() -> void:
	if active_notes.is_empty():
		feedback_label.text = "MISS"
		combo = 0
		return

	var best_index := -1
	var best_error := INF
	for i in range(active_notes.size()):
		var note_data := active_notes[i]
		if bool(note_data["held"]):
			continue

		var error := absf(song_time - float(note_data["time"]))
		if error < best_error:
			best_error = error
			best_index = i

	if best_index == -1:
		return

	if String(active_notes[best_index]["type"]) == NOTE_SURFACE_HOLD:
		_judge_hold_start(best_index, best_error)
		return

	if best_error <= PERFECT_WINDOW:
		_apply_judgement(best_index, "PERFECT", 1000)
	elif best_error <= GREAT_WINDOW:
		_apply_judgement(best_index, "GREAT", 700)
	elif best_error <= GOOD_WINDOW:
		_apply_judgement(best_index, "GOOD", 400)
	elif best_error <= MISS_WINDOW:
		_apply_judgement(best_index, "MISS", 0)
	else:
		feedback_label.text = "MISS"
		combo = 0

func _judge_hold_start(note_index: int, error: float) -> void:
	if error <= GOOD_WINDOW:
		var note_data := active_notes[note_index]
		note_data["held"] = true
		note_data["start_judgement"] = _judgement_for_error(error)
		active_notes[note_index] = note_data
		feedback_label.text = "HOLD"
	elif error <= MISS_WINDOW:
		_apply_judgement(note_index, "MISS", 0)
	else:
		feedback_label.text = "MISS"
		combo = 0

func _finish_held_notes() -> void:
	var i := active_notes.size() - 1
	while i >= 0:
		var note_data := active_notes[i]
		if bool(note_data["held"]) and song_time >= float(note_data["end_time"]):
			if hit_input_down:
				var judgement := String(note_data["start_judgement"])
				_apply_judgement(i, judgement, _points_for_hold_judgement(judgement))
			else:
				_apply_judgement(i, "MISS", 0)
		i -= 1

func _release_held_notes() -> void:
	var i := active_notes.size() - 1
	while i >= 0:
		var note_data := active_notes[i]
		if bool(note_data["held"]):
			var end_error := absf(song_time - float(note_data["end_time"]))
			if end_error <= GOOD_WINDOW:
				var start_judgement := String(note_data["start_judgement"])
				var end_judgement := _judgement_for_error(end_error)
				var judgement := _weaker_judgement(start_judgement, end_judgement)
				_apply_judgement(i, judgement, _points_for_hold_judgement(judgement))
			else:
				_apply_judgement(i, "MISS", 0)
		i -= 1

func _apply_judgement(note_index: int, judgement: String, points: int) -> void:
	_remove_note_at(note_index)
	if points > 0:
		combo += 1
		best_combo = maxi(best_combo, combo)
		score += points
	else:
		combo = 0
	feedback_label.text = judgement

func _remove_note_at(index: int) -> void:
	var note_data := active_notes[index]
	var note := note_data["node"] as MeshInstance3D
	if is_instance_valid(note):
		_release_note(note, String(note_data["type"]))
	active_notes.remove_at(index)

func _finish_if_done() -> void:
	if spawned_notes.is_empty() and active_notes.is_empty():
		finished = true
		feedback_label.text = "FINISHED"
		_update_hud()

func _update_hud() -> void:
	var held_count := 0
	for note_data in active_notes:
		if bool(note_data["held"]):
			held_count += 1

	hud_label.text = "Score %d\nCombo %d\nBest %d\nTime %.2f\nHolding %d" % [score, combo, best_combo, song_time, held_count]

func _note_is_expired(note_data: Dictionary) -> bool:
	if bool(note_data["held"]):
		return song_time - float(note_data["end_time"]) > MISS_WINDOW
	return song_time - float(note_data["time"]) > MISS_WINDOW

func _event_start_position(event: Dictionary) -> Vector3:
	var note_type := String(event.get("type", NOTE_SURFACE_TAP))
	if note_type == NOTE_EDGE_SLIDE:
		return _edge_to_position_for_size(String(event.get("edge", "front_top")), float(event.get("t", 0.5)), CENTER_SIZE)
	var uv: Vector2 = event.get("uv", Vector2(0.5, 0.5))
	return _face_to_position_for_size(String(event.get("face", "front")), uv, CENTER_SIZE)

func _event_target_position(event: Dictionary) -> Vector3:
	var note_type := String(event.get("type", NOTE_SURFACE_TAP))
	var start_position := _event_start_position(event)
	if note_type == NOTE_EDGE_SLIDE:
		return _edge_projection_to_outer(String(event.get("edge", "front_top")), start_position)
	return _face_projection_to_outer(String(event.get("face", "front")), start_position)

func _event_basis(event: Dictionary, start_position: Vector3, target_position: Vector3) -> Basis:
	var note_type := String(event.get("type", NOTE_SURFACE_TAP))
	if note_type == NOTE_EDGE_SLIDE:
		return _basis_from_y_forward(_edge_tangent(String(event.get("edge", "front_top"))), target_position - start_position)
	if note_type == NOTE_SURFACE_HOLD:
		return _basis_from_forward(target_position - start_position)
	return _face_basis(String(event.get("face", "front")))

func _update_hold_note_visual(note_data: Dictionary, note: MeshInstance3D, progress: float) -> void:
	var start_position: Vector3 = note_data["start_position"]
	var target_position: Vector3 = note_data["target_position"]
	var head_position := start_position.lerp(target_position, progress)
	if bool(note_data["held"]):
		head_position = target_position

	var length := maxf(start_position.distance_to(head_position), 0.05)
	var midpoint := start_position.lerp(head_position, 0.5)
	var note_basis := _basis_from_forward(head_position - start_position)
	note.global_transform = Transform3D(note_basis, midpoint)
	note.scale = Vector3(1.0, 1.0, length)

func _update_target_marker(note_type: String, target_position: Vector3, marker_basis: Basis, bar_length: float) -> void:
	target_marker.visible = true
	var marker_mesh: Mesh = target_meshes.get(note_type, target_meshes[NOTE_SURFACE_TAP])
	target_marker.mesh = marker_mesh
	target_marker.global_transform = Transform3D(marker_basis, target_position)
	if note_type == NOTE_EDGE_SLIDE:
		target_marker.scale = Vector3(1.0, bar_length, 1.0)
	else:
		target_marker.scale = Vector3.ONE

func _face_to_position(face: String, uv: Vector2) -> Vector3:
	return _face_to_position_for_size(face, uv, OUTER_SIZE)

func _face_projection_to_outer(face: String, start_position: Vector3) -> Vector3:
	var half := OUTER_SIZE * 0.5
	match face:
		"front":
			return Vector3(start_position.x, start_position.y, -half)
		"back":
			return Vector3(start_position.x, start_position.y, half)
		"left":
			return Vector3(-half, start_position.y, start_position.z)
		"right":
			return Vector3(half, start_position.y, start_position.z)
		"top":
			return Vector3(start_position.x, half, start_position.z)
		"bottom":
			return Vector3(start_position.x, -half, start_position.z)
		_:
			return Vector3(start_position.x, start_position.y, -half)

func _face_to_position_for_size(face: String, uv: Vector2, size: float) -> Vector3:
	var half := size * 0.5
	var x := lerpf(-half, half, uv.x)
	var y := lerpf(-half, half, uv.y)
	match face:
		"front":
			return Vector3(x, y, -half)
		"back":
			return Vector3(-x, y, half)
		"left":
			return Vector3(-half, y, -x)
		"right":
			return Vector3(half, y, x)
		"top":
			return Vector3(x, half, y)
		"bottom":
			return Vector3(x, -half, -y)
		_:
			return Vector3(x, y, -half)

func _face_basis(face: String) -> Basis:
	match face:
		"front":
			return Basis(Vector3.RIGHT, Vector3.UP, Vector3.FORWARD)
		"back":
			return Basis(Vector3.LEFT, Vector3.UP, Vector3.BACK)
		"left":
			return Basis(Vector3.FORWARD, Vector3.UP, Vector3.LEFT)
		"right":
			return Basis(Vector3.BACK, Vector3.UP, Vector3.RIGHT)
		"top":
			return Basis(Vector3.RIGHT, Vector3.BACK, Vector3.UP)
		"bottom":
			return Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.DOWN)
		_:
			return Basis.IDENTITY

func _edge_to_position(edge: String, t: float) -> Vector3:
	return _edge_to_position_for_size(edge, t, OUTER_SIZE)

func _edge_projection_to_outer(edge: String, start_position: Vector3) -> Vector3:
	var half := OUTER_SIZE * 0.5
	match edge:
		"front_top":
			return Vector3(start_position.x, half, -half)
		"front_bottom":
			return Vector3(start_position.x, -half, -half)
		"front_left":
			return Vector3(-half, start_position.y, -half)
		"front_right":
			return Vector3(half, start_position.y, -half)
		"back_top":
			return Vector3(start_position.x, half, half)
		"back_bottom":
			return Vector3(start_position.x, -half, half)
		"back_left":
			return Vector3(-half, start_position.y, half)
		"back_right":
			return Vector3(half, start_position.y, half)
		"left_top":
			return Vector3(-half, half, start_position.z)
		"left_bottom":
			return Vector3(-half, -half, start_position.z)
		"right_top":
			return Vector3(half, half, start_position.z)
		"right_bottom":
			return Vector3(half, -half, start_position.z)
		_:
			return Vector3(start_position.x, half, -half)

func _edge_to_position_for_size(edge: String, t: float, size: float) -> Vector3:
	var half := size * 0.5
	var axis_value := lerpf(-half, half, clampf(t, 0.0, 1.0))
	match edge:
		"front_top":
			return Vector3(axis_value, half, -half)
		"front_bottom":
			return Vector3(axis_value, -half, -half)
		"front_left":
			return Vector3(-half, axis_value, -half)
		"front_right":
			return Vector3(half, axis_value, -half)
		"back_top":
			return Vector3(axis_value, half, half)
		"back_bottom":
			return Vector3(axis_value, -half, half)
		"back_left":
			return Vector3(-half, axis_value, half)
		"back_right":
			return Vector3(half, axis_value, half)
		"left_top":
			return Vector3(-half, half, axis_value)
		"left_bottom":
			return Vector3(-half, -half, axis_value)
		"right_top":
			return Vector3(half, half, axis_value)
		"right_bottom":
			return Vector3(half, -half, axis_value)
		_:
			return Vector3(axis_value, half, -half)

func _edge_tangent(edge: String) -> Vector3:
	match edge:
		"front_top", "front_bottom", "back_top", "back_bottom":
			return Vector3.RIGHT
		"front_left", "front_right", "back_left", "back_right":
			return Vector3.UP
		"left_top", "left_bottom", "right_top", "right_bottom":
			return Vector3.BACK
		_:
			return Vector3.RIGHT

func _basis_from_forward(forward: Vector3) -> Basis:
	var z_axis := forward.normalized()
	if z_axis.length_squared() <= 0.0001:
		z_axis = Vector3.FORWARD
	var y_hint := Vector3.UP
	if absf(z_axis.dot(y_hint)) > 0.92:
		y_hint = Vector3.RIGHT
	var x_axis := y_hint.cross(z_axis).normalized()
	var y_axis := z_axis.cross(x_axis).normalized()
	return Basis(x_axis, y_axis, z_axis)

func _basis_from_y_forward(y_axis: Vector3, forward: Vector3) -> Basis:
	var clean_y := y_axis.normalized()
	var z_axis := forward - clean_y * forward.dot(clean_y)
	if z_axis.length_squared() <= 0.0001:
		z_axis = Vector3.FORWARD
	z_axis = z_axis.normalized()
	var x_axis := clean_y.cross(z_axis).normalized()
	return Basis(x_axis, clean_y, z_axis)

func _build_note_pools() -> void:
	_register_note_type(NOTE_SURFACE_TAP, Vector3(0.46, 0.46, 0.04), Color(0.9, 0.97, 1.0, 1.0), "SurfaceTap")
	_register_note_type(NOTE_SURFACE_HOLD, Vector3(0.34, 0.34, 1.0), Color(0.45, 1.0, 0.72, 1.0), "SurfaceHold")
	_register_note_type(NOTE_EDGE_SLIDE, Vector3(0.22, 0.85, 0.12), Color(1.0, 0.72, 0.28, 1.0), "EdgeSlide")
	target_meshes[NOTE_SURFACE_TAP] = _make_box_mesh(Vector3(0.52, 0.52, 0.08))
	target_meshes[NOTE_SURFACE_HOLD] = _make_box_mesh(Vector3(0.62, 0.62, 0.1))
	target_meshes[NOTE_EDGE_SLIDE] = _make_box_mesh(Vector3(0.24, 0.95, 0.14))

func _register_note_type(note_type: String, mesh_size: Vector3, color: Color, node_prefix: String) -> void:
	var note_mesh := _make_box_mesh(mesh_size)
	var note_material := _make_note_material(color)
	var pool: Array[MeshInstance3D] = []

	for i in range(NOTE_POOL_SIZE):
		var note := MeshInstance3D.new()
		note.name = "%s_%02d" % [node_prefix, i]
		note.mesh = note_mesh
		note.material_override = note_material
		note.visible = false
		notes_root.add_child(note)
		pool.append(note)

	note_meshes[note_type] = note_mesh
	note_pools[note_type] = pool

func _acquire_note(note_type: String) -> MeshInstance3D:
	var pool: Array = note_pools.get(note_type, [])
	if pool.is_empty():
		push_warning("Note pool exhausted for '%s'. Pool size: %d. Active notes: %d." % [note_type, NOTE_POOL_SIZE, active_notes.size()])
		return null
	var note := pool.pop_back() as MeshInstance3D
	note_pools[note_type] = pool
	return note

func _release_note(note: MeshInstance3D, note_type: String) -> void:
	note.visible = false
	note.scale = Vector3.ONE
	var pool: Array = note_pools.get(note_type, [])
	pool.append(note)
	note_pools[note_type] = pool

func _judgement_for_error(error: float) -> String:
	if error <= PERFECT_WINDOW:
		return "PERFECT"
	if error <= GREAT_WINDOW:
		return "GREAT"
	return "GOOD"

func _points_for_hold_judgement(judgement: String) -> int:
	match judgement:
		"PERFECT":
			return 1500
		"GREAT":
			return 1100
		"GOOD":
			return 700
		_:
			return 0

func _weaker_judgement(a: String, b: String) -> String:
	var order := ["MISS", "GOOD", "GREAT", "PERFECT"]
	if order.find(a) < order.find(b):
		return a
	return b

func _make_box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func _make_note_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.5
	return material
