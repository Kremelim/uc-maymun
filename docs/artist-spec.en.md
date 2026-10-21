# Artist spec: monkey character (Üç Maymun)

> Draft, 2026-10-21. English translation of [sanatci-sartnamesi.md](sanatci-sartnamesi.md) (sections 1–9), the version we send to artists.
> The Turkish document is the master; this one follows it.

Üç Maymun ("Three Monkeys") is a four-player online social bluffing game for PC/Steam, made in Godot 4.7.
Four monkeys sit around a card table in a 1970s Istanbul back room. They lie about their income, audit each other and show off the accessories they buy.
- **Style:** stylised cartoon. Bold silhouettes, exaggerated expressions, warm colours.

**Why names matter:** The game finds things in the model **by name**:
- the mouth that opens when a player talks;
- the auditor's hat;
- the crown somebody bought;
- the "caught" animation.

With the names below, a new monkey goes into the game without code changes.

**Reference model:** a free test monkey built to this spec, `test_monkey.glb`.
- Sent with this brief. Open it in Blender with **File → Import → glTF 2.0** to see every name and the hierarchy.

## 1. Deliverables

| File | Notes |
|---|---|
| `maymun_<name>.glb` | One file per monkey: glTF 2.0 binary, textures embedded. All accessories and animations in the same file. |
| `maymun_<name>.blend` | The source file (or the source of the tool you use). |
| Texture sources | Layered files (`.psd`, `.kra`, Substance project, …). |
| Renders | Front, side, back and 3/4, in the A-pose and the seated pose. |

File names: plain ASCII, no spaces (`maymun_kemal.glb`).

## 2. Scale, axes, origin

- **1 unit = 1 metre.** All transforms applied: scale 1, rotation 0 (Blender: Ctrl+A → All Transforms).
- **Facing:** in Blender Z is up and the monkey **faces -Y** (its face is visible in the Front view). Its left hand is on +X.
  - The glTF exporter turns this into glTF's Y-up, +Z-forward.
  - The game turns the monkey as it needs.
- **Origin:** on the floor, between the feet. In the seated animations it lies under the middle of the stool.
- **Height** (standing, A-pose): 0.9–1.7 m, ideally 1.2–1.4 m.
  - Cartoon proportions with a big head.
  - The test monkey is 1.25 m.

## 3. Pose, polygons, materials

- **Rest pose:** A-pose. Arms 35–45° down, palms down, legs slightly apart.
- **Triangles** (one monkey with all its accessories):
  - target **at most 20,000**;
  - hard limit **30,000**.

  Three monkeys are on screen at once and the style is cartoon: shape and colour carry the detail.
- **Materials:** at most 8 recommended.
  - Metallic-roughness PBR or flat colours.
  - Name the main fur material **`fur`**. The game sometimes reuses one model with different fur colours and tints that material.
- **Textures:** at most 2048×2048, preferably 1024–2048. **Do not paint light or shadow into them.** The game adds toon shading and an outline, and baked shading fights with both.
- **Skinning:** at most 4 bone influences per vertex.

## 4. Skeleton

One humanoid armature. Bone names follow Godot's humanoid profile (`SkeletonProfileHumanoid`), so ready-made humanoid animations (Mixamo, Quaternius) can be retargeted.

**Required bones:**

| Body | Left | Right |
|---|---|---|
| `Hips`, `Spine`, `Chest`, `Neck`, `Head` | `LeftUpperArm`, `LeftLowerArm`, `LeftHand` | `RightUpperArm`, `RightLowerArm`, `RightHand` |
| | `LeftUpperLeg`, `LeftLowerLeg`, `LeftFoot` | `RightUpperLeg`, `RightLowerLeg`, `RightFoot` |

**Recommended bones:**
- `UpperChest`;
- `LeftShoulder`, `RightShoulder`;
- `LeftToes`, `RightToes`;
- `Jaw`;
- `LeftEye`, `RightEye`;
- fingers, with the profile's names (e.g. `LeftIndexProximal`).

**Notes:**
- **Extra bones are welcome:** tail (`Tail1`, `Tail2`, …), ears, fur. The game leaves bones it does not know alone.
- **Root bone:** a `Root` bone at the top is fine (the test monkey has one), not required.
- **Mixamo names are accepted** (e.g. `mixamorig:Hips`): we map them on import. Godot names are preferred.
- **No scale keys on bones.**

## 5. Face: mouth and blink

Shape keys in Blender (morph targets in glTF, blend shapes in Godot):

| Name | 0 | 1 | Required |
|---|---|---|---|
| `jaw_open` | Mouth closed | Mouth fully open (widest while talking) | **Yes** |
| `blink` | Eyes open | Both eyes shut | Recommended |

- The game sets these itself, every frame:
  - **mouth:** from the loudness of the player's microphone;
  - **blink:** at random every 2–5.5 seconds.
- So **animations must not key `jaw_open` or `blink`.**
- Reserved for later expressions, optional for now: `smile`, `frown`, `surprised`.

## 6. Accessories and the auditor's hat

Players buy five accessories in the game's shop, and they **show on the monkey**.
- **Visibility:** leave them visible in the file; the game hides them and shows the ones a player owns.
- **Readability:** make them readable from 3 metres away, a little exaggerated.

| Object name | What | How it is attached |
|---|---|---|
| `acc_glasses` | Glasses | Parented to the `Head` bone (Blender: Ctrl+P → Bone) |
| `acc_gloves` | Both gloves, one object | Skinned to the armature, bends with the hands (Armature modifier, `LeftHand`/`RightHand` weights) |
| `acc_watch` | Wristwatch | Parented to `LeftLowerArm`, over the left wrist |
| `acc_chain` | Gold chain with a pendant | Parented to `UpperChest` (or `Chest`) |
| `acc_crown` | Crown | Parented to the `Head` bone |
| `auditor_hat` | **The auditor's hat:** a green accountant's eyeshade (a suggestion; the design is open, but it must read as "the auditor" from afar) | Parented to the `Head` bone |

- **Names exactly as written:** lower case, `acc_` + key.
- **One object per accessory:** join the pieces of an accessory into one object (frame and temples of the glasses, for example).
- **Crown and hat together:** a monkey can wear the crown and the auditor's hat at the same time, so they must not pass through each other.

## 7. Animations

**General rules:**
- **30 fps.**
- **One Blender Action per animation.**
  - Each exports as a separate animation (Actions on NLA tracks, or the exporter's "Actions" mode).
  - Use the names below, lower case.
- **All seated.** The monkey sits on a stool with its forearms on the table's edge:
  - **Stool:** seat **0.44 m** above the floor, centred over the origin.
  - **Table:** top **0.79 m** above the floor, its edge **0.38 m in front** of the monkey (-Y in Blender). The table is round, radius 1 m.
- **Start and end:** one-shot animations start and end in the base seated pose. The game blends them into the idle (0.25 s).
- **No root motion:** the monkey does not slide away. The hips may hop and come back.
- **Key every bone.** Keying every bone in every animation is safest: a bone left unkeyed can stay where the previous animation left it.

**Needed now:**

| Name | Loops | Length | When | What |
|---|---|---|---|---|
| `idle` | Yes | 3–5 s | Always | Breathing, looking around a little, tail sways. |
| `talk` | Yes | 1–2 s | While the player talks | Nods, hand gestures. The mouth does not move (that is `jaw_open`). Recommended. |
| `caught` | No | 1.5–2 s | Caught lying in an audit | Panic: hands to the cheeks, recoil, head shake. |
| `cheer` | No | 1–2 s | Cleared in an audit, the table saved | Joy: arms up, a hop. |
| `slump` | No | 1.5–2 s | Installment missed, the table bankrupt | Disappointment: shoulders drop, head down. |

**Later, for the vertical slice** (names reserved):
- `suspicious` — suspicious look;
- `laugh`;
- `surprised`;
- `point` — pointing at someone;
- `push_coins` — pushing coins;
- `flip_card` — flipping a card;
- `peek_card` — the auditor peeking at a card;
- the three wise monkeys: `see_no_evil`, `hear_no_evil`, `speak_no_evil`.

## 8. Export (Blender 4.x)

**File → Export → glTF 2.0 (.glb/.gltf):**

| Section | Setting |
|---|---|
| Format | glTF Binary (.glb) |
| Include | All objects (Selected Objects off) |
| Transform | +Y Up on |
| Data → Mesh | Apply Modifiers **off** (it drops shape keys). UVs and Normals on. |
| Data → Shape Keys | On |
| Data → Armature | Deform bones only off, so extra bones (tail) are kept. |
| Data → Skinning | On |
| Animation | On. Mode: **Actions**. Always Sample Animations on. |

## 9. Rights

- **Rights:** all commercial rights in the commissioned work pass to the team (work for hire). It is used in the game, on the store page, in trailers and in marketing.
- **Third-party content:** none unless its licence is stated (textures, brushes, model parts).
- **AI:** tell us if you used it. Steam requires AI-generated content that ships in the game to be disclosed.
- **Credits:** the artist is credited in the game (unless they prefer not to be).
