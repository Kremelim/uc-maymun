class_name TableProps
extends Node3D
## What lies on the table: the pot as a pile of coins with how much this round needs,
## and in front of every seat its declaration card, face down until everyone has
## declared. Presentation only: it draws what the view says.

const TABLE_TOP := 0.79
const COIN_RADIUS := 0.06
const COIN_HEIGHT := 0.02
const COINS_PER_COLUMN := 10
## Where the columns of the pot stand, around the middle of the table.
const POT_COLUMNS := [Vector2(0, 0), Vector2(0.13, 0), Vector2(-0.13, 0), Vector2(0, 0.13), Vector2(0, -0.13),
	Vector2(0.12, 0.12), Vector2(-0.12, -0.12), Vector2(0.12, -0.12), Vector2(-0.12, 0.12)]
const CARD_DISTANCE := 0.72
const CARD_SIZE := Vector3(0.16, 0.006, 0.22)
const CARD_BACK := Color(0.45, 0.08, 0.06)
const CARD_FRONT := Color(0.95, 0.9, 0.8)
const COIN_COLOR := Color(0.95, 0.74, 0.25)

var _coin_mesh := CylinderMesh.new()
var _pot: Node3D
var _pot_label: Label3D
var _shown_pot := -1
var _cards: Dictionary = {}  # seat -> {"mesh": MeshInstance3D, "label": Label3D}


## `my_seat` is where the camera sits: the pot's label goes on that side of the pile.
func setup(seat_count: int, my_seat: int) -> void:
	for child in get_children():
		child.queue_free()
	_cards.clear()
	_shown_pot = -1
	if seat_count == 0:
		return  # the seats are not known yet; the first view sets the table up again
	var coin_material := StandardMaterial3D.new()
	coin_material.albedo_color = COIN_COLOR
	coin_material.metallic = 0.2
	coin_material.roughness = 0.45
	coin_material.emission_enabled = true
	coin_material.emission = COIN_COLOR * 0.6  # gold even in the lamp's shadow
	_coin_mesh.top_radius = COIN_RADIUS
	_coin_mesh.bottom_radius = COIN_RADIUS
	_coin_mesh.height = COIN_HEIGHT
	_coin_mesh.radial_segments = 16
	_coin_mesh.material = coin_material
	_pot = Node3D.new()
	_pot.position = Vector3(0, TABLE_TOP, 0)
	add_child(_pot)
	_pot_label = _label(26)
	var towards_me := TAU * my_seat / seat_count
	_pot_label.position = Vector3(sin(towards_me), 0, cos(towards_me)) * 0.3 + Vector3.UP * (TABLE_TOP + 0.02)
	add_child(_pot_label)
	for seat in seat_count:
		var angle := TAU * seat / seat_count
		var direction := Vector3(sin(angle), 0, cos(angle))
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = CARD_SIZE
		mesh.mesh = box
		mesh.material_override = StandardMaterial3D.new()
		mesh.position = direction * CARD_DISTANCE + Vector3.UP * (TABLE_TOP + CARD_SIZE.y / 2.0)
		mesh.rotation.y = angle
		add_child(mesh)
		var label := _label(26)
		label.position = mesh.position + Vector3.UP * 0.07
		add_child(label)
		_cards[seat] = {"mesh": mesh, "label": label}


func update(view: Dictionary) -> void:
	if _cards.is_empty():
		return
	var pot: int = view["pot"]
	_set_pot(pot)
	var phase: int = view["phase"]
	# After the audit the round's installment is settled, and installment_due already shows the next one.
	var settled: bool = phase >= MatchState.Phase.SHOP
	_pot_label.text = "Kasa %d" % pot if settled else "Kasa %d / %d" % [pot, view["installment_due"]]
	_pot_label.modulate = Color(0.6, 1.0, 0.55) if not settled and pot >= int(view["installment_due"]) else Color.WHITE
	var declarations: PackedInt32Array = view["declarations"]
	for seat: int in _cards:
		var mesh: MeshInstance3D = _cards[seat]["mesh"]
		var label: Label3D = _cards[seat]["label"]
		var material := mesh.material_override as StandardMaterial3D
		if not declarations.is_empty():
			mesh.visible = true
			material.albedo_color = CARD_FRONT
			label.text = str(declarations[seat])
			label.visible = true
		elif phase == MatchState.Phase.DECLARE and view["declared"][seat]:
			mesh.visible = true  # face down: declared, not yet shown
			material.albedo_color = CARD_BACK
			label.visible = false
		else:
			mesh.visible = false
			label.visible = false


func _set_pot(count: int) -> void:
	if count == _shown_pot:
		return
	var grew := count > _shown_pot and _shown_pot >= 0
	_shown_pot = count
	for coin in _pot.get_children():
		coin.queue_free()
	var shown := mini(count, COINS_PER_COLUMN * POT_COLUMNS.size())
	for i in shown:
		var column: Vector2 = POT_COLUMNS[floori(float(i) / COINS_PER_COLUMN)]
		var coin := MeshInstance3D.new()
		coin.mesh = _coin_mesh
		coin.position = Vector3(column.x, COIN_HEIGHT * (i % COINS_PER_COLUMN + 0.5), column.y)
		_pot.add_child(coin)
	if grew:
		_pot.scale = Vector3.ONE * 1.25
		create_tween().tween_property(_pot, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK)


static func _label(font_size: int) -> Label3D:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true
	label.pixel_size = 0.0022
	label.font_size = font_size
	label.outline_size = 10
	label.no_depth_test = true
	return label
