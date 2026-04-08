# Timeless API Reference

This document covers both the **official public API** and the **unofficial API** used by Timeless Skills.

---

## Official Public API

**Base URL:** `https://api.timeless.day/v1`
**Auth:** `Authorization: Bearer YOUR_TOKEN`
**Docs:** [docs.timeless.day](https://docs.timeless.day/)
**Last Updated:** April 2026

### Authentication

```
Authorization: Bearer YOUR_TOKEN
```

Generate API tokens at [my.timeless.day/api-token](https://my.timeless.day/api-token). Tokens are 64-character hex strings.

### Pagination

Cursor-based. All list responses include:
```json
{
  "data": [...],
  "next_cursor": "eyJjcmV...",
  "has_more": true
}
```

Pass `cursor` as a query parameter. Control page size with `limit` (1-100, default 25).

### Resource IDs

| Resource | Prefix | Example |
|----------|--------|--------|
| Meeting | `mtg_` | `mtg_abc123` |
| Room | `room_` | `room_abc123` |
| Document | `doc_` | `doc_abc123` |
| User | `usr_` | `usr_abc123` |
| Speaker | `spk_` | `spk_abc123` |
| Webhook | `whk_` | `whk_abc123` |

### Error Format

```json
{
  "error": {
    "code": "not_found",
    "message": "Resource not found",
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
| 403 | `forbidden` | Token valid but lacks permission |
| 404 | `not_found` | Resource does not exist or not accessible |
| 429 | `rate_limited` | Too many requests |
| 500 | `internal_error` | Unexpected server error |

### Rate Limiting

| Endpoint | Limit |
|----------|-------|
| Most endpoints | 60 requests/minute |
| Webhook creation | 20 requests/minute |
| File upload | 10 requests/minute |

Headers on every response: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

---

### Endpoints

#### List Meetings

```
GET /meetings
```

Returns a paginated list of meetings.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `scope` | string | | `all` (default), `owned`, or `shared` |
| `status` | string | | `completed`, `processing`, `scheduled`, `failed` |
| `search` | string | | Search by title (substring match) |
| `q` | string | | Semantic search across meeting content |
| `start_date` | date | | From date (YYYY-MM-DD) |
| `end_date` | date | | To date (YYYY-MM-DD) |
| `participant` | string | | Filter by participant name or email |
| `company` | string | | Filter by company name or domain |
| `room_id` | string | | Filter by room ID |
| `id` | string[] | | Filter by meeting ID(s). Repeat for multiple. |
| `expand` | string | | `documents` to include inline |
| `cursor` | string | | Pagination cursor |
| `limit` | integer | | 1-100 (default 25) |

**Response schema:**
```json
{
  "data": [
    {
      "id": "mtg_abc123",
      "title": "Weekly standup",
      "status": "completed",
      "source": "google_meet",
      "start_time": "2026-01-15T10:00:00Z",
      "end_time": "2026-01-15T10:30:00Z",
      "duration": 1800,
      "host": {
        "id": "usr_def456",
        "name": "Alice Johnson",
        "email": "alice@example.com"
      },
      "participants": [
        {
          "name": "Bob Smith",
          "email": "bob@example.com",
          "title": "Engineer",
          "company": "Acme Corp"
        }
      ],
      "documents": [
        { "id": "doc_abc123", "title": "Meeting summary", "created_at": "2026-01-15T10:35:00Z" }
      ],
      "created_at": "2026-01-15T10:00:00Z"
    }
  ],
  "next_cursor": "eyJjcmV...",
  "has_more": true
}
```

**Meeting sources:** `google_meet`, `zoom`, `teams`, `slack`, `whatsapp`, `phone`, `upload`, `desktop`

**Meeting statuses:** `completed`, `processing`, `scheduled`, `failed`

---

#### Get Transcript

```
GET /meetings/{meeting_id}/transcript
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `meeting_id` | string | ✅ | Meeting ID (e.g., `mtg_abc123`) |

**Response schema:**
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
    }
  ]
}
```

---

#### Get Recording

```
GET /meetings/{meeting_id}/recording
```

Returns a temporary signed URL to download the recording.

**Response schema:**
```json
{
  "meeting_id": "mtg_abc123",
  "recording_url": "https://storage.example.com/recordings/abc123?token=..."
}
```

`recording_url` is `null` if no recording is available.

---

#### Get Document

```
GET /documents/{document_id}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `document_id` | string | ✅ | Document ID (e.g., `doc_abc123`) |
| `format` | string | | `html` (default), `markdown`, `raw`, `docx`, `json` |

**Response schema:**
```json
{
  "id": "doc_abc123",
  "title": "Meeting summary",
  "format": "markdown",
  "content": "# Weekly standup\n\n## Key decisions\n...",
  "created_at": "2026-01-15T10:35:00Z"
}
```

For `docx`, `content` is base64-encoded. For `json`, `content` is a JSON-serialized array of content blocks.

---

#### List Rooms

```
GET /rooms
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `scope` | string | | `all` (default), `owned`, or `shared` |
| `search` | string | | Search by title |
| `id` | string[] | | Filter by room ID(s) |
| `expand` | string | | `documents`, `meetings` |
| `cursor` | string | | Pagination cursor |
| `limit` | integer | | 1-100 (default 25) |

**Response schema:**
```json
{
  "data": [
    {
      "id": "room_abc123",
      "title": "Engineering standups",
      "created_at": "2026-01-01T00:00:00Z",
      "updated_at": "2026-01-15T10:30:00Z",
      "meeting_count": 42,
      "meetings": [...],
      "documents": [...]
    }
  ],
  "next_cursor": null,
  "has_more": false
}
```

---

#### Upload Media

```
PUT /meetings/upload
```

Upload raw binary file content (not multipart form data).

**Parameters:**
| Parameter | Location | Required | Description |
|-----------|----------|----------|-------------|
| `title` | query | | Recording title (max 500 chars) |
| `language` | query | | Language code (e.g., `en`) |
| `Content-Type` | header | ✅ | MIME type |

**Supported audio:** `audio/mpeg`, `audio/mp4`, `audio/wav`, `audio/webm`, `audio/ogg`, `audio/aac`, `audio/flac`
**Supported video:** `video/mp4`, `video/webm`, `video/ogg`, `video/quicktime`

**Response:** `{ "id": "mtg_abc123", "status": "processing" }`

Rate limit: 10 requests/minute.

---

#### Webhooks

##### Create Webhook

```
POST /webhooks
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `url` | string | ✅ | HTTPS URL (max 2048 chars) |
| `events` | string[] | ✅ | At least one event |
| `enabled` | boolean | | Default `true` |

**Events:** `meeting.transcript_ready`, `meeting.initial_summary_ready`

**Response includes `secret`** (only returned at creation time):
```json
{
  "id": "whk_abc123",
  "url": "https://example.com/webhooks",
  "events": ["meeting.transcript_ready"],
  "enabled": true,
  "secret": "a1b2c3d4e5f6...",
  "created_at": "2026-01-15T12:00:00Z",
  "updated_at": "2026-01-15T12:00:00Z"
}
```

##### List Webhooks

```
GET /webhooks
```

Returns array of webhooks (without `secret`).

##### Update Webhook

```
PATCH /webhooks/{webhook_id}
```

Partial update. Only include changed fields.

##### Delete Webhook

```
DELETE /webhooks/{webhook_id}
```

##### Webhook Signatures

Header: `X-Webhook-Signature: sha256=<hex HMAC-SHA256>`

Computed with the webhook `secret` as key and raw request body as message. Use constant-time comparison.

**Delivery:** 10s timeout, retries up to 3x (1s, 10s, 60s) for 5xx/429/network errors.

---

## Unofficial API

**Base URL:** `https://my.timeless.day`
**Auth:** `Authorization: Token YOUR_TOKEN`
**Last Updated:** March 2026

> These are internal API endpoints. They may change without notice. They are used for capabilities not yet available in the official API.

### Authentication

```
Authorization: Token YOUR_TOKEN
```

### Pagination

Page-based:
```json
{
  "count": 42,
  "next": "https://my.timeless.day/api/v1/spaces/meeting/?page=2",
  "previous": null,
  "results": [...]
}
```

### Endpoints

#### Get Space (Meeting or Room Details)

```
GET /api/v1/spaces/{uuid}/                           # Private
GET /api/v1/spaces/{uuid}/workspace/?host_uuid={id}  # Shared
GET /api/v1/spaces/public/{uuid}/{hostUuid}/          # Public
```

Returns full space details including `conversations[]`, `artifacts[]`, `contacts[]`, `organizations[]`, `threads[]`.

---

#### Chat with Meeting AI

```
POST /api/v1/agent/space/chat/
```

Sends a message; response is async. Poll the thread:

```
GET /api/v1/agent/threads/{thread_uuid}/
```

Until `is_running` is `false`.

---

#### Create a Room

```
POST /api/v1/spaces/
```

Body: `{"has_onboarded": true, "space_type": "ROOM", "title": "Room Title"}`

---

#### Add/Remove Conversation from Room

```
POST   /api/v1/spaces/{room_uuid}/resources/   # Add
DELETE /api/v1/spaces/{room_uuid}/resources/   # Remove
```

Body: `{"resource_type": "CONVERSATION", "resource_uuid": "CONV_UUID"}`

---

#### Get User Settings

```
GET /api/v1/users/
```

Returns user profile including `settings.identifier` for scheduling.

---

#### Create Scheduling Invite

```
POST /api/v1/invite/
```

See the `timeless-scheduling` skill for full details.

---

### Status Values

| Status | Description |
|--------|-------------|
| `COMPLETED` | Meeting processed, transcript ready |
| `SCHEDULED` | Bot scheduled for future meeting |
| `PROCESSING` | Transcription in progress |
| `FAILED` | Processing failed |
| `IN_CALL` | Bot is currently recording |
| `IN_WAITING_ROOM` | Bot waiting to be admitted |

### Recording Sources

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

### Error Handling

| Code | Action |
|------|--------|
| 401 | Token expired. Re-authenticate at my.timeless.day/api-token |
| 403 | No access. Try workspace or public endpoint. |
| 404 | Resource not found. |
| 429 | Rate limited. Back off and retry. |
| 500 | Server error. Retry with exponential backoff. |

### Rate Limits

No official limits. Be respectful:
- 0.5s delay between sequential requests
- Max ~60 requests per minute
- Use pagination
