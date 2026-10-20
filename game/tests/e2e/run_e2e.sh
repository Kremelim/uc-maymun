#!/usr/bin/env bash
# End-to-end test: 1 host + (PLAYERS-1) clients run headless on localhost over ENet.
# Passes when every income reached only its owner and everyone heard everyone
# else's (fake) voice through the host, never their own (see e2e_probe.gd).
# Usage: GODOT=/path/to/godot game/tests/e2e/run_e2e.sh
set -uo pipefail

GODOT="${GODOT:-godot}"
PLAYERS="${PLAYERS:-4}"
PORT="${PORT:-17777}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="$(mktemp -d)"
PIDS=()
NAMES=()

run() {
	local name="$1"
	shift
	timeout 60 "$GODOT" --headless --path "$PROJECT_DIR" -- --e2e --fake-voice --port="$PORT" "$@" >"$LOG_DIR/$name.log" 2>&1 &
	PIDS+=("$!")
	NAMES+=("$name")
}

run host --auto-host --auto-start="$PLAYERS" --seed=1234 --name=Host
sleep 1
for i in $(seq 1 $((PLAYERS - 1))); do
	run "client$i" --auto-join --name="Client$i"
done

status=0
for idx in "${!PIDS[@]}"; do
	if ! wait "${PIDS[$idx]}"; then
		echo "${NAMES[$idx]} exited with an error"
		status=1
	fi
done

grep -h "E2E" "$LOG_DIR"/*.log || true
if [ "$status" -ne 0 ]; then
	for f in "$LOG_DIR"/*.log; do
		echo "=== $f"
		cat "$f"
	done
fi
exit "$status"
