# Veteran Vectors — 10-Step LinkedIn-to-Client Onboarding Pipeline

## Architecture Document v4.0

**Date:** 2026-02-27
**Pipeline:** Prosp.ai LinkedIn Outreach → Notion CRM → Client Onboarding
**Source of Truth:** Notion CRM (Contacts, Projects, Meetings databases)

---

## Pipeline at a Glance

```
STEP 1          STEP 2           STEP 3           STEP 4          STEP 5A/B/C
LI Connection   Connection       Loom Research    Loom Video      Response
Sent via        Accepted →       Script →         Sent via        Handling
Prosp.ai        Notion Update    Company Intel    Prosp.ai        (3 paths)
                                 + Priority Score

WF_STEP1        WF_STEP1         WF_STEP3         WF_STEP4        WF_STEP5A/5C
Prosp.ai        Prosp.ai         Apify + Claude   Prosp.ai        Schedule/Calendly
webhook         webhook          + Notion         webhook         webhook

────────────────────────────────────────────────────────────────────────────────

STEP 6          STEP 7           STEP 8           STEP 9          STEP 10
Discovery       SOW/Contract     Contract         Contract        All Calendly
Call Held →     Creation →       Reminders        Signed →        Calls →
Notes + AI      Invoicing +      Every Other      Welcome         Notion
Proposal        Onboarding Doc   Day              Email           CRM Sync

WF_STEP6        WF_STEP7         WF_STEP8         WF_STEP9        WF_STEP10
BlueDot         Form/Webhook     Schedule         SignWell        Calendly
webhook         trigger          trigger          webhook         webhook
```

---

## Detailed Step Breakdown

### STEP 1-2: LinkedIn Connection (Prosp.ai → Notion)

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
                          │
                      ▼
                [Trigger WF_STEP3 (Loom Research)]
                - Pass: Name, LinkedIn URL, Notion Page ID
```

**Notion Fields Updated:**
- Name, Email, LinkedIn Profile, Company
- LI Connection Sent: ✓ (checkbox)
- LI Connection Accepted: ✓ (checkbox, on accept)
- Status: "Connection Sent" → "Connection Accepted"
- Source: "LI Loom Outreach"
- Last Contact Date: timestamp

---

### STEP 3: Loom Research Script (Research + Priority Score)

**Workflow:** `WF_STEP3_Loom_Research.json`
**Trigger:** Webhook from WF_STEP1 (connection accepted) OR manual trigger

```
[Webhook/Manual Trigger] → [Get Contact from Notion]
                                │
                          [Apify LinkedIn Scraper]
                          - Pull: Full name, headline, experience
                          - Pull: Company name, description
                                │
                          [Apollo.io Enrichment]
                          - Employee count
                          - Annual revenue
                          - Industry
                          - Company website
                          - Founded year
                                │
                          [Claude AI: Generate Research Brief]
                          - Priority Score (1-20)
                          - Loom video script/talking points
                          - Key pain points to address
                          - Personalization hooks
                                │
                          [Update Notion Contact]
                          - Employee Count, Revenue, Title
                          - Industry, Company Website
                          - Priority Score (number property)
                          - Loom Script (rich text)
                          - Status: "Research Complete"
```

**Priority Scoring (max 20 pts):**
- Employee Count (0-5 pts): 50-200 = 5, 20-49 = 4, 10-19 = 3
- Revenue (0-5 pts): $10M+ = 5, $5-10M = 4, $1-5M = 3
- Title/Seniority (0-3 pts): CEO/Founder = 3, VP = 2, Director = 1
- Industry Fit (0-3 pts): Services/ops-heavy = 3, manufacturing/retail = 2
- Company Maturity (0-2 pts): 2-25 years = 2
- Loom Script Quality (0-2 pts): Based on research completeness

---

### STEP 4: Loom Video Sent (Prosp.ai → Notion)

**Workflow:** `WF_STEP4_Loom_Sent.json`
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

### STEP 5A: No Response Follow-Up (3-Day Timer)

**Workflow:** `WF_STEP5A_No_Response_Followup.json`
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
             - Moved to group: "5 Bravo"
             - Need to Follow Up Date: today
```

**Follow-Up Campaign (3 messages in Prosp.ai):**
1. Day 4: "Hey {name}, did you get a chance to watch the video?"
2. Day 7: Value-add follow-up with case study
3. Day 10: Final touch — soft close or resource share

---

### STEP 5B: Response Received

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

### STEP 5C: Calendly Discovery Call Screening

**Workflow:** `WF_STEP5C_Calendly_Screening.json`
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

### STEP 6: Post-Discovery Call Processing

**Workflow:** `WF_STEP6_Meeting_Processing.json`
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

### STEP 7: SOW/Contract Creation

**Workflow:** `WF_STEP7_SOW_Contract.json`
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

### STEP 8: Contract Reminders

**Workflow:** `WF_STEP8_Contract_Reminders.json`
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

### STEP 9: Post-Signing Onboarding

**Workflow:** `WF_STEP9_Post_Signing.json`
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

### STEP 10: Calendly → Notion Sync (All Calls)

**Workflow:** `WF_STEP10_Calendly_Notion_Sync.json`
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
"Connection Sent" → "Connection Accepted" → "Research Complete" → "Loom Sent"
     STEP 1              STEP 2                  STEP 3              STEP 4
                                                                       │
                                                            ┌──────────┤
                                                            ▼          ▼
                                                    "Follow-Up    "Responded"
                                                     Sequence"      STEP 5B
                                                     STEP 5A          │
                                                                      ▼
                                                              "Meeting Booked"
                                                                  STEP 5C
                                                                      │
"Project Started" ← "Contract Sent" ← "Proposal Sent" ← "Meeting Held"
     STEP 9              STEP 7           STEP 8            STEP 6
                                                                │
                                                          "Proposal Draft"
                                                              STEP 6

Side exits: "Declined" (at any qualification/approval gate)
```

---

## Prosp.ai Webhook Events Reference

| Event | Workflow | Action |
|-------|----------|--------|
| `connection_sent` | WF_STEP1 | Create Notion contact, Status: "Connection Sent" |
| `connection_accepted` | WF_STEP1 | Update Notion, trigger WF_STEP3 research |
| `message_sent` (with Loom) | WF_STEP4 | Update Notion, Loom Sent: true |
| `reply_received` | WF_STEP1 | Update Notion, Status: "Responded" |

---

## Credential Requirements

| Service | Credential Type | Used In Steps |
|---------|----------------|---------------|
| Prosp.ai API | API Key (webhook + REST) | 1, 2, 4, 5A, 5B |
| Notion | Integration Token | All steps |
| Apify | API Token | 3 |
| Apollo.io | API Key | 3 |
| Anthropic Claude | API Key | 3, 6 |
| Calendly | OAuth2 | 5C, 10 |
| Gmail | OAuth2 | 5C, 8, 9 |
| Google Drive | OAuth2 | 6, 7, 9 |
| Google Docs | OAuth2 | 7 |
| BlueDot | Webhook Secret | 6 |
| SignWell | API Key | 7, 9 |
| Stripe | Secret Key | 7, 9 |
| Slack | Bot Token | 6, 7, 9 |

---

## File Manifest

| File | Step | Trigger |
|------|------|---------|
| `WF_STEP1_Prosp_LinkedIn_Connection.json` | 1, 2, 5B | Prosp.ai webhook |
| `WF_STEP3_Loom_Research.json` | 3 | Webhook (from STEP1) + Manual |
| `WF_STEP4_Loom_Sent.json` | 4 | Prosp.ai webhook |
| `WF_STEP5A_No_Response_Followup.json` | 5A | Daily schedule |
| `WF_STEP5C_Calendly_Screening.json` | 5C | Calendly webhook |
| `WF_STEP6_Meeting_Processing.json` | 6 | BlueDot webhook |
| `WF_STEP7_SOW_Contract.json` | 7 | n8n Form |
| `WF_STEP8_Contract_Reminders.json` | 8 | Every-other-day schedule |
| `WF_STEP9_Post_Signing.json` | 9 | SignWell webhook |
| `WF_STEP10_Calendly_Notion_Sync.json` | 10 | Calendly webhook |

---

## Import Order

| Order | File | Reason |
|-------|------|--------|
| 1 | WF_STEP1_Prosp_LinkedIn_Connection | Entry point, creates contacts |
| 2 | WF_STEP3_Loom_Research | Triggered by Step 1 |
| 3 | WF_STEP4_Loom_Sent | Tracks Loom delivery |
| 4 | WF_STEP5A_No_Response_Followup | Depends on Loom Sent status |
| 5 | WF_STEP5C_Calendly_Screening | Qualification gate |
| 6 | WF_STEP10_Calendly_Notion_Sync | Universal Calendly sync |
| 7 | WF_STEP6_Meeting_Processing | Post-call processing |
| 8 | WF_STEP7_SOW_Contract | Contract creation |
| 9 | WF_STEP8_Contract_Reminders | Reminder engine |
| 10 | WF_STEP9_Post_Signing | Final onboarding |
