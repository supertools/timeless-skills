# Timeless Skills

AI agent skill for [Timeless](https://timeless.day) meeting data.

Published on [ClawHub](https://clawhub.ai/eilonmore/timeless).

## What it does

- Search and list meetings, rooms, transcripts, AI summaries
- Upload audio/video recordings for transcription
- Chat with Timeless AI about meeting content
- Capture podcast episodes and YouTube videos into Timeless
- Build automations with cron polling patterns
- Create and manage rooms, add/remove conversations

## Files

| File | Description |
|------|-------------|
| [SKILL.md](SKILL.md) | Main skill file (loaded by OpenClaw agents) |
| [api-reference.md](api-reference.md) | Full Timeless API endpoint documentation |
| [scripts/](scripts/) | Helper scripts for uploads, podcasts, YouTube |

## Setup

Requires `TIMELESS_ACCESS_TOKEN` env var. Get your token at [my.timeless.day/api-token](https://my.timeless.day/api-token).

For YouTube capture, install [yt-dlp](https://github.com/yt-dlp/yt-dlp).

## Install via ClawHub

```bash
npx clawhub install timeless
```
