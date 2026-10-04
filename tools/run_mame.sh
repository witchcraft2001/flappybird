#!/bin/sh
# run_mame.sh -- MAME "sprinter" with the DSS system disk and the FBIRD floppy image on B:.
#   run_mame.sh run  IMAGE         interactive window (make run)
#   run_mame.sh test IMAGE SYM     scripted autotest of the AUTOTEST build (make test-emulator)
#
# The DSS system CHD goes on -hard1 through a diff, so the template is never modified; the game
# image goes on -flop2 (-beta:wd179x:1 35hd is required for it).
set -eu
MODE=${1:?usage: run_mame.sh run|test IMAGE [SYM]}
IMAGE=${2:?image}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
abspath() { case $1 in /*) printf '%s' "$1" ;; *) printf '%s/%s' "$PWD" "$1" ;; esac; }
IMAGE=$(abspath "$IMAGE")
MAME_DIR=${MAME_DIR:-/Users/dmitry/dev/zx/sprinter/mame_images/mame_release_v306_25.05.2025}
MAME=${MAME:-$MAME_DIR/mame}
DSS_IMAGE=${DSS_IMAGE:-$MAME_DIR/IMG/sp_hdd_sys.chd}
PYTHON=${PYTHON:-python3}
OUT=${FB_OUT:-$ROOT/build/autotest}
WORK=$OUT/mame

COMMON="-skip_gameinfo -bios v3.06 -rompath $MAME_DIR/roms -cfg_directory $WORK/cfg -nvram_directory $WORK/nvram \
 -hard1 $DSS_IMAGE -diff_directory $WORK/diff -beta:wd179x:1 35hd -flop2 $IMAGE"

mkdir -p "$WORK/cfg" "$WORK/nvram"
rm -rf "$WORK/diff"; mkdir -p "$WORK/diff"

case $MODE in
run)
	# shellcheck disable=SC2086
	cd "$MAME_DIR" && exec "$MAME" sprinter $COMMON -window -nofilter -video opengl ${MAME_EXTRA:-}
	;;
test)
	SYM=$(abspath "${3:?symbol file}")
	rm -f "$OUT"/report.txt "$OUT"/*.png "$OUT"/*.act "$OUT"/*.exp
	# no throttle: emulated time is what the script measures; no video/sound output needed
	# shellcheck disable=SC2086
	( cd "$MAME_DIR" && FB_SYM="$SYM" FB_OUT="$OUT" FB_ASSETS="$ROOT/src/assets" FB_PALETTE="$ROOT/src/res_pal.asm" \
	  "$MAME" sprinter $COMMON -video none -sound none -nothrottle -snapshot_directory "$OUT" ${MAME_EXTRA:-} \
	  -autoboot_script "$ROOT/tools/mame_fbird.lua" -seconds_to_run "${SECONDS_TO_RUN:-1200}" ) >"$OUT/mame.log" 2>&1 || true
	rmdir "$OUT/sprinter" 2>/dev/null || true
	# mismatching frames: actual | expected | difference
	"$PYTHON" "$ROOT/tools/autotest_png.py" "$OUT" "$ROOT/src/res_pal.asm"
	cat "$OUT/report.txt" 2>/dev/null || { echo "no report produced; see $OUT/mame.log"; exit 1; }
	grep -q '^RESULT: PASS' "$OUT/report.txt"
	;;
*)
	echo "unknown mode $MODE" >&2; exit 2 ;;
esac
