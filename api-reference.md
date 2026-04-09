# Timeless API Reference

**Last Updated**: April 9, 2026

This document covers both the **official** Timeless API and the **unofficial** API for extended features.

---

## Part 1: Official API

**Base URL**: `https://api.timeless.day/v1`  
**Docs**: [docs.timeless.day](https://docs.timeless.day/)

### Authentication

```
Authorization: Bearer YOUR_TOKEN
```

Get your token at [my.timeless.day/api-token](https://my.timeless.day/api-token). Tokens are 64-character hex strings.

### Error Format

All errors return a structured JSON body:

```json
{
  "error": {
    "code": "not_found",
    "message": "Resource not found"
  }
}
```

Validation errors include a `details` array:

```json
{
  "error": {
    "code": "bad_request",
    "message": "Request validation failed",
    "details": [
      { "field": "limit", "message": "Input should be less than or equal to 100" }
    ]
  }
}
```

| Status | Code | Description |
|--------|------|-------------|
| 400 | `bad_request` | Invalid request parameters or body |
| 401 | `unauthorized` | Missing or invalid API token |
| 403 | `forbidden` | Token is valid but lacks permission |
| 404 | `not_found` | Resource does not exist or is not accessible |
| 429 | `rate_limited` | Too many requests |
| 500 | `internal_error` | Unexpected server error |

### Rate Limiting

| Endpoint | Limit |
|----------|-------|
| Most endpoints | 60 requests/minute |
| Webhook creation | 20 requests/minute |
| File upload | 10 requests/minute |

Every response includes: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

When rate limited, a `Retry-After` header indicates seconds to wait.

### Pagination

List endpoints use cursor-based pagination:

```json
{
  "data": [...],
  "next_cursor": "eyJjcmV...",
  "has_more": true
}
```

Pass `cursor` as a query parameter to get the next page. Control page size with `limit` (1-100, default 25).

### Resource IDs

All resources use prefixed IDs:

| Resource | Prefix | Example |
|----------|--------|---------|
| Meeting | `mtg_` | `mtg_abc123` |
| Room | `room_` | `room_abc123` |
| Document | `doc_` | `doc_abc123` |
| User | `usr_` | `usr_abc123` |
| Speaker | `spk_` | `spk_abc123` |
| Webhook | `whk_` | `whk_abc123` |

---

### 1. List Meetings

```
GET /meetings
```

Returns a paginated list of meetings accessible to the authenticated user.

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `scope` | string | | `all` (default), `owned`, or `shared` |
| `search` | string | | Search by meeting title (substring match) |
| `q` | string | | Semantic search across meeting content |
| `start_date` | string | | From date (`YYYY-MM-DD`) |
| `end_date` | string | | To date (`YYYY-MM-DD`) |
| `status` | string | | `completed`, `processing`, `scheduled`, `failed` |
| `participant` | string | | Filter by participant name or email |
| `company` | string | | Filter by company name or domain |
| `room_id` | string | | Filter by room ID (e.g. `room_abc123`) |
| `id` | string | | Filter by meeting ID(s). Pass multiple: `?id=mtg_abc&id=mtg_def` |
| `expand` | string | | `documents` to include AI documents inline |
| `limit` | integer | | Results per page, 1-100 (default: 25) |
| `cursor` | string | | Pagination cursor from previous response |

#### Example

```bash
curl -s "https://api.timeless.day/v1/meetings?scope=owned&status=completed&start_date=2026-02-25&end_date=2026-03-04&limit=50" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

#### Response

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
      "host": {
        "id": "usr_123",
        "name": "Your Name",
        "email": "you@company.com"
      },
      "participants": [
        { "name": "Alice", "email": "alice@co.com", "title": "Engineer", "company": "Acme Corp" }
      ],
      "created_at": "2026-03-03T09:55:00Z"
    }
  ],
  "next_cursor": "eyJjcmVhdGVkX2F0Ijo...",
  "has_more": true
}
```

**Key fields:**
- `id`: Meeting ID (use for transcripts, recordings, documents)
- `status`: `completed` means transcript is ready
- `source`: `google_meet`, `zoom`, `teams`, `slack`, `whatsapp`, `phone`, `upload`, `desktop`

---

### 2. List Rooms

```
GET /rooms
```

Returns a paginated list of rooms.

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `scope` | string | | `all` (default), `owned`, or `shared` |
| `search` | string | | Search by room title |
| `id` | string | | Filter by room ID(s) |
| `expand` | string | | `documents`, `meetings`, or both |
| `limit` | integer | | Results per page, 1-100 (default: 25) |
| `cursor` | string | | Pagination cursor |

#### Example

```bash
curl -s "https://api.timeless.day/v1/rooms?scope=owned&expand=meetings" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

#### Response

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
        {
          "id": "mtg_abc123",
          "title": "Weekly standup",
          "status": "completed",
          "source": "google_meet",
          "start_time": "2025-01-15T10:00:00Z",
          "duration": 1800
        }
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
GET /meetings/{meeting_id}/transcript
```

Returns the transcript for a meeting with speaker identification and timestamps.

#### Example

```bash
curl -s "https://api.timeless.day/v1/meetings/mtg_abc123/transcript" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

#### Response

```json
{
  "meeting_id": "mtg_abc123",
  "language": "en",
  "speakers": [
    { "id": "spk_001", "name": "Alice Johnson" },
    { "id": "spk_002", "name": "Bob Smith" }
  ],
  "segments": [
    {
      "speaker_id": "spk_001",
      "start_time": 0,
      "end_time": 4.5,
      "text": "Good morning everyone, let's get started."
    },
    {
      "speaker_id": "spk_002",
      "start_time": 4.8,
      "end_time": 8.2,
      "text": "Sounds good. I have updates on the project."
    }
  ]
}
```

**Formatting the transcript:**

Map each segment's `speaker_id` to the `speakers` array:

```
[00:00:00] Alice Johnson: Good morning everyone, let's get started.
[00:00:04] Bob Smith: Sounds good. I have updates on the project.
```

---

### 4. Get Recording URL

```
GET /meetings/{meeting_id}/recording
```

Returns a temporary signed URL to download the recording.

#### Example

```bash
curl -s "https://api.timeless.day/v1/meetings/mtg_abc123/recording" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

#### Response

```json
{
  "meeting_id": "mtg_abc123",
  "recording_url": "https://storage.example.com/recordings/abc123?token=..."
}
```

> `recording_url` is `null` if no recording is available. The URL is time-limited.

---

### 5. Get Document

```
GET /documents/{document_id}
```

Returns an AI-generated document (summary, action items, notes) in your chosen format.

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `format` | string | | `html` (default), `markdown`, `raw`, `docx`, `json` |

#### Example

```bash
curl -s "https://api.timeless.day/v1/documents/doc_abc123?format=markdown" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

#### Response

```json
{
  "id": "doc_abc123",
  "title": "Meeting summary",
  "format": "markdown",
  "content": "# Weekly standup\n\n## Key decisions\n- Proceed with the new API design\n\n## Action items\n- Alice: Update the spec by Friday\n",
  "created_at": "2025-01-15T10:35:00Z"
}
```

> For `docx` format, `content` is base64-encoded. For `json`, it is a JSON-serialized array of content blocks.

---

### 6. Upload Media

```
PUT /meetings/upload
```

Upload an audio or video file for transcription. Send the raw binary file as the request body (not multipart form data).

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `title` | string | | Title for the recording (max 500 chars) |
| `language` | string | | Language code (e.g. `en`, `es`) |

#### Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Content-Type` | Yes | MIME type of the file |

**Supported audio:** `audio/mpeg`, `audio/mp4`, `audio/wav`, `audio/webm`, `audio/ogg`, `audio/aac`, `audio/flac`  
**Supported video:** `video/mp4`, `video/webm`, `video/ogg`, `video/quicktime`

#### Example

```bash
curl -X PUT "https://api.timeless.day/v1/meetings/upload?title=Team%20sync&language=en" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: audio/mpeg" \
  --data-binary @recording.mp3
```

#### Response

```json
{
  "id": "mtg_abc123",
  "status": "processing"
}
```

Poll `GET /meetings?id=mtg_abc123` until `status` changes from `processing` to `completed`.

Rate limit: 10 requests per minute.

---

### 7. Webhooks

#### Create Webhook

```
POST /webhooks
```

```bash
curl -X POST "https://api.timeless.day/v1/webhooks" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com/webhooks/timeless",
    "events": ["meeting.transcript_ready", "meeting.initial_summary_ready"]
  }'
```

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `url` | string | Yes | HTTPS URL to receive events (max 2048 chars) |
| `events` | array | Yes | At least one of: `meeting.transcript_ready`, `meeting.initial_summary_ready` |
| `enabled` | boolean | | Default `true`. Set `false` to create disabled. |

**Response:**

```json
{
  "id": "whk_abc123",
  "url": "https://example.com/webhooks/timeless",
  "events": ["meeting.transcript_ready", "meeting.initial_summary_ready"],
  "enabled": true,
  "secret": "a1b2c3d4e5f6...",
  "created_at": "2025-01-15T12:00:00Z",
  "updated_at": "2025-01-15T12:00:00Z"
}
```

> Store `secret` securely. It is only returned at creation time.

#### List Webhooks

```
GET /webhooks
```

```bash
curl -s "https://api.timeless.day/v1/webhooks" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

#### Update Webhook

```
PATCH /webhooks/{webhook_id}
```

Only include fields you want to change.

```bash
curl -X PATCH "https://api.timeless.day/v1/webhooks/whk_abc123" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"enabled": false}'
```

#### Delete Webhook

```
DELETE /webhooks/{webhook_id}
```

```bash
curl -X DELETE "https://api.timeless.day/v1/webhooks/whk_abc123" \
  -H "Authorization: Bearer $TIMELESS_ACCESS_TOKEN"
```

#### Webhook Signature Verification

Every delivery includes `X-Webhook-Signature: sha256=<hex digest>`. Verify with HMAC-SHA256:

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

**Delivery behavior:** 10s timeout. Retries up to 3 times (1s, 10s, 60s) on 5xx, 429, and network failures. 4xx (except 429) are not retried.

---

### Meeting Status Values (Official API)

| Status | Description |
|--------|-------------|
| `completed` | Meeting processed, transcript ready |
| `scheduled` | Meeting scheduled for the future |
| `processing` | Transcription in progress |
| `failed` | Processing failed |

### Meeting Sources (Official API)

| Source | Description |
|--------|-------------|
| `google_meet` | Google Meet |
| `zoom` | Zoom |
| `teams` | Microsoft Teams |
| `slack` | Slack huddle |
| `whatsapp` | WhatsApp voice message |
| `phone` | Phone call |
| `upload` | Uploaded file |
| `desktop` | Desktop app recording |

---

## Part 2: Unofficial API (Extended Features)

> These endpoints provide capabilities not yet available in the official API: space details, AI chat, room management, share URL resolution, and scheduling.

**Base URL**: `https://my.timeless.day`

### Authentication

```
Authorization: Token YOUR_TOKEN
```

The same token from [my.timeless.day/api-token](https://my.timeless.day/api-token) works for both APIs. The header format differs: `Bearer` for official, `Token` for unofficial.

### Rate Limits

No official rate limits documented. Be respectful:
- Add 0.5s delay between sequential requests
- Max ~60 requests per minute
- Use pagination instead of fetching everything at once

### Pagination

Unofficial API uses page-based pagination:

```json
{
  "count": 42,
  "next": "https://my.timeless.day/api/v1/spaces/meeting/?page=2",
  "previous": null,
  "results": [...]
}
```

### Error Handling

| Code | Meaning |
|------|---------|
| 401 | Token expired or invalid. Re-authenticate. |
| 403 | No access to this resource. Try workspace/public endpoints. |
| 404 | Resource not found. |
| 429 | Rate limited. Back off and retry. |
| 500 | Server error. Retry with exponential backoff. |

---

### 8. Get Space (Meeting or Room Details)

```
GET /api/v1/spaces/{uuid}/
```

Returns full details for any space including conversations, AI artifacts, contacts, organizations, and chat threads. No official equivalent.

#### Access Levels

| # | Endpoint | When to Use |
|---|----------|-------------|
| 1 | `GET /api/v1/spaces/{uuid}/` | Your own spaces (private) |
| 2 | `GET /api/v1/spaces/{uuid}/workspace/?host_uuid={hostUuid}` | Shared within workspace. `host_uuid` required. |
| 3 | `GET /api/v1/spaces/public/{uuid}/{hostUuid}/` | Publicly shared spaces |

Try in order. If one returns 401/403/404, try the next.

#### Example

```bash
curl -s "https://my.timeless.day/api/v1/spaces/abc123/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN"
```

#### Response

```json
{
  "uuid": "abc123",
  "title": "Weekly Standup",
  "space_type": "MEETING",
  "is_processing": false,
  "conversations": [
    {
      "uuid": "conv-456",
      "name": "Weekly Standup",
      "start_ts": "2026-03-03T10:00:00Z",
      "end_ts": "2026-03-03T10:45:00Z",
      "status": "COMPLETED",
      "language": "he",
      "source": "VIDEO_CONFERENCE_BOT_RECORDER",
      "event": {
        "title": "Weekly Standup",
        "attendees": ["alice@co.com", "bob@co.com"]
      }
    }
  ],
  "artifacts": [
    {
      "uuid": "art-789",
      "name": "Meeting Summary",
      "type": "summary",
      "content": {
        "body": "<h2>Key Decisions</h2><p>...</p>"
      },
      "version": 1
    }
  ],
  "contacts": [
    {
      "uuid": "contact-1",
      "name": "Alice",
      "conversations": [{ "uuid": "conv-456" }]
    }
  ],
  "organizations": [
    {
      "uuid": "org-1",
      "name": "Acme Corp",
      "conversations": [{ "uuid": "conv-456" }]
    }
  ],
  "threads": [
    {
      "uuid": "thread-1",
      "messages": [],
      "is_running": false
    }
  ]
}
```

**Key fields:**
- `conversations[]`: All recordings in this space. For meetings, typically one. For rooms, can be many.
- `artifacts[]`: AI-generated documents. `type` tells you what it is (e.g. `summary`). Content in `content.body` (HTML).
- `contacts[]` and `organizations[]`: Each contains nested `conversations[]`.
- `threads[]`: AI chat threads. Use `threads[0].uuid` to chat with the space agent.

---

### 9. Get Transcript by Conversation UUID

```
GET /api/v1/conversation/{conversation_uuid}/transcript/
```

Returns the transcript for a specific conversation. Use this when you have a conversation UUID from Get Space (e.g. for room conversations). For meeting-level transcripts, prefer the official `GET /meetings/{id}/transcript`.

#### Example

```bash
curl -s "https://my.timeless.day/api/v1/conversation/conv-456/transcript/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN"
```

#### Response

```json
{
  "items": [
    {
      "text": "Good morning everyone, let's get started.",
      "start_time": 0.5,
      "end_time": 3.2,
      "speaker_id": "speaker_0"
    }
  ],
  "speakers": [
    { "id": "speaker_0", "name": "Alice Johnson" }
  ],
  "language": "he"
}
```

---

### 10. Get Recording URL by Conversation UUID

```
GET /api/v1/conversation/{conversation_uuid}/recording/
```

Returns a time-limited signed URL. For meeting-level recordings, prefer the official `GET /meetings/{id}/recording`.

#### Example

```bash
curl -s "https://my.timeless.day/api/v1/conversation/conv-456/recording/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN"
```

#### Response

```json
{
  "media_url": "https://storage.googleapis.com/...?X-Goog-Signature=..."
}
```

---

### 11. Resolve a Timeless Share URL

URLs like `https://my.timeless.day/m/ENCODED_ID` contain two Base64-encoded short IDs (22 characters each), concatenated as `spaceId + hostId`.

#### Decoding Logic

```python
import base64

def decode_timeless_url(url):
    encoded = url.rstrip('/').split('/m/')[-1]
    combined = base64.b64decode(encoded).decode()
    ID_LEN = 22
    return {
        "space_id": combined[:ID_LEN],
        "host_id": combined[ID_LEN:]
    }
```

```javascript
function decodeTimelessUrl(url) {
  const encoded = url.replace(/\/$/, '').split('/m/').pop();
  const combined = Buffer.from(encoded, 'base64').toString();
  return {
    spaceId: combined.slice(0, 22),
    hostId: combined.slice(22)
  };
}
```

```bash
ENCODED="the_part_after_/m/"
DECODED=$(echo "$ENCODED" | base64 -d)
SPACE_ID=$(echo "$DECODED" | cut -c1-22)
HOST_ID=$(echo "$DECODED" | cut -c23-44)
```

Once decoded, use the space ID with Get Space (try private, workspace, public in order).

---

### 12. Chat with Meeting AI

```
POST /api/v1/agent/space/chat/
```

Send a question to the AI agent about a meeting or room. This is asynchronous: it returns `204 No Content` immediately. Poll the thread for the response.

#### Example

```bash
curl -X POST "https://my.timeless.day/api/v1/agent/space/chat/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "space_uuid": "abc123",
    "thread_uuid": "thread-1",
    "message": {
      "role": "user",
      "parts": [{"type": "text", "text": "What were the action items?"}],
      "date": "2026-03-04T18:00:00Z",
      "metadata": {"timestamp": "2026-03-04T18:00:00Z", "mentions": []},
      "id": "msg-unique-id"
    }
  }'
```

Get `thread_uuid` from the space's `threads[0].uuid` (via Get Space).

#### Polling for the Response

```bash
curl -s "https://my.timeless.day/api/v1/agent/threads/thread-1/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN"
```

Poll every 2-3 seconds until `is_running: false`. The last message with `role: "assistant"` is the AI's response.

---

### 13. Create a Room

```
POST /api/v1/spaces/
```

Create a new room for grouping meetings.

#### Example

```bash
curl -X POST "https://my.timeless.day/api/v1/spaces/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "has_onboarded": true,
    "space_type": "ROOM",
    "title": "Project Alpha"
  }'
```

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `has_onboarded` | boolean | Yes | Always `true` |
| `space_type` | string | Yes | Always `"ROOM"` |
| `title` | string | Yes | Room title |

Returns the full space object. Extract `uuid` for subsequent operations.

---

### 14. Add Resource to Room

```
POST /api/v1/spaces/{space_uuid}/resources/
```

Attach a conversation to a room.

```bash
curl -X POST "https://my.timeless.day/api/v1/spaces/ROOM_UUID/resources/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "resource_type": "CONVERSATION",
    "resource_uuid": "CONVERSATION_UUID"
  }'
```

---

### 15. Remove Resource from Room

```
DELETE /api/v1/spaces/{space_uuid}/resources/
```

Remove a conversation from a room. Same request body as Add Resource.

```bash
curl -X DELETE "https://my.timeless.day/api/v1/spaces/ROOM_UUID/resources/" \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "resource_type": "CONVERSATION",
    "resource_uuid": "CONVERSATION_UUID"
  }'
```

---

### Unofficial Status Values

| Status | Description |
|--------|-------------|
| `COMPLETED` | Meeting processed, transcript ready |
| `SCHEDULED` | Bot scheduled for future meeting |
| `PROCESSING` | Transcription in progress |
| `FAILED` | Processing failed |
| `IN_CALL` | Bot is currently recording |
| `IN_WAITING_ROOM` | Bot waiting to be admitted |

### Unofficial Recording Sources

| Source | Description |
|--------|-------------|
| `VIDEO_CONFERENCE_BOT_RECORDER` | Timeless bot joined the meeting |
| `GOOGLE_MEET_RECORDER` | Google Meet native recording |
| `DESKTOP_ZOOM_RECORDER` | Desktop app recorded Zoom |
| `DESKTOP_GOOGLE_MEET_RECORDER` | Desktop app recorded Google Meet |
| `DESKTOP_TEAMS_RECORDER` | Desktop app recorded Teams |
| `DESKTOP_LIVE_RECORDER` | Desktop app live recording |
| `TIMEOS_FILE_UPLOAD` | Uploaded file |
| `PHONE_CALL` | Phone call recording |
| `WHATSAPP_MESSAGE` | WhatsApp voice message |

---

## Common Workflows

### Workflow 1: Export All Meeting Transcripts

```
1. GET https://api.timeless.day/v1/meetings?scope=owned&status=completed&limit=100
   -> Collect all meeting IDs
   -> Paginate using next_cursor

2. For each meeting:
   GET https://api.timeless.day/v1/meetings/{id}/transcript
   -> Save transcript with speaker names

3. (Optional) For AI summaries:
   GET https://api.timeless.day/v1/meetings?scope=owned&status=completed&expand=documents
   -> Get document IDs from meetings, then:
   GET https://api.timeless.day/v1/documents/{doc_id}?format=markdown
```

### Workflow 2: Get All Conversations in a Room

```
1. GET https://my.timeless.day/api/v1/spaces/{room_uuid}/
   -> Response contains conversations[], contacts[], organizations[]

2. Collect ALL unique conversation UUIDs from:
   - space.conversations[].uuid
   - space.contacts[].conversations[].uuid
   - space.organizations[].conversations[].uuid
   (Deduplicate by UUID)

3. For each conversation UUID:
   GET https://my.timeless.day/api/v1/conversation/{uuid}/transcript/
   -> Fetch the transcript
```

### Workflow 3: Search Meetings and Get Summary

```
1. GET https://api.timeless.day/v1/meetings?q=quarterly+review&expand=documents
   -> Find meetings matching your semantic search

2. Pick the meeting, get its document IDs from documents[]

3. GET https://api.timeless.day/v1/documents/{doc_id}?format=markdown
   -> Full formatted summary

4. GET https://api.timeless.day/v1/meetings/{id}/transcript
   -> Full speaker-attributed transcript
```

### Workflow 4: Resolve a Shared Link and Read It

```
1. Decode the /m/ URL (see section 11)
2. Try GET https://my.timeless.day/api/v1/spaces/{space_uuid}/
3. If 40x, try GET https://my.timeless.day/api/v1/spaces/{space_uuid}/workspace/?host_uuid={host_uuid}
4. If 40x, try GET https://my.timeless.day/api/v1/spaces/public/{space_uuid}/{host_uuid}/
5. From the space response, get conversations and fetch transcripts
```

### Workflow 5: Automate with Webhooks

```
1. POST https://api.timeless.day/v1/webhooks
   -> Subscribe to meeting.transcript_ready and/or meeting.initial_summary_ready
   -> Store the secret for signature verification

2. When notified, verify the X-Webhook-Signature header

3. Fetch the meeting data:
   GET https://api.timeless.day/v1/meetings/{id}/transcript
   GET https://api.timeless.day/v1/documents/{doc_id}?format=markdown

4. Run your automation logic
```
