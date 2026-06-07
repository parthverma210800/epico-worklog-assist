# Epico — Smart Worklog Assist (Prototype)

A standalone Rails API prototype for **Smart Worklog Assist**, a feature designed to be ported
into the Epico ERP portal (https://mindbowser.epico.ai). It reduces "Missing Worklog" / Overdue
worklogs by auto-drafting timesheet entries from each engineer's own GitHub activity (PRs,
commits, reviews) plus Shortcut story context, and expanding them into detailed, structured
worklog entries with an AI composer. The engineer reviews and confirms — no silent writes.

> This repo is a **reference/spike** built TDD-first with stubbed GitHub/LLM and seed data.
> Once validated, the models, service objects, and endpoints port into the Epico monolith
> (Rails API + React/MUI) behind a feature flag, piloted, then rolled out org-wide.

## Why

Engineers write rich, multi-step worklogs (referencing Shortcut stories, GitHub PRs, commits),
which is valuable but laborious — so many days go unlogged. The bottleneck is the *effort of
transcribing* what the engineer already did, not missing data. This feature removes that effort.

## Key design decisions

- **Per-user delegated access:** clients won't grant org-level repo access, so each engineer
  connects their *own* GitHub/Shortcut account; Epico reads only what that user can already see.
- **Both mechanisms:** deterministic assist (hour pre-fill, skip weekend/leave/holiday,
  copy-forward) **+** an AI composer (approved cloud LLM, zero-retention).
- **Draft-and-confirm by default:** auto-draft, human accepts. Optional auto-publish later.
- **Delivery: port into the Epico monolith** (Model A).

## Stack

- Ruby 3.3, Rails 8.1 (API-only), **PostgreSQL**
- RSpec + FactoryBot, WebMock/VCR for stubbed integrations
- Sidekiq (background auto-draft job)

## Local setup

```bash
bundle install            # installs into vendor/bundle
bin/rails db:create db:migrate
bin/rails server
```

## Build order (small incremental commits)

1. Rails API scaffold (PostgreSQL) ✅
2. RSpec / FactoryBot / WebMock test setup
3. Schema: `users`, `projects`, `allocations`, `leaves`, `holidays`, `worklogs`,
   `integration_connections`, `project_repositories`, `worklog_drafts`
4. `Worklog::MissingDayResolver` (classify each day)
5. `Worklog::Prefiller` (deterministic suggestions)
6. `assist` + `bulk` endpoints — Phase 1, deterministic
7. `Integrations::Github::Client` + `Worklog::ActivityFetcher` (stubbed HTTP)
8. `Worklog::LlmClient` + `Worklog::AiComposer` + `AutoDraftJob` + `auto-draft`/`compose`
   endpoints — Phase 2, GitHub auto-read
