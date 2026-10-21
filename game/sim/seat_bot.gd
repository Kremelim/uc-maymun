class_name SeatBot
extends RefCounted
## Plays one seat of an online night with a SimBot's decisions. It reads only that
## seat's view (Night.view_for) and answers with the intents a player would send,
## so the host can run it for an empty seat and the e2e test for a whole client.
## Each decision is taken once per phase, in MatchRunner's order: a night played
## online by these bots ends exactly like the same matches in the simulator.
## Bots never offer or take bribes online: that needs talking.

const NONE := MatchState.NONE

var seat: int
var bot: SimBot

var _rules: RulesConfig
var _night_seed: int
var _match_index := -1
var _done := []  # [match_index, round, phase] already answered


func _init(kind: String, p_seat: int, p_rules: RulesConfig, p_night_seed: int) -> void:
	seat = p_seat
	bot = SimBot.preset(kind)
	bot.corruptible = false
	bot.offers_bribes = false
	_rules = p_rules
	_night_seed = p_night_seed


## What to send for this view; empty when nothing is expected from this seat.
func intents(view: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if view["night_over"]:
		return result
	if view["match_index"] != _match_index:
		_match_index = view["match_index"]
		bot.prepare(_rules, Night.match_seed_of(_night_seed, _match_index), seat)
	var here := [view["match_index"], view["round"], view["phase"]]
	if here == _done:
		return result
	var auditing: bool = view["auditor"] == seat
	match int(view["phase"]):
		MatchState.Phase.DECLARE:
			if view["my_declaration"] == NONE:
				result.append({"type": "declare", "amount": bot.declare(view)})
		MatchState.Phase.NEGOTIATE:
			var target := bot.vouch_target(view)  # asked even in basic matches, as MatchRunner does
			if target != NONE and not view["basic"]:
				result.append({"type": "vouch", "target": target})
			result.append({"type": "ready"})
		MatchState.Phase.CONTRIBUTE:
			if view["my_extra"] == NONE:
				result.append({"type": "contribute", "extra": bot.contribution(view)})
		MatchState.Phase.AUDIT_CHOOSE:
			if auditing:
				result.append({"type": "choose", "target": bot.choose_audit_target(view)})
		MatchState.Phase.AUDIT_DECIDE:
			if auditing:
				result.append({"type": "decide", "report": true})
		MatchState.Phase.SHOP:
			for item: int in bot.shopping_list(view):
				result.append({"type": "buy", "item": item})
			result.append({"type": "ready"})
		MatchState.Phase.MATCH_OVER:
			result.append({"type": "ready"})
	if not result.is_empty():
		_done = here
	return result
