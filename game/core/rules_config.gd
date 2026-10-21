class_name RulesConfig
extends Resource
## Tunable game numbers. Values live in data/*.tres and mirror docs/gdd/;
## logic must read them from here instead of hard-coding them.
## Defaults are rules v0.1; data/rules_v0_3.tres holds the current rules.

@export var max_players: int = 4
## With two players the known total gives away the other player's income.
@export var min_players: int = 3
## Spike lobby only, so two people can test networking and voice. Goes away
## when the full rules move into the game (M2).
@export var spike_min_players: int = 2
@export var round_count: int = 4
## One income per seat. Players learn only a set's total, never who got what.
@export var income_sets: Array[PackedInt32Array] = []

@export_group("Debt")
## Due every round. A shortfall carries over with interest; a surplus counts towards the next one.
@export var installment: int = 12
@export var shortfall_interest: float = 1.5

@export_group("Audit")
## A caught liar returns what they hid and pays the difference times this (rounded up)
## as a fine to the auditor.
@export var fine_multiplier: float = 1.0
## The auditor pays this to someone they audited and called clean.
@export var audit_compensation: int = 1
## Paid by the bank to everyone who vouched for a player called clean.
@export var vouch_reward: int = 2
## Declaring more than you got counts as a lie too.
@export var over_declaration_is_lie: bool = true
## On in v0.2: the auditor's income card is shown, so the round nobody can audit
## them stops being a free lie (docs/sim/bulgular-v0.1.md).
@export var auditor_card_open: bool = false
## On in v0.3: a payment to another player that neither cash nor accessories can cover
## becomes an IOU (senet), settled at Hesap Günü, instead of joining the common debt.
@export var unpaid_becomes_iou: bool = false

@export_group("Contributions")
## 0.6 in v0.2: everyone pays this share of what they declared (rounded up, or all
## their cash) when the declarations are revealed, so declaring honestly and paying
## little stops paying off.
@export var min_contribution_ratio: float = 0.0

@export_group("Shop")
@export var accessory_names := PackedStringArray()
@export var accessory_prices := PackedInt32Array()
## What each accessory is worth at the end: a status bonus over its price.
@export var accessory_values := PackedInt32Array()
## Whether the shop opens after the last round's audit too. Off in v0.2: with no
## audit left, buying is a free bonus rather than a risk.
@export var last_round_shop: bool = true

@export_group("Scoring")
## Night score per match by placement, when the table survives. A sunk table scores 0 for all.
@export var placement_points := PackedInt32Array([5, 3, 2, 1])
## 4 in v0.3: with rotate_first_auditor everyone audits first once a night.
@export var matches_per_night: int = 3
## On in v0.3: each new match of a night, the first auditor moves one seat on.
@export var rotate_first_auditor: bool = false
