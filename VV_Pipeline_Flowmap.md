# Veteran Vectors — Pipeline Flowmap

## Full Pipeline: Notion CRM → Google Sheets → Client Onboarding

```
════════════════════════════════════════════════════════════════════════════════
 WF0: LEAD CAPTURE (NOT YET BUILT)                   Trigger: Prosp.AI / Manual
════════════════════════════════════════════════════════════════════════════════

 INPUT                    AUTOMATION                    OUTPUT
 ─────                    ──────────                    ──────
 Prosp.AI sends LI   ──►  Log connection request    ──► Notion CRM (Contacts)
 connection request        │                             - Status: "Connection Requested"
   OR                      ├─ Source: LI Loom Outreach   - Name, LinkedIn Profile
 Manual entry              │  / 10X Vets / Content       - LI Connection Sent: Yes
 (Referral, Warm,          │  / Warm / Referral          │
  Networking)              ├─ Wait for acceptance    ──► Notion update
                           │  (Prosp.AI webhook OR       - LI Connection Accepted: Yes
                           │   manual toggle)             - Status: "Connection Accepted"
                           │                              │
                           └─ Slack #onboarding-alerts   └─► Ready for Loom outreach
                              "New connection accepted"

              ┌──────── Anthony records + sends Loom video (manual) ──────┐
              │  335 Loom videos pending (from CRM Hub metrics)           │
              └───────────────────────────────────────────────────────────┘
                                                         │
════════════════════════════════════════════════════════════════════════════════
 WF0.5: LOOM OUTREACH + FOLLOW-UP (NOT YET BUILT)    Trigger: Notion status
════════════════════════════════════════════════════════════════════════════════

 INPUT                    AUTOMATION                    OUTPUT
 ─────                    ──────────                    ──────
 Notion status change ──►  Detect: "Loom Sent"       ──► Notion CRM updated
 to "Loom Sent"            │                             - Loom Sent: Yes
   OR                      ├─ Log Loom sent date         - Status: "Loom Sent"
 Anthony marks Loom        ├─ Start 3-day timer          │
 as sent                   │                             ├─► Follow-Up Sequence
                           ├─ IF no response in 3d:      │   - Status: "Follow-Up Sequence"
                           │  → send follow-up msg        │   - Auto LI message or email
                           │                              │
                           ├─ IF responded (Yes):    ──► Notion update
                           │  → Status: "Responded"      - Responded: Yes
                           │  → Book meeting link         - Status: "Responded"
                           │                              │
                           ├─ IF declined/no response:──► Notion update
                           │  → Status: "Declined"       - Status: "Declined"
                           │                              │
                           └─ IF meeting booked:     ──► Notion update
                              → Status: "Meeting          - Call Booked: Yes
                                Scheduled"                - Status: "Meeting Scheduled"
                                                          │
                                                          └─► Feeds into WF1
                                                              (Calendly booking)

              ┌──────── GATE: Prospect must book a Calendly call ─────────┐
              │  Conversion: 107 booked / 375 looms = 28.5% book rate     │
              └───────────────────────────────────────────────────────────┘
                                                         │
════════════════════════════════════════════════════════════════════════════════
 WF1: AUDIT CALL BOOKED                                    Trigger: Calendly
════════════════════════════════════════════════════════════════════════════════

 INPUT                    AUTOMATION                    OUTPUT
 ─────                    ──────────                    ──────
 Calendly webhook    ──►  Filter: invitee.created   ──► Prospects Sheet row
 (invitee.created)        only                          - Prospect_ID
                          │                             - Name, Email, Company
                          ├─ Extract invitee data       - Status: "Audit Scheduled"
                          ├─ Check duplicate email       │
                          ├─ IF duplicate?               ├─► Notion CRM updated
                          │  YES → update row            │   - Status: "Meeting Scheduled"
                          │  NO  → append new row        │   - Audit Call: Yes (after held)
                          └─ Slack notify                │
                                                         ├─► Slack #onboarding-alerts
                                                         │   "New audit call booked"
                                                         ▼
                     ┌─────── GATE: Anthony conducts the audit call (manual) ──────┐
                     │  Notion status → "Meeting Held" (after call)                │
                     └─────────────────────────────────────────────────────────────┘
                                                         │
════════════════════════════════════════════════════════════════════════════════
 WF2: PROPOSAL GENERATION                              Trigger: BlueDot
════════════════════════════════════════════════════════════════════════════════

 INPUT                    AUTOMATION                    OUTPUT
 ─────                    ──────────                    ──────
 BlueDot webhook     ──►  Filter: title contains    ──► Google Drive
 (transcript ready)       "audit" OR "RAPID" OR         - Client folder created
                          "discovery" OR                - Proposal Google Doc
                          "veteran vectors"             - Proposal PDF
                          │                              │
                          ├─ Read Prospects Sheet        ├─► Prospects Sheet updated
                          ├─ Match to Prospect           │   - Status: "Proposal Draft"
                          │  ⚠ HARD STOP if no match    │   - Proposal_Link (Google Doc)
                          │  ⚠ SKIP if already drafted   │   - Form_Link (pre-filled)
                          │                              │   - Drive_Folder_ID
                          ├─ Create client Drive folder  │
                          ├─ Claude API: extract         ├─► Notion CRM updated
                          │  proposal from transcript    │   - Status: "Proposal Sent"
                          ├─ Parse AI response           │   - Projects relation linked
                          ├─ Copy proposal template      │
                          ├─ Populate template           ├─► Slack #onboarding-alerts
                          │  (batchUpdate placeholders)  │   "DRAFT Proposal Ready"
                          ├─ Export Google Doc → PDF      │   + Google Doc edit link
                          ├─ Upload PDF to Drive folder   │   + Pre-filled form link
                          ├─ Build pre-filled form URL    │
                          ├─ Update Prospects Sheet       │
                          └─ Slack notify                 │
                                                          ▼
                     ┌─────── GATE: Anthony reviews proposal in Google Docs ───────┐
                     │  - Edit content, fix pricing, verify scope                  │
                     │  - Client has NOT received anything yet                     │
                     │  - Only proceed when proposal is correct                    │
                     └─────────────────────────────────────────────────────────────┘
                                                          │
════════════════════════════════════════════════════════════════════════════════
 WF3: CONTRACT + INVOICING                             Trigger: n8n Form
════════════════════════════════════════════════════════════════════════════════

 INPUT                    AUTOMATION                    OUTPUT
 ─────                    ──────────                    ──────
 Anthony submits     ──►  Validate financial fields ──► SignWell
 pre-filled form          (parse $, convert cents)      - Contract sent to client
 (from Slack link)        │                              │
                          ├─ Read Prospects Sheet        ├─► Stripe
                          ├─ Lookup Drive Folder ID      │   - Customer created
                          ├─ IF no folder? fallback      │   - Invoice created
                          │                              │   - auto_advance=false
                          ├─ Build SignWell fields        │     (NOT sent yet)
                          ├─ SignWell: send contract      │   - Retainer subscription
                          │                              │     (if applicable)
                          ├─ Stripe: create customer     │
                          ├─ Stripe: invoice item        ├─► Client Tracker row
                          ├─ Stripe: create invoice      │   - Status: "Contract Sent"
                          │  (auto_advance=false)        │   - SignWell_Doc_ID
                          │                              │   - Stripe_Customer_ID
                          ├─ IF retainer? → create       │   - Invoice_ID
                          │  price + subscription        │   - Contract_Sent_Date (ISO)
                          │                              │
                          ├─ Log to Client Tracker       ├─► Slack #onboarding-alerts
                          └─ Slack notify                    "Contract sent, invoice ready"
                                                          │
                     ┌─────── GATE: Client must sign the contract ─────────────────┐
                     │  WF4 sends reminders while waiting                          │
                     └─────────────────────────────────────────────────────────────┘
                                                          │
════════════════════════════════════════════════════════════════════════════════
 WF4: CONTRACT REMINDERS                               Trigger: Daily 9 AM
════════════════════════════════════════════════════════════════════════════════

 INPUT                    AUTOMATION                    OUTPUT
 ─────                    ──────────                    ──────
 Schedule trigger    ──►  Read Client Tracker       ──► Gmail
 (every 24hr, 9 AM)      Filter: Status =               - 48hr: friendly reminder
                          "Contract Sent"                - 7 day: firmer reminder
                          │                              │
                          ├─ Calculate hours since   ──► Slack (14-day only)
                          │  Contract_Sent_Date          "Contract unsigned 14 days"
                          │  Check Last_Reminder_Sent    │
                          │                          ──► Client Tracker updated
                          ├─ 48hr  → friendly email      - Last_Reminder_Sent logged
                          ├─ 7day  → firmer email        - Status: "Contract Expired"
                          ├─ 14day → Slack escalation      (30-day only)
                          ├─ 30day → auto-expire         │
                          │                              │
                          └─ Log reminder sent           │
                                                         │
              ┌──────── No client action needed — fully automated ─────────┐
              │  48hr + 7day emails: auto-sent (professional templates)    │
              │  14day: Slack alert to Anthony (decide next action)        │
              │  30day: auto-expire (no client email, internal only)       │
              └────────────────────────────────────────────────────────────┘
                                                         │
                     ┌─────── GATE: Client signs in SignWell ──────────────────────┐
                     └─────────────────────────────────────────────────────────────┘
                                                         │
════════════════════════════════════════════════════════════════════════════════
 WF5: POST-SIGNING ONBOARDING                         Trigger: SignWell
════════════════════════════════════════════════════════════════════════════════

 INPUT                    AUTOMATION                    OUTPUT
 ─────                    ──────────                    ──────
 SignWell webhook    ──►  Filter: "completed" event ──► Stripe
 (document.completed)     │                             - Invoice SENT (post-signing)
                          ├─ Read Client Tracker          │
                          ├─ Match by SignWell_Doc_ID    ├─► Google Drive
                          │  ⚠ SKIP if "Onboarded"      │   - Signed PDF uploaded
                          │  ⚠ STOP if no Invoice_ID    │
                          │  ⚠ STOP if no Folder_ID     ├─► Slack
                          │                              │   - #client-{company} created
                          ├─ Stripe: send invoice        │   - Channel topic set
                          ├─ Download signed PDF         │   - Welcome message posted
                          ├─ Upload to client folder     │
                          │                              ├─► Google Drive
                          │  SEQUENTIAL (no parallel):   │   - Onboarding checklist
                          ├─ Create Slack channel         │     copied + shared with client
                          ├─ Set channel topic           │
                          ├─ Post welcome message        ├─► Google Calendar
                          ├─ Copy onboarding checklist   │   - Weekly reminder
                          ├─ Share checklist with client  │     (with end date)
                          ├─ Create weekly reminder      │
                          │                              ├─► Gmail
                          ├─ Send welcome email (ONCE)   │   - Welcome email to client
                          ├─ Update tracker: "Onboarded" │     (kickoff link + next steps)
                          └─ Slack final confirmation    │
                                                         ├─► Client Tracker updated
                                                         │   - Status: "Onboarded"
                                                         │   - Signed_Date
                                                         │   - Slack_Channel
                                                         │
                                                         ├─► Notion CRM updated
                                                         │   - Contact Status: "Project Started"
                                                         │   - Project Status: "Active"
                                                         │
                                                         └─► Slack #onboarding-alerts
                                                             "Fully onboarded!"
```

---

## Sequential Gate Chain (Full Pipeline)

```
Prosp.AI        Anthony          Prospect         Calendly          BlueDot
sends LI        sends Loom       responds/        booking           transcript
request         video            books call          │                  │
  │                │                │                 │                  │
  ▼                ▼                ▼                 ▼                  ▼
┌─────┐  ───►  ┌──────┐  ───►  ┌──────┐  ───►  ┌────┐  ───►  ┌────┐
│ WF0 │  GATE  │WF0.5 │  GATE  │ BOOK │  GATE  │WF1 │  GATE  │WF2 │
│     │  ────  │      │  ────  │ CALL │  ────  │    │  ────  │    │
└─────┘ accept └──────┘ respond└──────┘ audit  └────┘ audit  └────┘
        connect  loom    or book  calendly call    call   draft
        (LI)     sent    meeting  link     done    done   ready
                                                           │
                    Anthony            Anthony          Client           SignWell
                    reviews            submits          signs             webhook
                    proposal            form             contract            │
                       │                  │                │                 ▼
              ───►  ┌─────────┐  ───►  ┌────┐  ───►  ┌────┐  ───►  ┌────┐
              GATE  │ MANUAL  │  GATE  │WF3 │  GATE  │WF4 │  GATE  │WF5 │
              ────  │ REVIEW  │  ────  │    │  ────  │    │  ────  │    │
              human └─────────┘ human  └────┘ client └────┘ client └────┘
              review  edits in   submit  signs   waits  signs   fires
              needed  Google Doc  form   contract        contract auto
```

**Every gate is either a hard human action or a hard external event. Nothing auto-advances past a gate.**

---

## Data Flow Between Systems

```
              NOTION CRM (Lead Gen DB)                  GOOGLE SHEETS
          ┌───────────────────────────┐            ┌──────────────────┐
          │  Contacts (1,445 rows)    │            │  Prospects Tab   │
          │  ─────────────────────    │            │  ──────────────  │
 WF0   →  │  Name, LinkedIn Profile  │            │                  │
 WF0   →  │  LI Connection Sent/Acc  │ WF1 WRITE →│  Prospect_ID    │
 WF0   →  │  Source (LI Loom / etc)  │ WF1 WRITE →│  Name, Email    │
 WF0   →  │  Status                  │ WF1 WRITE →│  Company        │
 WF0.5 →  │  Loom Sent               │ WF2 WRITE →│  Status         │
 WF0.5 →  │  Responded               │ WF2 WRITE →│  Proposal_Link  │
 WF0.5 →  │  Need to Follow Up Date  │ WF2 WRITE →│  Form_Link      │
 WF1   →  │  Call Booked, Audit Call  │ WF2 WRITE →│  Drive_Folder_ID│
 WF1   →  │  Meetings (relation)     │            │                  │
 WF2   →  │  Projects (relation)     │            │  Client Tracker  │
 WF5   →  │  Status: Project Started │            │  ──────────────  │
          │                           │ WF3 WRITE →│  Client_Name    │
          │  Projects (23 rows)       │ WF3 WRITE →│  SignWell_Doc_ID│
          │  ────────────────────     │ WF3 WRITE →│  Invoice_ID    │
 WF2   →  │  Project Name             │ WF3 WRITE →│  Stripe IDs    │
 WF2   →  │  Client (relation)        │ WF4 WRITE →│  Last_Reminder │
 WF3   →  │  Project Cost, Retainer   │ WF5 WRITE →│  Status        │
 WF5   →  │  Project Status           │ WF5 WRITE →│  Signed_Date   │
 WF5   →  │  Dollars Received         │            └──────────────────┘
          │  Free or Paid              │
          │                           │               GOOGLE DRIVE
          │  Meetings (0 rows)        │            ┌──────────────────┐
          │  ──────────────────       │            │  Clients Folder  │
 WF1   →  │  Meeting Title            │            │  ──────────────  │
 WF1   →  │  Date, Contact            │ WF2 CREATE→│  {Company}/      │
 WF2   →  │  BlueDot Notes            │ WF2 UPLOAD→│  ├─ Proposal.doc │
 WF2   →  │  Meeting Category         │ WF2 UPLOAD→│  ├─ Proposal.pdf │
          └───────────────────────────┘ WF5 UPLOAD→│  ├─ Signed SOW   │
                                        WF5 COPY  →│  └─ Checklist    │
                                                    └──────────────────┘

                   STRIPE                            EXTERNAL APIs
              ┌──────────────────┐                 ┌──────────────────┐
  WF3 CREATE → │  Customer       │                 │  Prosp.AI        │
  WF3 CREATE → │  Invoice Item   │    WF0 RECV ← │  (LI automation)  │
  WF3 CREATE → │  Invoice (DRAFT)│                 │                  │
  WF3 CREATE → │  Subscription?  │                 │  Calendly        │
  WF5 SEND  → │  Invoice (LIVE) │    WF1 RECV ← │  (webhook in)    │
              └──────────────────┘                 │                  │
                                                   │  BlueDot         │
                ANTHROPIC CLAUDE                   │  WF2 RECV ← │  │
              ┌──────────────────┐                 │  (webhook in)    │
  WF2 CALL  → │  Sonnet 4       │                 │                  │
  WF2 RECV ← │  Proposal JSON  │                 │  SignWell        │
              └──────────────────┘    WF3 SEND  → │  (contract out)  │
                                      WF5 RECV ← │  (webhook in)    │
               GOOGLE CALENDAR                    │                  │
              ┌──────────────────┐                 │  Google Docs API │
  WF5 CREATE → │  Weekly reminder│    WF2 CALL  → │  (batchUpdate)   │
              │  (with end date) │                 │                  │
              └──────────────────┘                 │  Gmail           │
                                      WF4 SEND  → │  (reminders)     │
                  SLACK                WF5 SEND  → │  (welcome email) │
              ┌──────────────────┐                 └──────────────────┘
  WF0  POST → │  #onboarding-    │
  WF1  POST → │    alerts         │
  WF2  POST → │  (all WF notifs)  │
  WF3  POST → │                  │
  WF4  POST → │  #client-{co}    │
  WF5  POST → │  (per client)    │
  WF5 CREATE→ │                  │
              └──────────────────┘
```

---

## Notion CRM ↔ Pipeline Status Alignment

```
╔════════════════════════════════════════════════════════════════════════════════╗
║  NOTION CONTACT STATUS        PIPELINE STAGE          GOOGLE SHEETS STATUS   ║
╠════════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  "Connection Requested"  ──►  WF0: Lead Capture       (not in Sheets yet)    ║
║       565 contacts            Prosp.AI sent LI req                           ║
║                                      │                                       ║
║  "Connection Accepted"   ──►  WF0: Lead Captured      (not in Sheets yet)    ║
║       381 contacts            Ready for Loom                                 ║
║                                      │                                       ║
║  "Loom Sent"             ──►  WF0.5: Outreach          (not in Sheets yet)   ║
║       2 contacts              Loom video delivered                            ║
║                                      │                                       ║
║  "Follow-Up Sequence"    ──►  WF0.5: Follow-Up         (not in Sheets yet)   ║
║       53 contacts             3-day auto follow-up                           ║
║                                      │                                       ║
║  "Responded"             ──►  WF0.5: Qualified          (not in Sheets yet)  ║
║       15 contacts             Prospect replied yes                           ║
║                                      │                                       ║
║  "Declined"              ──►  DEAD END                  (not in Sheets)      ║
║       315 contacts            No further automation                          ║
║                                      │                                       ║
║  "Meeting Scheduled"     ──►  WF1: Calendly Booked  →  "Audit Scheduled"    ║
║       20 contacts             Call on calendar            Prospects Sheet     ║
║                                      │                                       ║
║  "Meeting Held"          ──►  GATE: Audit Conducted     "Audit Scheduled"    ║
║       56 contacts             Call completed              (unchanged)         ║
║                                      │                                       ║
║  "Proposal Sent"         ──►  WF2: Proposal Gen     →  "Proposal Draft"     ║
║       2 contacts              Draft created               Prospects Sheet     ║
║                                      │                                       ║
║  (no Notion status)      ──►  WF3: Contract Sent    →  "Contract Sent"      ║
║                               SignWell + Stripe           Client Tracker      ║
║                                      │                                       ║
║  (no Notion status)      ──►  WF4: Reminders        →  "Contract Expired"   ║
║                               30-day auto-expire          Client Tracker      ║
║                                      │                                       ║
║  "Project Started"       ──►  WF5: Onboarded        →  "Onboarded"          ║
║       7 contacts              Fully activated             Client Tracker      ║
║                                                                              ║
╚════════════════════════════════════════════════════════════════════════════════╝
```

### Notion Project Status ↔ Pipeline

| Notion Project Status | Count | Pipeline Stage | What It Means |
|----------------------|-------|----------------|---------------|
| Need Follow Up | 6 | Pre-WF1 | Audit call pending or needs re-engagement |
| Proposal Sent | 7 | WF2 → WF3 gap | Proposal delivered, waiting on contract |
| Active | 5 | Post-WF5 | Client onboarded, work in progress |
| Completed | 4 | Post-WF5 | Project delivered, retainer may continue |

### Notion Contact Sources (Lead Channels)

| Source | Count | % of Total | Entry Point |
|--------|-------|------------|-------------|
| LI Loom Outreach | 1,120 | 77.6% | WF0 → WF0.5 (primary) |
| LI Loom Outreach/10X Vets | 171 | 11.8% | WF0 → WF0.5 (sub-campaign) |
| LI Content Outreach | 31 | 2.1% | WF0 (content-based) |
| Networking/Podcast | 26 | 1.8% | Manual entry → WF1 |
| Warm Outreach/Text | 12 | 0.8% | Manual entry → WF1 |
| Referral | 6 | 0.4% | Manual entry → WF1 |
| Unknown / blank | 78 | 5.4% | Various |

---

## Status Lifecycle (Dual Source of Truth: Notion + Google Sheets)

```
NOTION CRM STATUS (upstream — lead gen through audit):

  "Connection      "Connection      "Loom        "Follow-Up       "Responded"
   Requested"  ──►  Accepted"  ──►  Sent"   ──►  Sequence"  ──►  or "Declined"
      WF0              WF0          WF0.5          WF0.5            WF0.5
                                                                      │
                                      ┌───────────────────────────────┘
                                      ▼
                              "Meeting         "Meeting        "Proposal       "Project
                               Scheduled" ──►   Held"    ──►   Sent"     ──►   Started"
                                  WF1           GATE            WF2              WF5


GOOGLE SHEETS — PROSPECTS TAB (mid-stream — audit through proposal):

  "Audit Scheduled"  ──►  "Proposal Draft"  ──►  (manual review happens outside Sheets)
        WF1                     WF2


GOOGLE SHEETS — CLIENT TRACKER (downstream — contract through onboarding):

  "Contract Sent"  ──►  "Onboarded"     (happy path)
       WF3                  WF5
         │
         ├──►  "Contract Expired"        (30-day timeout)
         │          WF4
         │
         └──►  (no "Contract Declined"   (not yet built)
                 status — future WF)
```

---

## Funnel Metrics (from Notion CRM Hub)

```
  Total Leads ──────────────────────────────────────── 1,444
       │
  LI Connections Sent ──────────────────────────────── 1,325  (91.8% of leads)
       │
  LI Connections Accepted ──────────────────────────── 817    (56.6% accept rate)
       │
  Looms Sent ──────────────────────────────────────── 375    (45.9% of accepted)
       │
  Responses (Yes) ─────────────────────────────────── 153    (40.8% of looms)
       │
  Calls Booked ────────────────────────────────────── 107    (28.5% of looms)
       │
  Audit Calls ─────────────────────────────────────── 23     (21.5% of booked)
       │
  ├─ Free Projects ────────────────────────────────── 5
  └─ Paid Projects ────────────────────────────────── 5
       │
  Pipeline Value ──────────────────────────────────── $125,500
  Retainer MRR ────────────────────────────────────── $3,950
  Collected ───────────────────────────────────────── $3,250
```

---

## Sync Gaps (Notion ↔ Google Sheets)

| Gap | Impact | Resolution |
|-----|--------|------------|
| WF0 + WF0.5 not built | 817 accepted connections tracked ONLY in Notion. No automation for Loom outreach or follow-ups. | Build WF0 (Prosp.AI → Notion) and WF0.5 (Loom + follow-up automation) |
| No Notion API writes in WF1-WF5 | Google Sheets and Notion are disconnected. Status changes in Sheets don't sync back to Notion. | Add Notion API update nodes to WF1 (Meeting Scheduled), WF2 (Proposal Sent), WF5 (Project Started) |
| Meetings table empty | BlueDot transcripts exist but Meetings table has 0 rows. No meeting history in CRM. | WF1 should write to Meetings table on Calendly booking. WF2 should add BlueDot Notes after transcript. |
| No "Contract Sent" in Notion | Notion has no status between "Proposal Sent" and "Project Started". Clients in contract limbo are invisible in CRM. | Add Notion status update in WF3 (Contract Sent) and WF4 (Contract Expired) |
| Projects table missing fields | No Start Date, Retainer, or Dollars Received populated for most projects. | WF3/WF5 should write financial data back to Notion Projects table |
| 335 Loom videos pending | CRM Hub shows 335 looms to make. No automation to surface priority list or track recording. | WF0.5 should generate daily "Looms to Record" list from Notion contacts with Status: "Connection Accepted" |

---

## Gates Summary

| Gate | Where | Type | What Blocks |
|------|-------|------|-------------|
| G0: LI Accept | WF0 output | EXTERNAL | Prospect must accept LinkedIn connection request. |
| G0.5: Loom Record | Between WF0 → WF0.5 | MANUAL | Anthony must record and send Loom video. |
| G0.6: Prospect Response | WF0.5 follow-up | EXTERNAL | Prospect must respond or book a call. |
| G1: Audit Call | Between WF1 → WF2 | MANUAL | Anthony must conduct the call. BlueDot fires only after. |
| G2: Proposal Review | Between WF2 → WF3 | MANUAL | Anthony must review Google Doc. Status stays "Proposal Draft". Client sees nothing. |
| G3: Form Submit | WF3 trigger | MANUAL | Anthony must click form link and submit. Sends contract + creates invoice. |
| G4: Client Signature | Between WF3 → WF5 | EXTERNAL | Client must sign in SignWell. WF4 sends reminders while waiting. |
| G5: Idempotency | WF2 Match to Prospect | AUTO | Blocks duplicate BlueDot webhooks from creating duplicate proposals. |
| G6: Idempotency | WF5 Match Client Record | AUTO | Blocks duplicate SignWell webhooks from re-onboarding. |
| G7: Invoice Guard | WF5 Match Client Record | AUTO | Blocks onboarding if Invoice_ID is missing (prevents Stripe errors). |
| G8: Folder Guard | WF5 Match Client Record | AUTO | Blocks onboarding if Drive_Folder_ID is missing (prevents upload errors). |

---

## Priority Build Order (Not Yet Built)

| Priority | Workflow | Trigger | Impact |
|----------|----------|---------|--------|
| P0 | **Notion API sync in WF1-WF5** | Existing WFs | Closes the Notion ↔ Sheets gap. Every status change writes back to Notion. |
| P1 | **WF0: Lead Capture** | Prosp.AI webhook | Automates "Connection Requested" → "Connection Accepted" logging. |
| P2 | **WF0.5: Loom Outreach** | Notion status change | Automates 3-day follow-up sequence. Surfaces daily Loom recording list. |
| P3 | **WF2.5: Proposal Delivery** | Anthony "Reviewed" click | Sends finalized proposal via email or LinkedIn. Closes the gap between WF2 (draft) and WF3 (contract). |
