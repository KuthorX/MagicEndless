#!/bin/sh
# Renders the score and the SFX hits with the shared audiokit renderer (offline, no playback).
# Holds the shared render lock for the whole batch so parallel jobs on this machine serialise.
# Usage: tools/audio/render_all.sh [cue ...]   (default: every spec in tools/audio/build)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
PY="arch -arm64 /tmp/audiokit/venv/bin/python"
$PY "$HERE/compose.py"
$PY "$HERE/gen_sfx.py" hits
if [ $# -eq 0 ]; then set -- menu battle_base battle_war boss gameover sfx_hits; fi
specs=""
for c in "$@"; do specs="$specs $HERE/build/$c.json"; done
exec lockf -t 3600 /tmp/audiokit/render.lock sh -c '
  for s in "$@"; do
    echo "== $s"
    arch -arm64 /tmp/audiokit/venv/bin/python /tmp/audiokit/render.py "$s" || exit 1
  done' sh $specs
