#!/bin/sh
# Prints duration, integrated LUFS and true peak for each audio file given (no playback).
# Usage: tools/audio/analyze.sh assets/audio/music/*.mp3 assets/audio/sfx/*.wav
for f in "$@"; do
  dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$f")
  # pad short files with silence so the 400 ms gating window sees the whole sound
  stats=$(ffmpeg -nostats -hide_banner -i "$f" -af "apad=pad_dur=0.5,ebur128=peak=true" -f null - 2>&1 | \
    awk '/Integrated loudness/{s=1} s&&/I:/{i=$2} s&&/Peak:/{p=$2} END{print i, p}')
  printf '%-34s %7.2fs  I=%6s LUFS  TP=%6s dBTP\n' "$(basename "$f")" "$dur" $stats
done
