"""Builds the free test monkey of Üç Maymun and exports it as a GLB.

It stands in for the real monkeys until they are bought or commissioned, and it follows
docs/sanatci-sartnamesi.md point by point, so it is also a worked example of the spec:
bone names, shape keys, accessory and auditor-hat objects, actions, scale and facing.

Everything is generated (Blender's Suzanne head plus simple shapes), so the result is
free to use (CC0) and can be rebuilt at any time:

    blender -b --factory-startup --python tools/blender/make_test_monkey.py -- \
        --out game/assets/monkeys/test_monkey.glb

Tested with Blender 4.5 LTS.

Conventions (Blender): Z is up, 1 unit is 1 metre, the monkey looks towards -Y (the
front view) and its left hand is on +X. The glTF exporter turns this into glTF's
Y-up, +Z-forward.
"""

import argparse
import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

FPS = 30

# Rest skeleton in an A-pose: (bone, parent, head, tail). Left-side bones are mirrored
# to the right. The names are Godot's humanoid profile (SkeletonProfileHumanoid), so the
# model needs no bone map on import. Tail bones are extra; extra bones are allowed.
BONES = [
    ("Root", None, (0, 0, 0), (0, 0, 0.15)),
    ("Hips", "Root", (0, 0, 0.55), (0, 0, 0.64)),
    ("Spine", "Hips", (0, 0, 0.64), (0, 0, 0.74)),
    ("Chest", "Spine", (0, 0, 0.74), (0, 0, 0.84)),
    ("UpperChest", "Chest", (0, 0, 0.84), (0, 0, 0.94)),
    ("Neck", "UpperChest", (0, 0, 0.94), (0, 0, 1.0)),
    ("Head", "Neck", (0, 0, 1.0), (0, 0, 1.3)),
    ("Jaw", "Head", (0, -0.04, 1.03), (0, -0.13, 1.01)),
    ("LeftEye", "Head", (0.056, -0.12, 1.14), (0.056, -0.17, 1.14)),
    ("LeftShoulder", "UpperChest", (0.04, 0, 0.92), (0.15, 0, 0.92)),
    ("LeftUpperArm", "LeftShoulder", (0.15, 0, 0.92), (0.36, 0, 0.78)),
    ("LeftLowerArm", "LeftUpperArm", (0.36, 0, 0.78), (0.55, 0, 0.65)),
    ("LeftHand", "LeftLowerArm", (0.55, 0, 0.65), (0.63, 0, 0.6)),
    ("LeftUpperLeg", "Hips", (0.1, 0, 0.55), (0.11, 0, 0.31)),
    ("LeftLowerLeg", "LeftUpperLeg", (0.11, 0, 0.31), (0.11, 0, 0.08)),
    ("LeftFoot", "LeftLowerLeg", (0.11, 0, 0.08), (0.11, -0.1, 0.03)),
    ("LeftToes", "LeftFoot", (0.11, -0.1, 0.03), (0.11, -0.16, 0.03)),
    ("Tail1", "Hips", (0, 0.14, 0.56), (0, 0.32, 0.5)),
    ("Tail2", "Tail1", (0, 0.32, 0.5), (0, 0.5, 0.55)),
    ("Tail3", "Tail2", (0, 0.5, 0.55), (0, 0.58, 0.75)),
]

# Suzanne is made with size 2; this scales her to a big cartoon head (about 31 cm tall).
HEAD_SCALE = 0.16
HEAD_CENTER = Vector((0, -0.01, 1.1))

# Linear colours (Blender's base colour), metallic, roughness.
MATERIALS = {
    "fur": ((0.16, 0.08, 0.035), 0.0, 0.8),
    "face": ((0.62, 0.4, 0.24), 0.0, 0.6),
    "eye": ((0.9, 0.88, 0.82), 0.0, 0.3),
    "pupil": ((0.01, 0.01, 0.01), 0.0, 0.2),
    "mouth": ((0.05, 0.006, 0.006), 0.0, 0.5),
    "gold": ((1.0, 0.62, 0.15), 0.9, 0.3),
    "frame": ((0.02, 0.02, 0.02), 0.2, 0.4),
    "glove": ((0.85, 0.85, 0.82), 0.0, 0.7),
    "strap": ((0.12, 0.05, 0.02), 0.0, 0.6),
    "silver": ((0.8, 0.82, 0.85), 0.9, 0.25),
    "visor": ((0.01, 0.16, 0.05), 0.0, 0.4),
}


def mirrored(name):
    return "Right" + name[4:] if name.startswith("Left") else name


def all_bones():
    bones = list(BONES)
    for name, parent, head, tail in BONES:
        if name.startswith("Left"):
            bones.append((mirrored(name), mirrored(parent), flip(head), flip(tail)))
    return bones


def flip(point):
    return (-point[0], point[1], point[2])


REST = {name: (Vector(head), Vector(tail)) for name, _parent, head, tail in all_bones()}


# --- Geometry ---------------------------------------------------------------------

class Builder:
    """Collects parts into one bmesh, with per-vertex bone weights and tags."""

    def __init__(self, material_names):
        self.bm = bmesh.new()
        self.materials = list(material_names)
        self.weights = []  # per vertex: {bone: weight}
        self.tags = {}  # tag -> set of vertex indices

    def add(self, part, material, weigh, tag=None, smooth=True):
        """Copies the bmesh `part` in. `weigh(position)` returns {bone: weight}."""
        index = self.materials.index(material)
        mapping = {}
        for v in part.verts:
            mapping[v] = self.bm.verts.new(v.co)
            self.weights.append(weigh(v.co))
            if tag:
                self.tags.setdefault(tag, set()).add(len(self.weights) - 1)
        for f in part.faces:
            face = self.bm.faces.new([mapping[v] for v in f.verts])
            face.material_index = index
            face.smooth = smooth
        part.free()

    def to_object(self, name, armature):
        # Plain colours need no texture, but a UV map keeps importers happy (Godot builds
        # tangents from it) and leaves room for one: a cylindrical projection will do.
        uv = self.bm.loops.layers.uv.new("UVMap")
        for face in self.bm.faces:
            for loop in face.loops:
                co = loop.vert.co
                loop[uv].uv = (math.atan2(co.x, -co.y) / math.tau + 0.5, co.z / 1.4)
        mesh = bpy.data.meshes.new(name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for material in self.materials:
            mesh.materials.append(bpy.data.materials[material])
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        groups = {}
        for i, weights in enumerate(self.weights):
            for bone, weight in weights.items():
                if bone not in groups:
                    groups[bone] = obj.vertex_groups.new(name=bone)
                groups[bone].add([i], weight, "REPLACE")
        obj.parent = armature
        modifier = obj.modifiers.new("Armature", "ARMATURE")
        modifier.object = armature
        return obj


def ellipsoid(center, radii, segments=24, rings=14, tilt=0.0):
    """`tilt`: degrees about X (positive lifts the front)."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=1.0)
    turn = Matrix.Rotation(math.radians(-tilt), 3, "X")
    for v in bm.verts:
        v.co = Vector(center) + turn @ Vector((v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2]))
    return bm


def tube(points, radii, segments=14, steps=5, caps=True):
    """A tube through `points` with a radius per point, `steps` rings per segment."""
    path = []
    for i in range(len(points) - 1):
        a, b = Vector(points[i]), Vector(points[i + 1])
        for s in range(steps):
            t = s / steps
            path.append((a.lerp(b, t), radii[i] + (radii[i + 1] - radii[i]) * t))
    path.append((Vector(points[-1]), radii[-1]))
    bm = bmesh.new()
    rings = []
    for i, (center, radius) in enumerate(path):
        before = path[max(i - 1, 0)][0]
        after = path[min(i + 1, len(path) - 1)][0]
        direction = (after - before).normalized()
        helper = Vector((0, 0, 1)) if abs(direction.z) < 0.9 else Vector((1, 0, 0))
        side = direction.cross(helper).normalized()
        up = side.cross(direction).normalized()
        ring = []
        for k in range(segments):
            angle = math.tau * k / segments
            ring.append(bm.verts.new(center + (side * math.cos(angle) + up * math.sin(angle)) * radius))
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for k in range(segments):
            bm.faces.new([a[k], a[(k + 1) % segments], b[(k + 1) % segments], b[k]])
    if caps:
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])
    return bm


def torus(center, axis, major, minor, segments=24, sides=8):
    bm = bmesh.new()
    axis = Vector(axis).normalized()
    helper = Vector((0, 0, 1)) if abs(axis.z) < 0.9 else Vector((1, 0, 0))
    u = axis.cross(helper).normalized()
    w = axis.cross(u)
    rings = []
    for i in range(segments):
        a = math.tau * i / segments
        radial = u * math.cos(a) + w * math.sin(a)
        ring = []
        for j in range(sides):
            b = math.tau * j / sides
            ring.append(bm.verts.new(Vector(center) + radial * (major + minor * math.cos(b)) + axis * minor * math.sin(b)))
        rings.append(ring)
    for i in range(segments):
        a, b = rings[i], rings[(i + 1) % segments]
        for j in range(sides):
            bm.faces.new([a[j], b[j], b[(j + 1) % sides], a[(j + 1) % sides]])
    return bm


def rigid(bone):
    return lambda _position: {bone: 1.0}


def along(chain, blend=0.05):
    """Weights for a vertex from the bones of `chain`: the nearest bone, blended with its
    neighbour within `blend` metres of the joint (half and half at the joint)."""
    segments = [(name, REST[name][0], REST[name][1]) for name in chain]

    def weigh(position):
        best = None
        for i, (_name, head, tail) in enumerate(segments):
            d = tail - head
            u = max(0.0, min(1.0, (position - head).dot(d) / d.length_squared))
            distance = (head + d * u - position).length
            if best is None or distance < best[0]:
                best = (distance, i, u * d.length, d.length)
        _distance, i, s, length = best
        if s < blend and i > 0:
            a = 0.5 + 0.5 * s / blend
            return {segments[i][0]: a, segments[i - 1][0]: 1.0 - a}
        if length - s < blend and i < len(segments) - 1:
            a = 0.5 + 0.5 * (length - s) / blend
            return {segments[i][0]: a, segments[i + 1][0]: 1.0 - a}
        return {segments[i][0]: 1.0}

    return weigh


def to_head(local):
    """Suzanne's own coordinates (size 2) to the model's."""
    return HEAD_CENTER + Vector(local) * HEAD_SCALE


def suzanne_head(builder):
    bpy.ops.mesh.primitive_monkey_add(size=2)
    suzanne = bpy.context.active_object
    suzanne.modifiers.new("Smooth", "SUBSURF").levels = 1
    head = bmesh.new()
    head.from_object(suzanne, bpy.context.evaluated_depsgraph_get())
    bpy.data.objects.remove(suzanne)
    # Suzanne's eyes are separate islands: they become the white of the eyes.
    island_of = {}
    for v in head.verts:
        if v in island_of:
            continue
        stack, island = [v], []
        island_of[v] = island
        while stack:
            a = stack.pop()
            island.append(a)
            for e in a.link_edges:
                b = e.other_vert(a)
                if b not in island_of:
                    island_of[b] = island
                    stack.append(b)
    for part_name in ("head", "eyes"):
        part = bmesh.new()
        mapping = {}
        for v in head.verts:
            is_eye = len(island_of[v]) < 300
            if is_eye == (part_name == "eyes"):
                mapping[v] = part.verts.new(to_head(v.co))
        face_materials = []
        for f in head.faces:
            if all(v in mapping for v in f.verts):
                part.faces.new([mapping[v] for v in f.verts])
                c = f.calc_center_median()
                front = c.y < -0.4 and -0.95 < c.z < 0.45 and abs(c.x) < 0.95
                inner_ear = abs(c.x) > 1.0 and f.normal.y < -0.3
                face_materials.append("face" if front or inner_ear else "fur")
        if part_name == "eyes":
            builder.add(part, "eye", rigid("Head"), tag="eyes")
            continue
        # Faces of one bmesh share a material in Builder.add, so split skin and fur.
        for material in ("fur", "face"):
            piece = bmesh.new()
            remap = {}
            for f, m in zip(part.faces, face_materials):
                if m != material:
                    continue
                verts = []
                for v in f.verts:
                    if v not in remap:
                        remap[v] = piece.verts.new(v.co)
                    verts.append(remap[v])
                piece.faces.new(verts)
            builder.add(piece, material, rigid("Head"))
        part.free()
    head.free()
    for side in (1, -1):
        builder.add(ellipsoid(to_head((0.35 * side, -0.8, 0.22)), (0.016, 0.01, 0.018), 12, 8),
            "pupil", rigid("Head"), tag="eyes")
    # A thin dark mouth along Suzanne's lips; the "jaw_open" shape key opens it downwards.
    builder.add(ellipsoid(to_head((0, -0.8, -0.58)), (0.042, 0.008, 0.007), 20, 10), "mouth", rigid("Head"), tag="mouth")


def body(builder):
    torso_chain = ["Hips", "Spine", "Chest", "UpperChest"]
    builder.add(ellipsoid((0, 0.01, 0.75), (0.19, 0.15, 0.23)), "fur", along(torso_chain))
    builder.add(ellipsoid((0, -0.09, 0.72), (0.14, 0.075, 0.17)), "face", along(torso_chain))
    builder.add(tube([(0, 0, 0.9), (0, 0, 1.0)], [0.075, 0.07]), "fur", along(["UpperChest", "Neck", "Head"]))
    for side in (1, -1):
        def p(x, y, z, s=side):
            return (x * s, y, z)
        left = "Left" if side == 1 else "Right"
        arm = [left + "Shoulder", left + "UpperArm", left + "LowerArm", left + "Hand"]
        builder.add(tube([p(0.08, 0, 0.92), p(0.15, 0, 0.92), p(0.36, 0, 0.78), p(0.55, 0, 0.65)],
            [0.06, 0.055, 0.048, 0.042], steps=6), "fur", along(arm))
        builder.add(ellipsoid(p(0.595, 0, 0.62), (0.05, 0.04, 0.055), 16, 10), "face", along(arm[2:]))
        builder.add(ellipsoid(p(0.58, -0.04, 0.64), (0.02, 0.02, 0.025), 10, 6), "face", along(arm[2:]))
        leg = [left + "UpperLeg", left + "LowerLeg", left + "Foot"]
        builder.add(tube([p(0.1, 0, 0.6), p(0.11, 0, 0.31), p(0.11, 0, 0.08)], [0.075, 0.06, 0.05], steps=6),
            "fur", along(leg))
        builder.add(ellipsoid(p(0.11, -0.06, 0.04), (0.055, 0.1, 0.035), 16, 10), "face",
            along([left + "Foot", left + "Toes"]))
    builder.add(tube([(0, 0.12, 0.57), (0, 0.32, 0.5), (0, 0.5, 0.55), (0, 0.58, 0.75)], [0.032, 0.026, 0.02, 0.014],
        segments=10), "fur", along(["Tail1", "Tail2", "Tail3"]))


# --- Accessories ------------------------------------------------------------------

def attach_to_bone(obj, armature, bone_name):
    """Parents `obj` to a bone without moving it (as Ctrl+P > Bone in the editor)."""
    bone = armature.data.bones[bone_name]
    obj.parent = armature
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name
    tail = armature.matrix_world @ bone.matrix_local @ Matrix.Translation((0, bone.length, 0))
    obj.matrix_parent_inverse = tail.inverted()


def accessory(name, parts, armature, bone=None):
    """Rigid parts on one bone, or (bone=None) skinned parts with their own weights."""
    builder = Builder(sorted({material for _part, material, _weigh in parts}))
    for part, material, weigh in parts:
        builder.add(part, material, weigh or rigid(bone))
    obj = builder.to_object(name, armature)
    if bone:
        obj.modifiers.clear()
        obj.vertex_groups.clear()
        attach_to_bone(obj, armature, bone)
    return obj


def accessories(armature):
    eye_y, eye_z = -0.158, 1.137
    glasses = []
    for side in (1, -1):
        glasses.append((torus((0.056 * side, eye_y, eye_z), (0, 1, 0), 0.042, 0.006), "frame", None))
        glasses.append((tube([(0.098 * side, eye_y, eye_z), (0.115 * side, -0.06, eye_z + 0.01)], [0.005, 0.005],
            segments=6, steps=1), "frame", None))
    glasses.append((tube([(-0.016, eye_y, eye_z + 0.01), (0.016, eye_y, eye_z + 0.01)], [0.005, 0.005],
        segments=6, steps=1), "frame", None))
    accessory("acc_glasses", glasses, armature, "Head")

    gloves = []
    for side in (1, -1):
        left = "Left" if side == 1 else "Right"
        hand = rigid(left + "Hand")
        gloves.append((ellipsoid((0.595 * side, 0, 0.62), (0.058, 0.048, 0.063), 16, 10), "glove", hand))
        gloves.append((ellipsoid((0.58 * side, -0.045, 0.64), (0.026, 0.026, 0.03), 10, 6), "glove", hand))
        gloves.append((torus((0.545 * side, 0, 0.655), (0.82 * side, 0, -0.57), 0.05, 0.012), "glove",
            along([left + "LowerArm", left + "Hand"])))
    accessory("acc_gloves", gloves, armature)

    accessory("acc_watch", [
        (torus((0.5, 0, 0.685), (0.82, 0, -0.57), 0.05, 0.01), "strap", None),
        (tube([(0.5, -0.045, 0.695), (0.5, -0.06, 0.695)], [0.022, 0.022], segments=16, steps=1), "silver", None),
    ], armature, "LeftLowerArm")

    accessory("acc_chain", [
        (torus((0, -0.03, 0.93), (0, -0.6, 1), 0.12, 0.011, 32, 6), "gold", None),
        (tube([(0, -0.145, 0.85), (0, -0.16, 0.85)], [0.03, 0.03], segments=16, steps=1), "gold", None),
    ], armature, "UpperChest")

    crown = [(tube([(0, 0.0, 1.22), (0, 0.0, 1.27)], [0.068, 0.074], segments=20, steps=1, caps=False), "gold", None)]
    for i in range(5):
        a = math.tau * i / 5
        base = Vector((math.sin(a) * 0.07, math.cos(a) * 0.07, 1.27))
        crown.append((tube([base, base + Vector((0, 0, 0.045))], [0.018, 0.002], segments=6, steps=1), "gold", None))
    accessory("acc_crown", crown, armature, "Head")

    # The auditor's green eyeshade: a band round the head and a brim over the eyes.
    accessory("auditor_hat", [
        (torus((0, 0.005, 1.185), (0, 0.12, 1), 0.1, 0.011, 32, 6), "visor", None),
        # Half of this disc is inside the head; the front half is the brim, tipped down.
        (ellipsoid((0, -0.1, 1.18), (0.1, 0.075, 0.005), 24, 6, tilt=-18), "visor", None),
    ], armature, "Head")


# --- Skeleton and poses -----------------------------------------------------------

def make_armature():
    data = bpy.data.armatures.new("MonkeyRig")
    armature = bpy.data.objects.new("MonkeyRig", data)
    bpy.context.scene.collection.objects.link(armature)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode="EDIT")
    for name, parent, head, tail in all_bones():
        bone = data.edit_bones.new(name)
        bone.head, bone.tail = head, tail
        bone.roll = 0.0
        if parent:
            bone.parent = data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)


def mirror_spec(spec):
    kind, value = spec
    if kind == "aim":
        return kind, flip(value)
    return kind, [((axis[0], -axis[1], -axis[2]), degrees) for axis, degrees in value]


def seated(**changes):
    """The base pose: sitting on a stool, leaning a little towards the table, forearms on
    its edge. Specs are ("aim", direction) or ("rot", [(axis, degrees)]), in armature
    space and for the left side; the right side is mirrored unless given."""
    pose = {
        "hips": (0, 0.03, -0.07),
        "Spine": ("rot", [(X, 6)]),
        "Chest": ("rot", [(X, 5)]),
        "UpperChest": ("rot", [(X, 3)]),
        "Neck": ("rot", [(X, -4)]),
        "Head": ("rot", [(X, -8)]),
        "LeftShoulder": ("rot", [(Z, -12)]),
        "LeftUpperArm": ("aim", (0.35, -0.9, -0.2)),
        "LeftLowerArm": ("aim", (-0.35, -1, 0.25)),
        "LeftHand": ("aim", (-0.3, -1, -0.25)),
        "LeftUpperLeg": ("aim", (0.18, -1, 0.05)),
        "LeftLowerLeg": ("aim", (0.05, -0.2, -1)),
        "LeftFoot": ("aim", (0.05, -1, -0.3)),
        "LeftToes": ("aim", (0.05, -1, 0)),
        "Tail1": ("aim", (0, 0.6, -1)),
        "Tail2": ("aim", (0.15, 1, 0.1)),
        "Tail3": ("aim", (0.3, 0.4, 1)),
    }
    pose.update(changes)
    for name in list(pose):
        if name.startswith("Left") and mirrored(name) not in changes:
            pose[mirrored(name)] = mirror_spec(pose[name])
    return pose


def more(spec, *rotations):
    """`spec` plus extra rotations (only for "rot" specs)."""
    return "rot", list(spec[1]) + list(rotations)


def solve(armature, pose):
    """Forward kinematics: turns a pose spec into local pose-bone rotations, plus the hips'
    location. Parents are solved before children (all_bones() lists them in that order)."""
    posed, local = {}, {}
    bones = armature.data.bones
    hips_location = Vector()
    for name, parent, _head, _tail in all_bones():
        rest = bones[name].matrix_local
        if parent:
            start = posed[parent] @ bones[parent].matrix_local.inverted() @ rest
        else:
            start = rest.copy()
        if name == "Hips":
            shift = Vector(pose.get("hips", (0, 0, 0)))
            hips_location = start.to_quaternion().inverted() @ shift
            start = Matrix.Translation(shift) @ start
        turn = Quaternion()
        spec = pose.get(name)
        if spec and spec[0] == "aim":
            turn = (start.to_3x3() @ Vector((0, 1, 0))).rotation_difference(Vector(spec[1]).normalized())
        elif spec:
            for axis, degrees in spec[1]:
                turn = Quaternion(Vector(axis), math.radians(degrees)) @ turn
        before = start.to_quaternion()
        after = turn @ before
        posed[name] = Matrix.Translation(start.translation) @ after.to_matrix().to_4x4()
        local[name] = before.inverted() @ after
    return local, hips_location, posed


def make_action(armature, name, keys):
    """`keys`: [(frame, pose)]. Every bone is keyed at every key, so blending between
    actions in Godot never leaves a bone behind."""
    action = bpy.data.actions.new(name)
    armature.animation_data_create()
    armature.animation_data.action = action
    for frame, pose in keys:
        local, hips_location, _posed = solve(armature, pose)
        for bone_name, rotation in local.items():
            pose_bone = armature.pose.bones[bone_name]
            pose_bone.rotation_mode = "QUATERNION"
            pose_bone.rotation_quaternion = rotation
            pose_bone.keyframe_insert("rotation_quaternion", frame=frame, group=bone_name)
        hips = armature.pose.bones["Hips"]
        hips.location = hips_location
        hips.keyframe_insert("location", frame=frame, group="Hips")
    track = armature.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, int(action.frame_range[0]), action)
    armature.animation_data.action = None


def actions(armature):
    base = seated()

    # idle (loops): breathing, a slow look around, the tail sways.
    make_action(armature, "idle", [
        (1, base),
        (61, seated(UpperChest=("rot", [(X, 1)]), Head=more(base["Head"], (Z, 6)), Tail3=("aim", (0.5, 0.3, 1)))),
        (121, base),
    ])

    # talk (loops while the voice is on): nods and a hand that goes with the words.
    gesture = ("aim", (-0.6, -0.6, 0.55))
    make_action(armature, "talk", [
        (1, base),
        (11, seated(Head=more(base["Head"], (X, 8)), RightLowerArm=gesture)),
        (21, seated(Head=more(base["Head"], (X, -3)), RightLowerArm=("aim", (0.4, -0.9, 0.3)))),
        (31, seated(Head=more(base["Head"], (X, 6), (Z, -5)), RightLowerArm=gesture)),
        (41, base),
    ])

    # caught (once): hands to the cheeks, leans back, shakes the head.
    caught = dict(Spine=("rot", [(X, -6)]), LeftUpperArm=("aim", (0.5, -0.5, 0.25)),
        LeftLowerArm=("aim", (-0.55, -0.2, 0.85)), LeftHand=("aim", (-0.3, 0, 1)))
    make_action(armature, "caught", [
        (1, base),
        (8, seated(Head=("rot", [(X, -18)]), **caught)),
        (16, seated(Head=("rot", [(X, -15), (Z, 12)]), **caught)),
        (24, seated(Head=("rot", [(X, -15), (Z, -12)]), **caught)),
        (32, seated(Head=("rot", [(X, -15), (Z, 8)]), **caught)),
        (40, seated(Head=("rot", [(X, -12)]), **caught)),
        (55, base),
    ])

    # cheer (once): arms up, two hops on the stool.
    up = dict(LeftUpperArm=("aim", (0.45, -0.1, 1)), LeftLowerArm=("aim", (0.15, -0.1, 1)),
        LeftHand=("aim", (0, 0, 1)), Head=("rot", [(X, -15)]))
    make_action(armature, "cheer", [
        (1, base),
        (8, seated(hips=(0, 0.03, -0.02), **up)),
        (15, seated(hips=(0, 0.03, -0.07), **up)),
        (22, seated(hips=(0, 0.03, -0.02), **up)),
        (30, seated(hips=(0, 0.03, -0.07), **up)),
        (45, base),
    ])

    # slump (once): head down, shoulders forward, arms hang.
    down = dict(Spine=("rot", [(X, 14)]), Chest=("rot", [(X, 12)]), Neck=("rot", [(X, 10)]), Head=("rot", [(X, 22)]),
        LeftShoulder=("rot", [(Z, -20), (Y, 8)]), LeftUpperArm=("aim", (0.15, -0.25, -1)),
        LeftLowerArm=("aim", (-0.1, -0.7, -1)), LeftHand=("aim", (0, -0.3, -1)))
    make_action(armature, "slump", [
        (1, base),
        (14, seated(**down)),
        (44, seated(**down)),
        (60, base),
    ])


def report(armature):
    """Where hands, elbows and knees end up in the base pose (to check against the table)."""
    _local, _hips, posed = solve(armature, seated())
    for name in ("LeftLowerArm", "LeftHand", "LeftLowerLeg", "Head", "Tail3"):
        head = posed[name].translation
        print("%-14s head at (%.2f, %.2f, %.2f)" % (name, head.x, head.y, head.z))


# --- Main -------------------------------------------------------------------------

def make_materials():
    for name, (color, metallic, roughness) in MATERIALS.items():
        material = bpy.data.materials.new(name)
        material.use_nodes = True
        shader = material.node_tree.nodes["Principled BSDF"]
        shader.inputs["Base Color"].default_value = (*color, 1.0)
        shader.inputs["Metallic"].default_value = metallic
        shader.inputs["Roughness"].default_value = roughness


def add_shape_keys(obj, tags):
    obj.shape_key_add(name="Basis", from_mix=False)
    jaw = obj.shape_key_add(name="jaw_open", from_mix=False)
    mouth = [obj.data.vertices[i].co for i in tags["mouth"]]
    top = max(co.z for co in mouth)
    for i in tags["mouth"]:
        co = obj.data.vertices[i].co
        # Grows downwards from the upper lip to about 3 cm, and a little forwards.
        jaw.data[i].co = Vector((co.x * 1.05, co.y - 0.003, top - (top - co.z) * 4.0 - 0.002))
    blink = obj.shape_key_add(name="blink", from_mix=False)
    for side in (1, -1):
        mine = [i for i in tags["eyes"] if obj.data.vertices[i].co.x * side > 0]
        middle = sum(obj.data.vertices[i].co.z for i in mine) / len(mine)
        for i in mine:
            co = obj.data.vertices[i].co
            blink.data[i].co = Vector((co.x, co.y, middle + (co.z - middle) * 0.12))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    parser.add_argument("--blend", help="also save the .blend here (to look at it in Blender)")
    args = parser.parse_args(argv)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.fps = FPS
    make_materials()
    armature = make_armature()

    builder = Builder(MATERIALS.keys())
    suzanne_head(builder)
    body(builder)
    tags = builder.tags
    monkey = builder.to_object("MonkeyBody", armature)
    add_shape_keys(monkey, tags)
    accessories(armature)
    actions(armature)
    report(armature)

    if args.blend:
        bpy.ops.wm.save_as_mainfile(filepath=args.blend)
    bpy.ops.export_scene.gltf(
        filepath=args.out,
        export_format="GLB",
        export_yup=True,
        export_apply=False,
        export_skins=True,
        export_morph=True,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_force_sampling=True,
        export_frame_range=False,
    )
    print("Wrote", args.out)


main()
