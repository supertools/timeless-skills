This file should be appended to SKILL.md - see PR description for details.

The remaining sections of SKILL.md that were split due to size constraints:

## Scheduling

For meeting scheduling with productivity-first slot selection and curated invite links, read the `timeless-scheduling` skill.

---

## Notes

- Podcast MP3s can be large (100-300MB for long episodes). Downloads may take a minute.
- YouTube downloads require yt-dlp. If not installed, the script will fail with a clear error.
- Always clean up downloaded files from /tmp after uploading.
- Set `YTDLP_PATH` env var if yt-dlp is not on PATH.

---

## Error Handling

### Official API

Structured error responses:
```json
{ "error": { "code": "not_found", "message": "Resource not found" } }
```

| Code | Error Code | Action |
|------|-----------|--------|
| 400 | `bad_request` | Invalid parameters. Check `details` array for field-level errors. |
| 401 | `unauthorized` | Token expired. Re-authenticate at my.timeless.day/api-token |
| 403 | `forbidden` | Valid token but insufficient permissions. |
| 404 | `not_found` | Resource not found. Check ID. |
| 429 | `rate_limited` | Too many requests. Check `Retry-After` header. |
| 500 | `internal_error` | Server error. Retry with backoff. |

Rate limit headers on every response: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

### Unofficial API

| Code | Action |
|------|--------|
| 401 | Token expired. Re-authenticate at my.timeless.day/api-token |
| 403 | No access. Try workspace or public endpoint. |
| 404 | Not found. Check UUID. |
| 429 | Rate limited. Wait and retry. |

## Rate Limiting

- **Official API**: 60 requests/minute (most endpoints), 20/minute (webhooks), 10/minute (uploads).
- **Unofficial API**: No official limits, but be respectful: 0.5s delay between requests, max ~60 per minute.
