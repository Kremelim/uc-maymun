extends SceneTree
## Fails if any of our scripts has a GDScript warning. The editor shows warnings,
## but headless runs never print them. So this writes an override.cfg that turns
## every warning into an error, starts a second Godot that compiles all scripts
## under it, and removes the file again:
##   godot --headless --path game --script res://tests/lint_warnings.gd

const SELF_PATH := "res://tests/lint_warnings.gd"
const OVERRIDE_PATH := "res://override.cfg"
const CHECK_FLAG := "--lint-check"
const SKIPPED_DIRS := ["res://addons", "res://.godot"]
const WARNING_PREFIX := "debug/gdscript/warnings/"
const LEVEL_WARN := 1
const LEVEL_ERROR := 2


func _init() -> void:
	if CHECK_FLAG in OS.get_cmdline_user_args():
		# Deferred so autoloads (Network, Session, ...) exist when scripts compile.
		_check.call_deferred()
	else:
		_launch_check()


func _launch_check() -> void:
	var override := ConfigFile.new()
	for property: Dictionary in ProjectSettings.get_property_list():
		var key: String = property["name"]
		var level: Variant = ProjectSettings.get_setting(key)
		if key.begins_with(WARNING_PREFIX) and typeof(level) == TYPE_INT and level == LEVEL_WARN:
			override.set_value("debug", key.trim_prefix("debug/"), LEVEL_ERROR)
	override.save(OVERRIDE_PATH)
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", SELF_PATH, "--", CHECK_FLAG]
	var output: Array = []
	var exit_code := OS.execute(OS.get_executable_path(), args, output, true)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OVERRIDE_PATH))
	for chunk: String in output:
		print(chunk)
	quit(exit_code)


func _check() -> void:
	var failed := PackedStringArray()
	var paths := _script_paths("res://")
	for path in paths:
		if path == SELF_PATH:
			continue
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			failed.append(path)
	for path in failed:
		printerr("LINT FAIL %s (warning shown above as an error)" % path)
	print("Lint: %d scripts checked, %d with warnings" % [paths.size() - 1, failed.size()])
	quit(1 if not failed.is_empty() else 0)


func _script_paths(dir: String) -> PackedStringArray:
	var paths := PackedStringArray()
	if dir.trim_suffix("/") in SKIPPED_DIRS:
		return paths
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			paths.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		paths.append_array(_script_paths(dir.path_join(sub)))
	return paths
