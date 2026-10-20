class_name TableState
extends RefCounted
## Authoritative state of one table. Pure logic: no nodes, no networking.
## Only the host owns an instance. Clients see it through public_snapshot()
## and their own private_view(), never the whole thing.

const NOT_DECLARED := -1

var rules: RulesConfig
var seat_count: int
var round_number: int = 0

var _incomes := PackedInt32Array()
var _declarations := PackedInt32Array()


func _init(p_rules: RulesConfig, p_seat_count: int) -> void:
	assert(p_seat_count >= 1 and p_seat_count <= p_rules.max_players, "seat count out of range")
	rules = p_rules
	seat_count = p_seat_count


## Starts a new round: picks an income set and deals it in a seeded, shuffled order.
## With fewer seats than the set has values, the extra values are not dealt.
func deal(rng: RandomNumberGenerator) -> void:
	round_number += 1
	var income_set: PackedInt32Array = rules.income_sets[rng.randi_range(0, rules.income_sets.size() - 1)]
	_incomes = _shuffled(income_set, rng).slice(0, seat_count)
	_declarations = PackedInt32Array()
	_declarations.resize(seat_count)
	_declarations.fill(NOT_DECLARED)


func total_income() -> int:
	var total := 0
	for amount in _incomes:
		total += amount
	return total


func income_of(seat: int) -> int:
	return _incomes[seat]


## Returns false and changes nothing when the declaration is not allowed.
## Declarations can change until the last player declares; then all are revealed and locked.
func declare(seat: int, amount: int) -> bool:
	if seat < 0 or seat >= seat_count:
		return false
	if amount < 0 or amount > total_income():
		return false
	if all_declared():
		return false
	_declarations[seat] = amount
	return true


func all_declared() -> bool:
	return not _declarations.is_empty() and not _declarations.has(NOT_DECLARED)


## Everything every player may see. Must never contain incomes.
## Like the paper slips in the rules, amounts stay hidden until everyone has declared.
func public_snapshot() -> Dictionary:
	var declared: Array = []
	for amount in _declarations:
		declared.append(amount != NOT_DECLARED)
	var snapshot := {
		"round": round_number,
		"total_income": total_income(),
		"declared": declared,
	}
	if all_declared():
		var declared_sum := 0
		for amount in _declarations:
			declared_sum += amount
		snapshot["declarations"] = _declarations.duplicate()
		snapshot["missing"] = total_income() - declared_sum
	return snapshot


## What only the player sitting in `seat` may see, including their own unrevealed declaration.
func private_view(seat: int) -> Dictionary:
	return {"seat": seat, "income": _incomes[seat], "declaration": _declarations[seat]}


## Fisher-Yates with our own RNG: Array.shuffle() uses the global RNG and would break determinism.
static func _shuffled(values: PackedInt32Array, rng: RandomNumberGenerator) -> PackedInt32Array:
	var result := values.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := result[i]
		result[i] = result[j]
		result[j] = swap
	return result
