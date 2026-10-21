extends SceneTree
## Checks monkey models against docs/sanatci-sartnamesi.md and prints a report:
##   godot --headless --path game --script res://tools/check_monkey_model.gd -- --model=res://assets/monkeys/new.glb
## Without --model it checks every body in the cast (res://assets/monkeys/cast.tres).
## Copy a delivery under game/assets/monkeys/ and import it first (open the editor once,
## or run --import). Exits with 1 if a model has errors; warnings do not fail it.

const CAST_PATH := "res://assets/monkeys/cast.tres"


func _init() -> void:
	# Deferred so the Session autoload (which holds the rules) exists.
	_run.call_deferred()


func _run() -> void:
	var rules: RulesConfig = root.get_node("Session").get("RULES")
	var paths := PackedStringArray()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--model="):
			paths.append(arg.trim_prefix("--model="))
	if paths.is_empty():
		for body: PackedScene in (load(CAST_PATH) as MonkeyCast).bodies:
			if body.resource_path not in paths:
				paths.append(body.resource_path)
	var failed := false
	for path in paths:
		print("Model: %s" % path)
		var scene := load(path) as PackedScene
		if scene == null:
			print("  ✗ Yüklenemedi. Dosya game/ altında mı, içe aktarıldı mı (editörü bir kez aç ya da --import)?")
			failed = true
			continue
		var check := MonkeyModelCheck.of(scene, rules.accessory_keys)
		print(check.report())
		failed = failed or not check.passed()
	quit(1 if failed else 0)
