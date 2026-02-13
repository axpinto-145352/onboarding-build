# Veteran Vectors — Consolidated Agent Audit Report

**Date:** 2026-02-12
**Agents Run:** Security Auditor, Data Integrity Validator, Cost & Efficiency Optimizer, Pipeline Continuity Validator, Quality Gate Enforcer
**Scope:** All 5 n8n workflow JSONs (WF1-WF5), architecture docs, agents team prompt
**Mode:** READ-ONLY audit — no files modified

---

## Executive Summary

Five specialized agents audited the full onboarding automation system. Across all agents, the audit identified:

- **3 CRITICAL** security vulnerabilities (unauthenticated webhooks)
- **2 CRITICAL** pipeline gaps (no proposal delivery to client, BlueDot/WF1 race condition)
- **12 HIGH** severity findings across security, data integrity, and pipeline continuity
- **~20 MEDIUM** findings covering injection risks, data leaks, and sync gaps
- **Estimated pipeline cost:** $1.40–$2.76 per lead (optimizable to $1.23–$2.03)
- **3 unbuilt workflows** needed (WF0, WF1.5, WF2.5) — priority order: WF2.5 first

The single most critical finding across all agents: **WF2 sets status "Proposal Sent" immediately after generation, but no proposal is ever delivered to the client.** This creates a false audit trail and means every proposal must be manually emailed outside the system.

---

## Agent 1: Security Auditor — 22 Findings

### CRITICAL (3)

| ID | Workflow | Finding |
|----|----------|---------|
| SEC-004 | WF1 | **Calendly webhook has no signature verification.** Attackers can POST fabricated booking data, poisoning the Prospects Sheet. |
| SEC-005 | WF2 | **BlueDot webhook has no signature verification.** Attackers can inject crafted transcripts that flow into the Claude API and generate proposals with attacker-controlled content. Highest risk — bridges untrusted input into AI + document generation. |
| SEC-006 | WF5 | **SignWell webhook has no signature verification.** Attackers can trigger invoice sending, Slack channel creation, and welcome emails by posting fake `document.completed` events. |

### HIGH (5)

| ID | Workflow | Finding |
|----|----------|---------|
| SEC-007 | WF3 | Onboarding form has no authentication or CAPTCHA. Anyone with the URL can submit arbitrary data creating contracts and invoices. |
| SEC-008 | WF2 | Raw transcript text injected into Claude API JSON body without escaping. Quotes/backslashes break the JSON; prompt injection possible. |
| SEC-009 | WF5 | Client data (Project, Company) interpolated into Slack API JSON bodies without escaping. |
| SEC-010 | WF3 | Form input values interpolated into SignWell API JSON body without escaping. Attacker-crafted names could alter JSON structure. |
| SEC-019 | WF5 | No replay protection. Duplicate SignWell webhooks re-send invoices, re-create Slack channels, and re-send welcome emails. |

### MEDIUM (9)

| ID | Summary |
|----|---------|
| SEC-002 | No `.gitignore` — real credentials could be accidentally committed |
| SEC-011 | Google Sheets formula injection via `cellFormat: USER_ENTERED` (=, +, -, @ prefixes) |
| SEC-012 | SSRF risk — `completed_pdf_url` from webhook used directly in HTTP GET |
| SEC-013 | Unsanitized data in Google Docs batchUpdate JSON body |
| SEC-014 | Client email posted to #onboarding-alerts Slack channel |
| SEC-015 | Pre-filled form URL with full PII posted to Slack |
| SEC-016 | Client Slack channels created as public (`is_private: false`) |
| SEC-020 | No Stripe idempotency keys — duplicate form submissions create duplicate customers/invoices |
| SEC-021 | WF2 idempotency check bypassable for non-"Proposal Sent" statuses |

### Top Security Priority
1. Add webhook signature verification to WF1, WF2, WF5 (SEC-004/005/006)
2. Add replay protection to WF5 (SEC-019)
3. Fix JSON injection in all HTTP Request bodies (SEC-008/009/010)
4. Add form authentication (SEC-007)

---

## Agent 2: Data Integrity Validator — 14 Findings

### HIGH (4)

| ID | Finding |
|----|---------|
| DATA-5 | **Prospect_ID created by WF1 but completely unused by WF2.** WF2 uses fragile name-in-transcript matching instead of the reliable Prospect_ID. |
| DATA-7 | **Stripe failure after SignWell send creates unrecoverable state.** If Stripe API fails in WF3, no Client Tracker row exists, but the contract HAS been sent. WF5 will fail with no matching record. |
| DATA-8 | **No null check on Invoice_ID in WF5.** Empty Invoice_ID produces malformed Stripe URL `/invoices//send`, breaking the entire downstream chain (no Slack channel, no email, no onboarding). |
| DATA-14 | **Dual branch convergence in WF5 causes duplicate welcome emails.** Both parallel paths (Slack + Checklist) feed into "Send Welcome Email", which fires twice. |

### MEDIUM (6)

| ID | Finding |
|----|---------|
| DATA-3 | WF2 processes prospects regardless of status (no guard for non-"Audit Scheduled" states) |
| DATA-6 | WF3 Company_Name fallback in folder lookup can return wrong prospect's folder |
| DATA-9 | Manually edited Contract_Sent_Date silently suppresses all reminders (parsed as NaN, skipped) |
| DATA-10 | WF4 uses Email as lookup — not unique for multi-project clients |
| DATA-11 | Naming inconsistency: `Full_Name` (Prospects) vs `Full_Client_Name` (form) vs `Client_Name` (Tracker) |
| DATA-12 | No null check on Drive_Folder_ID in WF5 — empty value cascades failures |

### Column Alignment
All column names match exactly between workflows for both sheets. No spelling mismatches found. Status transitions are valid and sequential.

---

## Agent 3: Cost & Efficiency Optimizer — 7 Findings

### Cost-Per-Lead Breakdown

| Component | Cost |
|-----------|------|
| Claude API (Sonnet) | $0.056 |
| SignWell (per-document) | ~$1.00 |
| n8n executions (~34/lead) | $0.34–$1.70 |
| Google APIs | $0.00 (quota-based) |
| Slack, Gmail | $0.00 |
| **Total per lead** | **$1.40–$2.76** |

### Top Optimizations

| ID | Change | Savings | Risk |
|----|--------|---------|------|
| COST-1 | Split Claude into Haiku (extraction) + Sonnet (narrative) | 52% on AI costs | LOW |
| COST-4A/B/C | Filter webhook subscriptions at source (Calendly, BlueDot, SignWell) | 50-80% fewer n8n executions | LOW |
| COST-6 | WF4 weekday-only schedule | 29% fewer daily executions | VERY LOW |
| COST-2 | Filter WF4 Google Sheets reads | 95% fewer rows transferred | LOW |
| COST-3 | Remove PDF export+upload if Google Doc suffices | 40% fewer Drive API calls | MEDIUM |
| COST-5 | Merge Slack channel topic into create; batch WF4 escalations | 14% fewer Slack calls | LOW |

**Optimized cost per lead: $1.23–$2.03 (12-27% savings)**

The dominant cost drivers are SignWell per-document fees and n8n execution overhead — not the AI.

---

## Agent 4: Pipeline Continuity Validator — 23 Gaps, 4 Race Conditions

### CRITICAL Gaps

| ID | Stage | Finding |
|----|-------|---------|
| GAP-08 | 2 | **WF2 title filter only matches "audit" or "RAPID".** Calls titled "discovery", "intro", or "meeting" are silently dropped. No error, no notification. Proposal never generated. |
| GAP-12 | 3 | **No automated proposal delivery to client.** WF2 generates the proposal but nothing sends it to the client. Anthony must manually email every proposal. |

### Race Conditions

| ID | Severity | Finding |
|----|----------|---------|
| RACE-01 | CRITICAL | **BlueDot fires before WF1 creates the Prospect row.** If a short call ends while the Calendly webhook is still processing, WF2 finds no match and hard-stops. No retry. No notification. |
| RACE-02 | HIGH | **Duplicate BlueDot webhooks** cause concurrent WF2 executions, both passing the idempotency check (Drive_Folder_ID still empty), creating duplicate folders/proposals. |
| RACE-03 | MEDIUM | WF4 `Last_Reminder_Sent` overwrites previous value instead of appending — fragile deduplication. |
| RACE-04 | MEDIUM | WF5 parallel branches both trigger "Send Welcome Email" — potential duplicate emails. |

### Notion Sync Deficit
**None of the 5 built workflows write to Notion.** Notion is designated as the CRM but is completely disconnected from the operational pipeline. Every lead's Notion record stays at whatever status it had before the system took over.

### Priority Order for New Workflows
1. **WF2.5** (Proposal Review + Delivery) — Closes the critical gap between proposal generation and client receipt
2. **WF0** (Prospector Lead Capture) — Creates data foundation for top-of-funnel visibility
3. **WF1.5** (Loom Outreach + Follow-Up) — Adds operational polish; core action must stay manual

### Manual Steps That SHOULD Stay Manual
1. Conducting the audit call (core business value)
2. Reviewing the AI-generated proposal (CRITICAL quality gate)
3. Submitting the onboarding form (financial/legal quality gate)
4. Recording personalized Loom videos (differentiation)
5. 14-day escalation response (relationship judgment)
6. Deciding email vs LinkedIn for proposal delivery (context-dependent)

---

## Agent 5: Quality Gate Enforcer — 8 Gates Audited

### Gate Status Summary

| Gate | Type | Status | Verdict |
|------|------|--------|---------|
| QG-1: Proposal Review | HARD (intended) | **BYPASSABLE** | "Proposal Sent" set before review. Slack failure orphans proposal. |
| QG-2: Form Access | HARD | **ENFORCED** | Form URL internal-only. Amounts editable by design. |
| QG-3: Invoice Timing | HARD | **ENFORCED** | `auto_advance=false` confirmed. Invoice sent only post-signing. |
| QG-4: Follow-up Emails | AUTOMATED | **ENFORCED** | Professional templates. No debug data. 30-day expire is internal-only. |
| QG-5: Proposal Delivery | NONE | **MISSING** | No mechanism to deliver proposal to client exists. |
| QG-6a: Booking Intake | AUTOMATED | **ENFORCED** | No client-facing actions. Safe. |
| QG-6b: Contract Send | HARD | **ENFORCED** | Gated by form submission. Anthony must act. |
| QG-6c: Post-Signing | HARD | **ENFORCED** | Gated by SignWell `document.completed`. Requires actual signature. |

### Critical Finding: "Proposal Sent" Is a Lie
WF2 node `wf2-node-13` writes `"Status": "Proposal Sent"` to the Prospects Sheet immediately after generating the proposal — before Anthony reviews it and before it is delivered to the client. The proposal is never automatically delivered. The status creates a false audit trail.

**Fix:** Change status to `"Proposal Draft"` in WF2. Add a separate trigger (WF2.5) that sets `"Proposal Sent"` only after Anthony explicitly approves and the proposal is delivered.

### Retainer Subscription Timing Risk
WF3 creates the Stripe retainer subscription (`collection_method: "send_invoice"`) before the contract is signed. Depending on billing cycle timing, a retainer invoice could be generated before the client signs. Recommendation: move subscription creation to WF5 (post-signing) or create it paused.

---

## Cross-Agent Priority Matrix

### P0 — Fix Immediately (Before Production)

| Finding | Agents | Action |
|---------|--------|--------|
| Webhook auth on WF1, WF2, WF5 | Security + Pipeline | Add HMAC signature verification to all 3 webhooks |
| WF2 status: "Proposal Sent" → "Proposal Draft" | Quality Gate + Pipeline | Change one string in WF2 JSON |
| WF5 replay protection | Security + Data Integrity | Add idempotency check: skip if Status = "Onboarded" |
| WF5 Invoice_ID null check | Data Integrity + Pipeline | Add validation before Stripe send |
| WF5 duplicate welcome email | Data Integrity + Pipeline | Add Merge (Wait for All) node before Send Welcome Email |

### P1 — Fix Before Scale (1-3 clients/month)

| Finding | Agents | Action |
|---------|--------|--------|
| JSON injection in WF2/WF3/WF5 | Security | Use `JSON.stringify()` for all interpolated values |
| WF3 idempotency | Security + Pipeline | Add duplicate check before SignWell/Stripe calls |
| Form authentication | Security | Add secret token to form URL |
| Stripe idempotency keys | Security | Add `Idempotency-Key` header to all Stripe calls |
| WF2 title filter expansion | Pipeline | Add "discovery", "intro", "call" to filter conditions |

### P2 — Build New Workflows

| Priority | Workflow | Agents | Purpose |
|----------|----------|--------|---------|
| 1st | WF2.5: Proposal Review + Delivery | Pipeline + Quality Gate | Close the proposal-to-client gap |
| 2nd | WF0: Prospector Lead Capture | Pipeline | Top-of-funnel visibility |
| 3rd | WF1.5: Loom + Follow-Up | Pipeline | Operational polish |
| All | Notion sync in WF1, WF2, WF3, WF5 | Pipeline + Data Integrity | Connect CRM to operational pipeline |

### P3 — Optimize for Efficiency

| Finding | Agent | Savings |
|---------|-------|---------|
| Filter webhook subscriptions at source | Cost | 50-80% fewer n8n executions |
| Split Claude into Haiku + Sonnet | Cost | 52% AI cost reduction |
| WF4 weekday-only schedule | Cost | 29% fewer daily runs |
| Make client Slack channels private | Security | Prevents data leakage |
| Add `.gitignore` | Security | Prevents accidental credential commits |
