# Smart Worklog Assist — API Reference

The backend contract the Epico React/MUI UI builds against. All endpoints are
JSON, namespaced under `/api/v1`.

## Conventions

- **Success:** `{ "data": <object|array>, "meta": { ... } }`
- **Error:** `{ "error": { "code", "message", "details", "request_id" } }`
- **Content-Type:** `application/json`

### Authentication

Prototype shim: the current user is resolved from the `X-User-Id` request header,
falling back to the first seeded user. **In Epico this is replaced by the portal's
real session auth** — every endpoint operates on "the current user".

```
X-User-Id: 7
```

### Status codes

`200` OK · `201` Created · `204` No Content · `400` bad_request ·
`404` not_found · `422` validation_failed / invalid_provider.

---

## Integrations (per-user account connections)

The engineer connects their own GitHub (and optionally Shortcut) account. The
token is stored **encrypted at rest and never returned**.

### `GET /api/v1/integrations`
List the current user's connections.

```json
{ "data": [
  { "provider": "github", "status": "connected", "scopes": "repo",
    "connected_at": "2026-06-07T18:27:19.552Z" }
], "meta": {} }
```

### `POST /api/v1/integrations`
Connect (or update) an account. Prototype = paste a token (GitHub PAT); in Epico
GitHub uses the OAuth redirect and stores the resulting token here the same way.

Request:
```json
{ "provider": "github", "access_token": "ghp_...", "scopes": "repo" }
```
Response `201`: the connection object (no token). Unknown provider → `422`
(`invalid_provider`). Missing field → `400`.

### `DELETE /api/v1/integrations/:provider`
Disconnect; deletes the stored token. `204` on success, `404` if not connected.

---

## Worklog drafts

### `POST /api/v1/worklogs/auto_draft`
Generate drafts for the current user's **missing** days that month, built from
their connected GitHub activity. Returns `[]` if no GitHub account is connected.
**Never auto-publishes** — drafts await acceptance.

Request:
```json
{ "year": 2026, "month": 6 }
```
Response `201`:
```json
{ "data": [
  { "id": 3, "project": "Mocingbird", "work_date": "2026-06-05", "hours": "8.0",
    "description": "Story -> sc-169861\n1. point PR #11832 base to staging-next\n2. bump nokogiri, commit & push",
    "source_refs": ["github:org/epp:PR#11832", "github:org/epp:commit:06bde00"],
    "origin": "ai", "status": "suggested" }
], "meta": { "count": 1 } }
```

### `GET /api/v1/worklog_drafts`
List the current user's pending (`suggested`) drafts. Same draft shape as above.

### `POST /api/v1/worklog_drafts/:id/accept`
Promote a draft into a real worklog (the "Accept" action). Marks the draft
`accepted`. `404` if the draft isn't the current user's.

Response `201`:
```json
{ "data": { "worklog_id": 18, "draft": { "id": 3, "...": "...", "status": "accepted" } }, "meta": {} }
```

### Draft object fields

| field | notes |
|---|---|
| `id` | draft id |
| `project` | project name the activity mapped to |
| `work_date` | the day being drafted |
| `hours` | from the user's allocation (default 8) |
| `description` | the composed worklog text |
| `source_refs` | provenance, e.g. `["github:org/epp:PR#11832"]` |
| `origin` | `ai` or `deterministic` |
| `status` | `suggested` → `accepted` / `dismissed` |

---

## Typical UI flow (maps to the React screens)

1. **Settings → Connect GitHub** → `POST /api/v1/integrations`
2. **Worklog page → "Refresh from GitHub"** → `POST /api/v1/worklogs/auto_draft`
   → render returned drafts as "✨ Draft ready" rows
3. **Review** a draft (edit text/hours client-side if desired)
4. **Accept** → `POST /api/v1/worklog_drafts/:id/accept` → row becomes a saved worklog

## What Epico provides vs. this prototype

- **Missing-day detection** (weekend/holiday/leave/missing) already exists in Epico —
  this prototype recreates it (`Worklogs::MissingDayResolver`) only to run standalone.
  On port, feed Epico's existing missing-days into the drafting services instead.
- **Auth, the worklog table UI, and the "Connect GitHub" button** are built in Epico's
  React app; this backend supplies the data and decisions behind them.
