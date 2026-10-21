class_name MonkeyCast
extends Resource
## Who sits where: a body (an imported monkey model) and a fur tint for every seat, and
## the look. Bringing in the real monkeys means editing the cast in the inspector
## (res://assets/monkeys/cast.tres), not code.

## Seat N gets bodies[N % size]: one model is enough while there is only the test monkey.
@export var bodies: Array[PackedScene] = []
## Multiplies the colour of the "fur" material, so monkeys with the same body differ.
@export var fur_tints: Array[Color] = []
## Toon light and an outline (style A in docs/m3-plan.md), or the model's own materials.
@export var toon := true


func body_for(seat: int) -> PackedScene:
	return bodies[seat % bodies.size()]


func tint_for(seat: int) -> Color:
	return Color.WHITE if fur_tints.is_empty() else fur_tints[seat % fur_tints.size()]
