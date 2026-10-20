extends SceneTree
## Renders the table from one seat with fake data and saves a PNG, so layout
## changes can be checked without four game windows. Needs a display, e.g. Xvfb:
##   SEAT=0 STATE=pending|revealed OUT=/path/shot.png xvfb-run -a godot --path game \
##     --rendering-method gl_compatibility --rendering-driver opengl3 \
##     --resolution 960x540 --script res://tests/visual/render_table.gd
## Add MOUTH_OPEN=1 to show the monkeys talking, and "-- --fake-voice" at the end
## to show the HUD's voice controls.

const NAMES := ["Kerem", "Gonc", "Abdulalim", "Ulas"]
const FRAMES_TO_SETTLE := 30


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var seat := int(OS.get_environment("SEAT"))
	var network: Node = root.get_node("Network")
	var session: Node = root.get_node("Session")
	# Offline, our peer id is 1, so give id 1 the seat we want to look from.
	var roster := {}
	for s in NAMES.size():
		roster[1 if s == seat else 100 + s] = {"name": NAMES[s], "seat": s}
	network.roster = roster
	var declarations := PackedInt32Array([4, 6, 6, 5])
	session.private_view = {"seat": seat, "income": 8, "declaration": declarations[seat]}
	if OS.get_environment("STATE") == "pending":
		session.public_state = {"round": 2, "total_income": 20, "declared": [true, false, true, true]}
	else:
		session.public_state = {
			"round": 2,
			"total_income": 20,
			"declared": [true, true, true, true],
			"declarations": declarations,
			"missing": -1,
		}
	change_scene_to_file("res://features/table/table.tscn")
	for i in FRAMES_TO_SETTLE:
		if OS.get_environment("MOUTH_OPEN") == "1":
			for monkey in root.find_children("*", "MonkeyPlaceholder", true, false):
				(monkey as MonkeyPlaceholder).set_mouth_open(1.0)
		await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("OUT"))
	quit()
