# Frontend Integration — Smart Worklog Assist

How the Epico React/MUI app wires up the "Auto Draft from PR" feature. Backend
contract is in [`API.md`](API.md); an importable Postman collection is in
[`postman/`](postman/).

## The real "Add workLog" form (observed on Epico)

Project → **Timesheet** → **Worklogs** tab → **Add Worklog** opens a dialog with:

- **Select date for work log*** — date picker
- Checkboxes: **On full day leave** · **On half day leave** · **Holiday**
- **Hours*** — number spinner
- **Description*** — rich-text editor (Bold / Italic / Underline / link, style dropdown)
- Action row: **⚡ Rewrite with AI**, **Add**, then **Submit**

The form already classifies non-working days (the checkboxes) — so the backend's
`MissingDayResolver` is prototype-only and is NOT needed in Epico.

## What we add: one button

Place a new button **immediately to the left of "Rewrite with AI"**:

```
[ ✨ Auto Draft from PR ]   [ ⚡ Rewrite with AI ]   [ Add ]            [ Submit ]
```

Two distinct AI actions, side by side:
- **Auto Draft from PR (new):** description is empty → generate it from the user's
  GitHub commits/PRs for the selected date on this project.
- **Rewrite with AI (existing):** there is text → polish/rephrase it. Unchanged.

## Button behavior

On click, using the form's current **date** and **hours**:

```js
setDrafting(true);
try {
  const { data, meta } = await api.post(
    `/api/v1/projects/${projectId}/worklogs/compose`,
    { date: form.date, hours: form.hours }   // date as YYYY-MM-DD
  );
  if (data) {
    descriptionEditor.setHTML(toHtml(data.description)); // fill rich-text editor
    setSourceChips(data.source_refs);                    // e.g. "PR #11832"
  } else {
    toast.info(meta.message); // "No GitHub activity found for ... on <date>"
  }
} catch (e) {
  if (e.status === 502) toast.error("Couldn't draft right now — try again.");
} finally {
  setDrafting(false);
}
```

- The endpoint returns a plain-text, multi-line `description` (newline-separated
  steps grouped by story). Convert newlines to the editor's paragraph nodes when
  inserting — don't drop it in as one blob.
- `hours` comes back echoed (from the form, or the user's allocation default);
  the form already has its own hours field, so just keep the user's value.
- Result is **editable** — this only pre-fills the Description; the user reviews
  and clicks the form's normal **Submit** to save. (No separate save call needed;
  Auto Draft only writes into the form.)

## States to handle

| Response | Meaning | UI |
|---|---|---|
| `201` + `data` | draft generated | fill Description, show source chips |
| `201` + `data: null`, `meta.message` | no GitHub activity that day | inline note, leave Description empty |
| `502 ai_unavailable` | LLM key/outage | toast, let user type manually |
| GitHub not connected | returns the no-activity shape | nudge: "Connect GitHub in Settings to auto-draft" |

Disable / show a spinner on the button while `drafting`.

## One-time setup elsewhere: Connect GitHub

A small **Connected Accounts** panel (Settings):

```js
api.get("/api/v1/integrations")                       // list -> show status chip
api.post("/api/v1/integrations",   { provider:"github", access_token, scopes:"repo" })
api.delete(`/api/v1/integrations/github`)             // disconnect
```

The token is stored encrypted server-side and never returned.

## Division of labor

- **UI team builds:** the **Auto Draft from PR** button (one button + loading/error
  states) and the **Connected Accounts** panel. Renders whatever `compose` returns.
- **This backend owns:** GitHub fetch, repo→project mapping, AI composition, and
  the contract. Nothing about GitHub/Claude touches the React code — it's all
  behind the `compose` call.

## Auth

Every call carries the current user. Prototype uses an `X-User-Id` header; in
Epico it rides the existing session — use the standard API client, no special handling.
