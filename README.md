# Timeless Skills

AI agent skills for [Timeless](https://timeless.day) meeting data.

Published on [ClawHub](https://clawhub.ai/eilonmore/timeless).

## What it does

- Search and list meetings, rooms, transcripts, AI summaries
- Upload audio/video recordings for transcription
- Chat with Timeless AI about meeting content
- Capture podcast episodes and YouTube videos into Timeless
- Schedule meetings with productivity-first slot selection and curated invite links
- Build automations with cron polling patterns
- Create and manage rooms, add/remove conversations

## Skills

| Skill | Description |
|-------|-------------|
| [timeless-api](timeless-api/SKILL.md) | Meetings, rooms, transcripts, capture, automation |
| [timeless-scheduling](timeless-scheduling/SKILL.md) | Meeting scheduling with smart slot selection |

## Shared Files

| File | Description |
|------|-------------|
| [api-reference.md](api-reference.md) | Full Timeless API endpoint documentation |
| [scripts/](scripts/) | Helper scripts for uploads, podcasts, YouTube |

## Setup

Requires `TIMELESS_ACCESS_TOKEN` env var. Get your token at [my.timeless.day/api-token](https://my.timeless.day/api-token).

For YouTube capture, install [yt-dlp](https://github.com/yt-dlp/yt-dlp).

## Install via ClawHub

```bash
npx clawhub install timeless
```
