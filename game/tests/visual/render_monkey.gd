extends SceneTree
## Renders one monkey model up close and saves a PNG: to look at a delivered model the
## way the game shows it (toon look, accessories, an animation frame, an open mouth)
## without starting a night. Needs a display, e.g. Xvfb:
##   MODEL=res://assets/monkeys/test_monkey.glb ANIM=cheer TIME=0.3 OUT=/path/shot.png \
##     xvfb-run -a godot --path game --rendering-method gl_compatibility \
##     --rendering-driver opengl3 --resolution 960x540 --script res://tests/visual/render_monkey.gd
## MODEL: the model (default: the test monkey). ANIM, TIME: animation and second (default: idle, 0).
## VIEW: front, side, back or three_quarter (default). ACC: accessory keys, comma-separated, or "all".
## AUDITOR=1: the auditor's hat. MOUTH: 0-1. BLINK=1: eyes shut. TOON=0: the model's own materials.
## TINT: fur tint as an HTML colour (e.g. ff9955). TABLE=1: with the table and a stool, as in the game.
## CLOSE=1: the head only (to check the mouth and the blink).

const DEFAULT_MODEL := "res://assets/monkeys/test_monkey.glb"
const VIEWS := {
	"front": Vector3(0, 0, -1),
	"side": Vector3(1, 0, 0),
	"back": Vector3(0, 0, 1),
	"three_quarter": Vector3(0.7, 0, -1),
}
const LOOK_AT := Vector3(0, 0.85, 0)
const CAMERA_DISTANCE := 2.2
const CLOSE_LOOK_AT := Vector3(0, 1.05, 0)
const CLOSE_DISTANCE := 0.75
const CAMERA_RISE := 0.25


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var env := func(key: String, fallback: String) -> String:
		var value := OS.get_environment(key)
		return fallback if value == "" else value
	var stage := Node3D.new()
	root.add_child(stage)
	_light(stage)
	var monkey: Monkey = (load("res://features/monkey/monkey.tscn") as PackedScene).instantiate()
	stage.add_child(monkey)
	var model: PackedScene = load(env.call("MODEL", DEFAULT_MODEL))
	monkey.dress(model, Color(env.call("TINT", "ffffff")), env.call("TOON", "1") == "1")
	monkey.set_player_name(str(env.call("MODEL", DEFAULT_MODEL)).get_file().get_basename())
	var accessories: String = env.call("ACC", "")
	if accessories == "all":
		accessories = ",".join((load("res://data/rules_v0_3.tres") as RulesConfig).accessory_keys)
	monkey.set_accessories(accessories.split(",", false))
	monkey.set_auditor(env.call("AUDITOR", "0") == "1")
	if env.call("TABLE", "0") == "1":
		_table(stage)
	# The monkey faces -Z; the camera stands on the side named by VIEW.
	var direction: Vector3 = VIEWS.get(env.call("VIEW", "three_quarter"), VIEWS["three_quarter"])
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.fov = 40.0
	var close: bool = env.call("CLOSE", "0") == "1"
	var target := CLOSE_LOOK_AT if close else LOOK_AT
	camera.position = target + direction.normalized() * (CLOSE_DISTANCE if close else CAMERA_DISTANCE) + Vector3.UP * CAMERA_RISE
	camera.look_at(target)
	camera.current = true
	var player := monkey.find_children("*", "AnimationPlayer", true, false)
	var animation: String = env.call("ANIM", "idle")
	var mouth := float(env.call("MOUTH", "0"))
	var shut: bool = env.call("BLINK", "0") == "1"
	for frame in 20:
		if not player.is_empty():
			var animations := player[0] as AnimationPlayer
			animations.play(animation)
			animations.seek(float(env.call("TIME", "0")), true)
		_hold_shape(monkey, Monkey.MOUTH_SHAPE, mouth)
		_hold_shape(monkey, Monkey.BLINK_SHAPE, 1.0 if shut else 0.0)
		await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("OUT"))
	quit()


## Sets a blend shape on every mesh after the monkey's own _process has run this frame.
func _hold_shape(monkey: Monkey, shape: String, value: float) -> void:
	if shape == Monkey.MOUTH_SHAPE:
		monkey.set_mouth_open(value)
		return
	for mesh: Node in monkey.find_children("*", "MeshInstance3D", true, false):
		var index := (mesh as MeshInstance3D).find_blend_shape_by_name(shape)
		if index >= 0:
			(mesh as MeshInstance3D).set_blend_shape_value(index, value)


func _light(stage: Node3D) -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.16, 0.15, 0.17)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.5, 0.48, 0.45)
	environment.ambient_light_energy = 0.7
	var world := WorldEnvironment.new()
	world.environment = environment
	stage.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 150, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	stage.add_child(sun)


## The edge of the game's table in front of the monkey, and its stool, at the game's
## distances (Table.MONKEY_RADIUS from the centre).
func _table(stage: Node3D) -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.32, 0.18, 0.08)
	var top := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.08
	disc.material = wood
	top.mesh = disc
	top.position = Vector3(0, 0.75, -1.38)
	stage.add_child(top)
	var stool := MeshInstance3D.new()
	var seat := CylinderMesh.new()
	seat.top_radius = 0.2
	seat.bottom_radius = 0.16
	seat.height = 0.44
	seat.material = wood
	stool.mesh = seat
	stool.position.y = 0.22
	stage.add_child(stool)
