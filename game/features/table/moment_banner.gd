class_name MomentBanner
extends PanelContainer
## Big, short announcements for the moments that matter: declarations opening, someone
## caught, the installment missed. They queue up and fade in and out one after another.

const SHOW_SEC := 1.9
const FADE_SEC := 0.25
## With a long queue, each announcement stays for less time so the table does not lag behind.
const BUSY_QUEUE := 3
const TITLE_COLOR := Color(1.0, 0.82, 0.38)
const BAD_COLOR := Color(1.0, 0.45, 0.35)
const GOOD_COLOR := Color(0.55, 0.9, 0.5)

var _queue: Array = []
var _busy := false

@onready var _title: Label = $VBox/BannerTitle
@onready var _subtitle: Label = $VBox/BannerSubtitle


func announce(title: String, subtitle: String = "", color: Color = TITLE_COLOR) -> void:
	_queue.append([title, subtitle, color])
	if not _busy:
		_next()


## Drops what is waiting; the announcement on screen still finishes unless hidden too.
func clear() -> void:
	_queue.clear()


func _next() -> void:
	if _queue.is_empty():
		_busy = false
		hide()
		return
	_busy = true
	var item: Array = _queue.pop_front()
	_title.text = item[0]
	_subtitle.text = item[1]
	_subtitle.visible = item[1] != ""
	_title.add_theme_color_override("font_color", item[2])
	modulate.a = 0.0
	show()
	var hold := SHOW_SEC if _queue.size() < BUSY_QUEUE else SHOW_SEC * 0.5
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_SEC)
	tween.tween_interval(hold)
	tween.tween_property(self, "modulate:a", 0.0, FADE_SEC)
	tween.finished.connect(_next)
