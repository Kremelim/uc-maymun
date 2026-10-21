extends Node
## End-to-end test of a whole night over a real ENet connection.
## Network adds this node when the game starts with --e2e (see run_e2e.sh):
##   host:    --e2e --auto-host --auto-start=N --e2e-kind=K --bot-kinds=... --bot-delay=0 --seed=S
##   clients: --e2e --auto-join --e2e-kind=K --seed=S
## Every peer plays its seat with a SeatBot of kind K, through the same intents a
## person sends; the host fills the empty seats with its own bots. Checked at the end:
## - every match ended exactly as MatchRunner plays it with the same bots and seeds,
##   on the host and on every client;
## - each peer only ever received its own seat's view: no incomes, no audit peek that
##   was not its own, declarations hidden until all were in, nothing of Hesap Günü early;
## - with --fake-voice, everyone heard every other person through the host, never themselves.
## With --e2e-leave-at-match=M a client walks out when match M starts, and the host
## (told by --e2e-leavers=L) checks that bots took over and the night still ended.
## The matches then no longer replay the simulator, so that comparison is skipped.

const TIMEOUT_SEC := 60.0
## Voice packets needed from each other player before a peer counts them as heard.
const MIN_VOICE_PACKETS := 5
const AUDIO_RELEASE_WAIT_SEC := 0.25

var _expected_clients := 0
var _leavers := 0
var _reports: Dictionary = {}  # peer_id -> report
var _bot: SeatBot
var _night_seed := 0
var _kind := ""
var _results: Array = []  # per match: {"points", "wealth"} as this peer saw them at Hesap Günü
var _night_points := PackedInt32Array()
var _night_over := false
var _view_errors: Array = []
var _voice_packets: Dictionary = {}  # speaker peer_id -> packets received
var _act_pending := false
var _reported := false
var _finished := false


func _ready() -> void:
	get_tree().create_timer(TIMEOUT_SEC).timeout.connect(_finish.bind(["timed out after %d s" % TIMEOUT_SEC]))
	Session.view_changed.connect(_on_view)
	VoiceChat.voice_received.connect(_on_voice)
	_night_seed = int(CmdArgs.value("--seed", "0"))
	_kind = CmdArgs.value("--e2e-kind", "dürüst")
	if CmdArgs.has_flag("--auto-host"):
		_leavers = int(CmdArgs.value("--e2e-leavers", "0"))
		_expected_clients = int(CmdArgs.value("--auto-start", "2")) - 1 - _leavers


func _on_view(view: Dictionary) -> void:
	_check_view(view)
	if view.has("reckoning") and _results.size() == view["match_index"]:
		var reckoning: Dictionary = view["reckoning"]
		_results.append({"points": reckoning["points"], "wealth": reckoning["wealth"]})
	_night_points = view["night_points"]
	_night_over = view["night_over"]
	if not _act_pending:
		# Deferred: on the host a request is applied at once and pushes a new view while we are still here.
		_act_pending = true
		_act.call_deferred()


func _act() -> void:
	_act_pending = false
	var view := Session.view
	if _finished or view.is_empty():
		return
	var leave_at := int(CmdArgs.value("--e2e-leave-at-match", "-1"))
	if leave_at >= 0 and view["match_index"] >= leave_at:
		_finished = true
		print("E2E: leaving in the middle of the night")
		_leave_and_quit(0)
		return
	if _bot == null:
		_bot = SeatBot.new(_kind, view["seat"], Session.RULES, _night_seed)
	for intent in _bot.intents(view):
		Session.request(intent)


func _check_view(view: Dictionary) -> void:
	var seat := Network.local_seat()
	if view["seat"] != seat:
		_view_errors.append("got the view of seat %d" % view["seat"])
	var phase: int = view["phase"]
	if phase != MatchState.Phase.MATCH_OVER:
		if _has_key(view, "incomes") or view.has("reckoning"):
			_view_errors.append("saw Hesap Günü data in phase %d" % phase)
	if view.has("audit_peek") and (phase != MatchState.Phase.AUDIT_DECIDE or view["auditor"] != seat):
		_view_errors.append("saw an audit peek that was not its own")
	if phase == MatchState.Phase.DECLARE and not (view["declarations"] as PackedInt32Array).is_empty():
		_view_errors.append("saw declarations before everyone declared")
	for event: Dictionary in view["events"]:
		if event["type"] == "transfer" and seat not in [event["from"], event["to"]]:
			_view_errors.append("saw someone else's transfer")


func _on_voice(peer_id: int, _frames: PackedVector2Array, _level: float) -> void:
	_voice_packets[peer_id] = _voice_packets.get(peer_id, 0) + 1


# Voice keeps arriving after the night, so both sides re-check every frame.
func _process(_delta: float) -> void:
	if _finished:
		return  # Leaving the table afterwards would otherwise look like a fresh, empty game.
	if Network.is_host():
		_check_reports()
	else:
		_try_report()


func _try_report() -> void:
	if _reported or not _night_over:
		return
	if VoiceChat.is_available() and not _heard_everyone_else():
		return
	_reported = true
	_report.rpc_id(1, {
		"seat": Network.local_seat(),
		"kind": _kind,
		"results": _results,
		"night_points": _night_points,
		"view_errors": _view_errors,
		"heard_seats": _heard_seats(),
		"heard_self": _voice_packets.has(multiplayer.get_unique_id()),
	})


# "Everyone else", not "exactly everyone else": a peer that also hears itself
# should still report, so the host can name that bug instead of timing out.
func _heard_everyone_else() -> bool:
	var heard := _heard_seats()
	for seat: int in _other_people(Network.local_seat()):
		if seat not in heard:
			return false
	return true


func _heard_seats() -> Array:
	var seats: Array = []
	for peer_id: int in _voice_packets:
		if _voice_packets[peer_id] >= MIN_VOICE_PACKETS and Network.roster.has(peer_id):  # not someone who left
			seats.append(Network.seat_of(peer_id))
	seats.sort()
	return seats


## Seats of the people at the table other than `seat` (bots have no voice).
func _other_people(seat: int) -> Array:
	var seats: Array = []
	for info: Dictionary in Network.roster.values():
		if info["seat"] != seat:
			seats.append(info["seat"])
	seats.sort()
	return seats


@rpc("any_peer", "call_remote", "reliable")
func _report(report: Dictionary) -> void:
	if not Network.is_host():
		return
	_reports[multiplayer.get_remote_sender_id()] = report
	_check_reports()


func _check_reports() -> void:
	if _finished or _reports.size() < _expected_clients or not _night_over:
		return
	if VoiceChat.is_available() and not _heard_everyone_else():
		return
	var errors: Array = []
	var kinds: Array = []
	kinds.resize(Session.seat_names.size())
	kinds[Network.local_seat()] = _kind
	var forced_bots := CmdArgs.value("--bot-kinds").split(",", false)
	for i in Session.bot_seats.size():
		kinds[Session.bot_seats[i]] = forced_bots[i] if i < forced_bots.size() else "?"
	for peer_id: int in _reports:
		kinds[_reports[peer_id]["seat"]] = _reports[peer_id]["kind"]
	var expected: Array = []  # stays empty when bots took over mid-night: no simulator to compare with
	if _leavers > 0:
		if Session.bot_seats.size() != Session.seat_names.size() - 1 - _expected_clients:
			errors.append("bots sit in %s after %d left" % [Session.bot_seats, _leavers])
		if _results.size() != Session.RULES.matches_per_night:
			errors.append("the night ended after %d matches" % _results.size())
	else:
		expected = _simulated(kinds)
		_compare("host", _results, _night_points, expected, errors)
	for error: String in _view_errors:
		errors.append("host: %s" % error)
	for peer_id: int in _reports:
		var report: Dictionary = _reports[peer_id]
		var who := "peer %d (seat %d)" % [peer_id, report["seat"]]
		if report["seat"] != Network.seat_of(peer_id):
			errors.append("%s reported the wrong seat" % who)
		if not expected.is_empty():
			_compare(who, report["results"], report["night_points"], expected, errors)
		elif report["night_points"] != _night_points:
			errors.append("%s night points %s, host %s" % [who, report["night_points"], _night_points])
		for error: String in report["view_errors"]:
			errors.append("%s: %s" % [who, error])
		if VoiceChat.is_available():
			if report["heard_seats"] != _other_people(report["seat"]):
				errors.append("%s heard seats %s" % [who, report["heard_seats"]])
			if report["heard_self"]:
				errors.append("%s heard its own voice back" % who)
	if VoiceChat.is_available():
		if _heard_seats() != _other_people(Network.local_seat()):
			errors.append("host heard seats %s" % [_heard_seats()])
		if _voice_packets.has(multiplayer.get_unique_id()):
			errors.append("host heard its own voice back")
	_finish(errors, kinds)


## What the simulator says each match of this night ends like, with these bots in these seats.
func _simulated(kinds: Array) -> Array:
	var rules := Session.host_night().rules  # with or without the basic first match
	var expected: Array = []
	for index in rules.matches_per_night:
		var bots: Array[SimBot] = []
		for kind: String in kinds:
			bots.append(SimBot.preset(kind))
		var result := MatchRunner.play(rules, bots, Night.match_seed_of(_night_seed, index),
			MatchState.first_auditor_of(rules, index, kinds.size()), Night.is_basic(rules, index))
		expected.append({"points": result["points"], "wealth": result["wealth"]})
	return expected


static func _compare(who: String, results: Array, night_points: PackedInt32Array, expected: Array, errors: Array) -> void:
	if results.size() != expected.size():
		errors.append("%s saw %d matches end, expected %d" % [who, results.size(), expected.size()])
		return
	var total := PackedInt32Array()
	total.resize(night_points.size())
	for index in expected.size():
		for key: String in ["points", "wealth"]:
			if results[index][key] != expected[index][key]:
				errors.append("%s match %d %s: online %s, simulator %s" % [who, index, key, results[index][key], expected[index][key]])
		for seat in total.size():
			total[seat] += (expected[index]["points"] as PackedInt32Array)[seat]
	if night_points != total:
		errors.append("%s night points %s, expected %s" % [who, night_points, total])


func _finish(errors: Array, kinds: Array = []) -> void:
	if _finished:
		return
	_finished = true
	for error: String in errors:
		printerr("E2E FAIL: %s" % error)
	if errors.is_empty():
		var voice_note := ", everyone heard everyone else" if VoiceChat.is_available() else ""
		if _leavers > 0:
			print("E2E PASS: %d left mid-night, bots took over and the night ended for %d clients%s" % [
				_leavers, _expected_clients, voice_note])
		else:
			print("E2E PASS: %d clients + %d bots played %d matches online exactly like the simulator (seats: %s); every view went only to its seat%s" % [
				_expected_clients, Session.bot_seats.size(), _results.size(), ", ".join(kinds), voice_note])
	if Network.is_host():
		_done.rpc()
		await get_tree().create_timer(0.5).timeout
	_leave_and_quit(0 if errors.is_empty() else 1)


@rpc("authority", "call_remote", "reliable")
func _done() -> void:
	_finished = true
	_leave_and_quit(0)


## Leaves the table before quitting. The audio server frees voice players a mix
## cycle (~10 ms) after their scene goes; quitting straight from the table reports
## them as leaked. Headless frames can be far shorter than that, so wait by time.
func _leave_and_quit(exit_code: int) -> void:
	Network.leave()
	await get_tree().create_timer(AUDIO_RELEASE_WAIT_SEC).timeout
	get_tree().quit(exit_code)


static func _has_key(value: Variant, key: String) -> bool:
	if value is Dictionary:
		for k: Variant in value:
			if str(k) == key or _has_key(value[k], key):
				return true
	elif value is Array:
		for item: Variant in value:
			if _has_key(item, key):
				return true
	return false
