---
name: timeless-api
description: Query and manage Timeless meetings, rooms, transcripts, and AI documents. Capture podcast episodes and YouTube videos into Timeless for transcription. Use when the user asks about their meetings, wants to search meetings, read transcripts, get summaries, list rooms, create rooms, add/remove conversations from rooms, resolve Timeless share links, upload recordings, chat with Timeless AI about meeting content, or capture podcasts/YouTube videos.
version: 2.0.0
metadata:
  timelesssquads:
    requires:
      env:
        - TIMELESS_ACCESS_TOKEN
      bins:
        - curl
        - node
      anyBins:
        - yt-dlp
    primaryEnv: TIMELESS_ACCESS_TOKEN
    emoji: "\u23F0"
    homepage: https://github.com/supertools/timeless-skills
---

# Timeless API

> **Source**: [github.com/supertools/timeless-skills](https://github.com/supertools/timeless-skills)

Interact with [Timeless](https://timeless.day) meeting data: search meetings, read transcripts, get AI summaries, browse rooms, upload recordings, chat with the AI agent, and capture podcasts/YouTube videos for transcription.

## API Reference

For full endpoint documentation with response schemas, status enums, and detailed examples, read `../api-reference.md`.

## Prerequisites

- `TIMELESS_ACCESS_TOKEN` env var (get token at [my.timeless.day/api-token](https://my.timeless.day/api-token))
- `yt-dlp` for YouTube downloads (install via package manager: `apt install yt-dlp`, `brew install yt-dlp`, or `pip install yt-dlp`. Alternatively set `YTDLP_PATH` to point to an existing binary.)

Set up in TimelessSquads:
```bash
timelesssquads config patch env.vars.TIMELESS_ACCESS_TOKEN=<your_token>
```

## API Endpoints

This skill uses **two APIs**:

| API | Base URL | Auth Header | Used For |
|-----|----------|-------------|----------|
| **Official API** | `https://api.timeless.day/v1` | `Authorization: Bearer $TIMELESS_ACCESS_TOKEN` | Meetings, rooms, transcripts, recordings, documents, uploads, webhooks |
| **Unofficial API** | `https://my.timeless.day` | `Authorization: Token $TIMELESS_ACCESS_TOKEN` | Space details, AI chat, room management, scheduling, share URL resolution |

The same token works with both APIs. The official API uses `Bearer` scheme; the unofficial API uses `Token` scheme.

### Pagination

- **Official API**: Cursor-based. Response: `{ data: [...], next_cursor: "...", has_more: true }`. Pass `cursor` and `limit` (1-100, default 25).
- **Unofficial API**: Page-based. Response: `{ count, next, previous, results: [...] }`. Pass `page` and `per_page`.

### Resource IDs

The official API uses prefixed IDs: `mtg_` (meetings), `room_` (rooms), `doc_` (documents), `usr_` (users), `spk_` (speakers), `whk_` (webhooks).

The unofficial API uses raw UUIDs. When crossing between APIs, the underlying UUID is the same (strip or add the prefix).

---

## Operations — Official API

### 1. List Meetings

```
GET https://api.timeless.day/v1/meetings
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `scope` | string | `all` (default), `owned`, or `shared` |
| `status` | string | `completed`, `processing`, `scheduled`, `failed` |
| `search` | string | Search by meeting title (substring match) |
| `q` | string | Semantic search across meeting content |
| `start_date` | string | From date (YYYY-MM-DD) |
| `end_date` | string | To date (YYYY-MM-DD) |
| `participant` | string | Filter by participant name or email |
| `company` | string | Filter by company name or domain |
| `room_id` | string | Filter by room ID (e.g., `room_abc123`) |
| `id` | string | Filter by meeting ID(s). Repeat for multiple: `?id=mtg_abc&id=mtg_def` |
| `expand` | string | `documents` to include documents inline |
| `cursor` | string | Pagination cursor from previous response |
| `limit` | integer | Results per page (1-100, default 25) |

```bash
curl -s "https://api.timeless.day/v1/meetings?scope=owned&status=completed&limit=50" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

**Response:**
```json
{
  "data": [
    {
      "id": "mtg_abc123",
      "title": "Weekly Standup",
      "status": "completed",
      "source": "google_meet",
      "start_time": "2026-03-03T10:00:00Z",
      "end_time": "2026-03-03T10:45:00Z",
      "duration": 2700,
      "host": { "id": "usr_def456", "name": "Alice Johnson", "email": "alice@co.com" },
      "participants": [
        { "name": "Bob Smith", "email": "bob@co.com", "title": "Engineer", "company": "Acme Corp" }
      ],
      "created_at": "2026-03-03T09:55:00Z"
    }
  ],
  "next_cursor": "eyJjcmV...",
  "has_more": true
}
```

**Key fields:**
- `id` = meeting ID (for Get Transcript, Get Recording, Get Document)
- Use `scope=all` to get both owned and shared meetings in one call

> **Semantic search**: Use `q=quarterly review` to find meetings by content relevance, not just title.

---

### 2. List Rooms

```
GET https://api.timeless.day/v1/rooms
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `scope` | string | `all` (default), `owned`, or `shared` |
| `search` | string | Search by room title |
| `id` | string | Filter by room ID(s) |
| `expand` | string | `documents`, `meetings` (can pass both) |
| `cursor` | string | Pagination cursor |
| `limit` | integer | Results per page (1-100, default 25) |

```bash
curl -s "https://api.timeless.day/v1/rooms?scope=owned&expand=meetings" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

**Response:**
```json
{
  "data": [
    {
      "id": "room_abc123",
      "title": "Project Alpha",
      "created_at": "2026-02-15T14:00:00Z",
      "updated_at": "2026-03-03T10:30:00Z",
      "meeting_count": 42,
      "meetings": [
        { "id": "mtg_abc123", "title": "Weekly standup", "status": "completed", "source": "google_meet", "start_time": "2026-03-03T10:00:00Z", "duration": 1800 }
      ]
    }
  ],
  "next_cursor": null,
  "has_more": false
}
```

---

### 3. Get Transcript

```
GET https://api.timeless.day/v1/meetings/{meeting_id}/transcript
```

```bash
curl -s "https://api.timeless.day/v1/meetings/mtg_abc123/transcript" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

**Response:**
```json
{
  "meeting_id": "mtg_abc123",
  "language": "en",
  "speakers": [
    { "id": "spk_001", "name": "Alice Johnson" },
    { "id": "spk_002", "name": "Bob Smith" }
  ],
  "segments": [
    { "speaker_id": "spk_001", "start_time": 0.5, "end_time": 3.2, "text": "Good morning everyone, let's get started." },
    { "speaker_id": "spk_002", "start_time": 3.5, "end_time": 5.8, "text": "I'll share the roadmap updates." }
  ]
}
```

**How to get meeting_id:**
- From List Meetings: `id` field

**Format as readable text** by mapping `speaker_id` to speaker names:
```
[00:00:00] Alice Johnson: Good morning everyone