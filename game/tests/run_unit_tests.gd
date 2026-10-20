extends SceneTree
## Minimal headless test runner. Runs every test_* method of tests/unit/test_*.gd
## and exits with 1 if anything fails:
##   godot --headless --path game --script res://tests/run_unit_tests.gd

const UNIT_DIR := "res://tests/unit"


func _init() -> void:
	var passed := 0
	var failed := 0
	for file in DirAccess.get_files_at(UNIT_DIR):
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script: GDScript = load(UNIT_DIR.path_join(file))
		if script == null or not script.can_instantiate():
			failed += 1
			printerr("FAIL %s — script does not compile" % file)
			continue
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var suite: TestSuite = script.new()
			suite.call(method_name)
			if suite.failures.is_empty():
				passed += 1
			else:
				failed += 1
				for message in suite.failures:
					printerr("FAIL %s::%s — %s" % [file, method_name, message])
	print("Unit tests: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
