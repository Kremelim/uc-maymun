class_name HowToPlay
extends Control
## "Nasıl oynanır": the rules in a few short pages, for the lobby and the table.
## Numbers come from the rules data, so the text follows when the rules change.

var _page := 0
var _pages: Array[Dictionary] = []

@onready var _title: Label = %PageTitle
@onready var _body: Label = %PageBody
@onready var _counter: Label = %PageCounter
@onready var _back_button: Button = %BackButton
@onready var _next_button: Button = %NextButton
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_pages = pages(Session.RULES)
	_back_button.pressed.connect(func() -> void: _show(_page - 1))
	_next_button.pressed.connect(func() -> void:
		if _page == _pages.size() - 1:
			hide()
		else:
			_show(_page + 1))
	_close_button.pressed.connect(hide)
	visibility_changed.connect(func() -> void:
		if visible:
			_show(0))
	_show(0)


static func pages(rules: RulesConfig) -> Array[Dictionary]:
	var ratio := roundi(rules.min_contribution_ratio * 100.0)
	var points := rules.placement_points
	return [
		{"title": "Amaç", "body": "Dört maymun, tek masa, ortak bir borç: %d jeton, her tur %d jeton taksit.\n\nBorcu birlikte ödeyin, cebe en çok parayı siz atın.\n\nMaç sonunda borç ödendiyse en zengin kazanır. Ödenmediyse herkes kaybeder." % [rules.installment * rules.round_count, rules.installment]},
		{"title": "1 · Gelir", "body": "Her tur herkese gizli bir gelir gelir. Kimin ne aldığını kimse bilmez; sadece masaya toplam kaç jeton dağıtıldığı bilinir.\n\nGelirin sol altta yazar. Onu sadece sen görürsün."},
		{"title": "2 · Beyan", "body": "Herkes \"bana şu kadar geldi\" der. Yalan söyleyebilirsin!\n\nSöylediğinin %%%d'ı hemen kasaya gider: az söylersen az ödersin.\n\nAma beyanlar açılınca \"kayıp jeton\" herkesin önünde görünür: toplamdan eksik olan para birilerinin cebinde.\n\nDenetçinin kartı açıktır; o yalan söyleyemez." % ratio},
		{"title": "3 · Konuşma ve katkı", "body": "Şimdi konuşun: kim yalan söylüyor, kasa yetecek mi?\n\nSonra herkes isterse kasaya fazladan jeton koyar (kapalı avuç, aynı anda açılır).\n\nKasa bu turun taksitini karşılamazsa eksik, faiziyle sonraki tura eklenir. Borç büyür."},
		{"title": "4 · Denetim", "body": "Her tur bir oyuncu denetçidir (sarı şapka). Birinin kartına gizlice bakar.\n\nYalan varsa raporlar: saklanan jetonlar kasaya döner, yalancı farkı ceza olarak denetçiye öder. Parası yetmezse borçlu kalır (senet).\n\nDenetçi göz de yumabilir (örtbas)… ama maç sonunda herkes görecek.\n\nTemiz birini denetlerse ona %d jeton tazminat öder." % rules.audit_compensation},
		{"title": "5 · Hesap Günü", "body": "%d tur sonra bütün kartlar açılır: kim ne aldı, kim yalan söyledi, kim örtbas etti.\n\nBorç ödendiyse en zenginden başlayarak %d / %d / %d / %d puan. Ödenmediyse herkes 0.\n\nBir gece %d maçtır; gecenin sonunda en çok puanı olan kazanır." % [rules.round_count, points[0], points[1], points[2], points[3], rules.matches_per_night]},
		{"title": "İkinci maçtan itibaren", "body": "İlk maç temel kurallarla oynanır. Sonra şunlar da açılır:\n\n• Kefil: birine kefil olursun. Temiz çıkarsa bankadan +%d alırsın; yalancı çıkarsa cezasının yarısını sen ödersin.\n• Masa altı: gizlice jeton verebilirsin (rüşvet, ittifak). Sadece veren ve alan görür.\n• Dükkan: aksesuar al. Herkes görür, maç sonunda değeri artar, cezada haczedilir." % rules.vouch_reward},
	]


func _show(page: int) -> void:
	_page = clampi(page, 0, _pages.size() - 1)
	_title.text = _pages[_page]["title"]
	_body.text = _pages[_page]["body"]
	_counter.text = "%d / %d" % [_page + 1, _pages.size()]
	_back_button.disabled = _page == 0
	_next_button.text = "Anladım, oynayalım" if _page == _pages.size() - 1 else "İleri"
