#!/bin/bash
# Upload a local audio/video file to Timeless for transcription
# Usage: upload.sh FILE_PATH LANGUAGE [TITLE]
# Requires: TIMELESS_ACCESS_TOKEN env var
set -euo pipefail

FILE="${1:?Usage: upload.sh FILE_PATH LANGUAGE [TITLE]}"
LANG="${2:?Usage: upload.sh FILE_PATH LANGUAGE [TITLE]}"
TITLE="${3:-$(basename "$FILE" | sed 's/\.[^.]*$//')}"
TOKEN="${TIMELESS_ACCESS_TOKEN:?TIMELESS_ACCESS_TOKEN not set}"
BASE="https://my.timeless.day"

FILENAME=$(basename "$FILE")
EXT="${FILENAME##*.}"

case "$EXT" in
  mp3) MIME="audio/mpeg" ;;
  wav) MIME="audio/wav" ;;
  m4a) MIME="audio/mp4" ;;
  mp4) MIME="video/mp4" ;;
  webm) MIME="audio/webm" ;;
  ogg) MIME="audio/ogg" ;;
  *) echo "Unsupported format: $EXT"; exit 1 ;;
esac

# Step 1: Presigned URL
echo "Getting upload URL..."
PRESIGN=$(curl -s -X POST "$BASE/api/v1/conversation/storage/presigned-url/" \
  -H "Authorization: Token $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"file_name\": \"$FILENAME\", \"file_type\": \"$MIME\"}")
URL=$(echo "$PRESIGN" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).url))")

# Step 2: Upload
echo "Uploading $FILENAME..."
curl -s -X PUT "$URL" -H "Content-Type: $MIME" --upload-file "$FILE" > /dev/null

# Step 3: Process
echo "Processing..."
RESULT=$(curl -s -X POST "$BASE/api/v1/conversation/process/media/" \
  -H "Authorization: Token $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"language\": \"$LANG\", \"filename\": \"$TITLE\"}")

SPACE=$(echo "$RESULT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>console.log(JSON.parse(d).space_uuid))")
echo "Uploaded. Space UUID: $SPACE"
echo "Poll https://my.timeless.day/api/v1/spaces/$SPACE/ until is_processing=false"
