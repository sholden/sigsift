# Sigsift — Project Overview

Sigsift ("signal sift") is a lead-generation tool for small firms. A user defines what kind of business opportunity they're hunting for, points the system at sources where that kind of work shows up, and an AI agent scans those sources on a schedule. Findings land in a human-review queue; reviewed findings become tracked leads.

The initial use case is a 3-person architecture firm chasing public-works and commercial roofing projects. The data model and agent are deliberately generic — the same app should work for a wedding DJ tracking event venues or a consultant tracking RFPs.

---

## Vocabulary

These terms are load-bearing. The codebase uses them consistently and so should any engineer or agent working in it.

| Term | Meaning |
|---|---|
| **Account** | A tenant. The firm using Sigsift. One Account per firm; users belong to it. |
| **User** | A person logged into an Account. Rails 8 built-in auth. Single-user surface in v1; multi-user is in the data model. |
| **Opportunity** | *What* the firm is hunting for. Holds a `criteria_text` (free-form description, written by the user) and `criteria_structured` (JSON, extracted from the text by Claude). Was originally called "Signal" — renamed because Ruby has a `Signal` module. |
| **Source** | *Where* to look — a URL the agent will scan. Belongs to an Opportunity. Has a `description`, free-form `notes` (hints for the agent), and a `scan_frequency_days`. |
| **ScanRun** | One execution of the agent against one Source. Has a status (pending/running/completed/no_op/failed), a human-readable `summary`, and `agent_context` (JSON memory carried into the next run). |
| **ScanRunTrace** | The full conversation log of a ScanRun — every tool call, every model response, token usage. Stored separately so it doesn't bloat normal queries. Lazy-loaded for debugging. |
| **PotentialLead** | A raw finding the agent extracted. Belongs to a Source and to the ScanRun that first found it (`found_by`). Has a `review_status`: pending / created_lead / dismissed. The human-review queue. |
| **LeadDetection** | An immutable log entry: "this ScanRun saw this PotentialLead." A PotentialLead has many LeadDetections — one per scan that surfaced it. |
| **Lead** | A tracked business opportunity. Either created from a reviewed PotentialLead, or entered manually. Five statuses: new_lead / tracking / proposal_sent / won / lost. |
| **Client** | The prospect's organization. Stored as flat fields on Lead (`client_name`, `contact_name`, `contact_email`, etc.). Not a separate model. |

**Naming gotchas:**
- Lead status uses `new_lead`, not `new` (Ruby reserved-word collision)
- Status enum strings match the symbol names
- Don't reintroduce `Signal` — it collides with `Kernel#trap`'s neighborhood

---

## Conceptual flow

```
1. User creates an Opportunity         "Public works roofing in Louisiana"
2. User adds Sources                   bid boards, agency procurement pages, RFP feeds
3. Agent scans each Source on schedule (or on demand)
   ├── extracts up to N findings → PotentialLeads (with LeadDetection log)
   └── post-processor dedups against prior PotentialLeads
4. User reviews PotentialLeads         create_lead / dismiss
5. Reviewed → Lead                     moves through pipeline new → tracking → proposal_sent → won/lost
```

---

## Stack

- **Rails 8.1.3** with **SQLite**
- **Solid Queue** (jobs), **Solid Cache**, **Solid Cable** — the database-backed Rails 8 trio
- **Vite** + **TypeScript** + **Hotwire** (Turbo Drive/Streams + Stimulus) + **Tailwind v4** — frontend
- **`turbo-rails`** gem for server-side helpers (`turbo_stream_from`, `Turbo::StreamsChannel.broadcast_*`)
- **`anthropic`** gem (criteria extraction)
- **`ruby-llm`** gem (the scanning agent's tool-use loop, multi-provider abstraction)
- **`playwright-ruby-client`** + headless Chromium (browser automation for the agent)
- Rails 8 built-in **authentication** generator (no Devise)
- **Kamal** for deploys

---

## Layered architecture

```
app/
├── models/             ← associations, validations, enums, scopes ONLY
│                         No business logic. No callbacks running services.
├── controllers/        ← HTTP only: params → service call → respond
├── services/
│   ├── opportunities/  ← criteria extraction
│   ├── scanning/       ← the AI scanning agent (the bulk of the system)
│   │   ├── strategies/ (PlaywrightAgent, Stub)
│   │   ├── tools/      (RubyLLM::Tool subclasses for the agent)
│   │   ├── prompts/    (Ruby classes returning strings + tool defs)
│   │   ├── duplicate_detection/ (Fingerprint + 60-day cooldown)
│   │   ├── process_findings.rb
│   │   ├── llm_client.rb
│   │   └── scan_budget.rb
│   └── potential_leads/ ← review actions (create_lead, dismiss)
├── jobs/
│   ├── scan_source_job.rb           ← one source, one scan
│   ├── scheduled_scan_job.rb        ← nightly: enqueue overdue sources
│   └── extract_opportunity_criteria_job.rb
├── frontend/           ← Vite-managed: TS Stimulus controllers, CSS, entrypoints
└── views/              ← ERB + Turbo Streams
```

**Hard rule:** business logic lives in services, not models or controllers. Models hold structure (associations, validations, enums); controllers translate HTTP to service calls. Anything more substantive belongs in `app/services/`.

---

## The scanning agent (high level)

When a Source is due for a scan (or the user clicks "Scan Now"), `ScanSourceJob` runs an agent against the Source's URL. The agent is a Ruby tool-use loop:

1. `Scanning::Strategies::PlaywrightAgent` opens a fresh headless Chromium.
2. `Scanning::Prompts::PlaywrightAgent` builds the system + user message from the Opportunity, Source, and prior `agent_context`.
3. `ruby-llm` runs the multi-turn tool-use loop. The agent calls navigation/inspection/interaction tools that drive Playwright.
4. Tool results are minimal — DOM text on demand, no screenshots. Keeps token cost low.
5. Per-scan budget caps trip the loop early via `Scanning::ScanBudgetExceeded` if cost, time, or tool-call count exceed limits.
6. Agent terminates by calling either `submit_findings(...)` or `escalate(reason)`.
7. Findings flow through `Scanning::DuplicateDetection::Fingerprint` and become PotentialLeads + LeadDetections.

The agent is configured in `config/initializers/scanning.rb` — model, budget defaults, max findings. All overridable per-source later if needed.

For deeper detail on agent design decisions and rationale, see `memory/project_sigsift_agent.md` (Claude Code agent context).

---

## Failure handling

- **Transient errors** (Anthropic 429, net timeouts) — Solid Queue `retry_on` with backoff; don't count toward auto-pause.
- **Real failures** (escalation, budget exceeded, captcha) — increment `consecutive_failure_count` on the Source.
- **3 consecutive real failures** — Source flips to `paused`. Scheduled scans skip it. User sees a "needs attention" widget on the dashboard and a red marker on the Opportunity page. Manual re-activation via the source edit form.

---

## Observability

Every ScanRun records summary metrics (token counts, cost in cents, tool-call count) on the `scan_runs` row. The full conversation lives in `scan_run_traces` (separate table, lazy-loaded). The source page has a Turbo Frame "View trace" expander for debugging.

For local prompt iteration, use `bin/scan`:

```bash
bin/scan --source 7                                      # use a real source's config, no DB writes
bin/scan --url https://city.gov/bids --opportunity 1     # ad-hoc URL with overrides
bin/scan --url ... --opportunity 1 --notes "..." --no-prior-findings
```

It runs the real agent and prints the full trace; nothing is persisted. Good for tuning prompts without polluting data.

---

## Getting started

```bash
bin/setup           # bundle, npm install, db:setup, seeds
npx playwright install chromium    # one-time, for the agent
bin/dev             # rails + vite together, with signal forwarding
```

Default seeded user: `scott@holdenarchitecture.com` / `password`.

The Solid Queue `scanning` queue runs in-process via Rails default `:async` adapter in development. For recurring jobs (scheduled scans), run `bin/jobs` separately.

---

## Where to learn more

- `memory/project_sigsift.md` — agent context: stack, data model, naming
- `memory/project_sigsift_agent.md` — agent context: scanning agent design decisions
- Rails 8 + Hotwire docs for the framework basics
- `ruby-llm` docs (rubyllm.com) for the agent loop and tools API
- `playwright-ruby-client` README for browser-driving specifics
