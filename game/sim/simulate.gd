extends SceneTree
## Plays thousands of bot matches per experiment and writes the results as Markdown:
##   godot --headless --path game --script res://sim/simulate.gd -- --matches=2000 --out=/abs/path.md
## Each experiment asks one question about the current rules (docs/gdd/kurallar-v0.3.md).
## Bots are crude models of players: read the numbers as "what the rules reward",
## not as predictions of what people will do. Exits with 1 if the engine reports any error.
## When the rules change, point RULES at the new data and rewrite the experiments;
## older reports stay in docs/sim/ with the commit that produced them.

const RULES: RulesConfig = preload("res://data/rules_v0_3.tres")
const RULES_NAME := "v0.3"
const DEFAULT_MATCHES := 2000
const BASE_SEED := 20261020

## id, question, lineup (bot presets), and rule changes for that experiment. An id
## asks the same question as in earlier reports, so they can be compared.
const EXPERIMENTS := [
	{"id": "E1", "question": "Herkes dürüstse masa kurtuluyor mu, kazananı ne belirliyor?",
		"lineup": ["dürüst", "dürüst", "dürüst", "dürüst"]},
	{"id": "E2", "question": "Herkes açgözlüyse (gelirinin yarısını saklıyor) masa batıyor mu?",
		"lineup": ["açgözlü", "açgözlü", "açgözlü", "açgözlü"]},
	{"id": "E3", "question": "Dürüstlerin arasındaki tek açgözlü kazanıyor mu?",
		"lineup": ["açgözlü", "dürüst", "dürüst", "dürüst"]},
	{"id": "E5", "question": "Rüşvete açık denetçiler (örtbas) yalanı ne kadar kârlı yapıyor? Karşılaştırma: E6.",
		"lineup": ["yolsuz", "yolsuz", "dürüst", "dürüst"]},
	{"id": "E6", "question": "İki açgözlü, iki dürüst: karışık masa.",
		"lineup": ["açgözlü", "açgözlü", "dürüst", "dürüst"]},
	{"id": "E7", "question": "Kaybedeceğini düşünen son turda katkıyı keserse? Karşılaştırma: E6.",
		"lineup": ["kinci", "kinci", "dürüst", "dürüst"]},
	{"id": "E8", "question": "Payının sadece bir kısmını ödemek isteyen bedavacı kazanıyor mu?",
		"lineup": ["bedavacı", "dürüst", "dürüst", "dürüst"]},
	{"id": "E15", "question": "Herkes rüşvete açıksa örtbas ekonomisi ne kadar büyüyor? Karşılaştırma: E2.",
		"lineup": ["yolsuz", "yolsuz", "yolsuz", "yolsuz"]},
	{"id": "E20", "question": "Senet olmasaydı (ödenemeyen ceza ortak borca eklenseydi)? Karşılaştırma: E6.",
		"lineup": ["açgözlü", "açgözlü", "dürüst", "dürüst"], "rules": {"unpaid_becomes_iou": false}},
	{"id": "E21", "question": "Senet olmasaydı, herkes açgözlüyken? Karşılaştırma: E2.",
		"lineup": ["açgözlü", "açgözlü", "açgözlü", "açgözlü"], "rules": {"unpaid_becomes_iou": false}},
]
## Installment sweep: how tight the debt is for a mixed table.
const SWEEP_LINEUP := ["açgözlü", "açgözlü", "dürüst", "dürüst"]
const SWEEP_INSTALLMENTS := [8, 9, 10, 11, 12, 13, 14, 15, 16]
## Lie size sweep: one greedy player among honest ones, hiding this share of its income.
const LIE_LINEUP := ["açgözlü", "dürüst", "dürüst", "dürüst"]
const LIE_HIDE_RATIOS := [0.25, 0.5, 0.75, 1.0]
## Fine sweep: does a smaller fine make lying alone worth it?
const FINE_MULTIPLIERS := [1.0, 0.75, 0.5]
const MIXED_LINEUP := ["açgözlü", "açgözlü", "dürüst", "dürüst"]
## Nights of identical liars: does the round you audit first decide the night?
const NIGHT_LINEUP := ["açgözlü", "açgözlü", "açgözlü", "açgözlü"]
## [rotate_first_auditor, matches_per_night]
const NIGHT_OPTIONS := [[false, 3], [true, 3], [true, 4]]
## Debt options: installment with the minimum share that matches it (installment / income total).
const DEBT_OPTIONS := [[12, 0.6], [13, 0.65], [14, 0.7], [15, 0.75]]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var collector := ErrorCollector.new()
	OS.add_logger(collector)
	var matches := int(CmdArgs.value("--matches", str(DEFAULT_MATCHES)))
	var lines := PackedStringArray([
		"# Simülasyon sonuçları — kurallar %s" % RULES_NAME,
		"",
		"> Bu dosya `game/sim/simulate.gd` tarafından üretilir; elle düzenlemeyin.",
		"> Deney başına %d maç, seed %d. Yorum: `docs/sim/bulgular-%s.md`." % [matches, BASE_SEED, RULES_NAME],
		"> Deney numaraları önceki raporlardaki aynı soruyu sorar; anlamı kalmayanlar çıkarıldı.",
		"",
		"Sütunlar: **Kazanma** = o tipteki bir oyuncunun maçı kazanma payı (4 kişide adil pay %25).",
		"**Puan** = gece skoru ortalaması (5/3/2/1, masa batarsa 0). **Yalan/tur** = yalan söylediği turların oranı.",
		"**Yakalanma** ve **örtbas** = yalanların ne kadarı raporlandı / rüşvetle kapatıldı.",
		"",
	])
	for experiment: Dictionary in EXPERIMENTS:
		var rules := _rules_with(experiment.get("rules", {}))
		var stats := _play_many(rules, experiment["lineup"], matches)
		lines.append_array(_experiment_section(experiment, stats))
	lines.append_array(_sweep_section(matches))
	lines.append_array(_lie_section(matches))
	lines.append_array(_fine_section(matches))
	lines.append_array(_night_section(matches))
	lines.append_array(_debt_section(matches))
	var report := "\n".join(lines) + "\n"
	var out := CmdArgs.value("--out", "")
	if out != "":
		var file := FileAccess.open(out, FileAccess.WRITE)
		file.store_string(report)
		file.close()
		print("Wrote %s" % out)
	else:
		print(report)
	var errors := collector.take()
	OS.remove_logger(collector)
	for error in errors:
		printerr("SIM ENGINE ERROR: %s" % error)
	quit(1 if not errors.is_empty() else 0)


func _rules_with(changes: Dictionary) -> RulesConfig:
	var rules: RulesConfig = RULES.duplicate()
	for key: String in changes:
		rules.set(key, changes[key])
	return rules


## Plays `matches` matches with the lineup's seats shuffled each time, so no bot
## type always audits first. `bot_changes` overrides preset fields, as {kind: {field: value}}.
## Returns totals per bot type, per seat (seat i audits round i + 1) and for the table.
func _play_many(rules: RulesConfig, lineup: Array, matches: int, bot_changes: Dictionary = {}) -> Dictionary:
	var by_kind := {}
	var seat_wins := PackedFloat64Array()
	seat_wins.resize(lineup.size())
	var seat_points := PackedInt32Array()
	seat_points.resize(lineup.size())
	var table := {"matches": matches, "succeeded": 0, "shortfall_rounds": 0, "close_rounds": 0, "unpaid_debt": 0, "iou_total": 0,
		"last_shop_gain": 0, "wealth": 0}
	var shuffler := RandomNumberGenerator.new()
	shuffler.seed = BASE_SEED
	for i in matches:
		var kinds := lineup.duplicate()
		for j in range(kinds.size() - 1, 0, -1):
			var k := shuffler.randi_range(0, j)
			var swap: Variant = kinds[j]
			kinds[j] = kinds[k]
			kinds[k] = swap
		var bots: Array[SimBot] = []
		for kind: String in kinds:
			var bot := SimBot.preset(kind)
			var changes: Dictionary = bot_changes.get(kind, {})
			for field: String in changes:
				bot.set(field, changes[field])
			bots.append(bot)
		var result := MatchRunner.play(rules, bots, BASE_SEED + i)
		table["succeeded"] += 1 if result["succeeded"] else 0
		table["shortfall_rounds"] += result["shortfall_rounds"]
		table["unpaid_debt"] += result["unpaid_debt"]
		table["iou_total"] += result["iou_total"]
		table["close_rounds"] += result["close_rounds"]
		var winners: Array = result["winners"]
		for seat in bots.size():
			var kind: String = kinds[seat]
			if not by_kind.has(kind):
				by_kind[kind] = {"seats": 0, "wins": 0.0, "points": 0, "wealth": 0, "lies": 0, "caught": 0, "covered": 0, "sank": 0, "auditor_lies": 0}
			var k: Dictionary = by_kind[kind]
			k["seats"] += 1
			k["wins"] += 1.0 / winners.size() if seat in winners else 0.0
			seat_wins[seat] += 1.0 / winners.size() if seat in winners else 0.0
			seat_points[seat] += (result["points"] as PackedInt32Array)[seat]
			k["points"] += (result["points"] as PackedInt32Array)[seat]
			k["wealth"] += (result["wealth"] as PackedInt32Array)[seat]
			k["lies"] += (result["lies"] as PackedInt32Array)[seat]
			k["caught"] += (result["caught"] as PackedInt32Array)[seat]
			k["covered"] += (result["covered"] as PackedInt32Array)[seat]
			k["sank"] += (result["sank_table"] as PackedInt32Array)[seat]
			k["auditor_lies"] += (result["auditor_round_lies"] as PackedInt32Array)[seat]
			table["last_shop_gain"] += (result["last_shop_gain"] as PackedInt32Array)[seat]
			table["wealth"] += (result["wealth"] as PackedInt32Array)[seat]
	return {"table": table, "by_kind": by_kind, "seat_wins": seat_wins, "seat_points": seat_points, "rounds": rules.round_count}


func _experiment_section(experiment: Dictionary, stats: Dictionary) -> PackedStringArray:
	var table: Dictionary = stats["table"]
	var matches: int = table["matches"]
	var lines := PackedStringArray([
		"## %s — %s" % [experiment["id"], " + ".join(_lineup_summary(experiment["lineup"]))],
		"",
		experiment["question"],
		"",
	])
	var changes: Dictionary = experiment.get("rules", {})
	if not changes.is_empty():
		lines.append("Kural değişikliği: `%s`" % JSON.stringify(changes))
		lines.append("")
	lines.append("- Masa kurtuldu: **%s**" % _percent(float(table["succeeded"]) / matches))
	lines.append("- Taksitin eksik kaldığı tur: maç başına %.2f · kıl payı (en fazla %d artıkla) ödendiği tur: %.2f" % [
		float(table["shortfall_rounds"]) / matches, MatchRunner.CLOSE_MARGIN, float(table["close_rounds"]) / matches])
	if table["unpaid_debt"] > 0:
		lines.append("- Ödenemeyip ortak borca eklenen: maç başına %.2f jeton" % (float(table["unpaid_debt"]) / matches))
	if table["iou_total"] > 0:
		lines.append("- Ödenemeyip senede dönüşen ceza ve tazminat: maç başına %.2f jeton" % (float(table["iou_total"]) / matches))
	if table["wealth"] > 0 and table["last_shop_gain"] > 0:
		lines.append("- Servetin son tur alışverişinden gelen kısmı: %s" % _percent(float(table["last_shop_gain"]) / table["wealth"]))
	var lineup: Array = experiment["lineup"]
	if lineup.count(lineup[0]) == lineup.size():
		# Identical players: any difference comes from the round each one audits.
		var parts := PackedStringArray()
		var seat_wins: PackedFloat64Array = stats["seat_wins"]
		var seat_points: PackedInt32Array = stats["seat_points"]
		for seat in seat_wins.size():
			parts.append("%d. tur %s / %.2f" % [seat + 1, _percent(seat_wins[seat] / matches), float(seat_points[seat]) / matches])
		lines.append("- Denetçi olduğu tura göre kazanma / puan: %s" % " · ".join(parts))
	lines.append("")
	lines.append("| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Son katkıyı kesti |")
	lines.append("|---|---|---|---|---|---|---|---|")
	var by_kind: Dictionary = stats["by_kind"]
	for kind: String in by_kind:
		var k: Dictionary = by_kind[kind]
		var seats: int = k["seats"]
		var lies: int = k["lies"]
		lines.append("| %s | %s | %.2f | %.1f | %s | %s | %s | %s |" % [
			kind,
			_percent(k["wins"] / seats),
			float(k["points"]) / seats,
			float(k["wealth"]) / seats,
			_percent(float(lies) / (seats * int(stats["rounds"]))),
			_percent(float(k["caught"]) / lies) if lies > 0 else "—",
			_percent(float(k["covered"]) / lies) if lies > 0 else "—",
			_percent(float(k["sank"]) / seats) if k["sank"] > 0 else "—",
		])
	lines.append("")
	return lines


func _sweep_section(matches: int) -> PackedStringArray:
	var lines := PackedStringArray([
		"## E11 — Taksit taraması: %s" % " + ".join(_lineup_summary(SWEEP_LINEUP)),
		"",
		"Borç ne kadar sıkı olmalı? Hedef: turların yaklaşık yarısında taksit kıl payı ödensin.",
		"Eksik ve kıl payı sütunları maç başına tur sayısıdır (4 turun kaçı).",
		"",
		"| Tur başı taksit | Toplam borç | Masa kurtuldu | Eksik kalan tur | Kıl payı ödenen tur | Açgözlü kazanma | Dürüst kazanma |",
		"|---|---|---|---|---|---|---|",
	])
	for installment: int in SWEEP_INSTALLMENTS:
		var rules := _rules_with({"installment": installment})
		var stats := _play_many(rules, SWEEP_LINEUP, matches)
		var table: Dictionary = stats["table"]
		var by_kind: Dictionary = stats["by_kind"]
		lines.append("| %d | %d | %s | %.2f | %.2f | %s | %s |" % [
			installment,
			installment * rules.round_count,
			_percent(float(table["succeeded"]) / matches),
			float(table["shortfall_rounds"]) / matches,
			float(table["close_rounds"]) / matches,
			_percent(by_kind["açgözlü"]["wins"] / by_kind["açgözlü"]["seats"]),
			_percent(by_kind["dürüst"]["wins"] / by_kind["dürüst"]["seats"]),
		])
	lines.append("")
	return lines


func _lie_section(matches: int) -> PackedStringArray:
	var lines := PackedStringArray([
		"## E19 — Yalan büyüklüğü: %s" % " + ".join(_lineup_summary(LIE_LINEUP)),
		"",
		"Ne kadar saklamak kârlı? Açgözlü her tur gelirinin bu kadarını saklıyor (denetçiyken kartı açık, saklayamıyor).",
		"",
		"| Sakladığı pay | Masa kurtuldu | Açgözlü kazanma | Açgözlü puan | Yakalanma | Dürüst kazanma | Dürüst puan |",
		"|---|---|---|---|---|---|---|",
	])
	for ratio: float in LIE_HIDE_RATIOS:
		var stats := _play_many(RULES, LIE_LINEUP, matches, {"açgözlü": {"hide_ratio": ratio}})
		var table: Dictionary = stats["table"]
		var greedy: Dictionary = stats["by_kind"]["açgözlü"]
		var honest: Dictionary = stats["by_kind"]["dürüst"]
		lines.append("| %s | %s | %s | %.2f | %s | %s | %.2f |" % [
			_percent(ratio),
			_percent(float(table["succeeded"]) / matches),
			_percent(greedy["wins"] / greedy["seats"]),
			float(greedy["points"]) / greedy["seats"],
			_percent(float(greedy["caught"]) / greedy["lies"]) if greedy["lies"] > 0 else "—",
			_percent(honest["wins"] / honest["seats"]),
			float(honest["points"]) / honest["seats"],
		])
	lines.append("")
	return lines


func _fine_section(matches: int) -> PackedStringArray:
	var lines := PackedStringArray([
		"## E22 — Ceza miktarı",
		"",
		"Ceza küçülürse tek başına yalan söylemek kârlı hale geliyor mu? Ceza = fark × çarpan, yukarı yuvarlanır.",
		"Hücreler: kazanma / gece skoru. Karışık masa: 2 açgözlü + 2 dürüst.",
		"",
		"| Ceza çarpanı | 1 açgözlü (%25 saklıyor) + 3 dürüst | 1 açgözlü (%50) + 3 dürüst | Karışık masa: açgözlü | Karışık masa: dürüst |",
		"|---|---|---|---|---|",
	])
	for multiplier: float in FINE_MULTIPLIERS:
		var rules := _rules_with({"fine_multiplier": multiplier})
		var small := _play_many(rules, LIE_LINEUP, matches, {"açgözlü": {"hide_ratio": 0.25}})
		var half := _play_many(rules, LIE_LINEUP, matches)
		var mixed := _play_many(rules, MIXED_LINEUP, matches)
		lines.append("| %s | %s | %s | %s | %s |" % [
			"%.2f" % multiplier,
			_wins_and_points(small["by_kind"]["açgözlü"]),
			_wins_and_points(half["by_kind"]["açgözlü"]),
			_wins_and_points(mixed["by_kind"]["açgözlü"]),
			_wins_and_points(mixed["by_kind"]["dürüst"]),
		])
	lines.append("")
	return lines


func _night_section(nights: int) -> PackedStringArray:
	var lines := PackedStringArray([
		"## E23 — Gece: %s" % " + ".join(_lineup_summary(NIGHT_LINEUP)),
		"",
		"Aynı dört oyuncu bir gece boyunca oynuyor; geceyi en çok toplam puanı alan kazanıyor (eşitlikte paylaşılır).",
		"Koltuk A, gecenin ilk maçında ilk denetçi olan; B, C, D onu izliyor. Adil pay %25.",
		"",
		"| İlk denetçi | Maç | A | B | C | D | En iyi − en kötü |",
		"|---|---|---|---|---|---|---|",
	])
	for option: Array in NIGHT_OPTIONS:
		var rules := _rules_with({"rotate_first_auditor": option[0], "matches_per_night": option[1]})
		var seat_wins := _play_nights(rules, NIGHT_LINEUP, nights)
		var cells := PackedStringArray()
		for seat in seat_wins.size():
			cells.append(_percent(seat_wins[seat] / nights))
		lines.append("| %s | %d | %s | %s |" % [
			"her maç bir kayıyor" if option[0] else "her maç A",
			option[1],
			" | ".join(cells),
			_percent((_max(seat_wins) - _min(seat_wins)) / nights),
		])
	lines.append("")
	return lines


## Plays nights of rules.matches_per_night matches between the same bots, seated in
## lineup order. Returns the share of nights each seat won, ties split.
func _play_nights(rules: RulesConfig, lineup: Array, nights: int) -> PackedFloat64Array:
	var seat_wins := PackedFloat64Array()
	seat_wins.resize(lineup.size())
	for night in nights:
		var totals := PackedInt32Array()
		totals.resize(lineup.size())
		for match_index in rules.matches_per_night:
			var bots: Array[SimBot] = []
			for kind: String in lineup:
				bots.append(SimBot.preset(kind))
			var first := MatchState.first_auditor_of(rules, match_index, lineup.size())
			var result := MatchRunner.play(rules, bots, BASE_SEED + night * rules.matches_per_night + match_index, first)
			var points: PackedInt32Array = result["points"]
			for seat in lineup.size():
				totals[seat] += points[seat]
		var best := 0
		for total in totals:
			best = maxi(best, total)
		if best == 0:
			continue  # the table sank every match: nobody wins the night
		var winners := totals.count(best)
		for seat in lineup.size():
			if totals[seat] == best:
				seat_wins[seat] += 1.0 / winners
	return seat_wins


func _debt_section(matches: int) -> PackedStringArray:
	var lines := PackedStringArray([
		"## E24 — Borç seçenekleri",
		"",
		"Taksit artarsa asgari oran da artmalı (taksit / gelir toplamı), yoksa az ödeyen kazanır.",
		"Herkes açgözlüyken masa ne sıklıkla batıyor, karışık masada (2 açgözlü + 2 dürüst) denge nasıl?",
		"Sıkışık tur = eksik ya da kıl payı ödenen. Hücreler: kazanma / gece skoru.",
		"",
		"| Taksit / asgari | Toplam borç | 4 açgözlü: masa kurtuldu | Karışık: sıkışık tur | Karışık: açgözlü | Karışık: dürüst | 1 bedavacı + 3 dürüst: bedavacı |",
		"|---|---|---|---|---|---|---|",
	])
	for option: Array in DEBT_OPTIONS:
		var rules := _rules_with({"installment": option[0], "min_contribution_ratio": option[1]})
		var greedy := _play_many(rules, NIGHT_LINEUP, matches)
		var mixed := _play_many(rules, MIXED_LINEUP, matches)
		var free_rider := _play_many(rules, ["bedavacı", "dürüst", "dürüst", "dürüst"], matches)
		var mixed_table: Dictionary = mixed["table"]
		lines.append("| %d / %s | %d | %s | %s | %s | %s | %s |" % [
			option[0],
			_percent(option[1]),
			option[0] * rules.round_count,
			_percent(float(greedy["table"]["succeeded"]) / matches),
			_percent(float(mixed_table["shortfall_rounds"] + mixed_table["close_rounds"]) / (matches * rules.round_count)),
			_wins_and_points(mixed["by_kind"]["açgözlü"]),
			_wins_and_points(mixed["by_kind"]["dürüst"]),
			_wins_and_points(free_rider["by_kind"]["bedavacı"]),
		])
	lines.append("")
	return lines


static func _wins_and_points(kind_stats: Dictionary) -> String:
	var seats: int = kind_stats["seats"]
	return "%s / %.2f" % [_percent(kind_stats["wins"] / seats), float(kind_stats["points"]) / seats]


static func _max(values: PackedFloat64Array) -> float:
	var result := values[0]
	for value in values:
		result = maxf(result, value)
	return result


static func _min(values: PackedFloat64Array) -> float:
	var result := values[0]
	for value in values:
		result = minf(result, value)
	return result


static func _lineup_summary(lineup: Array) -> PackedStringArray:
	var counts := {}
	for kind: String in lineup:
		counts[kind] = counts.get(kind, 0) + 1
	var parts := PackedStringArray()
	for kind: String in counts:
		parts.append("%d %s" % [counts[kind], kind])
	return parts


static func _percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)
