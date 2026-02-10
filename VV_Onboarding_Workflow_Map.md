# Veteran Vectors — Client Onboarding Automation Architecture (v2 — Optimized)

## Complete Workflow Map (Post-Audit Rebuild)

---

## The Pipeline at a Glance

```
CLIENT BOOKS     →  YOU DO THE    →  BLUEDOT         →  YOU REVIEW    →  YOU SUBMIT     →  REMINDERS   →  CLIENT SIGNS  →  INVOICE SENT  →  FULL
AUDIT CALL          AUDIT CALL       PROCESSES           PROPOSAL        ONBOARDING        IF NEEDED      CONTRACT        + ONBOARDING      ONBOARDING
                                     TRANSCRIPT                          FORM

   WF1                (manual)         WF2              (manual)          WF3               WF4          (manual)          WF5
   Calendly                            BlueDot                            n8n Form           Schedule      SignWell         SignWell
   webhook                             webhook                            trigger            trigger       (client)         webhook
```

**Key change from v1:** Invoice is now sent AFTER contract signing (WF5), not alongside the contract (WF3).

---

## Workflow 1: Audit Call Booked (Calendly Trigger)

**Trigger:** Client books an audit call via Calendly

**v2 improvements:** Event type filtering, duplicate detection, Prospect_ID generation, Slack notification

```
[Calendly Webhook] ──► [Filter: invitee.created only]
                              │
                         Other events ── (stop)
                              │
                         YES ──► [Extract Invitee Data]
                                  - Name, Email, Company
                                  - Generate Prospect_ID (VV-xxxx)
                                        │
                                        ▼
                                 [Read Prospects Sheet]
                                 Check for existing email
                                        │
                                        ▼
                                 [IF Duplicate?]
                                   │            │
                                  YES          NO
                                   │            │
                                   ▼            ▼
                            [Update Row]  [Append New Row]
                                   │            │
                                   ▼            ▼
                            [Slack: "New audit call booked"]
```

---

## Workflow 2: Audit Call Complete → Folder + Proposal + Pre-filled Form (BlueDot Trigger)

**Trigger:** BlueDot webhook fires after audit call recording is processed

**v2 improvements:** Hard-stop on match failure (no fallback), idempotency check, Gamma retry polling, sequential data flow

```
[BlueDot Webhook] ──► [Filter: "audit" in title?]
                            │
                       NO ──┘ (stop)
                            │
                       YES ──► [Read Prospects Sheet]
                                  (match by name/email)
                                     │
                                     ▼
                              [Match to Prospect]
                              ⚠ HARD STOP if no match found
                              ⚠ SKIP if already has Drive_Folder_ID
                                     │
                                     ▼
                              [Create Client Drive Folder]
                                     │
                                     ▼
                              [AI Node — OpenAI GPT-4o]
                              Extract from transcript
                                     │
                                     ▼
                              [Parse AI Response]
                                     │
                                     ▼
                              [Gamma API — Generate Proposal]
                                     │
                                     ▼
                              [Poll Gamma With Retry]  ◄── NEW: 5 attempts × 30s
                              Check status === 'completed'
                              Verify pdfUrl exists
                                     │
                                     ▼
                              [Download Proposal PDF]
                                     │
                                     ▼
                              [Upload to Client Drive Folder]
                                     │
                                     ▼
                              [Build Pre-filled Form URL]
                                     │
                                     ▼
                              [Update Prospects Sheet]  ◄── MOVED: Now runs AFTER all steps
                              - Status: "Proposal Sent"
                              - Drive_Folder_ID, Proposal_Link, Form_Link
                                     │
                                     ▼
                              [Slack Notify Anthony]
                              + Gamma edit link (REVIEW FIRST)
                              + Pre-filled form link (USE AFTER REVIEW)
```

---

## Workflow 3: Client Onboarding (n8n Form Trigger)

**Trigger:** Anthony submits the pre-filled onboarding form AFTER reviewing the proposal

**v2 improvements:** Form validation, pre-computed financial amounts, invoice created but NOT sent, full ISO timestamps

```
[n8n Form Submit] ──► [Validate Form Data]  ◄── NEW
                      Parse & validate all financial fields
                      Normalize Yes/No fields to booleans
                      Convert amounts to cents
                              │
                              ▼
                      [Read Prospects Sheet]
                      Lookup Drive_Folder_ID
                              │
                              ▼
                      [IF Needs Folder?]
                        │            │
                       YES          NO
                        │            │
                        ▼            │
                  [Fallback          │
                   Create Folder]    │
                        │            │
                        ▼            ▼
                      [Merge Folder ID]
                              │
                              ▼
                      [Build SignWell Fields]
                              │
                              ▼
                      [SignWell API — Send Contract]
                              │
                              ▼
                      [Stripe — Create Customer]
                              │
                              ▼
                      [Stripe — Create Invoice Item]  ◄── Uses pre-validated cents
                              │
                              ▼
                      [Stripe — Create Invoice]  ◄── auto_advance=false (NOT SENT)
                              │
                              ▼
                      [IF Retainer = Yes]
                        │            │
                       YES          NO
                        │            │
                        ▼            │
                  [Create Price +    │
                   Subscription]     │
                        │            │
                        ▼            ▼
                      [Log to Client Tracker Sheet]
                      - Full ISO timestamp for Contract_Sent_Date
                      - Invoice_ID (for WF5 to send later)
                      - Last_Reminder_Sent column
                      - Project_End_Date
                              │
                              ▼
                      [Slack: "Contract sent — invoice ready but not sent"]
```

---

## Workflow 4: Contract Reminders (Schedule Trigger)

**Trigger:** Runs every 24 hours at 9 AM

**v2 improvements:** Accurate ISO timing, reminder tracking to prevent duplicates, 14-day escalation, 30-day auto-expire

```
[Schedule Trigger] ──► [Read Client Tracker]
                        Filter: Status = "Contract Sent"
                              │
                              ▼
                      [Calculate Reminder Timing]
                      Uses full ISO timestamp
                      Checks Last_Reminder_Sent to prevent duplicates
                              │
                              ▼
                      [Route to correct action]
                              │
                   ┌──────────┼──────────┬──────────┐
                   ▼          ▼          ▼          ▼
             [48 hours]  [7 days]   [14 days]  [30 days]
             Friendly    Firmer     Slack       Auto-expire
             email       email      escalation  + update status
                   │          │          │          │
                   ▼          ▼          ▼          ▼
                      [Log Reminder Sent]  ◄── Prevents duplicate sends
```

---

## Workflow 5: Contract Signed → Full Onboarding (SignWell Webhook)

**Trigger:** SignWell webhook fires when all parties have signed

**v2 improvements:** Invoice sent here, race condition fixed, row lookup by SignWell_Doc_ID, checklist shared with client, calendar end date

```
[SignWell Webhook] ──► [Filter: "completed" event]
                              │
                              ▼
                      [Extract SignWell Data]
                              │
                              ▼
                      [Read Client Tracker + Match Record]
                              │
                              ▼
                      [Stripe Send Invoice]  ◄── MOVED FROM WF3
                              │
                              ▼
                      [Download Signed PDF → Upload to Drive]
                              │
                              ▼
                ┌─────────────┴─────────────┐
                │                            │
        [Create Slack Channel]       [Copy Onboarding Checklist]
        + Set topic                         │
        + Post welcome message       [Share With Client]  ◄── NEW
                │                            │
                │                    [Create Weekly Reminder]
                │                    with UNTIL date  ◄── FIXED
                │                            │
                └─────────────┬─────────────┘
                              │
                              ▼
                      [Send Welcome Email]  ◄── FIXED: Single convergence point
                              │
                              ▼
                      [Update Tracker: "Onboarded"]
                      lookupColumn: SignWell_Doc_ID  ◄── FIXED
                              │
                              ▼
                      [Slack: "Fully onboarded!"]
```

---

## Data Flow Summary

```
CALENDLY          BLUEDOT           N8N FORM          SIGNWELL
(booking)         (transcript)      (you review)      (signature)
    │                 │                  │                 │
    ▼                 ▼                  ▼                 ▼
┌──────────────────────────────────────────────────────────────┐
│               PROSPECTS SHEET (Tab 1)                        │
│  Prospect_ID | Name | Email | Company | Status |             │
│  Drive_Folder_ID | Proposal_Link | Form_Link                │
├──────────────────────────────────────────────────────────────┤
│               CLIENT TRACKER (Tab 2)                         │
│  Client | Project | Cost | SignWell_Doc_ID | Stripe IDs |    │
│  Invoice_ID | Drive_Folder_ID | Status | Contract_Sent_Date │
│  Last_Reminder_Sent | Project_End_Date                       │
└──────────────────────────────────────────────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
   GOOGLE DRIVE       STRIPE         SLACK
   Client Folder/     Customer       #client-{company}
   ├── Proposal.pdf   Invoice        #onboarding-alerts
   ├── Signed SOW     Subscription
   └── Checklist *    (* shared)     GOOGLE CALENDAR
                                     Weekly Reminder (with end date)
```

---

## Prospects Sheet Columns (Updated v2)

| Column | Header | Populated By |
|--------|--------|-------------|
| A | Prospect_ID | WF1 (NEW) |
| B | First_Name | WF1 |
| C | Last_Name | WF1 |
| D | Full_Name | WF1 |
| E | Email | WF1 |
| F | Company_Name | WF1 |
| G | Client_Title | WF1 |
| H | Company_Address | WF1 |
| I | Company_City | WF1 |
| J | Company_State | WF1 |
| K | Company_Zipcode | WF1 |
| L | Scheduled_Time | WF1 |
| M | Event_URI | WF1 |
| N | Status | WF1 → WF2 |
| O | Booked_Date | WF1 (now full ISO) |
| P | Proposal_Link | WF2 |
| Q | Form_Link | WF2 |
| R | Drive_Folder_ID | WF2 |

## Client Tracker Columns (Updated v2)

| Column | Header | Populated By |
|--------|--------|-------------|
| A | Client_Name | WF3 |
| B | Email | WF3 |
| C | Company | WF3 |
| D | Project | WF3 |
| E | Project_Cost | WF3 |
| F | Monthly_Retainer | WF3 |
| G | SignWell_Doc_ID | WF3 |
| H | Stripe_Customer_ID | WF3 |
| I | Invoice_ID | WF3 (NEW — for WF5 to send) |
| J | Drive_Folder_ID | WF3 |
| K | Status | WF3 → WF4 → WF5 |
| L | Contract_Sent_Date | WF3 (now full ISO) |
| M | Signed_Date | WF5 |
| N | Slack_Channel | WF5 |
| O | Last_Reminder_Sent | WF4 (NEW) |
| P | Project_End_Date | WF3 (NEW) |

---

## Import Order

| Order | File | Why This Order |
|-------|------|----------------|
| 1 | WF1_Calendly_Booking.json | Standalone, no dependencies |
| 2 | WF3_Onboarding_Form.json | Need the form ID for WF2 |
| 3 | WF2_BlueDot_Proposal.json | References WF3's form ID |
| 4 | WF4_Contract_Reminders.json | Standalone, reads Client Tracker |
| 5 | WF5_Post_Signing.json | Last, needs everything else set up |

---

## Placeholders to Replace Before Import

| Placeholder | Where | What to Put |
|-------------|-------|-------------|
| `YOUR_SPREADSHEET_ID` | All workflows | Google Sheet ID |
| `YOUR_CLIENTS_FOLDER_ID` | WF2, WF3 | Root Clients folder in Drive |
| `YOUR_GAMMA_THEME_ID` | WF2 | From Gamma app themes |
| `YOUR_FORM_ID` | WF2 | n8n form URL path from WF3 |
| `YOUR_SIGNWELL_TEMPLATE_ID` | WF3 | SignWell template ID |
| `YOUR_CHECKLIST_TEMPLATE_DOC_ID` | WF5 | Google Doc checklist template |
| `YOUR_CALENDLY_LINK` | WF5 | Kickoff call Calendly link |
