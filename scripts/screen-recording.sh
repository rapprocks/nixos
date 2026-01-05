#!/usr/bin/env bash

OUTPUT_DIR="$HOME/Videos/screenrecordings"

# Check if we're being called in indicator mode (by waybar exec)
if [[ "$1" == "--indicator" ]] || [[ "$1" == "-i" ]]; then
  if pgrep -x wf-recorder >/dev/null; then
    echo '{"text": "󰻂", "tooltip": "Stop recording", "class": "active"}'
  else
    echo '{"text": ""}'
  fi
  exit 0
fi

# Normal mode: toggle recording
if [[ ! -d "$OUTPUT_DIR" ]]; then
  notify-send "Screen recording directory does not exist: $OUTPUT_DIR" -u critical -t 3000
  exit 1
fi

filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"

toggle_indicator() {
  pkill -RTMIN+8 waybar
}

stop_screenrecording() {
  pkill -x wf-recorder
  notify-send "Screen recording saved to $OUTPUT_DIR" -t 2000
  sleep 0.2
  toggle_indicator
}

screenrecording_active() {
  pgrep -x wf-recorder >/dev/null
}

start_screenrecording() {
  region=$(slurp) || exit 1
  wf-recorder -g "$region" -f "$filename" -c libx264 -p crf=23 -p preset=medium -p movflags=+faststart &
  toggle_indicator
}

if screenrecording_active; then
  stop_screenrecording
else
  start_screenrecording
fi