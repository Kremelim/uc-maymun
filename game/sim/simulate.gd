extends SceneTree
## Plays thousands of bot matches per experiment and writes the results as Markdown:
##   godot --headless --path game --script res://sim/simulate.gd -- --matches=2000 --out=/abs/path.md
## Each experiment asks one question about the current rules (docs/gdd/kurallar-v0.2.md).
## Bots are crude models of players: read the numbers as "what the rules reward",
## not as predictions of what people will do. Exits with 1 if the engine reports any error.
## When the rules change, point RULES at the new data and rewrite the experiments;
## older reports stay in docs/sim/ with the commit that produced them.

const RULES: RulesConfig = preload("res://data/rules_v0_2.tres")
const RULES_NAME := "v0.2"
const DEFAULT_MATCHES := 2000
const BASE_SEED := 20261020

## id, question, lineup (bot presets), and rule changes for that experiment. An id
## asks the same question as in the v0.1 report, so the two can be compared.
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
]
## Installment sweep: how tight the debt is for a mixed table.
const SWEEP_LINEUP := ["açgözlü", "açgözlü", "dürüst", "dürüst"]
const SWEEP_INSTALLMENTS := [8, 9, 10, 11, 12, 13, 14, 15, 16]
## Lie size sweep: one greedy player among honest ones, hiding this share of its income.
const LIE_LINEUP := ["açgözlü", "dürüst", "dürüst", "dürüst"]
const LIE_HIDE_RATIOS := [0.25, 0.5, 0.75, 1.0]


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
		"> Deney numaraları v0.1 raporundaki aynı soruyu sorar; v0.2'de anlamı kalmayanlar çıkarıldı.",
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
	var table := {"matches": matches, "succeeded": 0, "shortfall_rounds": 0, "close_rounds": 0, "unpaid_debt": 0, "last_shop_gain": 0, "wealth": 0}
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
			k["points"] += (result["points"] as PackedInt32Array)[seat]
			k["wealth"] += (result["wealth"] as PackedInt32Array)[seat]
			k["lies"] += (result["lies"] as PackedInt32Array)[seat]
			k["caught"] += (result["caught"] as PackedInt32Array)[seat]
			k["covered"] += (result["covered"] as PackedInt32Array)[seat]
			k["sank"] += (result["sank_table"] as PackedInt32Array)[seat]
			k["auditor_lies"] += (result["auditor_round_lies"] as PackedInt32Array)[seat]
			table["last_shop_gain"] += (result["last_shop_gain"] as PackedInt32Array)[seat]
			table["wealth"] += (result["wealth"] as PackedInt32Array)[seat]
	return {"table": table, "by_kind": by_kind, "seat_wins": seat_wins, "rounds": rules.round_count}


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
		lines.append("- Ödenemeyip ortak borca eklenen ceza ve tazminat: maç başına %.2f jeton" % (float(table["unpaid_debt"]) / matches))
	if table["wealth"] > 0 and table["last_shop_gain"] > 0:
		lines.append("- Servetin son tur alışverişinden gelen kısmı: %s" % _percent(float(table["last_shop_gain"]) / table["wealth"]))
	var lineup: Array = experiment["lineup"]
	if lineup.count(lineup[0]) == lineup.size():
		# Identical players: any difference comes from the round each one audits.
		var parts := PackedStringArray()
		var seat_wins: PackedFloat64Array = stats["seat_wins"]
		for seat in seat_wins.size():
			parts.append("%d. tur %s" % [seat + 1, _percent(seat_wins[seat] / matches)])
		lines.append("- Denetçi olduğu tura göre kazanma: %s" % " · ".join(parts))
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
