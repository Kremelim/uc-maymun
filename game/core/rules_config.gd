class_name RulesConfig
extends Resource
## Tunable game numbers. Values live in data/*.tres and mirror docs/gdd/;
## logic must read them from here instead of hard-coding them.

@export var max_players: int = 4
## Lower than the design's 4 so the spike can be tested with fewer people.
@export var min_players: int = 2
@export var round_count: int = 4
## One income per seat. Players learn only a set's total, never who got what.
@export var income_sets: Array[PackedInt32Array] = []
