# Veteran Vectors — Consolidated Agent Audit Report (v3)

**Date:** 2026-02-17
**Agents Run:** Security Auditor, Data Integrity Validator, Pipeline Continuity Validator, Quality Gate Enforcer, Cost & Efficiency Optimizer
**Scope:** All 9 n8n workflow JSONs (WF1, WF1B, WF2, WF3, WF3B, WF4, WF5, WF6, WF7), architecture docs
**Pipeline Version:** v3 (Notion CRM, lead qualification, discovery + audit split)
**Mode:** READ-ONLY audit — no files modified

---

## Executive Summary

Five specialized agents audited the complete v3 pipeline (9 workflows, 112 total nodes). The v3 rebuild successfully migrated from Google Sheets to Notion CRM, added lead qualification, separated discovery and audit call processing, and introduced Slack interactive buttons for manual gates.

However, the audit identified:

- **9 CRITICAL** findings (security, data integrity, pipeline gaps)
- **16 HIGH** severity findings
- **13 MEDIUM** findings
- **3 LOW** findings
- **Estimated pipeline cost:** ~$1.17 per lead (excluding Stripe processing fees)
- **~60 external API calls** per lead (Calendly booking → fully onboarded)

**The single most critical finding across all agents:** WF7 queries Notion Projects for `Project Status = 'Active'`, but **no workflow in the entire pipeline ever sets that status**. WF4 creates projects as `"Contract Sent"` and WF6 updates the Contact (not the Project) to `"Project Started"`. Weekly check-ins will never fire.

---

## Agent 1: Security Auditor — 22 Findings

### CRITICAL (6)

| ID | Workflow | Finding |
|----|----------|---------|
| SEC-01 | WF1 | **Calendly webhook has no signature verification.** Attackers can POST fabricated booking data, creating bogus Notion contacts and triggering qualification. |
| SEC-02 | WF2 | **BlueDot discovery webhook has no signature verification.** Attackers can inject crafted transcripts into Claude API and create Drive folders. |
| SEC-03 | WF3 | **BlueDot audit webhook has no signature verification.** Injected transcripts flow into AI proposal generation, creating attacker-controlled proposals. |
| SEC-04 | WF6 | **SignWell webhook has no signature verification.** Attackers can trigger invoice sending, Slack channel creation, and welcome emails by posting fake `document.completed` events. |
| SEC-05 | WF1B | **Slack interaction webhook has no verification.** Slack sends a signing secret that should be verified. Without it, anyone can POST accept/deny decisions. |
| SEC-06 | WF3B | **Slack interaction webhook has no verification.** Same as SEC-05 — fake proposal send triggers are possible. |

### HIGH (7)

| ID | Workflow | Finding |
|----|----------|---------|
| SEC-07 | WF4 | **Onboarding form has no authentication.** Anyone with the URL can submit arbitrary data, creating SignWell contracts and Stripe invoices/subscriptions. |
| SEC-08 | WF2/WF3 | **Raw transcript text injected into Claude API JSON body without escaping.** Quotes/backslashes in transcripts break the JSON structure. Transcript content is only truncated via `.substring(0, 15000)`, not sanitized. |
| SEC-09 | WF2/WF3 | **Prompt injection risk.** Attacker-controlled transcript content is directly included in the Claude prompt. A crafted transcript could manipulate proposal output. |
| SEC-10 | WF1 | **Slack Block Kit JSON injection.** `$json.qualification_reasons.join()` and `$json.pain_points` are interpolated directly into the JSON body of the Slack interactive message without escaping. |
| SEC-11 | WF4 | **No Stripe idempotency keys.** Duplicate form submissions create duplicate Stripe customers, invoice items, invoices, prices, and subscriptions. |
| SEC-12 | WF6 | **No Stripe idempotency keys on invoice send or subscription resume.** Duplicate SignWell webhooks re-send invoices. |
| SEC-13 | WF6 | **SSRF risk.** `completed_pdf_url` from the SignWell webhook is used directly in an HTTP GET. Attacker-controlled webhook payloads could make the server fetch internal URLs. |

### MEDIUM (7)

| ID | Workflow | Finding |
|----|----------|---------|
| SEC-14 | WF1 | Client email and PII posted to `#onboarding-alerts` Slack channel in plain text. |
| SEC-15 | WF3 | Unsanitized client data interpolated into Google Docs batchUpdate JSON body. Names with quotes could break the API call. |
| SEC-16 | WF4 | SignWell JSON body has unescaped string interpolation for `$json.client_name` and `$json.client_email`. |
| SEC-17 | WF1B | Calendly cancellation reason contains user-controlled data without sanitization. |
| SEC-18 | All | No `.gitignore` file — real API keys/credentials could be accidentally committed. |
| SEC-19 | WF6 | No replay protection beyond status check. The window between "Contract Sent" and "Project Started" allows duplicate processing. |
| SEC-20 | WF4 | SignWell `test_mode` hardcoded to `false`. Should be configurable for staging. |

### LOW (2)

| ID | Workflow | Finding |
|----|----------|---------|
| SEC-21 | WF6 | Google Calendar OAuth2 requires separate credential setup — easily missed during deployment. |
| SEC-22 | WF6 | `DateTime.now()` in calendar event creation doesn't explicitly specify timezone, relying on n8n server timezone. |

### Top Security Priority
1. Add webhook signature verification to WF1, WF2, WF3, WF6 (SEC-01 through SEC-04)
2. Add Slack signing secret verification to WF1B, WF3B (SEC-05/06)
3. Fix JSON escaping in all HTTP Request bodies (SEC-08/10/15/16)
4. Add Stripe idempotency keys (SEC-11/12)
5. Add form authentication (SEC-07)

---

## Agent 2: Data Integrity Validator — 16 Findings

### CRITICAL (3)

| ID | Workflow | Finding |
|----|----------|---------|
| DATA-01 | WF7 | **"Active" status never set.** WF7 queries `Project Status = 'Active'`, but WF4 creates projects as `"Contract Sent"` and WF6 updates only the Contact status to `"Project Started"`, never the Project record. **Weekly check-ins will produce zero results.** |
| DATA-02 | WF5 | **Notes field overwritten.** `Log Reminder in Notion` (wf5-node-12) writes `richTextValue` to the Notes field, **completely replacing** all existing meeting notes, action items, and AI summaries stored by WF2. This destroys critical client data every time a reminder runs. |
| DATA-03 | WF2/WF6 | **Drive folder ID not persisted to Notion.** WF2 creates a Google Drive folder but never saves the folder ID back to the Notion contact. WF3 must re-search by name (unreliable — name matching can return wrong folder). WF6 also searches by name. If company name changes or has special characters, lookups fail. |

### HIGH (6)

| ID | Workflow | Finding |
|----|----------|---------|
| DATA-04 | WF4/WF6 | **Stripe IDs not persisted to Notion.** WF4 creates Stripe customer, invoice, and subscription but never saves IDs to Notion. WF6 searches Stripe by email to re-find them — fragile for clients with multiple email addresses or duplicate Stripe customers. |
| DATA-05 | WF4 | **Missing Client relation on Project record.** `Create Notion Project` (wf4-node-12) does not set the `Client` relation property to link the project back to the contact. The Notion Projects DB has a Client relation column per the CSV, but it's never populated. |
| DATA-06 | WF5 | **Uses `Last Contact Date` as proxy for contract-sent date.** The code comment explicitly says "We use Last Contact Date as proxy for contract sent date." But WF1 sets this to the booking date, not the contract date. Reminders will calculate days-since-sent from the wrong date. |
| DATA-07 | WF6/WF7 | **Slack channel naming mismatch.** WF6 creates channels as `client-{company_name}`. WF7 builds channel references as `client-{project_name}`. These won't match unless company and project names are identical, causing WF7 to reference nonexistent channels. |
| DATA-08 | WF2 | **Creates Drive folder every time without dedup.** No check for existing folder before creating. If BlueDot retries the webhook, a duplicate folder is created with the same name. |
| DATA-09 | WF2/WF3 | **Meeting records missing Contact relation.** Both `Create Notion Meeting Record` nodes don't set the `Contact` relation property from the Meetings DB schema. Meetings are orphaned in Notion. |

### MEDIUM (5)

| ID | Workflow | Finding |
|----|----------|---------|
| DATA-10 | WF3 | **Drive folder search uses wrong HTTP method.** `Find Existing Drive Folder` (wf3-node-5b) uses POST to `googleapis.com/drive/v3/files` with a JSON body containing a `q` parameter. The Files.list endpoint requires GET with query parameters, not POST with JSON body. This node will fail. |
| DATA-11 | WF6 | **Same Drive search issue.** `Find Client Drive Folder` (wf6-node-9b) uses POST with a JSON body for Drive search. Same failure mode as DATA-10. |
| DATA-12 | WF2 | **Name-based contact matching is fragile.** If client name in BlueDot doesn't exactly match Notion (e.g., "Bob Smith" vs "Robert Smith"), the match fails and the workflow hard-stops. |
| DATA-13 | WF1 | **No duplicate Notion contact prevention.** If Calendly retries the webhook or the same person books multiple times, duplicate contacts are created. |
| DATA-14 | WF1B | **Leadmatic email PDF attachment not configured.** `Send Leadmatic Email` references binary data `property: "data"` but there's no upstream node that fetches or provides the PDF. The email will be sent without the attachment. |

### LOW (2)

| ID | Workflow | Finding |
|----|----------|---------|
| DATA-15 | WF2 | `Action Items ` property name has a trailing space — must exactly match the Notion column name or will silently fail. |
| DATA-16 | WF4 | Date parsing in `Project_Start_Date` and `Project_End_Date` doesn't validate date format. Invalid dates pass through to Notion and SignWell. |

---

## Agent 3: Pipeline Continuity Validator — 15 Gaps

### CRITICAL Gaps (3)

| ID | Stage | Finding |
|----|-------|---------|
| G-01 | WF1→WF2 | **Qualified leads bypass Anthony's approval.** Auto-qualified leads (revenue >= $500K, pain points present, budget indicated) go straight to `"Discovery Scheduled"` and Slack notification — no accept/deny buttons. Anthony has no opportunity to reject qualified leads that may not be a good fit for other reasons. |
| G-02 | WF7 | **Weekly check-ins produce zero results.** (Same as DATA-01.) No workflow sets `Project Status = 'Active'`. The entire WF7 workflow is dead code. |
| G-03 | WF2/WF3 | **BlueDot single-webhook routing unsupported.** WF2 and WF3 have separate webhook endpoints (`bluedot-discovery` and `bluedot-audit`). BlueDot typically supports ONE webhook URL per account, not two. All recordings would go to one webhook, meaning the other workflow never fires. |

### HIGH Gaps (5)

| ID | Stage | Finding |
|----|-------|---------|
| G-04 | WF3→WF3B | **Slack Interactivity Request URL conflict.** Slack apps allow only ONE Interactivity Request URL. WF1B (`slack-lead-decision`) and WF3B (`slack-proposal-send`) both need to receive button clicks. The WF3B notes acknowledge this but no solution is implemented. One of the two workflows will not receive button clicks. |
| G-05 | WF4→WF5 | **WF5 reminder timer starts from wrong date.** WF5 uses `Last Contact Date` as the contract-sent timer (DATA-06). For a lead booked on Jan 1 with contract sent on Feb 1, WF5 calculates 31+ days elapsed on the first run and immediately auto-expires the contract. |
| G-06 | WF6 | **WF6 updates Contact but not Project.** `Update Notion - Project Started` (wf6-node-14) updates the Contact's Status to `"Project Started"` but never touches the Project record. The Notion Project stays at `"Contract Sent"` permanently. |
| G-07 | WF3 | **Drive file search will fail.** DATA-10 means WF3 can never find an existing Drive folder, always falling through to create a new one. Clients accumulate duplicate folders. |
| G-08 | WF1→WF1B | **Race condition on rapid Slack interaction.** If Anthony clicks Accept/Deny before the Notion contact is fully created, the `notion_page_id` in the button value could be empty, causing WF1B to fail silently on the Notion update. |

### MEDIUM Gaps (5)

| ID | Stage | Finding |
|----|-------|---------|
| G-09 | WF2 | **No idempotency check.** If BlueDot retries the webhook, WF2 creates duplicate Drive folders, duplicate meeting records, and re-processes the transcript through Claude (duplicate API costs). |
| G-10 | WF1B | **Calendly cancellation may fail silently.** If the `calendly_event_uuid` is empty or the event was already cancelled, the Calendly API returns an error but the workflow continues to mark as Declined in Notion and send the leadmatic email. |
| G-11 | All | **No workflow-level error trigger nodes.** None of the 9 workflows have error handler nodes. All failures are silent unless n8n execution logs are monitored manually. |
| G-12 | WF4 | **Stripe failure after SignWell leaves orphaned contract.** If Stripe customer creation fails after SignWell contract is sent, the client receives a contract but no invoice/retainer is created. No rollback or alert. |
| G-13 | WF6 | **No fallback for missing completed_pdf_url.** If SignWell webhook doesn't include the PDF URL, `Download Signed PDF` fails and the entire downstream chain (Drive upload → Slack → email → Notion → calendar) is blocked. |

### RACE CONDITIONS (2)

| ID | Severity | Finding |
|----|----------|---------|
| RACE-01 | HIGH | **BlueDot fires before Notion contact exists.** If a very short discovery call ends while WF1 is still processing the Calendly webhook, WF2 fires with no matching Notion contact and hard-stops. No retry, no notification. |
| RACE-02 | MEDIUM | **Concurrent WF2 executions from duplicate BlueDot webhooks.** Both pass the match check (no idempotency guard), creating parallel Drive folders and Claude API calls. |

---

## Agent 4: Quality Gate Enforcer — 6 Gates Audited

### Gate Status Summary

| Gate | Type | Status | Verdict |
|------|------|--------|---------|
| QG-1: Lead Accept/Deny | HARD (intended) | **PARTIALLY BYPASSED** | Only unqualified leads get accept/deny buttons. Qualified leads skip Anthony's review entirely (G-01). |
| QG-2: Proposal Review | HARD | **ENFORCED** | WF3 sets "Proposal Draft". Anthony reviews Google Doc, clicks Slack button. WF3B sends and sets "Proposal Sent". Well-designed. |
| QG-3: Form Submission | HARD | **ENFORCED** | Form URL is internal-only. Financial fields are validated. Anthony must manually submit. |
| QG-4: Invoice Timing | HARD | **ENFORCED** | `auto_advance=false` in WF4. Invoice sent only by WF6 post-signing. Correct. |
| QG-5: Post-Signing | HARD | **ENFORCED** | Gated by SignWell `document.completed` webhook. Requires actual signature. Idempotency check prevents re-processing. |
| QG-6: Reminder Escalation | AUTOMATED | **PARTIALLY ENFORCED** | Daily reminders run correctly, but wrong start date (DATA-06/G-05) means thresholds are miscalculated. 30-day auto-expire may trigger prematurely. |

### Key Quality Gate Findings

**1. Qualified Lead Auto-Approval (QG-1)**
WF1 auto-approves leads meeting all criteria (revenue >= $500K, pain points, budget). This means Anthony never sees these leads before the discovery call happens. For a high-touch consulting business, **every lead should get Anthony's review** — revenue alone doesn't determine fit.

**Recommendation:** Route ALL leads through accept/deny buttons, with qualified leads highlighted as "Recommended: Accept" and unqualified as "Needs Review."

**2. Proposal Status Lifecycle is Correct**
Unlike v2 (which set "Proposal Sent" before delivery), v3 correctly uses:
- WF3: `"Proposal Draft"` (after generation)
- WF3B: `"Proposal Sent"` (after actual delivery)

This is a significant improvement over v2.

**3. Retainer Subscription Timing is Correct**
WF4 creates the subscription paused (`pause_collection[behavior]=void`). WF6 resumes it post-signing. No billing occurs before the contract is signed.

---

## Agent 5: Cost & Efficiency Optimizer — Pipeline Cost Analysis

### Node Count by Workflow

| Workflow | Nodes | Trigger Type |
|----------|-------|-------------|
| WF1 | 8 | Webhook (Calendly) |
| WF1B | 9 | Webhook (Slack) |
| WF2 | 13 | Webhook (BlueDot) |
| WF3 | 17 | Webhook (BlueDot) |
| WF3B | 6 | Webhook (Slack) |
| WF4 | 14 | Form |
| WF5 | 12 | Schedule (daily) |
| WF6 | 26 | Webhook (SignWell) |
| WF7 | 7 | Schedule (weekly) |
| **Total** | **112** | |

### External API Calls Per Lead (Full Pipeline)

| Stage | API Calls | Services |
|-------|-----------|----------|
| WF1 (booking) | 3 | Notion (create), Slack (post) |
| WF1B (decision) | 3 | Notion (update), Slack (update), Calendly (cancel) — only if denied |
| WF2 (discovery) | 8 | Notion (query + update + create), Drive (create + upload), Claude, Slack |
| WF3 (audit) | 13 | Notion (query + update + create), Drive (search + create + upload + copy + update + export + upload), Claude, Slack |
| WF3B (proposal) | 5 | Drive (export), Gmail, Notion (update), Slack |
| WF4 (contract) | 10 | SignWell, Stripe (×4-6), Notion (update + create), Slack |
| WF5 (reminders) | 4/day | Notion (query + update), Gmail, Slack (maybe) |
| WF6 (onboarding) | 17 | Notion (query ×2), Stripe (×4-5), Drive (search + upload), Slack (×2), Gmail, Calendar, HTTP (download) |
| WF7 (check-ins) | 3/week | Notion (query), Slack (×2) |
| **Total per lead** | **~62** | **One-time: ~59, Recurring: ~4/day + 3/week** |

### Cost-Per-Lead Breakdown

| Component | Cost | Notes |
|-----------|------|-------|
| Claude API (Sonnet) | ~$0.15 | 2 calls: discovery (~$0.05) + audit proposal (~$0.10) |
| SignWell | ~$1.00 | Per-document pricing (depends on plan) |
| n8n executions | $0.00-$1.70 | Self-hosted = $0, Cloud = ~$0.05/execution × ~34 executions |
| Google APIs | $0.00 | Free tier / quota-based |
| Slack API | $0.00 | Free |
| Gmail API | $0.00 | Free |
| Stripe processing | 2.9% + $0.30 | Per payment (not per API call) |
| Calendly | $0.00 | Webhook included in plan |
| **Total per lead** | **~$1.17** | Excluding Stripe processing fees and SignWell plan tier |

### Top Optimizations

| ID | Change | Savings | Risk |
|----|--------|---------|------|
| COST-01 | **Split Claude into Haiku (extraction) + Sonnet (narrative).** Use Haiku for WF2 meeting notes extraction, Sonnet only for WF3 proposal generation. | ~40% on AI costs ($0.06 saved) | LOW |
| COST-02 | **Consolidate BlueDot to single webhook.** Route discovery vs. audit calls in one workflow based on title filter, eliminating duplicate webhook overhead. | Simplifies architecture | LOW |
| COST-03 | **Cache Stripe customer lookups in Notion.** Store `stripe_customer_id` and `invoice_id` in Notion during WF4, eliminating 4 Stripe API calls in WF6. | 4 fewer API calls per lead | LOW |
| COST-04 | **WF5 weekday-only schedule.** Contract reminders on weekdays only. | 29% fewer daily executions | VERY LOW |
| COST-05 | **Persist Drive folder ID in Notion.** Eliminates Drive search API calls in WF3 and WF6. | 2 fewer API calls per lead | LOW |
| COST-06 | **Filter Notion queries with date range.** WF5 queries ALL "Contract Sent" contacts daily. Add a date filter to only fetch contacts from last 30 days. | Fewer rows transferred | LOW |

**Optimized cost per lead: ~$1.00–$1.10 (10-15% savings)**

The dominant cost driver is SignWell per-document fees. AI costs are minimal.

---

## Cross-Agent Priority Matrix

### P0 — Fix Immediately (Before Production)

| Finding | Agents | Action | Impact |
|---------|--------|--------|--------|
| WF7 "Active" status never set (DATA-01/G-02) | Data + Pipeline | WF6: Add Project status update to "Active". WF7 queries "Active". | **Weekly check-ins broken** |
| WF5 overwrites Notes (DATA-02) | Data | Change to append (prefix with existing Notes) or use a dedicated "Reminder Log" property. | **Client data destroyed** |
| Drive folder ID not persisted (DATA-03) | Data + Pipeline | WF2: Save folder ID to Notion contact after creation. WF3/WF6: Read from Notion instead of searching. | **Wrong folders, duplicate folders** |
| WF5 wrong timer date (DATA-06/G-05) | Data + Pipeline | Add "Contract Sent Date" property to Notion, set it in WF4, read it in WF5 instead of "Last Contact Date". | **Premature contract expiry** |
| Drive search uses wrong HTTP method (DATA-10/11) | Data + Pipeline | Change WF3 and WF6 Drive search from POST to GET with query parameters. | **Drive lookups fail** |
| Webhook signature verification (SEC-01 to SEC-06) | Security | Add HMAC/signing secret verification to all 6 webhooks. | **All webhooks exploitable** |

### P1 — Fix Before Scale (1-3 clients/month)

| Finding | Agents | Action |
|---------|--------|--------|
| Qualified leads bypass review (G-01) | Pipeline + Quality Gate | Route all leads through accept/deny with qualification score displayed |
| Slack Interactivity URL conflict (G-04) | Pipeline | Create a single dispatcher webhook that routes by `action_id` prefix |
| BlueDot single webhook issue (G-03) | Pipeline | Merge WF2/WF3 webhooks into one endpoint, route by title filter |
| Stripe IDs not persisted (DATA-04) | Data | Store `stripe_customer_id`, `invoice_id`, `subscription_id` in Notion |
| Missing Client relation on Project (DATA-05) | Data | Add Client relation to WF4 `Create Notion Project` |
| Missing Contact relation on Meetings (DATA-09) | Data | Add Contact relation to WF2/WF3 `Create Notion Meeting Record` |
| Stripe idempotency keys (SEC-11/12) | Security | Add `Idempotency-Key` header to all Stripe API calls |
| JSON escaping (SEC-08/10/15/16) | Security | Use `JSON.stringify()` for all interpolated values in HTTP Request bodies |
| Slack channel naming consistency (DATA-07) | Data | Standardize on company name in both WF6 and WF7 |
| WF6 Project status update (G-06) | Pipeline | Add Project record status update to "Project Started" in WF6 |
| Leadmatic PDF attachment (DATA-14) | Data | Add Google Drive download node before email in WF1B |
| Form authentication (SEC-07) | Security | Add secret token to form URL or require authenticated access |

### P2 — Add Error Handling & Monitoring

| Finding | Agent | Action |
|---------|-------|--------|
| No error handlers (G-11) | Pipeline | Add error trigger nodes to all 9 workflows → Slack `#onboarding-errors` |
| WF2 duplicate folder creation (DATA-08/G-09) | Data + Pipeline | Add Drive folder existence check before creating |
| Duplicate Notion contacts (DATA-13) | Data | Add email uniqueness check before creating contact in WF1 |
| Stripe failure after SignWell (G-12) | Pipeline | Add IF gate after SignWell, rollback or alert on Stripe failure |
| PDF URL fallback (G-13) | Pipeline | Add IF check for empty PDF URL, fallback to SignWell API download |
| BlueDot → WF2 race condition (RACE-01) | Pipeline | Add retry logic or delay in WF2 before Notion lookup |

### P3 — Optimize

| Finding | Agent | Savings |
|---------|-------|---------|
| Split Claude Haiku/Sonnet (COST-01) | Cost | ~40% AI cost reduction |
| Cache Stripe IDs in Notion (COST-03) | Cost | 4 fewer API calls/lead |
| Persist Drive folder ID (COST-05) | Cost | 2 fewer API calls/lead |
| Weekday-only reminders (COST-04) | Cost | 29% fewer WF5 executions |
| Add `.gitignore` (SEC-18) | Security | Prevents credential commits |

---

## Notion Status Lifecycle Audit

### Contact Status Flow (as built)

```
"Pending Review" → "Discovery Scheduled" → "Meeting Held" → "Proposal Draft" → "Proposal Sent" → "Contract Sent" → "Project Started"
     WF1              WF1/WF1B                 WF2               WF3              WF3B              WF4               WF6
       │
       └─► "Declined" (WF1B deny or WF5 30-day expire)
```

**Verdict:** Contact status lifecycle is correct and well-designed.

### Project Status Flow (as built)

```
"Contract Sent" → ??? (never updated)
     WF4
```

**Verdict: BROKEN.** WF6 updates Contact status but not Project status. WF7 queries for "Active" — a status that is never set. Fix: WF6 should update Project to "Active" or "Project Started", and WF7 should query for the matching status.

---

## Slack Integration Architecture

| Workflow | Slack Method | Channel | Type |
|----------|-------------|---------|------|
| WF1 | n8n Slack node | #onboarding-alerts | Notification |
| WF1 | HTTP Request (Block Kit) | #onboarding-alerts | Interactive (buttons) |
| WF1B | HTTP Request (response_url) | Original message | Message update |
| WF2 | n8n Slack node | #onboarding-alerts | Notification |
| WF3 | HTTP Request (Block Kit) | #onboarding-alerts | Interactive (buttons) |
| WF3B | HTTP Request (response_url) | Original message | Message update |
| WF4 | n8n Slack node | #onboarding-alerts | Notification |
| WF5 | n8n Slack node | #onboarding-alerts | Notification |
| WF6 | HTTP Request (conversations.create) | client-{company} | Channel creation |
| WF6 | HTTP Request (chat.postMessage) | client-{company} | Welcome message |
| WF6 | n8n Slack node | #onboarding-alerts | Notification |
| WF7 | n8n Slack node | #onboarding-alerts | Check-in templates |

**Critical Slack Architecture Issue:** Slack's Interactivity Request URL is a single URL per Slack app. WF1B and WF3B each define their own webhook paths. Only one can be the active Interactivity URL. **Solution:** Create a single dispatcher webhook that inspects `action_id` and routes to the appropriate handler.

---

## Placeholder Reference (Verified Against All 9 Workflows)

| Placeholder | Workflows | Count | What to Put |
|-------------|-----------|-------|-------------|
| `YOUR_NOTION_CONTACTS_DB_ID` | WF1, WF2, WF3, WF5, WF6 | 5 | Notion Contacts database ID |
| `YOUR_NOTION_PROJECTS_DB_ID` | WF4, WF6, WF7 | 3 | Notion Projects database ID |
| `YOUR_NOTION_MEETINGS_DB_ID` | WF2, WF3 | 2 | Notion Meetings database ID |
| `YOUR_CLIENTS_FOLDER_ID` | WF2, WF3 (×2) | 3 | Root Clients folder in Google Drive |
| `YOUR_PROPOSAL_TEMPLATE_DOC_ID` | WF3 | 1 | Google Doc proposal template ID |
| `YOUR_SIGNWELL_TEMPLATE_ID` | WF4 | 1 | SignWell template ID |
| `YOUR_CALENDLY_LINK` | WF6 | 1 | Kickoff call Calendly link |
| `YOUR_CALENDLY_PERSONAL_TOKEN` | WF1B | 1 | Calendly API token (HTTP Header Auth) |
| Slack Bot Token (xoxb-) | WF1, WF1B, WF3, WF3B, WF6 | 5 | Slack Bot OAuth token (HTTP Header Auth) |
| Stripe Secret Key (sk_live_) | WF4, WF6 | 7 | Stripe secret key (HTTP Header Auth) |
| Anthropic API Key | WF2, WF3 | 2 | Claude API key (HTTP Header Auth: x-api-key) |
| Google OAuth2 | WF2, WF3, WF3B, WF6 | 5 | Google Drive/Docs/Calendar OAuth2 credentials |
| Gmail OAuth2 | WF1B, WF3B, WF5, WF6 | 4 | Gmail send credentials |
| SignWell API Key | WF4 | 1 | SignWell API key (HTTP Header Auth: X-Api-Key) |

**Total unique credentials required: 8** (Notion, Google OAuth2, Slack Bot, Stripe, Anthropic, SignWell, Calendly, Gmail OAuth2)

---

## What v3 Fixed from v2

| v2 Issue | v3 Status |
|----------|-----------|
| Google Sheets as database | **FIXED** — Notion CRM is single source of truth |
| "Proposal Sent" set before delivery | **FIXED** — "Proposal Draft" in WF3, "Proposal Sent" only in WF3B after actual email |
| Invoice sent before contract signed | **FIXED** — Draft in WF4 (auto_advance=false), sent in WF6 |
| No lead qualification | **FIXED** — Calendly custom questions evaluated in WF1 |
| No discovery/audit call separation | **FIXED** — WF2 (discovery) and WF3 (audit) are separate |
| No manual gate for lead approval | **PARTIALLY FIXED** — Only unqualified leads get accept/deny (qualified leads auto-approved) |
| No proposal delivery mechanism | **FIXED** — WF3B sends via email after Slack button click |
| Retainer subscription timing | **FIXED** — Created paused in WF4, resumed in WF6 |
| No Slack interactive buttons | **FIXED** — Accept/deny in WF1, Send Proposal in WF3 |
| Slack channels public | **FIXED** — WF6 creates private channels (is_private: true) |

---

## Files Audited

| File | Nodes | External APIs |
|------|-------|--------------|
| `WF1_Discovery_Qualification.json` | 8 | Calendly, Notion, Slack |
| `WF1B_Qualification_Decision.json` | 9 | Slack, Calendly, Notion, Gmail |
| `WF2_Discovery_Call_Processing.json` | 13 | BlueDot, Notion, Google Drive, Claude, Slack |
| `WF3_Audit_Proposal.json` | 17 | BlueDot, Notion, Google Drive, Google Docs, Claude, Slack |
| `WF3B_Proposal_Send.json` | 6 | Slack, Google Drive, Gmail, Notion |
| `WF4_Client_Onboarding.json` | 14 | n8n Form, SignWell, Stripe, Notion, Slack |
| `WF5_Reminders.json` | 12 | Notion, Gmail, Slack |
| `WF6_Post_Signing.json` | 26 | SignWell, Notion, Stripe, Google Drive, Slack, Gmail, Google Calendar |
| `WF7_Weekly_Checkins.json` | 7 | Notion, Slack |
| `VV_Onboarding_Workflow_Map.md` | — | Architecture documentation |
| `VV_Pipeline_Flowmap.md` | — | Pipeline flow documentation |

---

*Generated by 5-agent review team — Veteran Vectors Pipeline v3 Audit*
*Security Auditor • Data Integrity Validator • Pipeline Continuity Validator • Quality Gate Enforcer • Cost & Efficiency Optimizer*
