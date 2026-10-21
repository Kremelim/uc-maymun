extends Node3D
## Table scene: presentation only. Reads Session's cached view of our seat and sends
## intents back; every rule lives in core/ and runs on the host.

const MONKEY_SCENE: PackedScene = preload("res://features/table/monkey_placeholder.tscn")
const SEAT_RADIUS := 1.6
const EYE_HEIGHT := 1.85
## The camera sits behind and above the seat, looking down at the table, so the pot,
## the cards and the neighbours all fit above the HUD.
const CAMERA_BACK := 1.0
const LOOK_TARGET := Vector3(0, 0.55, 0)
## The meter uses the same scaling as the mouths, so "full" means a wide-open mouth.
const MIC_METER_GAIN := MonkeyPlaceholder.MOUTH_GAIN
const NONE := MatchState.NONE
const PHASE_NAMES := {
	MatchState.Phase.DECLARE: "Beyan",
	MatchState.Phase.NEGOTIATE: "Pazarlık",
	MatchState.Phase.CONTRIBUTE: "Katkı",
	MatchState.Phase.AUDIT_CHOOSE: "Denetim",
	MatchState.Phase.AUDIT_DECIDE: "Denetim",
	MatchState.Phase.SHOP: "Dükkan",
	MatchState.Phase.MATCH_OVER: "Hesap Günü",
}
const PRIVATE_COLOR := "#ffd166"
## The action card's border: gold when the table waits for you, dim otherwise.
const YOUR_TURN_BORDER := Color(1.0, 0.78, 0.3)
const WAITING_BORDER := Color(0.35, 0.3, 0.25)
const LIE_COLOR := Color(1.0, 0.45, 0.35)

var _monkeys: Dictionary = {}  # seat -> MonkeyPlaceholder
var _self_voice_playback: AudioStreamGeneratorPlayback
var _view: Dictionary = {}
## Seats behind the entries of the vouch / transfer menus, rebuilt with each view.
var _vouch_seats: Array = []
var _transfer_seats: Array = []
## The round whose declaration box we already filled in, so a new view does not overwrite typing.
var _declare_prefilled := []
var _seconds_left := -1.0
## The newest event already announced in the banner.
var _last_event_id := -1
var _action_style: StyleBoxFlat

@onready var _seats_root: Node3D = $Seats
@onready var _camera: Camera3D = $Camera3D
@onready var _phase_label: Label = %PhaseLabel
@onready var _debt_label: Label = %DebtLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _me_label: Label = %MeLabel
@onready var _action_panel: PanelContainer = $Hud/ActionPanel
@onready var _action_title: Label = %ActionTitle
@onready var _action_label: Label = %ActionLabel
@onready var _waiting_label: Label = %WaitingLabel
@onready var _rules_button: Button = %RulesButton
@onready var _how_to_play: HowToPlay = %HowToPlay
@onready var _banner: MomentBanner = %Banner
@onready var _props: TableProps = $Props
@onready var _declare_row: Control = %DeclareRow
@onready var _declare_spin: SpinBox = %DeclareSpin
@onready var _declare_button: Button = %DeclareButton
@onready var _vouch_row: Control = %VouchRow
@onready var _vouch_option: OptionButton = %VouchOption
@onready var _contribute_row: Control = %ContributeRow
@onready var _extra_spin: SpinBox = %ExtraSpin
@onready var _contribute_button: Button = %ContributeButton
@onready var _target_buttons: HBoxContainer = %TargetButtons
@onready var _decide_row: Control = %DecideRow
@onready var _report_button: Button = %ReportButton
@onready var _clean_button: Button = %CleanButton
@onready var _shop_grid: GridContainer = %ShopGrid
@onready var _transfer_row: Control = %TransferRow
@onready var _transfer_to: OptionButton = %TransferTo
@onready var _transfer_spin: SpinBox = %TransferSpin
@onready var _transfer_button: Button = %TransferButton
@onready var _ready_button: Button = %ReadyButton
@onready var _log_text: RichTextLabel = %LogText
@onready var _reckoning_panel: Control = %ReckoningPanel
@onready var _reckoning_dim: Control = %ReckoningDim
@onready var _reckoning_title: Label = %ReckoningTitle
@onready var _reckoning_grid: GridContainer = %ReckoningGrid
@onready var _reckoning_notes: Label = %ReckoningNotes
@onready var _next_button: Button = %NextButton
@onready var _lobby_button: Button = %LobbyButton
@onready var _leave_button: Button = %LeaveButton
@onready var _voice_row: Control = %VoiceRow
@onready var _mic_toggle: CheckButton = %MicToggle
@onready var _loopback_toggle: CheckButton = %LoopbackToggle
@onready var _mic_meter: ProgressBar = %MicMeter
@onready var _incoming_voice_label: Label = %IncomingVoiceLabel
@onready var _self_voice: AudioStreamPlayer = $SelfVoice


func _ready() -> void:
	Session.view_changed.connect(_on_view_changed)
	_declare_button.pressed.connect(func() -> void: _send({"type": "declare", "amount": int(_declare_spin.value)}))
	_vouch_option.item_selected.connect(func(index: int) -> void: _send({"type": "vouch", "target": _vouch_seats[index]}))
	_contribute_button.pressed.connect(func() -> void: _send({"type": "contribute", "extra": int(_extra_spin.value)}))
	_report_button.pressed.connect(func() -> void: _send({"type": "decide", "report": true}))
	_clean_button.pressed.connect(func() -> void: _send({"type": "decide", "report": false}))
	_transfer_button.pressed.connect(_on_transfer_pressed)
	_ready_button.pressed.connect(func() -> void: _send({"type": "ready"}))
	_next_button.pressed.connect(func() -> void: _send({"type": "ready"}))
	_lobby_button.pressed.connect(func() -> void: Network.end_game("Gece bitti."))
	_leave_button.pressed.connect(Network.leave)
	_rules_button.pressed.connect(_how_to_play.show)
	_action_style = (_action_panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	_action_panel.add_theme_stylebox_override("panel", _action_style)
	_build_shop()
	_build_seats()
	_setup_voice()
	# The first view may have arrived while this scene was loading; Session keeps the latest copy.
	_on_view_changed(Session.view)


func _send(intent: Dictionary) -> void:
	Session.request(intent)


func _my_seat() -> int:
	return int(_view.get("seat", Network.local_seat()))


func _name(seat: int) -> String:
	if seat < 0 or seat >= Session.seat_names.size():
		return "?"
	return Session.seat_names[seat] + (" (sen)" if seat == _my_seat() else "")


func _build_seats() -> void:
	for monkey: Node in _seats_root.get_children():
		monkey.queue_free()
	_monkeys.clear()
	var my_seat := _my_seat()
	var seat_count := Session.seat_names.size()
	for seat in seat_count:
		var floor_position := _seat_position(seat, seat_count)
		if seat == my_seat:
			# First person: we sit here, so we see the table instead of our own monkey.
			_camera.position = floor_position * (1.0 + CAMERA_BACK / SEAT_RADIUS) + Vector3.UP * EYE_HEIGHT
			_camera.look_at(LOOK_TARGET)
			continue
		var monkey := MONKEY_SCENE.instantiate() as MonkeyPlaceholder
		_seats_root.add_child(monkey)
		monkey.position = floor_position
		monkey.look_at(Vector3.ZERO)
		monkey.set_player_name(Session.seat_names[seat])
		_monkeys[seat] = monkey
	_props.setup(seat_count, my_seat)


func _build_shop() -> void:
	var rules := Session.RULES
	for item in rules.accessory_prices.size():
		var button := Button.new()
		button.text = "%s %d" % [rules.accessory_names[item], rules.accessory_prices[item]]
		button.tooltip_text = "Maç sonu değeri: %d" % rules.accessory_values[item]
		button.pressed.connect(func() -> void: _send({"type": "buy", "item": item}))
		_shop_grid.add_child(button)


func _setup_voice() -> void:
	_voice_row.visible = VoiceChat.is_available()
	_loopback_toggle.visible = VoiceChat.is_available()
	_incoming_voice_label.visible = VoiceChat.is_available()
	if not VoiceChat.is_available():
		return
	for seat: int in _monkeys:
		_monkeys[seat].setup_voice(VoiceChat.sample_rate())
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = VoiceChat.sample_rate()
	generator.buffer_length = MonkeyPlaceholder.VOICE_BUFFER_SECONDS
	_self_voice.stream = generator
	_self_voice.play()
	_self_voice_playback = _self_voice.get_stream_playback()
	_mic_toggle.button_pressed = VoiceChat.mic_enabled
	_loopback_toggle.button_pressed = VoiceChat.loopback
	_mic_toggle.toggled.connect(func(on: bool) -> void: VoiceChat.mic_enabled = on)
	_loopback_toggle.toggled.connect(func(on: bool) -> void: VoiceChat.loopback = on)
	VoiceChat.voice_received.connect(_on_voice_received)


func _process(delta: float) -> void:
	if _voice_row.visible:
		_mic_meter.value = clampf(VoiceChat.own_level * MIC_METER_GAIN, 0.0, 1.0)
		_incoming_voice_label.text = _incoming_voice_text()
	if _seconds_left >= 0.0:
		_seconds_left = maxf(0.0, _seconds_left - delta)
		_timer_label.text = "%d:%02d" % [floori(_seconds_left / 60.0), int(_seconds_left) % 60]


## e.g. "Gelen ses: Gonc 0.12 · Abdulalim — · Ulas —" ("—" = nothing in the last second).
func _incoming_voice_text() -> String:
	var parts := PackedStringArray()
	for peer_id: int in Network.roster:
		if peer_id == multiplayer.get_unique_id():
			continue
		var level := VoiceChat.incoming_level(peer_id)
		var shown := "—" if level < 0.0 else "%.2f" % level
		parts.append("%s %s" % [Network.roster[peer_id]["name"], shown])
	return "Gelen ses: " + " · ".join(parts)


func _on_voice_received(peer_id: int, frames: PackedVector2Array, level: float) -> void:
	if peer_id == multiplayer.get_unique_id():
		# Loopback test: our own voice, played without position.
		if _self_voice_playback.get_frames_available() >= frames.size():
			_self_voice_playback.push_buffer(frames)
		return
	var monkey: MonkeyPlaceholder = _monkeys.get(Network.seat_of(peer_id))
	if monkey != null:
		monkey.push_voice(frames, level)


func _seat_position(seat: int, seat_count: int) -> Vector3:
	var angle := TAU * seat / maxi(seat_count, 1)
	return Vector3(sin(angle), 0, cos(angle)) * SEAT_RADIUS


func _on_view_changed(view: Dictionary) -> void:
	var first := _view.is_empty()
	_view = view
	if view.is_empty():
		return
	if first or _monkeys.size() != Session.seat_names.size() - 1:
		_build_seats()
		_setup_voice_for_new_monkeys()
	_update_top()
	_update_me()
	_update_monkeys()
	_update_actions()
	_update_log()
	_update_reckoning()
	_props.update(view)
	_announce_events(first)


func _setup_voice_for_new_monkeys() -> void:
	if VoiceChat.is_available():
		for seat: int in _monkeys:
			_monkeys[seat].setup_voice(VoiceChat.sample_rate())


func _update_top() -> void:
	var v := _view
	var phase: int = v["phase"]
	var parts := PackedStringArray([
		"Maç %d/%d" % [v["match_index"] + 1, v["matches_per_night"]],
		"Tur %d/%d" % [v["round"] + 1, v["round_count"]],
		_phase_name(phase),
		"Denetçi: %s" % _name(v["auditor"]),
	])
	if v["night_over"]:
		parts = PackedStringArray(["Gece bitti"])
	_phase_label.text = " · ".join(parts)
	var carry: int = v["carry"]
	var after_audit: bool = phase == MatchState.Phase.SHOP
	var due_text := ("Sonraki tur ödenecek: %d" if after_audit else "Bu tur ödenecek: %d") % v["installment_due"]
	if carry > 0:
		due_text += " (%d devreden)" % carry
	elif carry < 0:
		due_text += " (%d alacak düşüldü)" % -carry
	_debt_label.text = "%s · Kasa: %d" % [due_text, v["pot"]]
	if v["phase"] == MatchState.Phase.MATCH_OVER:
		_debt_label.text = "Masa kurtuldu" if carry <= 0 else "Masa battı: %d borç kaldı" % carry
	_seconds_left = float(v["seconds_left"])
	_timer_label.visible = _seconds_left >= 0.0


func _update_me() -> void:
	var v := _view
	var seat := _my_seat()
	var lines := PackedStringArray()
	lines.append("%s · gece puanın: %d" % [Session.seat_names[seat] if seat < Session.seat_names.size() else "", v["night_points"][seat]])
	lines.append("Gelirin: %d (gizli) · cebin: %d" % [v["my_income"], v["my_cash"]])
	if v["phase"] > MatchState.Phase.DECLARE:
		lines.append("Beyanın: %d · asgarin: %d (ödendi)" % [v["my_declaration"], v["minimums"][seat]])
	var balance := MatchState.balance_of(v["ious"], seat)
	if balance != 0:
		lines.append("Senet: %+d (maç sonunda)" % balance)
	var items := _accessory_names(v["accessories"][seat])
	if items != "":
		lines.append("Aksesuarların: %s" % items)
	_me_label.text = "\n".join(lines)


func _update_monkeys() -> void:
	var v := _view
	var phase: int = v["phase"]
	for seat: int in _monkeys:
		var monkey: MonkeyPlaceholder = _monkeys[seat]
		monkey.set_player_name(Session.seat_names[seat])
		monkey.set_auditor(seat == v["auditor"] and not v["night_over"])
		var lines := PackedStringArray()
		if seat == v["auditor"]:
			lines.append("DENETÇİ")
		if phase == MatchState.Phase.DECLARE:
			lines.append("beyanını verdi" if v["declared"][seat] else "düşünüyor…")
		if phase == MatchState.Phase.CONTRIBUTE:
			lines.append("avucu kapalı" if v["contributed"][seat] else "katkı: ?")
		elif not (v["contributions"] as PackedInt32Array).is_empty():
			lines.append("katkı %d" % v["contributions"][seat])
		var vouch_for: int = v["vouches"][seat]
		if vouch_for != NONE:
			lines.append("kefil → %s" % _name(vouch_for))
		var items := _accessory_names(v["accessories"][seat])
		if items != "":
			lines.append(items)
		var balance := MatchState.balance_of(v["ious"], seat)
		if balance != 0:
			lines.append("senet %+d" % balance)
		if v["ready"][seat] and phase in [MatchState.Phase.NEGOTIATE, MatchState.Phase.SHOP]:
			lines.append("hazır")
		monkey.set_status(" · ".join(lines))


func _update_actions() -> void:
	var v := _view
	var seat := _my_seat()
	var phase: int = v["phase"]
	var auditing: bool = v["auditor"] == seat
	var basic: bool = v["basic"]
	for row: Control in [_declare_row, _vouch_row, _contribute_row, _target_buttons, _decide_row, _shop_grid, _transfer_row, _ready_button]:
		row.visible = false
	var title := _phase_name(phase)
	var text := ""
	match phase:
		MatchState.Phase.DECLARE:
			_declare_row.visible = true
			var card_open := Session.RULES.auditor_card_open and auditing
			var here := [v["match_index"], v["round"]]
			if _declare_prefilled != here:
				_declare_prefilled = here
				_declare_spin.max_value = v["total_income"]
				_declare_spin.value = v["my_income"]
			_declare_spin.editable = not card_open
			_declare_button.text = "Beyan et" if v["my_declaration"] == NONE else "Beyanı değiştir"
			if card_open:
				text = "Bu tur denetçisin: kartın herkese açık, beyanın gelirin (%d) olmak zorunda. Onayla." % v["my_income"]
			else:
				text = "Bu tur sana %d jeton geldi. Masaya kaç geldiğini söyle. Yalan söyleyebilirsin: az söylersen az ödersin, ama denetçi yakalarsa ceza ödersin." % v["my_income"]
				text += "\nSöylediğinin %%%d'ı hemen kasaya gider." % roundi(Session.RULES.min_contribution_ratio * 100.0)
			if v["my_declaration"] != NONE:
				text = "Beyanın: %d. Herkes beyan edince kartlar açılacak." % v["my_declaration"]
		MatchState.Phase.NEGOTIATE:
			_ready_button.visible = true
			_ready_button.disabled = v["ready"][seat]
			_ready_button.text = "Hazırım" if not v["ready"][seat] else "Diğerleri bekleniyor…"
			text = _missing_text(v["missing"]) + " Konuşun: kim yalan söylüyor, kasa yetecek mi?"
			if not basic:
				_vouch_row.visible = true
				_transfer_row.visible = true
				_fill_vouch_options(seat, auditing)
				text += " Kefil olabilir, masa altından jeton verebilirsin."
			text += " Bitince \"Hazırım\"."
		MatchState.Phase.CONTRIBUTE:
			var due: int = v["installment_due"]
			var gap: int = due - int(v["pot"])
			if gap > 0:
				text = "Kasada %d var, bu tur %d lazım: %d eksik. Eksik kalırsa borç faiziyle büyür." % [v["pot"], due, gap]
			else:
				text = "Kasada %d var, bu tur %d lazım: taksit asgarilerle zaten ödendi." % [v["pot"], due]
			if v["my_extra"] == NONE:
				_contribute_row.visible = true
				_extra_spin.max_value = v["my_cash"]
				_extra_spin.value = mini(int(_extra_spin.value), v["my_cash"])
				text += "\nÜstüne koymak istediğini seç (istemezsen 0) ve avucunu kapat. Herkesinki aynı anda açılır."
			else:
				text += "\nAvucuna %d koydun." % v["my_extra"]
		MatchState.Phase.AUDIT_CHOOSE:
			if auditing:
				title = "Denetim · sen denetçisin"
				_target_buttons.visible = true
				_fill_target_buttons(seat)
				text = "Kimin kartına bakacaksın? %s Parantezde beyanları var." % _missing_text(v["missing"])
			else:
				_transfer_row.visible = not basic
				text = "%s kimi denetleyeceğini seçiyor." % _name(v["auditor"])
				if not basic:
					text += " Rüşvet teklif etmek istersen masa altını kullan."
		MatchState.Phase.AUDIT_DECIDE:
			var target: int = v["audit_target"]
			if auditing:
				title = "Denetim · karar senin"
				_decide_row.visible = true
				_transfer_row.visible = not basic
				var declared: int = v["declarations"][target]
				var peek: int = v["audit_peek"]
				var lie := peek - declared
				text = "%s: kartında %d, beyanı %d." % [_name(target), peek, declared]
				if lie != 0:
					text += " YALAN, fark %d!\nRaporlarsan saklanan para kasaya döner ve sana %d ceza öder. \"Temiz\" dersen göz yummuş olursun (örtbas): maç sonunda herkes görür." % [absi(lie), MatchState.fine_with(Session.RULES, lie)]
				else:
					text += " Doğru söylemiş.\n\"Temiz\" de; ona %d jeton tazminat ödersin." % Session.RULES.audit_compensation
			else:
				_transfer_row.visible = not basic
				text = "Denetim: %s → %s. Kart inceleniyor…" % [_name(v["auditor"]), _name(target)]
				if target == seat:
					text = "%s senin kartına bakıyor!" % _name(v["auditor"])
		MatchState.Phase.SHOP:
			title = "Tur sonu · dükkan"
			_ready_button.visible = true
			_ready_button.disabled = v["ready"][seat]
			_ready_button.text = "Turu bitir" if not v["ready"][seat] else "Diğerleri bekleniyor…"
			_shop_grid.visible = true
			for item in _shop_grid.get_child_count():
				(_shop_grid.get_child(item) as Button).disabled = Session.RULES.accessory_prices[item] > v["my_cash"]
			text = "%s Aksesuar alabilirsin: herkes görür, maç sonunda değeri artar, cezada haczedilir." % _audit_summary()
		MatchState.Phase.MATCH_OVER:
			title = "Hesap Günü"
			text = "Maç bitti."
	if v["night_over"]:
		title = "Gece bitti"
		text = ""
	var my_turn: bool = seat in v["awaiting"] and not v["night_over"]
	_action_title.text = ("Sıra sende · " + title) if my_turn else title
	_action_label.text = text
	_action_label.visible = text != ""
	_action_style.border_color = YOUR_TURN_BORDER if my_turn else WAITING_BORDER
	_waiting_label.text = _waiting_text()
	_waiting_label.visible = _waiting_label.text != ""
	_transfer_spin.max_value = maxi(1, v["my_cash"])
	_transfer_button.disabled = v["my_cash"] == 0
	if _transfer_row.visible:
		_fill_transfer_options(seat)


func _phase_name(phase: int) -> String:
	if phase == MatchState.Phase.NEGOTIATE and _view.get("basic", false):
		return "Konuşma"
	return PHASE_NAMES.get(phase, "")


func _fill_vouch_options(seat: int, auditing: bool) -> void:
	_vouch_option.clear()
	_vouch_seats = [NONE]
	_vouch_option.add_item("Kimseye")
	for other in Session.seat_names.size():
		if other != seat and other != _view["auditor"]:
			_vouch_seats.append(other)
			_vouch_option.add_item(_name(other))
	_vouch_option.select(maxi(0, _vouch_seats.find(_view["vouches"][seat])))
	_vouch_option.disabled = auditing
	if auditing:
		_vouch_option.set_item_text(0, "Denetçi kefil olamaz")


func _fill_transfer_options(seat: int) -> void:
	var chosen: int = _transfer_seats[_transfer_to.selected] if _transfer_to.selected in range(_transfer_seats.size()) else NONE
	_transfer_to.clear()
	_transfer_seats = []
	for other in Session.seat_names.size():
		if other != seat:
			_transfer_seats.append(other)
			_transfer_to.add_item(_name(other))
	_transfer_to.select(maxi(0, _transfer_seats.find(chosen)))


func _fill_target_buttons(seat: int) -> void:
	for child: Node in _target_buttons.get_children():
		child.queue_free()
	for other in Session.seat_names.size():
		if other == seat:
			continue
		var button := Button.new()
		button.text = "%s (%d)" % [_name(other), _view["declarations"][other]]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: _send({"type": "choose", "target": other}))
		_target_buttons.add_child(button)


func _on_transfer_pressed() -> void:
	if _transfer_seats.is_empty():
		return
	_send({"type": "transfer", "to": _transfer_seats[_transfer_to.selected], "amount": int(_transfer_spin.value)})


func _waiting_text() -> String:
	var names := PackedStringArray()
	for seat: int in _view["awaiting"]:
		if seat != _my_seat():
			names.append(_name(seat))
	return "Bekleniyor: %s" % ", ".join(names) if not names.is_empty() else ""


func _audit_summary() -> String:
	var audit: Dictionary = _view["audit"]
	if audit.is_empty():
		return ""
	if audit["caught"]:
		return "%s yakalandı! Fark %d." % [_name(audit["target"]), audit["difference"]]
	return "%s temiz çıktı." % _name(audit["target"])


## Shows the moments of the newest events in the banner. On the first view only the
## round we arrive in, not the whole history.
func _announce_events(first: bool) -> void:
	var events: Array = _view["events"]
	if events.is_empty():
		return
	if _view.has("reckoning"):
		# Hesap Günü's table says it all, and the banner would cover its title.
		_last_event_id = events[-1]["id"]
		_banner.clear()
		_banner.hide()
		return
	if first:
		_last_event_id = events[-1]["id"]
		var v := _view
		_banner.announce("Maç %d · Tur %d" % [v["match_index"] + 1, v["round"] + 1], "Denetçi: %s" % _name(v["auditor"]))
		return
	for event: Dictionary in events:
		if event["id"] > _last_event_id:
			_last_event_id = event["id"]
			_announce(event)


func _announce(e: Dictionary) -> void:
	match str(e["type"]):
		"match_started":
			var how := "Temel kurallar: kefil, masa altı ve dükkan yok." if e["basic"] else "Tam kurallar: kefil, masa altı ve dükkan açık."
			_banner.announce("Maç %d" % (e["match"] + 1), how)
		"round_started":
			_banner.announce("Tur %d" % (e["round"] + 1), "Denetçi: %s" % _name(e["auditor"]))
		"declarations_revealed":
			var missing: int = e["missing"]
			if missing > 0:
				_banner.announce("Beyanlar açıldı", "Kayıp jeton: %d. Birileri az söyledi!" % missing)
			elif missing < 0:
				_banner.announce("Beyanlar açıldı", "Beyan fazlası: %d. Biri fazla söyledi!" % -missing)
			else:
				_banner.announce("Beyanlar açıldı", "Kayıp jeton yok.")
		"contributions_revealed":
			var enough: bool = e["pot"] >= e["due"]
			_banner.announce("Kasada %d jeton" % e["pot"], "Bu tur %d lazım" % e["due"],
				MomentBanner.GOOD_COLOR if enough else MomentBanner.TITLE_COLOR)
		"audit_target":
			_banner.announce("Denetim", "%s → %s" % [_name(e["auditor"]), _name(e["target"])])
		"audit_result":
			if e["caught"]:
				_banner.announce("YAKALANDI!", "%s yalan söylemiş: fark %d" % [_name(e["target"]), e["difference"]], MomentBanner.BAD_COLOR)
			else:
				_banner.announce("Temiz", "Denetçi: %s temiz" % _name(e["target"]))
		"installment":
			if e["pot"] >= e["due"]:
				_banner.announce("Taksit ödendi", "%d / %d" % [e["pot"], e["due"]], MomentBanner.GOOD_COLOR)
			else:
				_banner.announce("Taksit eksik!", "Borç faiziyle büyüdü: %d devretti" % e["carry"], MomentBanner.BAD_COLOR)
		"match_over":
			if e["succeeded"]:
				_banner.announce("Masa kurtuldu!", "Hesap Günü", MomentBanner.GOOD_COLOR)
			else:
				_banner.announce("Masa battı!", "Herkes 0 puan", MomentBanner.BAD_COLOR)
		"replaced":
			_banner.announce("%s kalktı" % Session.seat_names[e["seat"]], "Yerine bot oynuyor")


func _update_log() -> void:
	var lines := PackedStringArray()
	for event: Dictionary in _view["events"]:
		var line := _event_text(event)
		if line != "":
			lines.append(line)
	_log_text.text = "\n".join(lines)


func _event_text(e: Dictionary) -> String:
	match str(e["type"]):
		"match_started":
			return "[b]— Maç %d —[/b]" % (e["match"] + 1)
		"round_started":
			return "[b]Tur %d[/b] · denetçi: %s" % [e["round"] + 1, _name(e["auditor"])]
		"declared":
			return "%s beyanını verdi" % _name(e["seat"])
		"declarations_revealed":
			return "Beyanlar açıldı. %s" % _missing_text(e["missing"])
		"vouched":
			if e["target"] == NONE:
				return "%s kefaletini geri aldı" % _name(e["seat"])
			return "Kefil: %s → %s" % [_name(e["seat"]), _name(e["target"])]
		"transfer":
			return "[color=%s]Masa altı: %s → %s, %d jeton (gizli)[/color]" % [PRIVATE_COLOR, _name(e["from"]), _name(e["to"]), e["amount"]]
		"contributed":
			return "%s avucunu kapattı" % _name(e["seat"])
		"contributions_revealed":
			return "Katkılar açıldı. Kasada %d jeton" % e["pot"]
		"audit_target":
			return "Denetim: %s → %s" % [_name(e["auditor"]), _name(e["target"])]
		"audit_result":
			if e["caught"]:
				return "[color=#ff7059]%s YAKALANDI, fark %d[/color]" % [_name(e["target"]), e["difference"]]
			return "%s: temiz" % _name(e["target"])
		"installment":
			if e["pot"] >= e["due"]:
				return "Taksit ödendi (%d/%d)" % [e["pot"], e["due"]]
			return "[color=#ff7059]Taksit eksik (%d/%d). Devreden: %d[/color]" % [e["pot"], e["due"], e["carry"]]
		"bought":
			return "%s: %s aldı" % [_name(e["seat"]), Session.RULES.accessory_names[e["item"]]]
		"match_over":
			return "[b]Masa kurtuldu![/b]" if e["succeeded"] else "[b]Masa battı. Herkes 0 puan.[/b]"
		"night_over":
			return "[b]Gece bitti.[/b]"
		"replaced":
			return "%s masadan kalktı, yerine bot oynuyor" % Session.seat_names[e["seat"]]
	return ""


func _update_reckoning() -> void:
	var v := _view
	var shown: bool = v.has("reckoning")
	_reckoning_panel.visible = shown
	_reckoning_dim.visible = shown
	if not shown:
		return
	var reckoning: Dictionary = v["reckoning"]
	var seat_count := Session.seat_names.size()
	var seat := _my_seat()
	_reckoning_title.text = "Hesap Günü · Maç %d · %s" % [v["match_index"] + 1, "Masa kurtuldu" if reckoning["succeeded"] else "Masa battı"]
	for child: Node in _reckoning_grid.get_children():
		child.queue_free()
	_reckoning_grid.columns = seat_count + 1
	_grid_cell("")
	for s in seat_count:
		_grid_cell(_name(s), true)
	var notes := PackedStringArray()
	for round_entry: Dictionary in reckoning["rounds"]:
		_grid_cell("Tur %d (gelir/beyan)" % (round_entry["round"] + 1))
		var incomes: PackedInt32Array = round_entry["incomes"]
		var declarations: PackedInt32Array = round_entry["declarations"]
		for s in seat_count:
			var cell := _grid_cell("%d / %d%s" % [incomes[s], declarations[s], " D" if round_entry["auditor"] == s else ""])
			if incomes[s] != declarations[s]:
				cell.add_theme_color_override("font_color", LIE_COLOR)
		var audit: Dictionary = round_entry["audit"]
		if round_entry["covered_up"]:
			notes.append("Tur %d: %s, %s yalanını ÖRTBAS etti." % [round_entry["round"] + 1, _name(round_entry["auditor"]), _name(audit["target"])])
		for t: Dictionary in round_entry["transfers"]:
			notes.append("Tur %d: masa altı %s → %s, %d jeton." % [round_entry["round"] + 1, _name(t["from"]), _name(t["to"]), t["amount"]])
	_grid_cell("Yalan (yakalanan)")
	for s in seat_count:
		var lies := 0
		var caught := 0
		for round_entry: Dictionary in reckoning["rounds"]:
			if (round_entry["incomes"] as PackedInt32Array)[s] != (round_entry["declarations"] as PackedInt32Array)[s]:
				lies += 1
			var audit: Dictionary = round_entry["audit"]
			if audit.get("target", NONE) == s and audit.get("caught", false):
				caught += 1
		_grid_cell("%d (%d)" % [lies, caught])
	_grid_cell("Servet", true)
	for s in seat_count:
		_grid_cell(str(reckoning["wealth"][s]), true)
	_grid_cell("Puan", true)
	for s in seat_count:
		_grid_cell(str(reckoning["points"][s]), true)
	_grid_cell("Gece toplamı", true)
	for s in seat_count:
		_grid_cell(str(v["night_points"][s]), true)
	if notes.is_empty():
		notes.append("Örtbas da masa altı da yok.")
	if v["night_over"] and not Network.is_host():
		notes.append("Yeni bir gece için host lobiye dönecek.")
	_reckoning_notes.text = "Kırmızı: yalan. D: denetçi.\n" + "\n".join(notes)
	_next_button.visible = not v["night_over"]
	_next_button.disabled = v["ready"][seat]
	_next_button.text = "Sonraki maça hazırım" if not v["ready"][seat] else "Diğerleri bekleniyor…"
	_lobby_button.visible = v["night_over"] and Network.is_host()
	if v["night_over"]:
		_reckoning_title.text = "Gece bitti · " + _night_winner_text()


func _grid_cell(text: String, strong: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14 if strong else 13)
	_reckoning_grid.add_child(label)
	return label


func _night_winner_text() -> String:
	var points: PackedInt32Array = _view["night_points"]
	var best := 0
	for p in points:
		best = maxi(best, p)
	var names := PackedStringArray()
	for s in points.size():
		if points[s] == best and best > 0:
			names.append(_name(s))
	return "Kazanan: %s (%d puan)" % [", ".join(names), best] if not names.is_empty() else "Kazanan yok"


func _accessory_names(items: Array) -> String:
	var names := PackedStringArray()
	for item: int in items:
		names.append(Session.RULES.accessory_names[item])
	return ", ".join(names)


static func _missing_text(missing: int) -> String:
	if missing > 0:
		return "KAYIP JETON: %d." % missing
	if missing < 0:
		return "BEYAN FAZLASI: %d." % -missing
	return "Kayıp jeton yok."
