---
name: timeless-api
description: Query and manage Timeless meetings, rooms, transcripts, and AI documents. Capture podcast episodes and YouTube videos into Timeless for transcription. Use when the user asks about their meetings, wants to search meetings, read transcripts, get summaries, list rooms, create rooms, add/remove conversations from rooms, resolve Timeless share links, upload recordings, chat with Timeless AI about meeting content, or capture podcasts/YouTube videos.
version: 2.0.0
metadata:
  openclaw:
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

Official API docs: [docs.timeless.day](https://docs.timeless.day/)

## Prerequisites

- `TIMELESS_ACCESS_TOKEN` env var (get token at [my.timeless.day/api-token](https://my.timeless.day/api-token))
- `yt-dlp` for YouTube downloads (install via package manager: `apt install yt-dlp`, `brew install yt-dlp`, or `pip install yt-dlp`. Alternatively set `YTDLP_PATH` to point to an existing binary.)

Set up in OpenClaw:
```bash
openclaw config patch env.vars.TIMELESS_ACCESS_TOKEN=<your_token>
```

## Base URLs

This skill uses two APIs. Prefer the official API when available.

**Official API** (meetings, rooms, transcripts, recordings, documents, uploads, webhooks):
```
https://api.timeless.day/v1
Authorization: Bearer $TIMELESS_ACCESS_TOKEN
```

**Unofficial API** (spaces, AI chat, room management, scheduling, share URLs):
```
https://my.timeless.day
Authorization: Token $TIMELESS_ACCESS_TOKEN
```

> The same `TIMELESS_ACCESS_TOKEN` works for both. The header format differs: `Bearer` for official, `Token` for unofficial.

---

## Operations

### 1. List Meetings

```
GET https://api.timeless.day/v1/meetings
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `scope` | string | `all` (default), `owned`, or `shared` |
| `search` | string | Search by meeting title (substring match) |
| `q` | string | Semantic search across meeting content |
| `start_date` | string | From date (YYYY-MM-DD) |
| `end_date` | string | To date (YYYY-MM-DD) |
| `status` | string | `completed`, `processing`, `scheduled`, `failed` |
| `participant` | string | Filter by participant name or email |
| `company` | string | Filter by company name or domain |
| `room_id` | string | Filter by room ID (e.g. `room_abc123`) |
| `expand` | string | `documents` to include AI documents inline |
| `limit` | integer | Results per page, 1-100 (default: 25) |
| `cursor` | string | Pagination cursor from previous response |

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
      "title": "Weekly standup",
      "status": "completed",
      "source": "google_meet",
      "start_time": "2025-01-15T10:00:00Z",
      "end_time": "2025-01-15T10:30:00Z",
      "duration": 1800,
      "host": { "id": "usr_def456", "name": "Alice Johnson", "email": "alice@example.com" },
      "participants": [
        { "name": "Bob Smith", "email": "bob@example.com", "title": "Engineer", "company": "Acme Corp" }
      ],
      "created_at": "2025-01-15T10:00:00Z"
    }
  ],
  "next_cursor": "eyJjcmVhdGVkX2F0Ijo...",
  "has_more": true
}
```

**Key fields:**
- `id` = meeting ID (use for Get Transcript, Get Recording, Get Document)
- Use `scope=all` to get both owned and shared meetings in one call

**Pagination:** pass `next_cursor` as `cursor` param to get the next page. Repeat while `has_more` is `true`.

---

### 2. List Rooms

```
GET https://api.timeless.day/v1/rooms
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `scope` | string | `all` (default), `owned`, or `shared` |
| `search` | string | Search by room title |
| `expand` | string | `documents`, `meetings`, or both (`expand=documents&expand=meetings`) |
| `limit` | integer | Results per page, 1-100 (default: 25) |
| `cursor` | string | Pagination cursor from previous response |

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
      "title": "Engineering standups",
      "created_at": "2025-01-01T00:00:00Z",
      "updated_at": "2025-01-15T10:30:00Z",
      "meeting_count": 42,
      "meetings": [
        { "id": "mtg_abc123", "title": "Weekly standup", "status": "completed", "source": "google_meet", "start_time": "2025-01-15T10:00:00Z", "duration": 1800 }
      ]
    }
  ],
  "next_cursor": null,
  "has_more": false
}
```

---

### 3. Get Space (Meeting or Room Details) — Unofficial API

> This endpoint uses the **unofficial API** (`https://my.timeless.day`) and returns rich data not available via the official API: conversations, artifacts, contacts, organizations, and AI chat threads.

Spaces have three access levels. **Try in order until one succeeds:**

#### 3a. Private Space (your own)

```bash
curl -s "https://my.timeless.day/api/v1/spaces/{uuid}/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN"
```

#### 3b. Workspace Space (shared within team)

> **`host_uuid` is required** for shared spaces. Get it from the `host_user.uuid` field in the List Meetings or List Rooms response.

```bash
curl -s "https://my.timeless.day/api/v1/spaces/{uuid}/workspace/?host_uuid={hostUuid}" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN"
```

#### 3c. Public Space (publicly shared)

```bash
curl -s "https://my.timeless.day/api/v1/spaces/public/{uuid}/{hostUuid}/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN"
```

**Response includes:**
- `conversations[]`: Recordings in this space (each has `uuid`, `name`, `start_ts`, `end_ts`, `status`, `language`)
- `artifacts[]`: AI-generated documents. Check `type` field (e.g., `"summary"`). Content is in `content.body` (HTML).
- `contacts[]`: Each has nested `conversations[]`
- `organizations[]`: Each has nested `conversations[]`
- `threads[]`: AI chat threads. Use `threads[0].uuid` to chat with the agent.

**Collecting all conversations in a room:**
Deduplicate conversation UUIDs from `conversations[]` + `contacts[].conversations[]` + `organizations[].conversations[]`.

---

### 4. Get Transcript

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
    { "speaker_id": "spk_001", "start_time": 0, "end_time": 4.5, "text": "Good morning everyone, let's get started." },
    { "speaker_id": "spk_002", "start_time": 4.8, "end_time": 8.2, "text": "Sounds good. I have updates on the project." }
  ]
}
```

**How to get meeting_id:** from the `id` field in List Meetings response.

**Format as readable text** by mapping `speaker_id` to speaker names:
```
[00:00:00] Alice Johnson: Good morning everyone, let's get started.
[00:00:04] Bob Smith: Sounds good. I have updates on the project.
```

> **For room conversations:** To fetch transcripts for individual conversations within a room (accessed via Get Space), use the unofficial transcript endpoint: `GET https://my.timeless.day/api/v1/conversation/{conversation_uuid}/transcript/` with `Authorization: Token`.

---

### 5. Get Recording URL

```
GET https://api.timeless.day/v1/meetings/{meeting_id}/recording
```

```bash
curl -s "https://api.timeless.day/v1/meetings/mtg_abc123/recording" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

**Response:**
```json
{
  "meeting_id": "mtg_abc123",
  "recording_url": "https://storage.example.com/recordings/abc123?token=..."
}
```

> The URL is time-limited. Fetch it fresh when needed. `recording_url` is `null` if no recording is available.

---

### 6. Upload a Recording

```
PUT https://api.timeless.day/v1/meetings/upload
```

Single-step upload: send the raw file as the request body with metadata as query parameters.

| Parameter | Location | Description |
|-----------|----------|-------------|
| `title` | query | Optional title for the recording (max 500 chars) |
| `language` | query | Language code for transcription (e.g. `en`, `es`) |
| `Content-Type` | header | MIME type of the file |

**Supported types:** `audio/mpeg`, `audio/mp4`, `audio/wav`, `audio/webm`, `audio/ogg`, `audio/aac`, `audio/flac`, `video/mp4`, `video/webm`, `video/ogg`, `video/quicktime`

```bash
curl -X PUT "https://api.timeless.day/v1/meetings/upload?title=Team%20sync&language=en" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: audio/mpeg" \
  --data-binary @recording.mp3
```

**Response:**
```json
{
  "id": "mtg_abc123",
  "status": "processing"
}
```

Poll `GET /meetings?id=mtg_abc123` until `status` changes from `processing` to `completed`.

Or use the helper script: `bash ../scripts/upload.sh FILE_PATH LANGUAGE [TITLE]`

**Supported file extensions:** mp3, wav, m4a, mp4, webm, ogg, aac, flac, mov

---

### 7. Resolve a Timeless Share URL — Unofficial API

URLs like `https://my.timeless.day/m/ENCODED_ID` contain two Base64-encoded short IDs (22 chars each).

**Decoding (shell):**
```bash
ENCODED="the_part_after_/m/"
DECODED=$(echo "$ENCODED" | base64 -d)
SPACE_ID=$(echo "$DECODED" | cut -c1-22)
HOST_ID=$(echo "$DECODED" | cut -c23-44)
```

**Decoding (Python):**
```python
import base64

def decode_timeless_url(url):
    encoded = url.rstrip('/').split('/m/')[-1]
    combined = base64.b64decode(encoded).decode()
    return combined[:22], combined[22:]  # (space_id, host_id)
```

After decoding, fetch with Get Space (try private -> workspace -> public).

---

### 8. Chat with Timeless AI — Unofficial API

Ask questions about a meeting or room.

#### Step 1: Send Message

```bash
curl -X POST "https://my.timeless.day/api/v1/agent/space/chat/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "space_uuid": "SPACE_UUID",
    "thread_uuid": "THREAD_UUID",
    "message": {
      "role": "user",
      "parts": [{"type": "text", "text": "What were the action items?"}],
      "date": "'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'",
      "metadata": {"timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'", "mentions": []},
      "id": "'$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)'"
    }
  }'
```

Get `thread_uuid` from the space's `threads[0].uuid` (via Get Space).

#### Step 2: Poll for Response

```bash
curl -s "https://my.timeless.day/api/v1/agent/threads/{thread_uuid}/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN"
```

Poll every 2-3 seconds until `is_running` is `false`. The AI response is the last message with `role: "assistant"` in the `messages` array.

---

### 9. Create a Room — Unofficial API

```bash
curl -X POST "https://my.timeless.day/api/v1/spaces/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"has_onboarded": true, "space_type": "ROOM", "title": "My Room"}'
```

**Response:** Full space object. Extract `uuid` for adding resources.

---

### 10. Add/Remove Conversations from a Room — Unofficial API

```bash
# Add a conversation
curl -X POST "https://my.timeless.day/api/v1/spaces/{room_uuid}/resources/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"resource_type": "CONVERSATION", "resource_uuid": "CONVERSATION_UUID"}'

# Remove a conversation
curl -X DELETE "https://my.timeless.day/api/v1/spaces/{room_uuid}/resources/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"resource_type": "CONVERSATION", "resource_uuid": "CONVERSATION_UUID"}'
```

Call Add once per conversation you want to attach. Get conversation UUIDs from Get Space (`conversations[].uuid`).

---

### 11. Get Document

```
GET https://api.timeless.day/v1/documents/{document_id}
```

Fetch an AI-generated document (summary, action items, notes) in your preferred format.

| Parameter | Type | Description |
|-----------|------|-------------|
| `format` | string | `html` (default), `markdown`, `raw`, `docx`, `json` |

```bash
curl -s "https://api.timeless.day/v1/documents/doc_abc123?format=markdown" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

**Response:**
```json
{
  "id": "doc_abc123",
  "title": "Meeting summary",
  "format": "markdown",
  "content": "# Weekly standup\n\n## Key decisions\n- Proceed with the new API design\n\n## Action items\n- Alice: Update the spec by Friday\n",
  "created_at": "2025-01-15T10:35:00Z"
}
```

**How to get document IDs:** Use `expand=documents` when listing meetings or rooms. Each meeting/room will include a `documents[]` array with `id`, `title`, and `created_at`.

---

### 12. Webhooks

Subscribe to events so Timeless notifies you when transcripts or summaries are ready.

**Available events:** `meeting.transcript_ready`, `meeting.initial_summary_ready`

#### Create a Webhook

```bash
curl -X POST "https://api.timeless.day/v1/webhooks" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com/webhooks/timeless",
    "events": ["meeting.transcript_ready", "meeting.initial_summary_ready"]
  }'
```

**Response:** Returns the webhook object including a `secret` for signature verification. Store the secret securely; it is only returned at creation time.

#### List Webhooks

```bash
curl -s "https://api.timeless.day/v1/webhooks" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

#### Update a Webhook

```bash
curl -X PATCH "https://api.timeless.day/v1/webhooks/whk_abc123" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"enabled": false}'
```

#### Delete a Webhook

```bash
curl -X DELETE "https://api.timeless.day/v1/webhooks/whk_abc123" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

#### Verifying Webhook Signatures

Every delivery includes an `X-Webhook-Signature` header (`sha256=<hex digest>`). Verify using HMAC-SHA256 with your webhook secret:

```python
import hashlib, hmac

def verify_signature(payload: bytes, signature_header: str, secret: str) -> bool:
    expected = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
    received = signature_header.removeprefix("sha256=")
    return hmac.compare_digest(expected, received)
```

**Delivery behavior:** 10s timeout, retries up to 3 times (1s, 10s, 60s) on 5xx/429/network failures.

---

## Common Workflows

### Export All Transcripts
1. List all meetings: `GET /meetings?scope=owned&status=completed&limit=100`
2. Paginate through all pages using `next_cursor`
3. For each meeting, fetch transcript using its `id`

### Get Meeting Summary
1. List meetings with documents: `GET /meetings?scope=owned&status=completed&expand=documents`
2. From the meeting's `documents[]`, find the document you want
3. Fetch the full content: `GET /documents/{document_id}?format=markdown`

### Get Everything from a Room
1. Get Space for the room UUID (unofficial API)
2. Collect all conversation UUIDs from `conversations[]`, `contacts[].conversations[]`, `organizations[].conversations[]` (deduplicate)
3. Fetch transcript for each conversation UUID using the unofficial transcript endpoint

### Search and Read
1. List meetings with `search=your+query` or use semantic search with `q=your+question`
2. Pick the meeting, get its `id`
3. Fetch transcript: `GET /meetings/{id}/transcript`
4. Fetch AI summary: use `expand=documents` in the list call, then `GET /documents/{doc_id}?format=markdown`

---

## Automation Patterns

### Webhooks (Recommended)

Use webhooks to react to new meetings automatically without polling.

1. Create a webhook: `POST /webhooks` with your URL and desired events
2. When a meeting transcript is ready, Timeless sends a POST to your URL with the meeting data
3. Verify the signature, then process the meeting (fetch transcript, documents, etc.)

### Cron Polling (Fallback)

For environments that cannot receive webhooks, use **cron polling with a state file**.

A cron job runs every 5-10 minutes. Each run:

1. Read a state file (`timeless-processed.json`). Create it with an empty `processed` array if missing.
2. Poll for completed meetings: `GET https://api.timeless.day/v1/meetings?scope=owned&status=completed&start_date=YYYY-MM-DD`
3. For each meeting: if its `id` is already in `processed`, skip it.
4. For new meetings: fetch whatever data you need (transcript, documents, space details), then run your automation logic.
5. Append processed IDs to the state file.
6. **If nothing is new, exit silently.** Do not message the user.

**State file format:**
```json
{
  "processed": ["mtg_abc123", "mtg_def456"],
  "last_check": "2026-03-05T12:00:00Z"
}
```

**Key rules:**
- An ID in `processed` is never processed again. This prevents duplicate work.
- Periodically prune old IDs (e.g., older than 30 days) to keep the file small.

**Cron setup (OpenClaw):**
```
openclaw cron add "timeless-poll" --schedule "*/5 * * * *" --task "Check for new completed Timeless meetings. Read timeless-processed.json for state. Poll the API. For new meetings: [your automation here]. If nothing new, reply HEARTBEAT_OK."
```

### What You Can Do With a New Meeting

Once a new completed meeting is detected (via webhook or polling), you have access to:
- **Transcript** (full speaker-attributed text via Get Transcript)
- **AI summary and documents** (via Get Document or Get Space `artifacts[]`)
- **Participants and metadata** (from the meeting object or Get Space)
- **Recording URL** (via Get Recording)
- **AI chat** (ask follow-up questions via Chat with Timeless AI)

Combine these with any external tool or API. Some examples of what people build:

- Auto-generate a recap presentation or document after every meeting
- Feed meeting data into a dashboard that tracks topics, action items, or meeting load over time
- Auto-curate Timeless rooms by adding conversations that match rules (participant, title, topic)
- Push summaries or action items to Slack, email, Notion, or a CRM
- Run sentiment analysis or extract custom fields from transcripts
- Build a searchable meeting knowledge base

The pattern is always the same: detect new meetings, pull the data, do your thing.

---

## Capture: Podcasts

Scripts in `../scripts/` folder.

1. **Search**: `bash ../scripts/podcast.sh search "podcast name"`
2. **List episodes**: `bash ../scripts/podcast.sh episodes FEED_URL [limit]`
3. **Download**: `bash ../scripts/podcast.sh download MP3_URL /tmp/episode.mp3`
4. **Upload to Timeless**: `bash ../scripts/upload.sh /tmp/episode.mp3 en "Episode Title"`
5. Clean up the file from /tmp

### Spotify links

Extract the episode title via oEmbed, then search by name:
```bash
curl -s "https://open.spotify.com/oembed?url=SPOTIFY_URL"
```

---

## Capture: YouTube

1. **Get info**: `bash ../scripts/youtube.sh info "YOUTUBE_URL"`
2. **Download video**: `bash ../scripts/youtube.sh download "YOUTUBE_URL" /tmp/video.mp4`
3. **Upload to Timeless**: `bash ../scripts/upload.sh /tmp/video.mp4 en "Video Title"`
4. Clean up the file from /tmp

Downloads as mp4 (video+audio). No ffmpeg needed. Uses the best pre-muxed format (typically 720p), which is fine for Timeless.

---

## Capture: Adding to a Room

After uploading, attach the content to a Timeless room for organized collections.

1. Upload returns a meeting `id`. Poll `GET https://api.timeless.day/v1/meetings?id={meeting_id}` until `status` is `completed`.
2. To get the conversation UUID, fetch the space via the unofficial API: `GET https://my.timeless.day/api/v1/spaces/{uuid}/` and extract `conversations[0].uuid`.
3. Add to room: `POST https://my.timeless.day/api/v1/spaces/{room_uuid}/resources/` with `{"resource_type": "CONVERSATION", "resource_uuid": "CONV_UUID"}`

To create a new room first: `POST https://my.timeless.day/api/v1/spaces/` with `{"has_onboarded": true, "space_type": "ROOM", "title": "My Collection"}`

---

## Notes

- Podcast MP3s can be large (100-300MB for long episodes). Downloads may take a minute.
- YouTube downloads require yt-dlp. If not installed, the script will fail with a clear error.
- Always clean up downloaded files from /tmp after uploading.
- Set `YTDLP_PATH` env var if yt-dlp is not on PATH.
- Official API uses prefixed IDs (`mtg_`, `room_`, `doc_`, `whk_`). Unofficial API uses plain UUIDs. Do not mix them across APIs.

---

## Error Handling

**Official API** returns structured errors:
```json
{ "error": { "code": "not_found", "message": "Resource not found" } }
```

| Code | Action |
|------|--------|
| 401 | Token expired. Re-authenticate at my.timeless.day/api-token |
| 403 | No access. For unofficial API, try workspace or public endpoint. |
| 404 | Not found. Check ID/UUID. |
| 429 | Rate limited. Check `Retry-After` header and wait. |

## Rate Limiting

**Official API** includes rate limit headers on every response:

| Endpoint | Limit |
|----------|-------|
| Most endpoints | 60 requests/minute |
| Webhook creation | 20 requests/minute |
| File upload | 10 requests/minute |

Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

**Unofficial API:** No official limits. Be respectful: 0.5s delay between sequential requests, max ~60 requests per minute.
