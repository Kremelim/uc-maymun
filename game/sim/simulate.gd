extends SceneTree
## Plays thousands of bot matches per experiment and writes the results as Markdown:
##   godot --headless --path game --script res://sim/simulate.gd -- --matches=2000 --out=/abs/path.md
## Each experiment asks one question from docs/gdd/kurallar-v0.1.md. Bots are crude
## models of players: read the numbers as "what the rules reward", not as predictions
## of what people will do. Exits with 1 if the engine reports any error.

const RULES: RulesConfig = preload("res://data/rules_v0_1.tres")
const DEFAULT_MATCHES := 2000
const BASE_SEED := 20261020

## id, question, lineup (bot presets), and rule changes for that experiment.
const EXPERIMENTS := [
	{"id": "E1", "question": "Herkes dürüstse masa kurtuluyor mu, kazananı ne belirliyor?",
		"lineup": ["dürüst", "dürüst", "dürüst", "dürüst"]},
	{"id": "E2", "question": "Herkes açgözlüyse (gelirinin yarısını saklıyor) masa batıyor mu?",
		"lineup": ["açgözlü", "açgözlü", "açgözlü", "açgözlü"]},
	{"id": "E3", "question": "Dürüstlerin arasındaki tek açgözlü kazanıyor mu?",
		"lineup": ["açgözlü", "dürüst", "dürüst", "dürüst"]},
	{"id": "E4", "question": "Sadece kendi denetçi turunda çalmak (\"bedava yalan\") ne kazandırıyor?",
		"lineup": ["fırsatçı", "dürüst", "dürüst", "dürüst"]},
	{"id": "E5", "question": "Rüşvete açık denetçiler (örtbas) yalanı ne kadar kârlı yapıyor? Karşılaştırma: E6.",
		"lineup": ["yolsuz", "yolsuz", "dürüst", "dürüst"]},
	{"id": "E6", "question": "Aynı masa, ama yalancılar rüşvet vermiyor ve denetçiler almıyor.",
		"lineup": ["açgözlü", "açgözlü", "dürüst", "dürüst"]},
	{"id": "E7", "question": "Kaybedeceğini düşünen son turda masayı batırırsa? Karşılaştırma: E6.",
		"lineup": ["kinci", "kinci", "dürüst", "dürüst"]},
	{"id": "E8", "question": "Payının sadece bir kısmını ödeyen bir bedavacı kazanıyor mu?",
		"lineup": ["bedavacı", "dürüst", "dürüst", "dürüst"]},
	{"id": "E9", "question": "Son turdan sonra dükkan kapalı olursa? Karşılaştırma: E3.",
		"lineup": ["açgözlü", "dürüst", "dürüst", "dürüst"], "rules": {"last_round_shop": false}},
	{"id": "E10", "question": "Fazla beyan yalan sayılmazsa? (Botlar fazla beyan etmiyor; kontrol amaçlı.) Karşılaştırma: E3.",
		"lineup": ["açgözlü", "dürüst", "dürüst", "dürüst"], "rules": {"over_declaration_is_lie": false}},
	{"id": "E12", "question": "Öneri: denetçinin kartı açık. \"Bedava yalan\" turu kapanıyor mu? Karşılaştırma: E4.",
		"lineup": ["fırsatçı", "dürüst", "dürüst", "dürüst"], "rules": {"auditor_card_open": true}},
	{"id": "E13", "question": "Öneri: herkes beyanının en az yarısını kasaya koymak zorunda. Bedavacılık bitiyor mu? Karşılaştırma: E8.",
		"lineup": ["bedavacı", "dürüst", "dürüst", "dürüst"], "rules": {"min_contribution_ratio": 0.5}},
	{"id": "E14", "question": "İki öneri birlikte, karışık masa. Karşılaştırma: E6.",
		"lineup": ["açgözlü", "açgözlü", "dürüst", "dürüst"], "rules": {"auditor_card_open": true, "min_contribution_ratio": 0.5}},
	{"id": "E15", "question": "Herkes rüşvete açıksa örtbas ekonomisi ne kadar büyüyor? Karşılaştırma: E2.",
		"lineup": ["yolsuz", "yolsuz", "yolsuz", "yolsuz"]},
	{"id": "E16", "question": "Asgari katkı adil paya eşit: taksit / gelir toplamı = 12 / 20 = beyanın %60'ı. Karşılaştırma: E8, E13.",
		"lineup": ["bedavacı", "dürüst", "dürüst", "dürüst"], "rules": {"min_contribution_ratio": 0.6}},
	{"id": "E17", "question": "Önerilen paket: kart açık + asgari katkı %60 + son tur dükkanı kapalı, karışık masa. Karşılaştırma: E6, E14.",
		"lineup": ["açgözlü", "açgözlü", "dürüst", "dürüst"],
		"rules": {"auditor_card_open": true, "min_contribution_ratio": 0.6, "last_round_shop": false}},
	{"id": "E18", "question": "Önerilen paket, herkes açgözlü. Karşılaştırma: E2.",
		"lineup": ["açgözlü", "açgözlü", "açgözlü", "açgözlü"],
		"rules": {"auditor_card_open": true, "min_contribution_ratio": 0.6, "last_round_shop": false}},
]
## Installment sweep: how tight the debt is for a mixed table.
const SWEEP_LINEUP := ["açgözlü", "açgözlü", "dürüst", "dürüst"]
const SWEEP_INSTALLMENTS := [8, 9, 10, 11, 12, 13, 14, 15, 16]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var collector := ErrorCollector.new()
	OS.add_logger(collector)
	var matches := int(CmdArgs.value("--matches", str(DEFAULT_MATCHES)))
	var lines := PackedStringArray([
		"# Simülasyon sonuçları — kurallar v0.1",
		"",
		"> Bu dosya `game/sim/simulate.gd` tarafından üretilir; elle düzenlemeyin.",
		"> Deney başına %d maç, seed %d. Yorum: `docs/sim/bulgular-v0.1.md`." % [matches, BASE_SEED],
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
## type always audits first. Returns totals per bot type and for the table.
func _play_many(rules: RulesConfig, lineup: Array, matches: int) -> Dictionary:
	var by_kind := {}
	var table := {"matches": matches, "succeeded": 0, "shortfall_rounds": 0, "close_rounds": 0, "last_shop_gain": 0, "wealth": 0}
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
			bots.append(SimBot.preset(kind))
		var result := MatchRunner.play(rules, bots, BASE_SEED + i)
		table["succeeded"] += 1 if result["succeeded"] else 0
		table["shortfall_rounds"] += result["shortfall_rounds"]
		table["close_rounds"] += result["close_rounds"]
		var winners: Array = result["winners"]
		for seat in bots.size():
			var kind: String = kinds[seat]
			if not by_kind.has(kind):
				by_kind[kind] = {"seats": 0, "wins": 0.0, "points": 0, "wealth": 0, "lies": 0, "caught": 0, "covered": 0, "sank": 0, "auditor_lies": 0}
			var k: Dictionary = by_kind[kind]
			k["seats"] += 1
			k["wins"] += 1.0 / winners.size() if seat in winners else 0.0
			k["points"] += (result["points"] as PackedInt32Array)[seat]
			k["wealth"] += (result["wealth"] as PackedInt32Array)[seat]
			k["lies"] += (result["lies"] as PackedInt32Array)[seat]
			k["caught"] += (result["caught"] as PackedInt32Array)[seat]
			k["covered"] += (result["covered"] as PackedInt32Array)[seat]
			k["sank"] += (result["sank_table"] as PackedInt32Array)[seat]
			k["auditor_lies"] += (result["auditor_round_lies"] as PackedInt32Array)[seat]
			table["last_shop_gain"] += (result["last_shop_gain"] as PackedInt32Array)[seat]
			table["wealth"] += (result["wealth"] as PackedInt32Array)[seat]
	return {"table": table, "by_kind": by_kind, "rounds": rules.round_count}


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
	if table["wealth"] > 0:
		lines.append("- Servetin son tur alışverişinden gelen kısmı: %s" % _percent(float(table["last_shop_gain"]) / table["wealth"]))
	lines.append("")
	lines.append("| Tip | Kazanma | Puan | Servet | Yalan/tur | Yakalanma | Örtbas | Masayı batırdı |")
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
		"Borç ne kadar sıkı olmalı? Hedef (kurallar v0.1): turların yaklaşık yarısında taksit kıl payı ödensin.",
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
