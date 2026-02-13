# Veteran Vectors — Pipeline Flowmap

## Inputs → Automations → Outputs (Sequential)

```
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
                          ├─ IF duplicate?               ├─► Slack #onboarding-alerts
                          │  YES → update row            │   "New audit call booked"
                          │  NO  → append new row        │
                          └─ Slack notify                │
                                                         ▼
                     ┌─────── GATE: Anthony conducts the audit call (manual) ──────┐
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
                          ├─ Claude API: extract         ├─► Slack #onboarding-alerts
                          │  proposal from transcript    │   "DRAFT Proposal Ready"
                          ├─ Parse AI response           │   + Google Doc edit link
                          ├─ Copy proposal template      │   + Pre-filled form link
                          ├─ Populate template           │
                          │  (batchUpdate placeholders)  │
                          ├─ Export Google Doc → PDF      │
                          ├─ Upload PDF to Drive folder   │
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
                                                         └─► Slack #onboarding-alerts
                                                             "Fully onboarded!"
```

---

## Sequential Gate Chain

```
Calendly          BlueDot           Anthony            Anthony          Client           SignWell
booking           transcript        reviews            submits          signs             webhook
  │                  │              proposal            form             contract            │
  ▼                  ▼                 │                  │                │                 ▼
┌────┐  ───►  ┌────┐  ───►  ┌─────────┐  ───►  ┌────┐  ───►  ┌────┐  ───►  ┌────┐
│WF1 │  GATE  │WF2 │  GATE  │ MANUAL  │  GATE  │WF3 │  GATE  │WF4 │  GATE  │WF5 │
│    │  ────  │    │  ────  │ REVIEW  │  ────  │    │  ────  │    │  ────  │    │
└────┘ audit  └────┘ human  └─────────┘ human  └────┘ client └────┘ client └────┘
       call    draft  review  edits in   submit  signs   waits  signs   fires
       done    ready  needed  Google Doc  form   contract        contract auto
```

**Every gate is either a hard human action or a hard external event. Nothing auto-advances past a gate.**

---

## Data Flow Between Systems

```
                  GOOGLE SHEETS                         GOOGLE DRIVE
              ┌──────────────────┐                 ┌──────────────────┐
              │  Prospects Tab   │                 │  Clients Folder  │
              │  ──────────────  │                 │  ──────────────  │
  WF1 WRITE → │  Prospect_ID    │                 │                  │
  WF1 WRITE → │  Name, Email    │    WF2 CREATE → │  {Company}/      │
  WF1 WRITE → │  Company        │    WF2 UPLOAD → │  ├─ Proposal.doc │
  WF2 WRITE → │  Status         │    WF2 UPLOAD → │  ├─ Proposal.pdf │
  WF2 WRITE → │  Proposal_Link  │    WF5 UPLOAD → │  ├─ Signed SOW   │
  WF2 WRITE → │  Form_Link      │    WF5 COPY  → │  └─ Checklist    │
  WF2 WRITE → │  Drive_Folder_ID│                 │                  │
              │                  │                 └──────────────────┘
              │  Client Tracker  │
              │  ──────────────  │                       SLACK
  WF3 WRITE → │  Client_Name    │                 ┌──────────────────┐
  WF3 WRITE → │  SignWell_Doc_ID│    WF1 POST  → │  #onboarding-    │
  WF3 WRITE → │  Invoice_ID    │    WF2 POST  → │    alerts         │
  WF3 WRITE → │  Stripe IDs    │    WF3 POST  → │  (all WF notifs)  │
  WF4 WRITE → │  Last_Reminder │    WF4 POST  → │                  │
  WF5 WRITE → │  Status        │    WF5 POST  → │  #client-{co}    │
  WF5 WRITE → │  Signed_Date   │    WF5 CREATE→ │  (per client)    │
              └──────────────────┘                 └──────────────────┘

                   STRIPE                            EXTERNAL APIs
              ┌──────────────────┐                 ┌──────────────────┐
  WF3 CREATE → │  Customer       │                 │  Calendly        │
  WF3 CREATE → │  Invoice Item   │    WF1 RECV ← │  (webhook in)    │
  WF3 CREATE → │  Invoice (DRAFT)│                 │                  │
  WF3 CREATE → │  Subscription?  │                 │  BlueDot         │
  WF5 SEND  → │  Invoice (LIVE) │    WF2 RECV ← │  (webhook in)    │
              └──────────────────┘                 │                  │
                                                   │  SignWell        │
                ANTHROPIC CLAUDE                   │  WF3 SEND  →   │
              ┌──────────────────┐    WF5 RECV ← │  (webhook in)    │
  WF2 CALL  → │  Sonnet 4       │                 │                  │
  WF2 RECV ← │  Proposal JSON  │                 │  Google Docs API │
              └──────────────────┘    WF2 CALL  → │  (batchUpdate)   │
                                                   │                  │
                GOOGLE CALENDAR                    │  Gmail           │
              ┌──────────────────┐    WF4 SEND  → │  (reminders)     │
  WF5 CREATE → │  Weekly reminder│    WF5 SEND  → │  (welcome email) │
              │  (with end date) │                 └──────────────────┘
              └──────────────────┘
```

---

## Status Lifecycle (Single Source of Truth: Google Sheets)

```
PROSPECTS SHEET STATUS:

  "Audit Scheduled"  ──►  "Proposal Draft"  ──►  (manual review happens outside Sheets)
        WF1                     WF2

CLIENT TRACKER STATUS:

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

## Gates Summary

| Gate | Where | Type | What Blocks |
|------|-------|------|-------------|
| G1: Audit Call | Between WF1 → WF2 | MANUAL | Anthony must conduct the call. BlueDot fires only after. |
| G2: Proposal Review | Between WF2 → WF3 | MANUAL | Anthony must review Google Doc. Status stays "Proposal Draft". Client sees nothing. |
| G3: Form Submit | WF3 trigger | MANUAL | Anthony must click form link and submit. Sends contract + creates invoice. |
| G4: Client Signature | Between WF3 → WF5 | EXTERNAL | Client must sign in SignWell. WF4 sends reminders while waiting. |
| G5: Idempotency | WF2 Match to Prospect | AUTO | Blocks duplicate BlueDot webhooks from creating duplicate proposals. |
| G6: Idempotency | WF5 Match Client Record | AUTO | Blocks duplicate SignWell webhooks from re-onboarding. |
| G7: Invoice Guard | WF5 Match Client Record | AUTO | Blocks onboarding if Invoice_ID is missing (prevents Stripe errors). |
| G8: Folder Guard | WF5 Match Client Record | AUTO | Blocks onboarding if Drive_Folder_ID is missing (prevents upload errors). |
