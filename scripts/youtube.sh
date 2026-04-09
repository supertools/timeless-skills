#!/bin/bash
# Download YouTube video for Timeless upload
# Usage:
#   youtube.sh info URL              - Get video metadata (title, duration, uploader)
#   youtube.sh download URL OUTPUT   - Download video (mp4) to OUTPUT
set -euo pipefail

YTDLP="${YTDLP_PATH:-yt-dlp}"

case "${1:-}" in
  info)
    URL="${2:?Usage: youtube.sh info URL}"
    "$YTDLP" --dump-json --no-download "$URL" 2>/dev/null | node -e "
      let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
        const j=JSON.parse(d);
        console.log('Title: '+j.title);
        console.log('Duration: '+j.duration+'s ('+Math.round(j.duration/60)+'m)');
        console.log('Uploader: '+j.uploader);
        console.log('Upload date: '+j.upload_date);
      })"
    ;;

  download)
    URL="${2:?Usage: youtube.sh download URL OUTPUT}"
    OUTPUT="${3:?}"
    echo "Downloading video from: $URL"
    "$YTDLP" -f "b" -o "$OUTPUT" "$URL" 2>&1 | tail -3
    SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
    echo "Done. Size: ${SIZE}"
    ;;

  *)
    echo "Usage: youtube.sh {info|download} [args...]"
    exit 1
    ;;
esac
