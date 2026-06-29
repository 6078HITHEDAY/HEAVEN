extends SceneTree

const RESOURCE_EXTENSIONS := [".gd", ".gdshader", ".tres", ".tscn"]
const RESOURCE_ROOTS := [
	"res://scenes",
	"res://scripts",
	"res://assets",
	"res://shaders",
	"res://themes",
	"res://config",
]

var failed := false

func _initialize() -> void:
	for root_path in RESOURCE_ROOTS:
		for path in _resource_paths(root_path):
			_load_resource(path)

	if failed:
		quit(1)
	else:
		print("All project resources loaded.")
		quit(0)

func _resource_paths(root_path: String) -> Array[String]:
	var paths: Array[String] = []
	var dirs := [root_path]

	while not dirs.is_empty():
		var current_path := dirs.pop_back() as String
		var dir := DirAccess.open(current_path)
		if dir == null:
			if current_path == root_path:
				push_warning("Skipping missing resource directory: %s" % current_path)
			else:
				push_error("Could not open directory: %s" % current_path)
				failed = true
			continue

		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if entry.begins_with("."):
				entry = dir.get_next()
				continue

			var entry_path := current_path.path_join(entry)
			if dir.current_is_dir():
				dirs.append(entry_path)
			elif _has_resource_extension(entry_path):
				paths.append(entry_path)

			entry = dir.get_next()
		dir.list_dir_end()

	paths.sort()
	return paths

func _has_resource_extension(path: String) -> bool:
	for extension in RESOURCE_EXTENSIONS:
		if path.ends_with(extension):
			return true
	return false

func _load_resource(path: String) -> void:
	var resource := ResourceLoader.load(path)
	if resource == null:
		push_error("Failed to load resource: %s" % path)
		failed = true
		return

	if resource is PackedScene:
		var scene := resource as PackedScene
		var instance := scene.instantiate()
		if instance == null:
			push_error("Failed to instantiate scene: %s" % path)
			failed = true
			return
		instance.queue_free()
