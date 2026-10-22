class_name MonkeyModelCheck
extends RefCounted
## Checks a monkey model against docs/sanatci-sartnamesi.md: skeleton and bone names,
## facing and size, the mouth and blink shapes, the animations, the accessory and
## auditor-hat nodes, and the triangle budget. Used by tools/check_monkey_model.gd for
## deliveries and by the unit tests for the models in the cast. Messages are Turkish:
## they are for the team and the artist.

const REQUIRED_BONES: Array[String] = ["Hips", "Spine", "Chest", "Neck", "Head",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"]
const RECOMMENDED_BONES: Array[String] = ["UpperChest", "LeftShoulder", "RightShoulder",
	"LeftToes", "RightToes", "Jaw", "LeftEye", "RightEye"]
const REQUIRED_ANIMATIONS: Array[String] = ["idle", "caught", "cheer", "slump"]
const RECOMMENDED_ANIMATIONS: Array[String] = ["talk"]
## Height of the rest pose (standing), in metres.
const HEIGHT_RANGE := Vector2(0.9, 1.7)
## The feet stand on the origin: the lowest point may be this far from y = 0.
const FLOOR_TOLERANCE := 0.05
## One monkey with all its accessories, in triangles.
const TRIANGLE_WARNING := 20000
const TRIANGLE_LIMIT := 30000
const TEXTURE_LIMIT := 2048
## The skeleton's name after Godot's humanoid retargeting on import.
const SHARED_SKELETON := "GeneralSkeleton"

var errors := PackedStringArray()
var warnings := PackedStringArray()
## What was found (counts, names), for the report.
var notes := PackedStringArray()


## Checks the model in `scene`. `accessory_keys`: RulesConfig.accessory_keys.
static func of(scene: PackedScene, accessory_keys: PackedStringArray) -> MonkeyModelCheck:
	var check := MonkeyModelCheck.new()
	var root := scene.instantiate()
	check.inspect(root, accessory_keys)
	root.free()
	return check


func passed() -> bool:
	return errors.is_empty()


func report() -> String:
	var lines := PackedStringArray()
	for note in notes:
		lines.append("  ✓ " + note)
	for warning in warnings:
		lines.append("  ! " + warning)
	for error in errors:
		lines.append("  ✗ " + error)
	lines.append("SONUÇ: %s (%d hata, %d uyarı)" % ["GEÇTİ" if passed() else "KALDI", errors.size(), warnings.size()])
	return "\n".join(lines)


func inspect(root: Node, accessory_keys: PackedStringArray) -> void:
	var skeletons := root.find_children("*", "Skeleton3D", true, false)
	if skeletons.size() != 1:
		errors.append("Tam bir iskelet (Skeleton3D) olmalı, %d tane var." % skeletons.size())
	else:
		_check_skeleton(skeletons[0] as Skeleton3D, root)
	_check_meshes(root)
	_check_animations(root)
	_check_nodes(root, accessory_keys)


func _check_skeleton(skeleton: Skeleton3D, root: Node) -> void:
	notes.append("İskelet: %d kemik" % skeleton.get_bone_count())
	# Import with a bone map renames the skeleton to %GeneralSkeleton; then animations
	# can be shared between models (docs/sanatci-sartnamesi.md, section 10).
	if skeleton.name != SHARED_SKELETON or not skeleton.unique_name_in_owner:
		warnings.append("İçe aktarırken kemik eşleme (Bone Map) açılmamış: animasyonlar modeller arasında paylaşılamaz (şartname, bölüm 10).")
	var missing := _missing(REQUIRED_BONES, func(bone: String) -> bool: return skeleton.find_bone(bone) >= 0)
	if not missing.is_empty():
		errors.append("Eksik kemik: %s" % ", ".join(missing))
	var optional := _missing(RECOMMENDED_BONES, func(bone: String) -> bool: return skeleton.find_bone(bone) >= 0)
	if not optional.is_empty():
		warnings.append("Önerilen kemik yok: %s" % ", ".join(optional))
	var left_arm := skeleton.find_bone("LeftUpperArm")
	if left_arm >= 0:
		# Facing +Z, the monkey's left hand is on +X.
		var to_root := _transform_to(root, skeleton)
		if (to_root * skeleton.get_bone_global_rest(left_arm)).origin.x <= 0.0:
			errors.append("Model ters bakıyor ya da sol/sağ karışık: sol kol +X'te olmalı (Godot'da yüz +Z'ye, Blender'da -Y'ye, önden görünüşe).")


func _check_meshes(root: Node) -> void:
	var triangles := 0
	var materials := {}
	var bounds := AABB()
	var has_bounds := false
	var mouth := false
	var blink := false
	var fur := false
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		mouth = mouth or mesh_node.find_blend_shape_by_name(Monkey.MOUTH_SHAPE) >= 0
		blink = blink or mesh_node.find_blend_shape_by_name(Monkey.BLINK_SHAPE) >= 0
		for surface in mesh_node.mesh.get_surface_count():
			triangles += _triangles(mesh_node.mesh, surface)
			var material := mesh_node.get_active_material(surface)
			if material != null:
				materials[material] = true
				fur = fur or material.resource_name == Monkey.FUR_MATERIAL
				_check_textures(material)
		if _is_extra(mesh_node):
			continue
		var box := _transform_to(root, mesh_node) * mesh_node.mesh.get_aabb()
		bounds = bounds.merge(box) if has_bounds else box
		has_bounds = true
	notes.append("%d üçgen, %d malzeme" % [triangles, materials.size()])
	if triangles > TRIANGLE_LIMIT:
		errors.append("Üçgen sayısı %d; sınır %d (aksesuarlar dahil)." % [triangles, TRIANGLE_LIMIT])
	elif triangles > TRIANGLE_WARNING:
		warnings.append("Üçgen sayısı %d; hedef en çok %d." % [triangles, TRIANGLE_WARNING])
	if not mouth:
		errors.append("Ağız için \"%s\" blend shape'i yok." % Monkey.MOUTH_SHAPE)
	if not blink:
		warnings.append("Göz kırpma için \"%s\" blend shape'i yok." % Monkey.BLINK_SHAPE)
	if not fur:
		warnings.append("\"%s\" adlı malzeme yok: koltuklara göre tüy rengi değişmez." % Monkey.FUR_MATERIAL)
	if not has_bounds:
		errors.append("Gövde modeli (mesh) yok.")
		return
	notes.append("Boy %.2f m (ayakta, dinlenme pozu)" % bounds.size.y)
	if bounds.size.y < HEIGHT_RANGE.x or bounds.size.y > HEIGHT_RANGE.y:
		errors.append("Boy %.2f m; %.1f-%.1f m arası olmalı (1 birim = 1 metre)." % [bounds.size.y, HEIGHT_RANGE.x, HEIGHT_RANGE.y])
	if absf(bounds.position.y) > FLOOR_TOLERANCE:
		warnings.append("Ayaklar zeminde değil: en alt nokta y = %.2f m (0 olmalı)." % bounds.position.y)


func _check_textures(material: Material) -> void:
	var base := material as BaseMaterial3D
	if base == null:
		return
	for texture: Texture2D in [base.albedo_texture, base.normal_texture, base.orm_texture, base.roughness_texture]:
		if texture != null and maxi(texture.get_width(), texture.get_height()) > TEXTURE_LIMIT:
			warnings.append("Doku %dx%d; en çok %d olmalı (%s)." % [texture.get_width(), texture.get_height(), TEXTURE_LIMIT, base.resource_name])


func _check_animations(root: Node) -> void:
	var players := root.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		errors.append("Animasyon yok (AnimationPlayer).")
		return
	var player := players[0] as AnimationPlayer
	var found := PackedStringArray()
	for animation_name in player.get_animation_list():
		var animation := player.get_animation(animation_name)
		found.append("%s %.1f sn" % [animation_name, animation.length])
		for track in animation.get_track_count():
			var path := str(animation.track_get_path(track))
			if animation.track_get_type(track) == Animation.TYPE_BLEND_SHAPE and (path.ends_with(":" + Monkey.MOUTH_SHAPE) or path.ends_with(":" + Monkey.BLINK_SHAPE)):
				warnings.append("\"%s\" animasyonu ağzı ya da gözü oynatıyor; onları oyun yönetir (%s)." % [animation_name, path])
	notes.append("Animasyonlar: %s" % ", ".join(found))
	var missing := _missing(REQUIRED_ANIMATIONS, player.has_animation)
	if not missing.is_empty():
		errors.append("Eksik animasyon: %s" % ", ".join(missing))
	var optional := _missing(RECOMMENDED_ANIMATIONS, player.has_animation)
	if not optional.is_empty():
		warnings.append("Önerilen animasyon yok: %s" % ", ".join(optional))


func _check_nodes(root: Node, accessory_keys: PackedStringArray) -> void:
	var found := {}
	var hat := false
	for node: Node in root.find_children("*", "Node3D", true, false):
		var node_name := str(node.name)
		if node_name.begins_with(Monkey.ACCESSORY_PREFIX):
			found[node_name.trim_prefix(Monkey.ACCESSORY_PREFIX)] = true
		hat = hat or node_name == Monkey.AUDITOR_HAT
	var missing := _missing(Array(accessory_keys), func(key: String) -> bool: return found.has(key))
	if not missing.is_empty():
		errors.append("Eksik aksesuar: %s" % ", ".join(Array(missing).map(func(key: String) -> String: return Monkey.ACCESSORY_PREFIX + key)))
	for key: String in found:
		if key not in accessory_keys:
			warnings.append("Bilinmeyen aksesuar adı: %s%s (yazım hatası mı?)" % [Monkey.ACCESSORY_PREFIX, key])
	if not hat:
		errors.append("Denetçi şapkası (%s) yok." % Monkey.AUDITOR_HAT)
	if missing.is_empty() and hat:
		notes.append("Aksesuarlar ve denetçi şapkası tam")


## Accessories and the hat: not part of the body's size.
static func _is_extra(node: Node) -> bool:
	while node != null:
		var node_name := str(node.name)
		if node_name.begins_with(Monkey.ACCESSORY_PREFIX) or node_name == Monkey.AUDITOR_HAT:
			return true
		node = node.get_parent()
	return false


static func _triangles(mesh: Mesh, surface: int) -> int:
	var arrays := mesh.surface_get_arrays(surface)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if not indices.is_empty():
		return floori(indices.size() / 3.0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	return floori(vertices.size() / 3.0)


## The transform from `node`'s space to `root`'s, without needing the scene tree.
static func _transform_to(root: Node, node: Node) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current := node
	while current != null and current != root:
		var spatial := current as Node3D
		if spatial != null:
			result = spatial.transform * result
		current = current.get_parent()
	return result


static func _missing(wanted: Array, has: Callable) -> PackedStringArray:
	var missing := PackedStringArray()
	for item: String in wanted:
		if not has.call(item):
			missing.append(item)
	return missing
