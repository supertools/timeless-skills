#!/bin/bash
# Upload a local audio/video file to Timeless for transcription
# Usage: upload.sh FILE_PATH LANGUAGE [TITLE]
# Requires: TIMELESS_ACCESS_TOKEN env var
#
# Uses the official Timeless API (single PUT request).
set -euo pipefail

FILE="${1:?Usage: upload.sh FILE_PATH LANGUAGE [TITLE]}"
LANG="${2:?Usage: upload.sh FILE_PATH LANGUAGE [TITLE]}"
TITLE="${3:-$(basename "$FILE" | sed 's/\.[^.]*$//')}"
TOKEN="${TIMELESS_ACCESS_TOKEN:?TIMELESS_ACCESS_TOKEN not set}"
BASE="https://api.timeless.day/v1"

FILENAME=$(basename "$FILE")
EXT="${FILENAME##*.}"

case "$EXT" in
  mp3) MIME="audio/mpeg" ;;
  wav) MIME="audio/wav" ;;
  m4a) MIME="audio/mp4" ;;
  mp4) MIME="video/mp4" ;;
  webm) MIME="audio/webm" ;;
  ogg) MIME="audio/ogg" ;;
  aac) MIME="audio/aac" ;;
  flac) MIME="audio/flac" ;;
  mov) MIME="video/quicktime" ;;
  *) echo "Unsupported format: $EXT"; exit 1 ;;
esac

ENCODED_TITLE=$(node -e "console.log(encodeURIComponent(process.argv[1]))" "$TITLE")

echo "Uploading $FILENAME..."
RESULT=$(curl -s -X PUT "$BASE/meetings/upload?title=$ENCODED_TITLE&language=$LANG" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: $MIME" \
  --data-binary @"$FILE")

MEETING_ID=$(echo "$RESULT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).id))")
STATUS=$(echo "$RESULT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).status || 'unknown'))")

echo "Uploaded. Meeting ID: $MEETING_ID (status: $STATUS)"
echo "Poll https://api.timeless.day/v1/meetings?id=$MEETING_ID until status=completed"
