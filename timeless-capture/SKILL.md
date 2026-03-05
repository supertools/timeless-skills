---
name: timeless-capture
description: Capture podcast episodes and YouTube videos into Timeless for transcription. Use when the user wants to save a podcast episode, YouTube video, or any audio/video URL to Timeless. Supports adding captured content to Timeless rooms for organized collections (e.g., product podcasts, investing talks). Requires TIMELESS_ACCESS_TOKEN env var. Requires yt-dlp for YouTube.
---

# Timeless Capture

> **Source**: [github.com/supertools/timeless-skills](https://github.com/supertools/timeless-skills) — pull the latest if this skill seems outdated.

Download podcast episodes or YouTube videos and upload them to Timeless for transcription and AI processing.

## Prerequisites

- `TIMELESS_ACCESS_TOKEN` env var (get token at [my.timeless.day/api-token](https://my.timeless.day/api-token))
- `yt-dlp` for YouTube downloads (install: `curl -sL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && chmod +x /usr/local/bin/yt-dlp`)

## Scripts

- `scripts/podcast.sh` — Search, list, and download podcast episodes
- `scripts/youtube.sh` — Get info and download YouTube video or audio
- `scripts/upload.sh` — Upload any audio/video file to Timeless

## Podcast Workflow

1. **Search**: `bash <skill-dir>/scripts/podcast.sh search "podcast name"`
2. **List episodes**: `bash <skill-dir>/scripts/podcast.sh episodes FEED_URL [limit]`
3. **Download**: `bash <skill-dir>/scripts/podcast.sh download MP3_URL /tmp/episode.mp3`
4. **Upload to Timeless**: `bash <skill-dir>/scripts/upload.sh /tmp/episode.mp3 en "Episode Title"`
5. Clean up the file from /tmp

### Spotify links

Extract the episode title via oEmbed, then search by name:
```bash
curl -s "https://open.spotify.com/oembed?url=SPOTIFY_URL"
```

## YouTube Workflow

1. **Get info**: `bash <skill-dir>/scripts/youtube.sh info "YOUTUBE_URL"`
2. **Download video**: `bash <skill-dir>/scripts/youtube.sh download "YOUTUBE_URL" /tmp/video.mp4`
3. **Upload to Timeless**: `bash <skill-dir>/scripts/upload.sh /tmp/video.mp4 en "Video Title"`
4. Clean up the file from /tmp

Downloads as mp4 (video+audio). No ffmpeg needed.

**Note:** Video download uses the best pre-muxed format (no ffmpeg needed). This is typically 720p, which is fine for Timeless.

## Adding to a Room

After uploading, attach the content to a Timeless room for organized collections. See `../api-reference.md` for the room and resource endpoints.

1. Upload returns a `space_uuid`. Poll `GET /api/v1/spaces/{space_uuid}/` until `is_processing=false`.
2. From the space response, get the `conversation.uuid`.
3. Add to room: `POST /api/v1/spaces/{room_uuid}/resources/` with `{"resource_type": "CONVERSATION", "resource_uuid": "CONV_UUID"}`

To create a new room first: `POST /api/v1/spaces/` with `{"has_onboarded": true, "space_type": "ROOM", "title": "My Collection"}`

## Notes

- Podcast MP3s can be large (100-300MB for long episodes). Downloads may take a minute.
- YouTube downloads require yt-dlp. If not installed, the script will fail with a clear error.
- Always clean up downloaded files from /tmp after uploading.
- Set `YTDLP_PATH` env var if yt-dlp is not on PATH.
