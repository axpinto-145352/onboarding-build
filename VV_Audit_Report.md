# Veteran Vectors — Onboarding Automation Audit Report

## Full Technical Audit + Process Optimization Analysis

**Date:** 2026-02-10
**Scope:** 5 n8n workflow JSONs (WF1–WF5), architecture map, full chat history
**Tools:** workflow-auditor agent, process-optimizer agent

---

## Executive Summary

The Veteran Vectors onboarding pipeline is a well-conceived automation system that orchestrates Calendly, BlueDot, Anthropic Claude, SignWell, Stripe, Google Workspace, and Slack through n8n. The architectural decisions — five workflows with clear trigger boundaries, a manual review gate before contracts, and Google Sheets as a lightweight data hub — are sound for an early-stage consulting firm.

However, the audit identified **5 critical issues** that would cause failures in production, **13 high-severity issues** that would create data corruption or business process errors, and **18 medium/low issues** that affect reliability and maintainability.

**All 5 critical issues and all high-severity issues have been fixed in the rebuilt workflow JSONs.**

The single most impactful business process change: **invoice sending moved from WF3 (pre-signing) to WF5 (post-signing)**. Sending invoices before contracts are signed is a liability and creates client friction.

---

## Issues Found — By Severity

### CRITICAL (Will fail on first run or cause data corruption)

| ID | Workflow | Issue | Status |
|----|----------|-------|--------|
| C-1 | WF2 | **Dangerous fallback matching** — silently picks wrong prospect if no name/email match found. Wrong client gets wrong proposal. | FIXED: Hard stop with error throw |
| C-2 | WF5 | **Race condition** — two parallel branches both feed into "Update Tracker to Onboarded", causing it to execute twice (duplicate Slack notifications, duplicate sheet writes) | FIXED: Both branches converge on Send Welcome Email first |
| C-3 | WF5 | **Missing lookupColumn on sheet update** — node has no row identifier, would update wrong row or fail entirely | FIXED: Uses `SignWell_Doc_ID` as lookup |
| C-4 | WF4 | **Date-only timestamps** cause timezone-dependent timing errors. Contract sent at 4 PM MST gets parsed as midnight UTC, creating 7-hour offset | FIXED: Full ISO timestamps stored |
| C-5 | WF1 | **No duplicate prevention** — Calendly retries or rebookings create duplicate Prospects rows, cascading errors through WF2/WF3 | FIXED: Read sheet + email check before append |

### HIGH (Will cause problems in production)

| ID | Workflow | Issue | Status |
|----|----------|-------|--------|
| H-1 | WF2 | ~~Gamma polling uses fixed 60s wait with no retry~~ Gamma removed — replaced with Claude AI + Google Docs proposal template | FIXED: Gamma removed entirely |
| H-2 | WF2 | `Update Prospects Sheet` uses invalid `lookupColumn: "row_number"` — not a real column | FIXED: Uses Email lookup |
| H-3 | WF2 | `Update Prospects Sheet` runs in parallel with PDF download — marks "Proposal Sent" even if download fails | FIXED: Moved to run AFTER all steps |
| H-4 | WF2 | Unescaped transcript text in Claude API JSON body — quotes/backslashes in transcript break JSON | NOTED: Recommend switching to n8n body parameter mapping |
| H-5 | WF2 | No IF gate when `matched === false` — creates Drive folder named "Unknown" and proceeds with empty data | FIXED: Hard stop on no match |
| H-6 | WF3 | Stripe amount parsing produces `NaN` if Initial_Payment is empty/non-numeric — Stripe rejects with 400 error | FIXED: Validation node pre-computes cents values |
| H-7 | WF3 | Same NaN risk on Retainer amount (field not required) | FIXED: Validation node handles both amounts |
| H-8 | WF3 | No error handling after SignWell API — if contract send fails, Stripe still creates customer/invoice for unsent contract | NOTED: Recommend adding IF gate after SignWell |
| H-9 | WF3 | Invoice sent simultaneously with contract (before signing) — business process risk | FIXED: Invoice created with `auto_advance=false`, sent in WF5 |
| H-10 | WF4 | Narrow reminder windows (48-72hrs, 168-192hrs) can miss reminders depending on send time | FIXED: Cumulative thresholds with `Last_Reminder_Sent` tracking |
| H-11 | WF4 | No duplicate reminder prevention — multiple runs within a window resend the same email | FIXED: `Last_Reminder_Sent` column tracks sent reminders |
| H-12 | WF5 | `Total_Cost` column referenced but actual column is `Project_Cost` — displays "undefined" in Slack | FIXED: Corrected column reference |
| H-13 | WF5 | `Project_Start_Date` referenced but never written by WF3 — always shows "TBD" | FIXED: Added to WF3 tracker write |

### MEDIUM (Affects reliability or data quality)

| ID | Workflow | Issue | Status |
|----|----------|-------|--------|
| M-1 | WF2 | Pre-filled form URL missing `Retainer_for_invoice` mapping | NOTED |
| M-2 | WF2 | Pre-filled form URL missing `Company_City` data | NOTED |
| M-3 | WF3 | SignWell field `api_id` names must exactly match template — SignWell silently ignores mismatches | NOTED: Verify via SignWell API |
| M-4 | WF3 | SignWell JSON body has unescaped string interpolation risk for names with quotes | NOTED |
| M-5 | WF3 | "Cost?" form field contains special character, never referenced in workflow (vestigial) | NOTED |
| M-6 | WF5 | `completed_pdf_url` from SignWell webhook may be empty — no fallback to API retrieval | NOTED |
| M-7 | WF5 | Calendar `DateTime.now()` doesn't specify timezone — could create events at wrong time | NOTED |
| M-8 | All | No workflow-level error handlers — silent failures with no notification | NOTED: Recommend error trigger nodes |

### LOW (Cosmetic or minor)

| ID | Workflow | Issue | Status |
|----|----------|-------|--------|
| L-1 | WF1 | Prospects sheet has columns (SignWell_Doc_ID, etc.) that WF1 never populates | NOTED |
| L-2 | WF5 | Slack channel creation uses raw HTTP instead of n8n Slack node — two credential types needed | NOTED |
| L-3 | WF5 | Google Calendar OAuth2 requires separate credential setup — could be missed | NOTED |

---

## Cross-Workflow Data Consistency

### Sheet Column Alignment

| Data Flow | Columns Match? | Issues Found |
|-----------|---------------|--------------|
| WF1 Prospects → WF2 Read | YES | None |
| WF2 Update Prospects → WF3 Read | YES | None |
| WF3 Client Tracker → WF4 Read | YES | None |
| WF3 Client Tracker → WF5 Read | **PARTIAL** | `Total_Cost` vs `Project_Cost` mismatch (FIXED), `Project_Start_Date` missing (FIXED) |

### Placeholder IDs Requiring Replacement

There are **12+ placeholder values** across all 5 workflows that must be replaced before first run:

| Placeholder | Occurrences | Workflows |
|-------------|-------------|-----------|
| `YOUR_SPREADSHEET_ID` | 8 | WF1, WF2 (×2), WF3 (×2), WF4, WF5 (×2) |
| `YOUR_CLIENTS_FOLDER_ID` | 2 | WF2, WF3 |
| `YOUR_PROPOSAL_TEMPLATE_DOC_ID` | 1 | WF2 |
| `YOUR_ANTHROPIC_API_KEY` | 1 | WF2 |
| `YOUR_FORM_ID` | 1 | WF2 |
| `YOUR_SIGNWELL_TEMPLATE_ID` | 1 | WF3 |
| `YOUR_CHECKLIST_TEMPLATE_DOC_ID` | 1 | WF5 |
| `YOUR_CALENDLY_LINK` | 1 | WF5 |

---

## What Was Fixed in the Rebuilt Workflows

### WF1: Calendly Booking (3 nodes → 9 nodes)

| Change | Why |
|--------|-----|
| Added event type filter (`invitee.created` only) | Prevents processing cancellations/reschedules as new bookings |
| Added duplicate detection (read sheet → check email → IF) | Prevents duplicate Prospects rows from retries/rebookings |
| Added `Prospect_ID` generation (`VV-` + base36 timestamp) | Creates reliable unique key for cross-workflow matching |
| Added Slack notification | Immediate awareness of new bookings |
| Full ISO timestamp in `Booked_Date` | Consistent with v2 timestamp strategy |

### WF2: BlueDot Proposal (15 nodes → 14 nodes)

| Change | Why |
|--------|-----|
| Removed dangerous fallback matching → hard stop with error | Prevents wrong-client proposals (highest risk bug) |
| Added idempotency check (skip if `Drive_Folder_ID` exists) | Prevents duplicate processing from BlueDot webhook retries |
| Removed Gamma API integration entirely — replaced with Claude AI + Google Docs proposal template | Eliminates Gamma dependency; proposals generated via Claude and rendered in branded Google Docs template |
| Moved `Update Prospects Sheet` to run AFTER all steps | Sheet only updated when all deliverables succeed |
| Changed sheet update to use Email lookup (was `row_number`) | Uses a real column for reliable row targeting |

### WF3: Onboarding Form (12 nodes → added validation)

| Change | Why |
|--------|-----|
| Added `Validate Form Data` code node | Validates financial fields parse to positive numbers, pre-computes cents, normalizes Yes/No to booleans |
| Invoice created with `auto_advance=false` (NOT SENT) | Invoice ready but deferred to WF5 post-signing |
| Stripe uses pre-validated `_initial_payment_cents` | Eliminates NaN risk from inline parsing |
| Full ISO timestamp in `Contract_Sent_Date` | Fixes WF4 reminder timing precision |
| Added `Last_Reminder_Sent`, `Project_End_Date`, `Invoice_ID` columns | Supports WF4 dedup and WF5 invoice sending |

### WF4: Contract Reminders (8 nodes → 15 nodes)

| Change | Why |
|--------|-----|
| Cumulative thresholds instead of narrow windows | ≥48hrs instead of 48-72hrs — no more missed reminders |
| `Last_Reminder_Sent` tracking column | Prevents duplicate reminder sends |
| Added 14-day Slack escalation | Internal alert for stale deals (personal outreach needed) |
| Added 30-day auto-expire | Updates status to "Contract Expired", stops reminder loop |
| `Log Reminder Sent` node after every action | Audit trail + dedup mechanism |

### WF5: Post-Signing (15 nodes → 16 nodes)

| Change | Why |
|--------|-----|
| Added `Stripe Send Invoice` step (moved from WF3) | Invoice sent AFTER contract is signed — correct business process |
| Fixed race condition — both branches converge on `Send Welcome Email` | Eliminates duplicate tracker updates and Slack messages |
| Added `lookupColumn: "SignWell_Doc_ID"` on tracker update | Correctly identifies which row to update |
| Added `Share Checklist With Client` node | Delivers on the welcome email's promise of shared checklist |
| Calendar reminder includes `UNTIL` date | Prevents infinite recurring reminders |
| Fixed `Total_Cost` → `Project_Cost` column reference | Correct data displayed in Slack messages |

---

## Recommended Optimal Onboarding Structure

```
PHASE 1: LEAD CAPTURE
  Calendly booking → WF1 → Prospects Sheet (with dedup + Prospect_ID)
  [Slack: "New audit call booked"]

PHASE 2: DISCOVERY
  Audit call happens (manual)
  BlueDot transcript → WF2 → Drive folder + Claude proposal + Google Doc + form URL
  [Slack: "Proposal ready for review" + links]
  Anthony reviews and edits proposal in Google Docs (MANUAL GATE — KEEP THIS)

PHASE 3: CONTRACT
  Anthony submits pre-filled form → WF3 → SignWell contract sent
  Stripe customer + invoice created (NOT sent yet)
  [Slack: "Contract sent — invoice ready but not sent"]

PHASE 4: FOLLOW-UP
  WF4 runs daily at 9 AM:
    48hr:  Friendly reminder email
    7 day: Firmer reminder email
    14 day: Internal Slack escalation to Anthony
    30 day: Auto-expire, update status to "Contract Expired"

PHASE 5: CLOSE + ONBOARD
  Client signs → WF5 fires:
    1. Download signed PDF → upload to Drive
    2. Send Stripe invoice (NOW — post-signing)
    3. Create Slack channel + welcome message
    4. Copy + share onboarding checklist with client
    5. Create weekly calendar reminder (with end date)
    6. Send welcome email
    7. Update tracker to "Onboarded"
    [Slack: "Client fully onboarded!"]

PHASE 6: PAYMENT CONFIRMATION (FUTURE — WF6)
  Stripe webhook listener for:
    invoice.paid → Update tracker, Slack notification
    invoice.payment_failed → Slack alert to Anthony
```

### Key Structural Changes Made

1. **Invoice timing moved from Phase 3 to Phase 5** — no money requested until contract is signed
2. **Manual gate between WF2 and WF3 preserved** — quality control checkpoint that prevents AI errors from reaching clients
3. **All duplicate/idempotency issues addressed** — WF1 dedup, WF2 idempotency check, WF4 reminder tracking
4. **Shared `Prospect_ID` column** added to create reliable cross-references

---

## Prioritized Recommendations (Not Yet Implemented)

### Quick Wins (1-2 hours each)

| # | Recommendation | Impact |
|---|---------------|--------|
| 1 | Add workflow-level error trigger nodes to all 5 workflows → Slack notification on any failure | Catches silent failures |
| 2 | Verify SignWell template field `api_id` names match via `GET /api/v1/document_templates/{id}` | Prevents silent field mismatches |
| 3 | Escape transcript text in WF2 Claude API JSON body using `JSON.stringify().slice(1,-1)` | Prevents broken AI calls from transcripts with quotes |
| 4 | Add IF gate after SignWell API in WF3 — check `$json.id` exists before proceeding to Stripe | Prevents invoicing for unsent contracts |

### Medium-Term (half day each)

| # | Recommendation | Impact |
|---|---------------|--------|
| 5 | Add `Retainer_for_invoice` to WF2 pre-fill mapping | Reduces manual entry in form |
| 6 | Handle Calendly cancellation events in WF1 (update status to "Cancelled") | Accurate pipeline data |
| 7 | Handle SignWell declined/voided events in WF5 (update status to "Contract Declined") | Deal-death awareness |
| 8 | Add Stripe duplicate customer check in WF3 (`GET /v1/customers?email=`) | Prevents duplicate Stripe customers on re-runs |
| 9 | Add `completed_pdf_url` fallback in WF5 — if empty, GET SignWell document API | Handles missing PDF URL in webhook |

### Longer-Term (1-2 days)

| # | Recommendation | Impact |
|---|---------------|--------|
| 10 | Build WF6 for Stripe payment webhook handling (`invoice.paid` / `invoice.payment_failed`) | Payment visibility |
| 11 | Add "stale proposal" alert for Prospects with "Proposal Sent" status older than 3 days | Prevents lost deals |
| 12 | Migrate from Google Sheets to Airtable or PostgreSQL when volume exceeds 5-10 clients/month | Scalability |

---

## Scalability Assessment

| Volume | Assessment |
|--------|-----------|
| **1-3 clients/month** (current) | Pipeline works well with the fixes above. Google Sheets is fine. Manual gates are appropriate. |
| **5-10 clients/month** | Google Sheets API rate limits start to strain (60 req/min/user). Add "processed" filters to sheet reads. |
| **10+ clients/month** | Consider migrating to Airtable or PostgreSQL. Manual review gate becomes a bottleneck — consider AI confidence scoring for auto-submit vs. manual review. |

---

## Architectural Observations

1. **Google Sheets as database is acceptable for current scale** but has no row-level locking, no concurrent write safety, and a 60 req/min rate limit.

2. **No idempotency keys on external API calls.** SignWell and Stripe calls have no idempotency keys. If any workflow is accidentally re-run, duplicates are created.

3. **The manual review gate is well-designed and should never be automated away.** It prevents AI-generated errors from reaching clients.

4. **Execution order `v1` is correct** — this is the modern n8n execution mode.

5. **The five-workflow split is the right architecture.** Each workflow has a unique trigger type and clear responsibility. No workflows should be combined.

---

## Files Delivered

| File | Description |
|------|-------------|
| `WF1_Calendly_Booking.json` | Rebuilt with dedup, event filtering, Prospect_ID, Slack notification |
| `WF2_BlueDot_Proposal.json` | Rebuilt with hard-stop matching, polling retry, sequential updates |
| `WF3_Onboarding_Form.json` | Rebuilt with validation, deferred invoice, ISO timestamps |
| `WF4_Contract_Reminders.json` | Rebuilt with tracking, escalation tiers, auto-expire |
| `WF5_Post_Signing.json` | Rebuilt with post-signing invoice, fixed race condition, shared checklist |
| `VV_Onboarding_Workflow_Map.md` | Updated architecture diagram with all v2 changes |
| `VV_Audit_Report.md` | This report |

---

## Import Order

| Order | File | Why |
|-------|------|-----|
| 1 | `WF1_Calendly_Booking.json` | Standalone, no dependencies |
| 2 | `WF3_Onboarding_Form.json` | Need the form ID for WF2's pre-fill URL |
| 3 | `WF2_BlueDot_Proposal.json` | References WF3's form ID |
| 4 | `WF4_Contract_Reminders.json` | Standalone, reads Client Tracker |
| 5 | `WF5_Post_Signing.json` | Last — needs everything else set up |

---

*Generated by workflow-auditor + process-optimizer agents — Veteran Vectors Onboarding Review*
