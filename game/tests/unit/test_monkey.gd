extends TestSuite
## The monkey and its models: the cast's models pass the delivery check, the check
## catches a broken model, and the table's API (accessories, auditor hat, mouth,
## reactions) reaches the model.

const MONKEY_SCENE := "res://features/monkey/monkey.tscn"
const CAST: MonkeyCast = preload("res://assets/monkeys/cast.tres")
const RULES_FILES := ["res://data/rules_v0_1.tres", "res://data/rules_v0_2.tres", "res://data/rules_v0_3.tres"]


func test_cast_models_pass_the_check() -> void:
	var keys: PackedStringArray = (load(RULES_FILES[-1]) as RulesConfig).accessory_keys
	assert_true(not CAST.bodies.is_empty(), "the cast has bodies")
	for body in CAST.bodies:
		var check := MonkeyModelCheck.of(body, keys)
		assert_true(check.passed(), "%s: %s" % [body.resource_path, check.report()])
		assert_eq(check.warnings.size(), 0, "%s has no warnings" % body.resource_path)


func test_check_finds_a_broken_model() -> void:
	# A small box on a skeleton with Mixamo names (as Godot imports them, ":" becomes "_"):
	# no shapes, no animations, no accessories.
	var root := Node3D.new()
	var skeleton := Skeleton3D.new()
	root.add_child(skeleton)
	skeleton.add_bone("mixamorig_Hips")
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.5
	mesh.mesh = box
	root.add_child(mesh)
	var check := MonkeyModelCheck.new()
	check.inspect(root, PackedStringArray(["glasses"]))
	root.free()
	assert_true(not check.passed(), "fails")
	var text := "\n".join(check.errors)
	for expected: String in ["Eksik kemik: Hips", "jaw_open", "Animasyon yok", "acc_glasses", "auditor_hat", "Boy 0.50 m"]:
		assert_true(expected in text, "reports %s in:\n%s" % [expected, text])


func test_check_finds_a_model_facing_backwards() -> void:
	var root := (CAST.bodies[0].instantiate() as Node3D)
	root.rotation.y = PI
	var holder := Node3D.new()
	holder.add_child(root)
	var check := MonkeyModelCheck.new()
	check.inspect(holder, PackedStringArray())
	holder.free()
	assert_true("\n".join(check.errors).contains("ters bakıyor"), "a turned model is reported: %s" % check.report())


func test_rules_name_every_accessory() -> void:
	for path: String in RULES_FILES:
		var rules: RulesConfig = load(path)
		assert_eq(rules.accessory_keys.size(), rules.accessory_names.size(), "%s: a key per accessory" % path)
		var unique := {}
		for key in rules.accessory_keys:
			unique[key] = true
		assert_eq(unique.size(), rules.accessory_keys.size(), "%s: keys are unique" % path)


func test_accessories_and_hat_follow_the_table() -> void:
	var monkey := _monkey()
	var keys := (load(RULES_FILES[-1]) as RulesConfig).accessory_keys
	assert_true(monkey.can_wear_all(keys), "the test monkey wears every accessory")
	assert_eq(_visible(monkey, "acc_crown"), false, "no crown to begin with")
	monkey.set_accessories(PackedStringArray(["crown", "gloves"]))
	assert_eq(_visible(monkey, "acc_crown"), true, "crown on")
	assert_eq(_visible(monkey, "acc_gloves"), true, "gloves on")
	assert_eq(_visible(monkey, "acc_glasses"), false, "glasses still off")
	assert_eq(_visible(monkey, "auditor_hat"), false, "no hat")
	monkey.set_auditor(true)
	assert_eq(_visible(monkey, "auditor_hat"), true, "hat while auditing")
	monkey.free()


func test_mouth_follows_the_voice() -> void:
	var monkey := _monkey()
	monkey.push_voice(PackedVector2Array(), 0.05)
	monkey._process(0.0)
	assert_true(absf(_shape(monkey, Monkey.MOUTH_SHAPE) - 0.05 * Monkey.MOUTH_GAIN) < 0.001, "mouth half open")
	monkey._process(1.0)
	assert_eq(_shape(monkey, Monkey.MOUTH_SHAPE), 0.0, "closes again in silence")
	monkey.free()


func test_reactions_play_and_unknown_ones_do_not() -> void:
	var monkey := _monkey()
	var player := monkey.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	assert_eq(str(player.current_animation), "idle", "idles")
	for reaction in Monkey.REACTIONS:
		assert_true(monkey.react(reaction), "%s plays" % reaction)
		assert_eq(str(player.current_animation), reaction, "%s is on" % reaction)
	assert_eq(monkey.react("dance"), false, "no dance animation")
	monkey.free()


func _monkey() -> Monkey:
	var monkey: Monkey = (load(MONKEY_SCENE) as PackedScene).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(monkey)
	monkey.dress(CAST.bodies[0], Color.WHITE, true)
	return monkey


static func _visible(monkey: Monkey, node_name: String) -> bool:
	var node := monkey.find_child(node_name, true, false) as Node3D
	# Bone-attached accessories come as a BoneAttachment3D with a mesh of the same name in it.
	return node != null and node.is_visible_in_tree()


static func _shape(monkey: Monkey, shape: String) -> float:
	for node: Node in monkey.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var index := mesh.find_blend_shape_by_name(shape)
		if index >= 0:
			return mesh.get_blend_shape_value(index)
	return -1.0
