# Veteran Vectors — 8-Step LinkedIn-to-Client Onboarding Pipeline

## Architecture Document v4.0

**Date:** 2026-02-27
**Pipeline:** Prosp.ai LinkedIn Outreach → Notion CRM → Client Onboarding
**Source of Truth:** Notion CRM (Contacts, Projects, Meetings databases)

---

## Pipeline at a Glance

```
STEP 1          STEP 2           STEP 3A/B/C      STEP 4          STEP 5
LI Connection   Loom Video       Response          Discovery       SOW/Contract
Sent/Accepted   Sent via         Handling           Call Held →     Creation →
via Prosp.ai    Prosp.ai         (3 paths)          Notes + AI      Invoicing +
                                                    Proposal        Onboarding Doc

WF_STEP1        WF_STEP2         WF_STEP3A/3C     WF_STEP4        WF_STEP5
Prosp.ai        Prosp.ai         Schedule/Calendly BlueDot         Form/Webhook
webhook         webhook          webhook           webhook         trigger

────────────────────────────────────────────────────────────────────────────────

STEP 6          STEP 7           STEP 8
Contract        Contract         All Calendly
Reminders       Signed →         Calls →
Every Other     Welcome          Notion
Day             Email            CRM Sync

WF_STEP6        WF_STEP7         WF_STEP8
Schedule        SignWell         Calendly
trigger         webhook         webhook
```

---

## Detailed Step Breakdown

### STEP 1: LinkedIn Connection (Prosp.ai → Notion)

**Workflow:** `WF_STEP1_Prosp_LinkedIn_Connection.json`
**Trigger:** Prosp.ai webhook (connection_sent, connection_accepted events)

```
[Prosp.ai Webhook] → [Parse Event Type]
                          │
                    [IF connection_sent]
                      │
                      ▼
                [Create/Update Notion Contact]
                - Name, LinkedIn URL, Company
                - Status: "Connection Sent"
                - Source: "LI Loom Outreach"
                - Tag: from Prosp.ai campaign
                          │
                    [IF connection_accepted]
                      │
                      ▼
                [Update Notion Contact]
                - LI Connection Accepted: ✓
                - Status: "Connection Accepted"
```

**Notion Fields Updated:**
- Name, Email, LinkedIn Profile, Company
- LI Connection Sent: ✓ (checkbox)
- LI Connection Accepted: ✓ (checkbox, on accept)
- Status: "Connection Sent" → "Connection Accepted"
- Source: "LI Loom Outreach"
- Last Contact Date: timestamp

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
**Trigger:** BlueDot webhook (call transcript ready)

```
[BlueDot Webhook] → [Filter: Discovery/Intro call]
        │
  [Match Notion Contact (by email/name)]
        │
  [Create Google Drive Folder (if not exists)]
  [Upload Transcript to Drive]
        │
  [Claude AI: Extract from Transcript]
  - Meeting summary
  - Action items
  - Pain points discussed
  - Budget/timeline mentioned
  - Next steps
        │
  [Update Notion Contact]
  - Status: "Meeting Held"
  - Meeting Notes (rich text)
  - Action Items
  - Drive Folder ID
        │
  [Create Notion Meeting Record]
  - Title, Date, Contact relation
  - Transcript URL, Summary
        │
  [Create Notion Action Items]
  - Linked to Meeting and Contact
        │
  [Generate Preliminary Proposal]
  - Claude AI generates proposal draft
  - Based on transcript + pain points
  - Stored in Google Drive folder
        │
  [Slack Notification]
  - "Discovery call processed for {name}"
  - Link to Notion contact
  - Link to Drive folder
```

---

### STEP 5: SOW/Contract Creation

**Workflow:** `WF_STEP5_SOW_Contract.json`
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
  - Populate all contract fields
  - Terms, scope, timeline, costs
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
  - Link to Client, Project details
        │
  [Create Onboarding Doc (Google Doc)]
  - Template with client info populated
        │
  [Slack: "Contract sent to {name}"]
```

---

### STEP 6: Contract Reminders

**Workflow:** `WF_STEP6_Contract_Reminders.json`
**Trigger:** Schedule (every other day, 9 AM)

```
[Schedule: Every Other Day 9 AM]
        │
  [Query Notion: Status = "Contract Sent"]
  [Filter: Contract Sent Date within last 30 days]
        │
  [For Each Unsigned Contract]
        │
  [Calculate days since Contract Sent Date]
        │
  ┌──────┼──────────────┐
  ▼      ▼              ▼
[< 14d] [14-29d]      [30+ days]
Gentle   Escalation    Auto-expire
reminder email +       Notion: "Declined"
email    Slack alert
        │
  [Update Notion: "Proposal Sent" status]
  [Log reminder date]
```

---

### STEP 7: Post-Signing Onboarding

**Workflow:** `WF_STEP7_Post_Signing.json`
**Trigger:** SignWell webhook (document.completed)

```
[SignWell Webhook: document.completed]
        │
  [Match Notion Contact]
  [Download Signed Contract PDF]
  [Upload to Google Drive]
        │
  [Stripe: Send Invoice (first payment)]
  [Stripe: Resume Retainer Subscription]
        │
  [Send Welcome Email]
  - Standardized template
  - Next steps: onboarding call
  - Calendly link for onboarding
        │
  [Update Notion]
  - Contact: "Project Started"
  - Project: "Active"
        │
  [Create Slack Channel (private)]
  - #client-{company}
  - Post welcome message
        │
  [Slack: "Client fully onboarded!"]
```

---

### STEP 8: Calendly → Notion Sync (All Calls)

**Workflow:** `WF_STEP8_Calendly_Notion_Sync.json`
**Trigger:** Calendly webhook (all event types)

```
[Calendly Webhook: invitee.created / cancelled]
        │
  [Find Notion Contact (by email)]
        │
  [Create/Update Notion Meeting Record]
  - Meeting title
  - Date/time
  - Contact relation
  - Meeting type (discovery/audit/onboarding/check-in)
  - Calendly event URL
        │
  [Update Notion Contact]
  - Last Contact Date: meeting date
  - Attach meeting to contact
```

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
"Project Started" ← "Contract Sent" ← "Proposal Sent" ← "Meeting Held"
     STEP 7              STEP 5           STEP 6            STEP 4
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

| Service | Credential Type | Used In Steps |
|---------|----------------|---------------|
| Prosp.ai API | API Key (webhook + REST) | 1, 2, 3A, 3B |
| Notion | Integration Token | All steps |
| Anthropic Claude | API Key | 4 |
| Calendly | OAuth2 | 3C, 8 |
| Gmail | OAuth2 | 3C, 6, 7 |
| Google Drive | OAuth2 | 4, 5, 7 |
| Google Docs | OAuth2 | 5 |
| BlueDot | Webhook Secret | 4 |
| SignWell | API Key | 5, 7 |
| Stripe | Secret Key | 5, 7 |
| Slack | Bot Token | 4, 5, 7 |

---

## File Manifest

| File | Step | Trigger |
|------|------|---------|
| `WF_STEP1_Prosp_LinkedIn_Connection.json` | 1, 3B | Prosp.ai webhook |
| `WF_STEP2_Loom_Sent.json` | 2 | Prosp.ai webhook |
| `WF_STEP3A_No_Response_Followup.json` | 3A | Daily schedule |
| `WF_STEP3C_Calendly_Screening.json` | 3C | Calendly webhook |
| `WF_STEP4_Meeting_Processing.json` | 4 | BlueDot webhook |
| `WF_STEP5_SOW_Contract.json` | 5 | n8n Form |
| `WF_STEP6_Contract_Reminders.json` | 6 | Every-other-day schedule |
| `WF_STEP7_Post_Signing.json` | 7 | SignWell webhook |
| `WF_STEP8_Calendly_Notion_Sync.json` | 8 | Calendly webhook |

---

## Import Order

| Order | File | Reason |
|-------|------|--------|
| 1 | WF_STEP1_Prosp_LinkedIn_Connection | Entry point, creates contacts |
| 2 | WF_STEP2_Loom_Sent | Tracks Loom delivery |
| 3 | WF_STEP3A_No_Response_Followup | Depends on Loom Sent status |
| 4 | WF_STEP3C_Calendly_Screening | Qualification gate |
| 5 | WF_STEP8_Calendly_Notion_Sync | Universal Calendly sync |
| 6 | WF_STEP4_Meeting_Processing | Post-call processing |
| 7 | WF_STEP5_SOW_Contract | Contract creation |
| 8 | WF_STEP6_Contract_Reminders | Reminder engine |
| 9 | WF_STEP7_Post_Signing | Final onboarding |
