# Veteran Vectors — 8-Step LinkedIn-to-Client Onboarding Pipeline

## Architecture Document v5.0

**Date:** 2026-03-14
**Pipeline:** Prosp.ai LinkedIn Outreach → Notion CRM → Client Onboarding
**Source of Truth:** Notion CRM (Contacts, Projects, Meetings databases)

---

## Pipeline at a Glance

```
═══ LEAD GEN WORKFLOWS ═══

Lead Gen WF0    Lead Gen WF1     Lead Gen WF2     Lead Gen WF3A/3C
Lead Score &    LI Connection    Loom Video       Response
Loom Script     Sent/Accepted    Sent Tracking    Handling
Generator       via Prosp.ai     (Sheet→Notion)   (3 paths)

WF0_Lead_       WF_STEP1_        WF_STEP2_        WF_STEP3A / 3C
Scoring.json    Prosp_LI.json    Loom_Sent.json   Followup/Calendly

═══ ONBOARDING WORKFLOWS ═══

Onboarding WF4  Onboarding WF4B  Onboarding WF5   Onboarding WF6
Discovery Call  Audit Call       SOW/Contract      Contract & Invoice
→ AI + GitHub   → Refine GitHub  Creation →        Reminders
+ Drive + Email + Notion         Invoicing + SOW   (Daily → Every 3 Days)
                                 Draft Email

WF_STEP4_       WF_STEP4B_       WF_STEP5_        WF_STEP6_
Meeting.json    Audit_Call.json  SOW_Contract.json Reminders.json

Onboarding WF7
Contract Signed
→ Welcome +
Invoice + Start

WF_STEP7_
Post_Signing
```

---

## Detailed Step Breakdown

### STEP 1: LinkedIn Connection (Prosp.ai → Notion)

**Workflow:** `WF_STEP1_Prosp_LinkedIn_Connection.json`
**Name:** `Lead Gen WF1 — Prosp LinkedIn Connection Tracking`
**Trigger:** Form Trigger (localhost) / Prosp.ai webhook (production)

```
[Form: Prosp LinkedIn Event] → [Normalize Data] → [Switch: Event Type]
                                                        │
                    ┌───────────────────────────────────┼────────────────────┐
                    ▼                                   ▼                    ▼
          [connection_sent]                   [connection_accepted]   [reply_received]
                    │                                   │                    │
          [Find Contact by LI URL]            [Find Contact]         [Find Contact]
                    │                                   │                    │
          [Exists?]                            [Exists?]              [Exists?]
           │      │                            │      │               │      │
          YES    NO                           YES    NO              YES    NO
           │      │                            │      │               │      │
     [Update]  [Create New]             [Update] [Create New]   [Update] [Create New]
     - Sent: ✓  - Sent: ✓              - Accepted  - Accepted  - Responded - Responded
               - Source: LI Loom             │      │
                                             └──┬───┘
                                                ▼
                                       [Add to Loom Videos Sheet]
                                       (handoff for manual Loom)
```

**Notion Fields Updated:**
- Name, Email, LinkedIn Profile, Company
- LI Connection Sent: ✓ (checkbox)
- LI Connection Accepted: ✓ (checkbox, on accept)
- Responded: ✓ (checkbox, on reply)
- Status: "Connection Sent" → "Connection Accepted" → "Responded"
- Source: "LI Loom Outreach"
- Last Contact Date: timestamp

**Google Sheets:** On `connection_accepted`, appends row to Loom Videos Sheet (Name, LI Profile) so Anthony knows to record and send a personalized Loom video.

---

### STEP 2: Loom Video Sent (Prosp.ai → Notion)

**Workflow:** `WF_STEP2_Loom_Sent.json`
**Trigger:** Prosp.ai webhook (message_sent event with Loom link detection)

```
[Prosp.ai Webhook] → [Filter: message contains loom.com]
                          │
                    [Find Notion Contact by LinkedIn URL]
                          │
                    [Update Notion Contact]
                    - Loom Sent: ✓
                    - Status: "Loom Sent"
                    - Last Contact Date: now
```

---

### STEP 3A: No Response Follow-Up (3-Day Timer)

**Workflow:** `WF_STEP3A_No_Response_Followup.json`
**Trigger:** Daily schedule (9 AM)

```
[Schedule Trigger: Daily 9 AM]
        │
  [Query Notion: Status = "Loom Sent" AND Loom Sent Date > 3 days ago]
        │
  [For Each Contact with No Response]
        │
        ├──► [Prosp.ai API: Move to Follow-Up Campaign]
        │    - Start 3-message follow-up sequence
        │    - Follow-up Loom video campaign
        │
        └──► [Update Notion Contact]
             - Status: "Follow-Up Sequence"
             - Moved to group: "3 Bravo"
             - Need to Follow Up Date: today
```

**Follow-Up Campaign (3 messages in Prosp.ai):**
1. Day 4: "Hey {name}, did you get a chance to watch the video?"
2. Day 7: Value-add follow-up with case study
3. Day 10: Final touch — soft close or resource share

---

### STEP 3B: Response Received

**Handled within:** `WF_STEP1_Prosp_LinkedIn_Connection.json` (reply_received event)

```
[Prosp.ai Webhook: reply_received]
        │
  [Find Notion Contact by LinkedIn URL]
        │
  [Update Notion Contact]
  - Responded: ✓
  - Status: "Responded"
  - Last Contact Date: now
```

---

### STEP 3C: Calendly Discovery Call Screening

**Workflow:** `WF_STEP3C_Calendly_Screening.json`
**Trigger:** Calendly webhook (invitee.created for Discovery Call)

```
[Calendly Webhook: invitee.created]
        │
  [Extract Booking Answers]
  - Name, Email, Company
  - Monthly Revenue (from custom question)
  - Employee Count, Budget
        │
  [Check Revenue: $0 - $5,000/month?]
    │                    │
   YES                  NO (Qualified)
    │                    │
    ▼                    ▼
  [Send Approval Email   [Update Notion]
   to Anthony]           - Status: "Meeting Booked"
  - Lead name, email     - Call Booked: ✓
  - Company, revenue
  - Employee count
  - Approve/Disapprove
    buttons (links)
        │
  ┌─────┴─────┐
  │           │
APPROVE    DISAPPROVE
  │           │
  ▼           ▼
[Notion:    [Send Cancellation Email]
 "Meeting    - Lead magnet free gift
 Booked"]    - "Don't qualify based on revenue"
  │           │
  │         [Delete Calendly Invite]
  │           │
  │         [Notion: "Declined"]
  ▼
[Calendly event continues]
```

**Approval Email Contains:**
- Lead name and contact info
- Company name and employee count
- Monthly revenue figure
- Approve button (webhook link)
- Disapprove button (webhook link)

---

### STEP 4: Post-Discovery Call Processing

**Workflow:** `WF_STEP4_Meeting_Processing.json`
**Name:** `Onboarding WF4 — Discovery Call Processing (Form → AI → Notion + Drive + GitHub)`
**Trigger:** Form Trigger (localhost) / BlueDot Svix webhook (production)

```
[Form: Meeting Transcript] → [Extract Form Data]
        │
  [Find Notion Contact (by email)]
        │
  [Extract Contact Info]
        │
  [Folder Exists?] → [Create Google Drive Folder if needed]
        │
  [Set Folder ID]
        │
  ┌─────┴─────────────────────────────────────┐
  ▼                                           ▼
  [GitHub: Create Repo from Template]   [Claude AI: 4-Section Analysis]
  - Private repo from vv-client-template  - ===MEETING_NOTES===
  - Includes all 8 Skills files           - ===PROPOSAL===
        │                                 - ===IMPLEMENTATION_GUIDE===
  [GitHub: Upload Transcript]             - ===ACTION_ITEMS=== (JSON)
                                                │
                                          [Parse AI Sections]
                                                │
                              ┌────────────┬────┴────┬──────────┬────────────┐
                              ▼            ▼         ▼          ▼            ▼
                        [Update Notion] [Meeting  [GitHub:   [GitHub:    [Draft
                         Meeting Held]  Record]   Proposal]  Impl Guide] Proposal
                                                                         Email]
```

**New in v5:** GitHub repo creation from template, expanded 4-section Claude AI prompt, proposal + implementation guide uploaded to GitHub, action items to Notion, draft proposal email via Gmail.

---

### STEP 4B: Audit Call Processing

**Workflow:** `WF_STEP4B_Audit_Call_Processing.json`
**Name:** `Onboarding WF4B — Audit Call Processing (Form → AI → Update GitHub + Notion)`
**Trigger:** Form Trigger (localhost) / BlueDot Svix webhook (production)

```
[Form: Audit Call Transcript] → [Extract Form Data]
        │
  [Find Notion Contact (by email)]
        │
  [Extract Contact Info (+ existing GitHub repo name)]
        │
  ┌─────┴─────────────────────────────────────┐
  ▼                    ▼                       ▼
  [Upload to Drive]  [GitHub: Upload         [Claude AI: Audit Analysis]
  (existing folder)   Audit Transcript]      - Refined proposal
                                              - Refined impl guide
                                              - Action items (JSON)
                                                    │
                                              [Parse AI Sections]
                                                    │
                              ┌────────────┬────────┴────────────┐
                              ▼            ▼                     ▼
                        [Update Notion] [Meeting Record    [GitHub: Update
                         Audit Notes]   Category=Audit]     Proposal + Guide]
```

**Key difference from STEP4:** Uses existing GitHub repo and Google Drive folder. GitHub operations use File > Edit (overwrite) instead of File > Create. Meeting Category = "Audit" instead of "Discovery".

---

### STEP 5: SOW/Contract Creation

**Workflow:** `WF_STEP5_SOW_Contract.json`
**Name:** `Onboarding WF5 — SOW/Contract Creation + Invoicing + Onboarding Doc`
**Trigger:** Form submission (Anthony submits after proposal approval)

```
[n8n Form: Contract Details]
- Client info (name, email, title, company)
- Project scope and name
- Timeline (start/end dates)
- Costs (fixed, retainer, initial payment)
- Compliance terms
        │
  [Create Google Drive Folder (if not exists)]
        │
  [PDFco: Fill SOW Template]
        │
  [Upload Unsigned Contract to Drive]
        │
  [SignWell: Create + Send for Signing]
  - Recipients: Anthony + Client
        │
  [Stripe: Create Customer]
  [Stripe: Create Invoice (DRAFT, auto_advance=false)]
  [IF Retainer: Create Subscription (PAUSED)]
        │
  [Update Notion Contact: "Contract Sent"]
  [Create Notion Project Record]
        │
  [Draft SOW Email (Gmail createDraft)]      ← NEW
  - Summarizes project scope, timeline, costs
  - Notes SignWell signing request is coming
  - Draft for Anthony to review before sending
        │
  [Save Stripe IDs to Notion]
```

---

### STEP 6: Contract & Invoice Reminders

**Workflow:** `WF_STEP6_Contract_Reminders.json`
**Name:** `Onboarding WF6 — Contract & Invoice Reminders (Daily → Every 3 Days)`
**Trigger:** Daily schedule (9 AM)

```
[Schedule: Every Day 9 AM]
        │
  ┌─────┴──────────────────────────────┐
  ▼                                    ▼
[Query: Unsigned Contracts]     [Query: Unpaid Invoices]
  │                                    │
[Calculate Days & Tier]         [Calculate Invoice Days & Tier]
  │                                    │
[Filter: Skip non-reminder days] [Filter: Skip non-reminder days]
  │                                    │
  ┌──────┼──────────────┐        ┌─────┴──────┐
  ▼      ▼              ▼        ▼            ▼
[≤7d]  [8-29d, %3]   [30+d]   [≤7d]      [8+d, %3]
Gentle  Escalation   Auto-     Gentle     Urgent
daily   every 3 days expire    Invoice    Invoice
  │      │              │        │            │
  └──┬───┘              │        └──────┬─────┘
     ▼                  ▼               ▼
[Log Reminder]    [Notion:Declined]  [Log Invoice Reminder]
```

**Reminder Schedule (contracts):** Daily for first 7 days, every 3 days for days 8-29, auto-expire at 30 days.
**Invoice Reminders (parallel):** Same daily/3-day pattern. Requires `Invoice Paid` checkbox property in Notion Contacts DB.

---

### STEP 7: Post-Signing Onboarding

**Workflow:** `WF_STEP7_Post_Signing.json`
**Trigger:** Schedule (every 15 minutes, dual-branch polling)

```
[Schedule: Every 15 Minutes]
        │
  ┌─────┴──────────────────────────────────┐
  ▼                                        ▼
BRANCH A: New Signatures            BRANCH B: Invoice Payment Check
  │                                        │
[Poll SignWell: completed docs]     [Query Notion: Status = "Contract Signed"]
  │                                        │
[Find Contact in Notion]            [For each pending contact]
  │                                        │
[Already processed?]                [Check Stripe Invoice Status]
  │ NO                                     │
[Download Signed Contract]          [Invoice Paid?]
[Upload to Google Drive]              │ YES          │ NO
  │                                   │              └─ (skip, wait)
[Update Notion: "Contract Signed"]    │
                                      ▼
                                  [Send Welcome Email]
                                  [Update Notion: "Project Started"]
                                  [Update Project: "Active"]
                                  [Resume Stripe Subscription]
```

**Key design:** Welcome email only sends after BOTH contract is signed AND invoice is paid. Branch A handles signing detection only — no Stripe operations (invoice is already sent by WF5). Branch B polls for payment confirmation before completing onboarding.

---

## Notion CRM Status Lifecycle (Complete)

```
"Connection Sent" → "Connection Accepted" → "Loom Sent"
     STEP 1              STEP 1                STEP 2
                                                  │
                                       ┌──────────┤
                                       ▼          ▼
                               "Follow-Up    "Responded"
                                Sequence"      STEP 3B
                                STEP 3A          │
                                                  ▼
                                          "Meeting Booked"
                                              STEP 3C
                                                  │
"Project Started" ← "Contract Signed" ← "Contract Sent" ← "Proposal Sent" ← "Meeting Held"
     STEP 7              STEP 7              STEP 5           STEP 6            STEP 4
                                                                │
                                                          "Proposal Draft"
                                                              STEP 4

Side exits: "Declined" (at any qualification/approval gate)
```

---

## Prosp.ai Webhook Events Reference

| Event | Workflow | Action |
|-------|----------|--------|
| `connection_sent` | WF_STEP1 | Create Notion contact, Status: "Connection Sent" |
| `connection_accepted` | WF_STEP1 | Update Notion, Status: "Connection Accepted" |
| `message_sent` (with Loom) | WF_STEP2 | Update Notion, Loom Sent: true |
| `reply_received` | WF_STEP1 | Update Notion, Status: "Responded" |

---

## Credential Requirements

| Service | Credential Type | Used In Steps | Notes |
|---------|----------------|---------------|-------|
| Prosp.ai | Webhook receiver (no polling API) | 1 | Form trigger for localhost |
| Notion | Integration Token (native node) | All steps | `notionApi` credential |
| Anthropic Claude | API Key | 4, 4B | `anthropicApi` credential |
| GitHub | Personal Access Token | 4, 4B | `githubApi` — repo scope required; HTTP Request for repo creation, native node for file ops |
| Calendly | OAuth2 | 3C | |
| Gmail | OAuth2 | 3C, 5, 6, 7 | `gmailOAuth2` — used for draft emails in 4, 5 |
| Google Drive | OAuth2 | 4, 4B, 5, 7 | |
| Google Sheets | OAuth2 | 1, 2 | For Loom Videos sheet |
| BlueDot | Svix Webhook (no REST API) | 4, 4B | Form trigger for localhost |
| SignWell | API Key | 5, 7 | |
| Stripe | Secret Key | 5, 7 | |
| PDFco | API Key | 5 | |

---

## File Manifest

### Lead Gen Workflows

| File | Workflow Name | Trigger |
|------|-------------|---------|
| `WF0_Lead_Scoring.json` | Lead Gen WF0 — Lead Score & Loom Script Generator | Schedule |
| `WF_STEP1_Prosp_LinkedIn_Connection.json` | Lead Gen WF1 — Prosp LinkedIn Connection Tracking | Form / Prosp.ai webhook |
| `WF_STEP2_Loom_Sent.json` | Lead Gen WF2 — Loom Sent Tracking (Sheet → Notion) | Schedule (30 min poll) |
| `WF_STEP3A_No_Response_Followup.json` | Lead Gen WF3A — No Response Follow-Up (3-Day Timer) | Daily schedule |
| `WF_STEP3C_Calendly_Screening.json` | Lead Gen WF3C — Calendly Discovery Call Screening | Calendly trigger |

### Onboarding Workflows

| File | Workflow Name | Trigger |
|------|-------------|---------|
| `WF_STEP4_Meeting_Processing.json` | Onboarding WF4 — Discovery Call Processing | Form / BlueDot webhook |
| `WF_STEP4B_Audit_Call_Processing.json` | Onboarding WF4B — Audit Call Processing | Form / BlueDot webhook |
| `WF_STEP5_SOW_Contract.json` | Onboarding WF5 — SOW/Contract Creation + Invoicing | n8n Form |
| `WF_STEP6_Contract_Reminders.json` | Onboarding WF6 — Contract & Invoice Reminders | Daily schedule |
| `WF_STEP7_Post_Signing.json` | Onboarding WF7 — Post-Signing Onboarding | Schedule / SignWell webhook |

---

## Import Order

| Order | File | Reason |
|-------|------|--------|
| 1 | WF0_Lead_Scoring | Lead scoring & research (standalone) |
| 2 | WF_STEP1_Prosp_LinkedIn_Connection | Entry point, creates contacts |
| 3 | WF_STEP2_Loom_Sent | Tracks Loom delivery |
| 4 | WF_STEP3A_No_Response_Followup | Depends on Loom Sent status |
| 5 | WF_STEP3C_Calendly_Screening | Qualification gate |
| 6 | WF_STEP4_Meeting_Processing | Post-call processing + GitHub repo |
| 7 | WF_STEP4B_Audit_Call_Processing | Audit call (depends on STEP4 repo) |
| 8 | WF_STEP5_SOW_Contract | Contract creation + draft SOW email |
| 9 | WF_STEP6_Contract_Reminders | Contract + invoice reminder engine |
| 10 | WF_STEP7_Post_Signing | Final onboarding |

## API Constraints

| Service | Constraint | Workaround |
|---------|-----------|------------|
| Prosp.ai | Webhook-only (no polling REST API) | Form trigger for localhost, webhook for production |
| BlueDot AI | Svix webhook-only (no REST API) | Form trigger for localhost, Svix webhook for production |
| GitHub | Native n8n node cannot create repos | HTTP Request for repo creation; native node for file ops |
