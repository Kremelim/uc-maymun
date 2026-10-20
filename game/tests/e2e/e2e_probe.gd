extends Node
## End-to-end test of hidden information over a real ENet connection.
## Network adds this node when the game starts with --e2e (see run_e2e.sh):
##   host:    --e2e --auto-host --auto-start=N
##   clients: --e2e --auto-join
## The host declares honestly, every client hides one coin and reports what it
## received. The host checks the reports against its own truth and exits 0 or 1.

const TIMEOUT_SEC := 30.0

var _expected_clients := 0
var _reports: Dictionary = {}  # peer_id -> report
var _private_seats_seen: Array = []
var _last_income := -1
var _declared := false
var _reported := false
var _finished := false


func _ready() -> void:
	get_tree().create_timer(TIMEOUT_SEC).timeout.connect(_finish.bind(["timed out after %d s" % TIMEOUT_SEC]))
	Session.private_view_changed.connect(_on_private_view)
	Session.public_state_changed.connect(_on_public_state)
	if CmdArgs.has_flag("--auto-host"):
		_expected_clients = int(CmdArgs.value("--auto-start", "2")) - 1


func _on_private_view(view: Dictionary) -> void:
	_private_seats_seen.append(view["seat"])
	_last_income = view["income"]
	if not _declared:
		_declared = true
		var amount := _last_income if Network.is_host() else _last_income - 1
		Session.request_declare.call_deferred(amount)


func _on_public_state(snapshot: Dictionary) -> void:
	if Network.is_host():
		_check_reports.call_deferred()
		return
	var my_seat := Network.local_seat()
	if _reported or _last_income < 0 or snapshot["declarations"][my_seat] == TableState.NOT_DECLARED:
		return
	_reported = true
	_report.rpc_id(1, {
		"private_seats": _private_seats_seen,
		"income": _last_income,
		"declaration_seen": snapshot["declarations"][my_seat],
		"public_has_income": _has_key(snapshot, "income"),
	})


@rpc("any_peer", "call_remote", "reliable")
func _report(report: Dictionary) -> void:
	if not Network.is_host():
		return
	_reports[multiplayer.get_remote_sender_id()] = report
	_check_reports()


func _check_reports() -> void:
	var snapshot := Session.public_state
	if _finished or _reports.size() < _expected_clients or not snapshot.has("missing"):
		return
	var truth := Session.host_state()
	var errors: Array = []
	if _private_seats_seen != [0]:
		errors.append("host received private views for seats %s" % [_private_seats_seen])
	for peer_id: int in _reports:
		var report: Dictionary = _reports[peer_id]
		var seat := Network.seat_of(peer_id)
		if report["private_seats"] != [seat]:
			errors.append("peer %d (seat %d) received private views for seats %s" % [peer_id, seat, report["private_seats"]])
		if report["income"] != truth.income_of(seat):
			errors.append("peer %d saw income %d, truth is %d" % [peer_id, report["income"], truth.income_of(seat)])
		if report["declaration_seen"] != truth.income_of(seat) - 1:
			errors.append("peer %d declaration did not reach the table" % peer_id)
		if report["public_has_income"]:
			errors.append("public snapshot sent to peer %d contains an income" % peer_id)
	if snapshot["missing"] != _expected_clients:
		errors.append("missing coins: expected %d, got %d" % [_expected_clients, snapshot["missing"]])
	_finish(errors)


func _finish(errors: Array) -> void:
	if _finished:
		return
	_finished = true
	for error: String in errors:
		printerr("E2E FAIL: %s" % error)
	if errors.is_empty():
		print("E2E PASS: %d clients, every income reached only its owner" % _expected_clients)
	if Network.is_host():
		_done.rpc()
		await get_tree().create_timer(0.5).timeout
	get_tree().quit(0 if errors.is_empty() else 1)


@rpc("authority", "call_remote", "reliable")
func _done() -> void:
	_finished = true
	get_tree().quit(0)


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
