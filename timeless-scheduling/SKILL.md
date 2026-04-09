---
name: timeless-scheduling
description: Schedule meetings using Timeless scheduling system with productivity-first slot selection. Create scheduling invites with curated time slots and share scheduling links. Use when the user wants to schedule a meeting, find available times, send a scheduling link, create a meeting invite, or coordinate a call with someone.
version: 1.0.0
metadata:
  openclaw:
    requires:
      env:
        - TIMELESS_ACCESS_TOKEN
      bins:
        - curl
    primaryEnv: TIMELESS_ACCESS_TOKEN
    emoji: "\U0001F4C5"
    homepage: https://github.com/supertools/timeless-skills
---

# Timeless Scheduling

> **Source**: [github.com/supertools/timeless-skills](https://github.com/supertools/timeless-skills)

Schedule meetings via the Timeless scheduling system. Requires `TIMELESS_ACCESS_TOKEN` env var.

## Prerequisites

- `TIMELESS_ACCESS_TOKEN` env var (get token at [my.timeless.day/api-token](https://my.timeless.day/api-token))

Set up in OpenClaw:
```bash
openclaw config patch env.vars.TIMELESS_ACCESS_TOKEN=<your_token>
```

## First-Time Setup

### 1. Get Scheduling Identifier

On first use, fetch the scheduling identifier:
```bash
curl -s https://my.timeless.day/api/v1/users/ \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN" | jq -r '.settings.identifier'
```
Save this identifier. The scheduling link is: `https://my.timeless.day/{identifier}`

### 2. Ask for Work Preferences (Once)

Before scheduling anything, ask the user:
- **Work days** (e.g. Sunday through Thursday, Monday through Friday)
- **Work hours** (e.g. 9:00 AM to 6:00 PM)
- **Timezone**

Save these preferences and never ask again.

---

## Context Gathering (Before Scheduling)

Before selecting slots, gather context about the meeting to determine authority, duration, urgency, and attendees.

**Where to look:** conversation history, email threads, chat/messaging history (Slack, Telegram), calendar.

**What to extract:**
- **Purpose:** Topic (used for title and description)
- **Authority:** Who initiated? Who needs whose time?
- **Urgency:** Deadline-driven? This week or "sometime soon"?
- **Duration:** Quick sync (15-30 min) or deep-dive (60+ min)?
- **Attendees:** Required vs. optional
- **Existing context:** Times already proposed or rejected

---

## Scheduling Decision Tree

### Internal Meetings (Team/Colleagues)
- Find the best time for most attendees
- Prioritize senior attendee calendars first
- Schedule directly on the calendar

### External Meetings

Determine authority:

**They have authority** (you are requesting their time):
Share the open scheduling link:
> "Here is my scheduling link: https://my.timeless.day/{identifier}
> Feel free to pick a slot, or if you prefer, share time slots that work for you."

**You have authority** (they are requesting your time):
- Find optimal time slots using productivity principles below
- Create a specific-slots invite
- Share the invite link with suggested times

---

## Productivity-First Slot Selection

When selecting time slots:

1. **Protect deep work blocks.** Never place a meeting in the middle of an uninterrupted stretch.
2. **Batch meetings together.** Place meetings adjacent to existing ones or at day edges.
3. **Avoid fragmentation.** A 1-hour gap between meetings is wasted; eliminate or fill it.
4. **Respect energy cycles.** Schedule meetings in the afternoon when possible (mornings for deep work).
5. **Buffer time.** Leave 5-10 minutes between back-to-back meetings.
6. **Respect work hours and days.** Never suggest slots outside configured hours/days.

**Bad:** 30-min call at 11:00 AM when meetings exist at 9:30 and 12:30, fragmenting a 3-hour block.
**Good:** Schedule at 12:00 PM right before the 12:30 meeting, preserving the morning.

---

## Creating Specific-Slot Invites

```bash
curl -X POST https://my.timeless.day/api/v1/invite/ \
  -H "Authorization: Token $TIMELESS_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Meeting Title",
    "duration": 30,
    "description": "",
    "suggestions": [
      {
        "start_ts": "2026-03-18T13:00:00.000Z",
        "end_ts": "2026-03-18T13:30:00.000Z"
      },
      {
        "start_ts": "2026-03-18T14:00:00.000Z",
        "end_ts": "2026-03-18T14:30:00.000Z"
      }
    ],
    "currentPageIndex": 0,
    "uuid": null,
    "locationType": 1,
    "vc_url": "GENERATE_GOOGLE_MEET",
    "location": "",
    "sharedNote": {"type": "doc", "content": [{"type": "paragraph"}]},
    "privateNote": {"type": "doc", "content": [{"type": "paragraph"}]},
    "sharedNotePermissions": "VIEW",
    "type": "ONE_ON_ONE",
    "is_negotiable": true,
    "timezone": "USER_TIMEZONE_HERE",
    "scheduling_settings_uuid": "SCHEDULING_SETTINGS_UUID"
  }'
```

**Response** returns an invite with a UUID. The scheduling link is:
```
https://my.timeless.day/{identifier}/i/{invite_uuid}
```

---

## Scheduling Link Formats

| Type | URL |
|------|-----|
| Open (general availability) | `https://my.timeless.day/{identifier}` |
| Specific slots (curated times) | `https://my.timeless.day/{identifier}/i/{invite_uuid}` |

---

## Best Practices

- Suggest 2-4 time slots for flexibility
- Use descriptive meeting titles that explain the purpose
- Default to Google Meet for video calls unless specified otherwise
- Include context in the meeting description when relevant
- Default to 30-minute meetings unless a longer session is needed

## Writing Style

When composing messages, titles, and descriptions:
- **Never use apostrophes.** Write "do not" instead of "don't", "here is" instead of "here's".
- **Never use em dashes, en dashes, or double dashes.** Use colons, semicolons, commas, or separate sentences.

---

## Error Handling

| Code | Action |
|------|--------|
| 401 | Token expired. Re-authenticate at my.timeless.day/api-token |
| 403 | No access. Check permissions. |
| 404 | Not found. Check UUID. |
| 429 | Rate limited. Wait and retry. |
