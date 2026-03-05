# Timeless Unofficial API Reference

**Version**: Pre-release (internal endpoints)  
**Base URL**: `https://my.timeless.day`  
**Last Updated**: March 4, 2026

> ⚠️ This documents Timeless's internal API endpoints that can be used for programmatic access before the official public API launches. These endpoints may change without notice.

---

## Authentication

All requests require a session token in the `Authorization` header:

```
Authorization: Token YOUR_TOKEN
```

### How to Get Your Token

1. Go to [my.timeless.day/api-token](https://my.timeless.day/api-token)
2. Copy the access token

> This token is tied to your user account. It may expire; grab a fresh one from the same page if you get 401 errors.

---

## Endpoints

### 1. List Meetings

```
GET /api/v1/spaces/meeting/
```

Returns a paginated list of your meetings.

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `include` | string | ✅ | `owned` (your meetings) or `shared` (shared with you) |
| `search` | string | | Search by meeting title or attendees |
| `start_date` | string | | From date (`YYYY-MM-DD`) |
| `end_date` | string | | To date (`YYYY-MM-DD`) |
| `status` | string | | Filter by status: `COMPLETED`, `SCHEDULED`, `PROCESSING`, `FAILED`, etc. |
| `page` | integer | | Page number (default: 1) |
| `per_page` | integer | | Results per page (default: 20) |

#### Example

```bash
# List your completed meetings from the last week
curl -s "https://my.timeless.day/api/v1/spaces/meeting/?include=owned&status=COMPLETED&start_date=2026-02-25&end_date=2026-03-04&per_page=50" \
  -H "Authorization: Token $TIMELESS_TOKEN"
```

#### Response

```json
{
  "count": 42,
  "next": "https://my.timeless.day/api/v1/spaces/meeting/?page=2",
  "previous": null,
  "results": [
    {
      "uuid": "abc123",
      "title": "Weekly Standup",
      "start_ts": "2026-03-03T10:00:00Z",
      "end_ts": "2026-03-03T10:45:00Z",
      "status": "COMPLETED",
      "primary_conversation_uuid": "conv-456",
      "conversation_source": "VIDEO_CONFERENCE_BOT_RECORDER",
      "host_user": {
        "uuid": "user-123",
        "email": "you@company.com",
        "first_name": "Your",
        "last_name": "Name"
      },
      "created_at": "2026-03-03T09:55:00Z"
    }
  ]
}
```

**Key fields:**
- `uuid`: The space UUID (use this to get full details via Get Space)
- `primary_conversation_uuid`: Use this to fetch the transcript
- `status`: `COMPLETED` means transcript is ready

> **To get all meetings (owned + shared):** Make two requests, one with `include=owned` and one with `include=shared`, then merge results.

---

### 2. List Rooms

```
GET /api/v1/spaces/room/
```

Returns a paginated list of your rooms (collaborative spaces containing multiple meetings).

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `include` | string | ✅ | `owned` or `shared` |
| `search` | string | | Search by room title |
| `page` | integer | | Page number (default: 1) |
| `per_page` | integer | | Results per page (default: 20) |

#### Example

```bash
curl -s "https://my.timeless.day/api/v1/spaces/room/?include=owned" \
  -H "Authorization: Token $TIMELESS_TOKEN"
```

#### Response

```json
{
  "count": 8,
  "results": [
    {
      "uuid": "room-123",
      "title": "Project Alpha",
      "host_user": {
        "uuid": "user-123",
        "email": "you@company.com",
        "first_name": "Your",
        "last_name": "Name"
      },
      "created_at": "2026-02-15T14:00:00Z"
    }
  ]
}
```

> Rooms don't have `start_ts`, `end_ts`, or `status` fields. To see the meetings inside a room, use **Get Space**.

---

### 3. Get Space (Meeting or Room Details)

```
GET /api/v1/spaces/{uuid}/
```

Returns the full details for any space (meeting or room), including conversations, AI-generated documents, contacts, and organizations.

#### Choosing the Right Endpoint

Timeless has three access levels for spaces. Try them in this order:

| # | Endpoint | When to Use |
|---|----------|-------------|
| 1 | `GET /api/v1/spaces/{uuid}/` | Your own spaces (private) |
| 2 | `GET /api/v1/spaces/{uuid}/workspace/?host_uuid={hostUuid}` | Spaces shared within your workspace. **`host_uuid` is required** (get it from `host_user.uuid` in the list response). |
| 3 | `GET /api/v1/spaces/public/{uuid}/{hostUuid}/` | Publicly shared spaces |

If endpoint 1 returns 401/403/404, try endpoint 2. If that also fails, try endpoint 3.

#### Example

```bash
# Private space
curl -s "https://my.timeless.day/api/v1/spaces/abc123/" \
  -H "Authorization: Token $TIMELESS_TOKEN"
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
      "conversations": [{ "uuid": "conv-456", "..." : "..." }]
    }
  ],
  "organizations": [
    {
      "uuid": "org-1",
      "name": "Acme Corp",
      "conversations": [{ "uuid": "conv-456", "..." : "..." }]
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
- `conversations[]`: All conversations (recordings) in this space. For meetings, typically one. For rooms, can be many.
- `artifacts[]`: AI-generated documents. The `type` field tells you what it is (e.g., `summary`). Content is in `content.body` (HTML).
- `contacts[]` and `organizations[]`: Each contains nested `conversations[]` for meetings associated with that contact/org.
- `threads[]`: AI chat threads. Use `threads[0].uuid` if you want to chat with the space agent.

---

### 4. Get Transcript

```
GET /api/v1/conversation/{conversation_uuid}/transcript/
```

Returns the full speaker-attributed transcript for a conversation.

#### How to Get the Conversation UUID

- From **List Meetings**: use the `primary_conversation_uuid` field
- From **Get Space**: use `conversations[].uuid`

#### Example

```bash
curl -s "https://my.timeless.day/api/v1/conversation/conv-456/transcript/" \
  -H "Authorization: Token $TIMELESS_TOKEN"
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
    },
    {
      "text": "I'll share the roadmap updates.",
      "start_time": 3.5,
      "end_time": 5.8,
      "speaker_id": "speaker_1"
    }
  ],
  "speakers": [
    { "id": "speaker_0", "name": "Alice Johnson" },
    { "id": "speaker_1", "name": "Bob Smith" }
  ],
  "language": "he"
}
```

**Formatting the transcript:**

Map each item's `speaker_id` to the `speakers` array to get human-readable output:

```
[00:00:00] Alice Johnson: Good morning everyone, let's get started.
[00:00:03] Bob Smith: I'll share the roadmap updates.
```

---

### 5. Get Recording URL

```
GET /api/v1/conversation/{conversation_uuid}/recording/
```

Returns a time-limited signed URL to the audio/video recording.

#### Example

```bash
curl -s "https://my.timeless.day/api/v1/conversation/conv-456/recording/" \
  -H "Authorization: Token $TIMELESS_TOKEN"
```

#### Response

```json
{
  "media_url": "https://storage.googleapis.com/...?X-Goog-Signature=..."
}
```

> The URL expires after a short time. Fetch it when you need it, don't cache it.

---

### 6. Upload a Recording

Upload an audio/video file for transcription and AI processing. This is a 3-step flow.

#### Step 1: Get a Presigned Upload URL

```bash
curl -X POST "https://my.timeless.day/api/v1/conversation/storage/presigned-url/" \
  -H "Authorization: Token $TIMELESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "file_name": "team-meeting.mp3",
    "file_type": "audio/mpeg"
  }'
```

**Response:**
```json
{
  "url": "https://storage.googleapis.com/..."
}
```

#### Step 2: Upload the File

```bash
curl -X PUT "PRESIGNED_URL_FROM_STEP_1" \
  -H "Content-Type: audio/mpeg" \
  --upload-file team-meeting.mp3
```

#### Step 3: Trigger Processing

```bash
curl -X POST "https://my.timeless.day/api/v1/conversation/process/media/" \
  -H "Authorization: Token $TIMELESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "language": "he",
    "filename": "Team Meeting March 4"
  }'
```

**Response:**
```json
{
  "event_uuid": "evt-abc123",
  "space_uuid": "space-xyz789"
}
```

After processing completes (poll `GET /api/v1/spaces/{space_uuid}/` until `is_processing` is `false`), the transcript and AI summary will be available.

**Supported formats:** mp3, wav, m4a, mp4, webm, ogg

---

### 7. Resolve a Timeless Share URL

Timeless URLs like `https://my.timeless.day/m/ENCODED_ID` contain two Base64-encoded short IDs (22 characters each), concatenated as `spaceId + hostId`.

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
// Node.js / JavaScript
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
# Shell
ENCODED="the_part_after_/m/"
DECODED=$(echo "$ENCODED" | base64 -d)
SPACE_ID=$(echo "$DECODED" | cut -c1-22)
HOST_ID=$(echo "$DECODED" | cut -c23-44)
```

Once decoded, use the space ID with the **Get Space** endpoints (try private → workspace → public, as described in section 3).

---

### 8. Chat with Meeting AI

```
POST /api/v1/agent/space/chat/
```

Send a question to Timeless's AI agent about a meeting or room.

> ⚠️ This endpoint is **asynchronous**. It returns `204 No Content` immediately. The AI response arrives via WebSocket/Pusher. For programmatic use, poll the thread for the response.

#### Example

```bash
# Send a question
curl -X POST "https://my.timeless.day/api/v1/agent/space/chat/" \
  -H "Authorization: Token $TIMELESS_TOKEN" \
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

#### Polling for the Response

```bash
# Poll the thread until is_running becomes false
curl -s "https://my.timeless.day/api/v1/agent/threads/thread-1/" \
  -H "Authorization: Token $TIMELESS_TOKEN"
```

The thread response includes a `messages` array with all messages (user + AI). The last message with `role: "assistant"` is the AI's response. Keep polling every 2-3 seconds until `is_running: false`.

---

## Common Workflows

### Workflow 1: Export All Meeting Transcripts

```
1. GET /api/v1/spaces/meeting/?include=owned&status=COMPLETED&per_page=100
   → Collect all meeting UUIDs and primary_conversation_uuids
   → Paginate through all pages using the `next` URL

2. For each meeting:
   GET /api/v1/conversation/{primary_conversation_uuid}/transcript/
   → Save transcript with speaker names

3. (Optional) For AI summaries:
   GET /api/v1/spaces/{uuid}/
   → Extract artifacts[] where type == "summary"
```

### Workflow 2: Get All Conversations in a Room

```
1. GET /api/v1/spaces/{room_uuid}/
   → Response contains conversations[], contacts[], organizations[]

2. Collect ALL unique conversation UUIDs from:
   - space.conversations[].uuid
   - space.contacts[].conversations[].uuid  
   - space.organizations[].conversations[].uuid
   (Deduplicate by UUID)

3. For each conversation UUID:
   GET /api/v1/conversation/{uuid}/transcript/
   → Fetch the transcript
```

### Workflow 3: Search Meetings and Get Transcripts

```
1. GET /api/v1/spaces/meeting/?include=owned&search=quarterly+review
   → Find meetings matching your search

2. Pick the meeting you want, take its primary_conversation_uuid

3. GET /api/v1/conversation/{primary_conversation_uuid}/transcript/
   → Full speaker-attributed transcript
```

### Workflow 4: Resolve a Shared Link and Read It

```
1. Decode the /m/ URL (see section 7)
2. Try GET /api/v1/spaces/{space_uuid}/
3. If 40x, try GET /api/v1/spaces/{space_uuid}/workspace/?host_uuid={host_uuid}
4. If 40x, try GET /api/v1/spaces/public/{space_uuid}/{host_uuid}/
5. From the space response, get conversations and fetch transcripts
```

---

## Status Values

| Status | Description |
|--------|-------------|
| `COMPLETED` | Meeting processed, transcript ready |
| `SCHEDULED` | Bot scheduled for future meeting |
| `PROCESSING` | Transcription in progress |
| `FAILED` | Processing failed |
| `IN_CALL` | Bot is currently recording |
| `IN_WAITING_ROOM` | Bot waiting to be admitted |

## Recording Sources

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

### 9. Create a Room

```
POST /api/v1/spaces/
```

Create a new room (collaborative space for grouping meetings).

#### Example

```bash
curl -X POST "https://my.timeless.day/api/v1/spaces/" \
  -H "Authorization: Token $TIMELESS_TOKEN" \
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
| `has_onboarded` | boolean | ✅ | Always `true` |
| `space_type` | string | ✅ | Always `"ROOM"` for rooms |
| `title` | string | ✅ | Room title |

#### Response

Returns the full space object (same schema as Get Space). Extract `uuid` for subsequent operations.

---

### 10. Add Resource to Room

```
POST /api/v1/spaces/{space_uuid}/resources/
```

Attach a conversation (meeting recording) to a room. Call once per conversation you want to add.

#### Example

```bash
curl -X POST "https://my.timeless.day/api/v1/spaces/ROOM_UUID/resources/" \
  -H "Authorization: Token $TIMELESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "resource_type": "CONVERSATION",
    "resource_uuid": "CONVERSATION_UUID"
  }'
```

#### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `resource_type` | string | ✅ | `"CONVERSATION"` |
| `resource_uuid` | string | ✅ | UUID of the conversation to attach |

> **How to get conversation UUIDs:** From List Meetings, use `primary_conversation_uuid`. From Get Space, use `conversations[].uuid`.

---

### 11. Remove Resource from Room

```
DELETE /api/v1/spaces/{space_uuid}/resources/
```

Remove a conversation from a room.

#### Example

```bash
curl -X DELETE "https://my.timeless.day/api/v1/spaces/ROOM_UUID/resources/" \
  -H "Authorization: Token $TIMELESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "resource_type": "CONVERSATION",
    "resource_uuid": "CONVERSATION_UUID"
  }'
```

Same request body as Add Resource.

---

## Rate Limits

No official rate limits are documented for the internal API. Be respectful:
- Add 0.5s delay between sequential requests
- Don't make more than 60 requests per minute
- Use pagination instead of fetching everything at once

## Error Handling

| Code | Meaning |
|------|---------|
| 401 | Token expired or invalid. Re-authenticate. |
| 403 | No access to this resource. Try workspace/public endpoints. |
| 404 | Resource not found. |
| 429 | Rate limited. Back off and retry. |
| 500 | Server error. Retry with exponential backoff. |
