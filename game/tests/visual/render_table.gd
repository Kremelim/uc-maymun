extends SceneTree
## Renders the table from one seat and saves a PNG, so layout changes can be checked
## without four game windows. Bots play a real night up to the requested phase.
## Needs a display, e.g. Xvfb:
##   SEAT=0 STATE=negotiate OUT=/path/shot.png xvfb-run -a godot --path game \
##     --rendering-method gl_compatibility --rendering-driver opengl3 \
##     --resolution 960x540 --script res://tests/visual/render_table.gd
## STATE: declare, negotiate, contribute, audit_choose, audit_decide, shop, match_over, night_over.
## Add MOUTH_OPEN=1 (or a fraction, e.g. 0.5 for normal speech) to show the monkeys
## talking, and "-- --fake-voice" at the end to show the HUD's voice controls.

const NAMES := ["Kerem", "Gonc", "Abdulalim", "Ulas"]
const KINDS := ["açgözlü", "dürüst", "kinci", "açgözlü"]
const NIGHT_SEED := 77
const FRAMES_TO_SETTLE := 30
const STATES := {
	"declare": MatchState.Phase.DECLARE,
	"negotiate": MatchState.Phase.NEGOTIATE,
	"contribute": MatchState.Phase.CONTRIBUTE,
	"audit_choose": MatchState.Phase.AUDIT_CHOOSE,
	"audit_decide": MatchState.Phase.AUDIT_DECIDE,
	"shop": MatchState.Phase.SHOP,
	"match_over": MatchState.Phase.MATCH_OVER,
}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var seat := int(OS.get_environment("SEAT"))
	var state := OS.get_environment("STATE")
	var network: Node = root.get_node("Network")
	var session: Node = root.get_node("Session")
	# Offline, our peer id is 1, so give id 1 the seat we want to look from.
	var roster := {}
	for s in NAMES.size():
		roster[1 if s == seat else 100 + s] = {"name": NAMES[s], "seat": s}
	network.roster = roster
	session.seat_names = PackedStringArray(NAMES)
	session.view = _play_to(state, seat)
	change_scene_to_file("res://features/table/table.tscn")
	var mouth_open := OS.get_environment("MOUTH_OPEN").to_float()
	for i in FRAMES_TO_SETTLE:
		if mouth_open > 0.0:
			for monkey in root.find_children("*", "MonkeyPlaceholder", true, false):
				(monkey as MonkeyPlaceholder).set_mouth_open(mouth_open)
		await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("OUT"))
	quit()


## Bots play from the start of the night until the view of `seat` shows `state`.
## Round 2 of the first match, so the log and the table have some history.
func _play_to(state: String, seat: int) -> Dictionary:
	var rules: RulesConfig = load("res://data/rules_v0_3.tres")
	var night := Night.new(rules, NAMES.size(), NIGHT_SEED)
	var bots: Array[SeatBot] = []
	for s in NAMES.size():
		bots.append(SeatBot.new(KINDS[s], s, rules, NIGHT_SEED))
	var done := func() -> bool:
		if state == "night_over":
			return night.night_over
		var m := night.current_match
		if state == "match_over":
			return m.is_over()
		return m.round_index == 1 and m.phase == STATES.get(state, MatchState.Phase.DECLARE)
	var guard := 0
	while not done.call() and guard < 5000:
		guard += 1
		for s in bots.size():
			for intent in bots[s].intents(night.view_for(s)):
				night.apply(s, intent)
				if done.call():
					return night.view_for(seat)
	return night.view_for(seat)
