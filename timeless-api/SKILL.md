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
[00:00:00] Alice Johnson: Good morning everyone, let's get started.
[00:00:03] Bob Smith: I'll share the roadmap updates.
```

---

### 4. Get Recording URL

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
  "recording_url": "https://storage.googleapis.com/...signed..."
}
```

> The URL is time-limited. Fetch it fresh when needed.

---

### 5. Get Document

Retrieve AI-generated documents (summaries, action items, notes) in multiple formats.

```
GET https://api.timeless.day/v1/documents/{document_id}
```

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
  "content": "# Weekly standup\n\n## Key decisions\n- Proceed with the new API design\n\n## Action items\n- Alice: Update the spec by Friday",
  "created_at": "2026-03-03T10:35:00Z"
}
```

**How to get document_id:**
- From List Meetings with `expand=documents`: each meeting's `documents[]` array
- From List Rooms with `expand=documents`: each room's `documents[]` array

> For `docx` format, `content` is base64-encoded. For `json` format, `content` is a JSON-serialized array of content blocks.

---

### 6. Upload a Recording

Single-step upload with raw binary body:

```
PUT https://api.timeless.day/v1/meetings/upload
```

| Parameter | Location | Description |
|-----------|----------|-------------|
| `title` | query | Optional title (max 500 chars) |
| `language` | query | Language code (e.g., `en`, `he`) |
| `Content-Type` | header | MIME type of the file |

```bash
curl -X PUT "https://api.timeless.day/v1/meetings/upload?title=Team%20Meeting&language=en" \
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

Poll `GET /meetings?id={id}` until `status` is `completed`.

Or use the helper script: `bash ../scripts/upload.sh FILE_PATH LANGUAGE [TITLE]`

**Supported audio types:** `audio/mpeg`, `audio/mp4`, `audio/wav`, `audio/webm`, `audio/ogg`, `audio/aac`, `audio/flac`
**Supported video types:** `video/mp4`, `video/webm`, `video/ogg`, `video/quicktime`

> Rate limit: 10 uploads per minute.

---

### 7. Webhooks

Subscribe to events instead of polling. Replaces the cron polling pattern for most use cases.

#### Create a Webhook

```bash
curl -X POST "https://api.timeless.day/v1/webhooks" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-server.com/webhooks/timeless",
    "events": ["meeting.transcript_ready", "meeting.initial_summary_ready"]
  }'
```

**Response:**
```json
{
  "id": "whk_abc123",
  "url": "https://your-server.com/webhooks/timeless",
  "events": ["meeting.transcript_ready", "meeting.initial_summary_ready"],
  "enabled": true,
  "secret": "a1b2c3d4e5f6...",
  "created_at": "2026-03-03T12:00:00Z",
  "updated_at": "2026-03-03T12:00:00Z"
}
```

> **Store the `secret` securely.** It is only returned at creation time and is used to verify webhook signatures.

**Available events:**
- `meeting.transcript_ready` — fired when a meeting transcript is available
- `meeting.initial_summary_ready` — fired when the AI summary is generated

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

#### Verify Webhook Signatures

Every delivery includes an `X-Webhook-Signature` header: `sha256=<hex HMAC-SHA256>`.

```python
import hashlib, hmac

def verify_signature(payload: bytes, signature_header: str, secret: str) -> bool:
    expected = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
    received = signature_header.removeprefix("sha256=")
    return hmac.compare_digest(expected, received)
```

```javascript
const crypto = require("crypto");

function verifySignature(payload, signatureHeader, secret) {
  const expected = crypto.createHmac("sha256", secret).update(payload).digest("hex");
  const received = signatureHeader.replace("sha256=", "");
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(received));
}
```

**Delivery behavior:**
- Timeout: 10 seconds
- Retries: up to 3 times (1s, 10s, 60s delays) for 5xx, 429, and network failures
- Success: any 2xx status code

---

## Operations — Unofficial API

> These operations use the unofficial API at `https://my.timeless.day` because the official API does not yet cover them. Use `Authorization: Token $TIMELESS_ACCESS_TOKEN` for all requests below.

### 8. Get Space (Meeting or Room Details)

Returns the full details for a space, including conversations, artifacts, contacts, organizations, and AI chat threads. This provides richer data than the official API's list endpoints.

Spaces have three access levels. **Try in order until one succeeds:**

#### 8a. Private Space (your own)

```bash
curl -s "https://my.timeless.day/api/v1/spaces/{uuid}/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN"
```

#### 8b. Workspace Space (shared within team)

> **`host_uuid` is required** for shared spaces. Get it from the `host_user.uuid` field in the List Meetings or List Rooms response.

```bash
curl -s "https://my.timeless.day/api/v1/spaces/{uuid}/workspace/?host_uuid={hostUuid}" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN"
```

#### 8c. Public Space (publicly shared)

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

### 9. Chat with Timeless AI

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

### 10. Resolve a Timeless Share URL

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

### 11. Create a Room

```bash
curl -X POST "https://my.timeless.day/api/v1/spaces/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"has_onboarded": true, "space_type": "ROOM", "title": "My Room"}'
```

**Response:** Full space object. Extract `uuid` for adding resources.

---

### 12. Add/Remove Conversations from a Room

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

## Common Workflows

### Export All Transcripts
1. List all meetings: `GET /meetings?scope=owned&status=completed&limit=100`
2. Paginate through all pages using `cursor`
3. For each meeting, fetch transcript using `meeting.id`

### Get Everything from a Room
1. Get Space for the room UUID (unofficial API)
2. Collect all conversation UUIDs from `conversations[]`, `contacts[].conversations[]`, `organizations[].conversations[]` (deduplicate)
3. Fetch transcript for each conversation

### Search and Read
1. Search meetings: `GET /meetings?q=your+query` (semantic) or `GET /meetings?search=keyword` (title)
2. Pick the meeting, use its `id`
3. Fetch transcript: `GET /meetings/{id}/transcript`
4. Fetch documents: use `expand=documents` in step 1, then `GET /documents/{doc_id}?format=markdown`

### Get Meeting Summary
1. List meetings with `expand=documents`: `GET /meetings?id=mtg_abc123&expand=documents`
2. From the response, find the document with the summary
3. Fetch full content: `GET /documents/{doc_id}?format=markdown`

---

## Automation Patterns

### Option 1: Webhooks (Recommended)

Use webhooks to react to new meetings without polling:

1. Create a webhook for the events you care about:
   ```bash
   curl -X POST "https://api.timeless.day/v1/webhooks" \
     -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"url": "https://your-server.com/hook", "events": ["meeting.transcript_ready"]}'
   ```
2. Store the `secret` from the response for signature verification.
3. When an event fires, your server receives a POST with the meeting data.
4. Verify the signature, then fetch transcript/documents/recordings as needed.

### Option 2: Cron Polling (Legacy)

If webhooks are not feasible, use **cron polling with a state file**.

A cron job runs every 5-10 minutes. Each run:

1. Read a state file (`timeless-processed.json`). Create it with an empty `processed` array if missing.
2. Poll for completed meetings: `GET /meetings?scope=owned&status=completed&start_date=YYYY-MM-DD`
3. For each meeting: if its `id` is already in `processed`, skip it.
4. For new meetings: fetch whatever data you need (transcript, documents, recordings), then run your automation logic.
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
- Use `scope=all` if the automation should cover meetings shared with you.

**Cron setup (TimelessSquads):**
```
timelesssquads cron add "timeless-poll" --schedule "*/5 * * * *" --task "Check for new completed Timeless meetings. Read timeless-processed.json for state. Poll the API. For new meetings: [your automation here]. If nothing new, reply HEARTBEAT_OK."
```

### What You Can Do With a New Meeting

Once a new completed meeting is detected (via webhook or polling), you have access to:
- **Transcript** (full speaker-attributed text via Get Transcript)
- **AI summary and documents** (via Get Document with format options)
- **Participants and metadata** (via List Meetings response)
- **Recording URL** (via Get Recording)
- **AI chat** (ask follow-up questions via Chat with Timeless AI, unofficial API)
- **Space details** (contacts, organizations, threads via Get Space, unofficial API)

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

1. Upload returns a meeting `id`. Poll `GET /meetings?id={id}` until `status` is `completed`.
2. Use Get Space (unofficial API) to get the conversation UUID.
3. Add to room: `POST https://my.timeless.day/api/v1/spaces/{room_uuid}/resources/` with `{"resource_type": "CONVERSATION", "resource_uuid": "CONV_UUID"}`

To create a new room first: see [Create a Room](#11-create-a-room).

---

## Scheduling

For meeting scheduling with productivity-first slot selection and curated invite links, read the `