#!/usr/bin/env bash
# End-to-end test: 1 host + (PLAYERS-1) clients run headless on localhost over ENet,
# and the host seats bots in the rest of the table. Each person's seat is played by
# a bot through the network. Passes when the whole night ends exactly as in the
# simulator, every view reached only its own seat, and everyone heard everyone
# else's (fake) voice through the host, never their own (see e2e_probe.gd).
# With LEAVER=1 the first client walks out when the second match starts: the host must
# seat a bot in its place and finish the night with the others.
# Usage: GODOT=/path/to/godot [PLAYERS=3] [LEAVER=1] game/tests/e2e/run_e2e.sh
set -uo pipefail

GODOT="${GODOT:-godot}"
PLAYERS="${PLAYERS:-3}"
LEAVER="${LEAVER:-0}"
SEED="${SEED:-1234}"
# One bot type per person (host first) and per host bot; kinds that do not bribe.
KINDS=(açgözlü dürüst bedavacı kinci)
PORT="${PORT:-17777}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="$(mktemp -d)"
PIDS=()
NAMES=()

run() {
	local name="$1"
	shift
	timeout 90 "$GODOT" --headless --path "$PROJECT_DIR" -- --e2e --fake-voice --port="$PORT" --seed="$SEED" "$@" >"$LOG_DIR/$name.log" 2>&1 &
	PIDS+=("$!")
	NAMES+=("$name")
}

BOT_KINDS=$(IFS=,; echo "${KINDS[*]:$PLAYERS}")
run host --auto-host --auto-start="$PLAYERS" --name=Host --e2e-kind="${KINDS[0]}" --bot-kinds="$BOT_KINDS" --bot-delay=0 --e2e-leavers="$LEAVER"
sleep 1
for i in $(seq 1 $((PLAYERS - 1))); do
	leave=()
	if [ "$i" -le "$LEAVER" ]; then
		leave=(--e2e-leave-at-match=1)
	fi
	run "client$i" --auto-join --name="Client$i" --e2e-kind="${KINDS[$i]}" "${leave[@]}"
done

status=0
for idx in "${!PIDS[@]}"; do
	if ! wait "${PIDS[$idx]}"; then
		echo "${NAMES[$idx]} exited with an error"
		status=1
	fi
done

grep -h "E2E" "$LOG_DIR"/*.log || true
# A passing run must also be a clean one: engine errors or leak warnings fail it too.
if grep -H -E "^(ERROR|SCRIPT ERROR)|ObjectDB instances were leaked" "$LOG_DIR"/*.log; then
	echo "engine errors or leaks in the logs above"
	status=1
fi
if [ "$status" -ne 0 ]; then
	for f in "$LOG_DIR"/*.log; do
		echo "=== $f"
		cat "$f"
	done
fi
exit "$status"
