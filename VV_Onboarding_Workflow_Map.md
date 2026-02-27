# Veteran Vectors — Client Pipeline Automation Architecture (v3)

## Complete Workflow Map (Full Pipeline Rebuild)

**Key changes from v2:**
- Notion CRM is now the single source of truth (Google Sheets removed)
- Discovery call + lead qualification added as entry point
- Slack interactive buttons for accept/deny and proposal sending
- Discovery and audit calls are separate workflows
- Retainer subscription created paused, resumed post-signing
- Weekly Thursday check-ins for active clients
- Daily contract reminders (not tiered)

---

## Pipeline at a Glance

```
LEAD BOOKS      QUALIFY     DISCOVERY    AUDIT        PROPOSAL     CONTRACT    REMINDERS   SIGNED      WEEKLY
DISCOVERY  ──►  ACCEPT/ ──► CALL     ──► CALL     ──► REVIEW + ──► + INVOICE ──► DAILY  ──► FULL     ──► THURSDAY
CALL            DENY        PROCESSED   PROCESSED    SEND                              ONBOARD     CHECK-INS

 WF1            WF1B        WF2         WF3          WF3B         WF4         WF5        WF6         WF7
 Calendly       Slack       BlueDot     BlueDot      Slack        n8n Form    Schedule   SignWell     Schedule
 webhook        button      webhook     webhook      button       trigger     trigger    webhook     trigger
```

---

## Workflow 1: Discovery Call Booked + Lead Qualification

**Trigger:** Calendly webhook (invitee.created for Discovery Call)

```
[Calendly Webhook] → [Filter: invitee.created]
                          │
                     [Extract & Qualify Lead]
                     - Parse all Calendly custom questions
                     - Evaluate: revenue, budget, pain points
                     - Generate Prospect_ID
                          │
                     [Create Notion Contact]
                     - All extracted data stored
                          │
                     [IF Qualified?]
                       │           │
                      YES         NO
                       │           │
                       ▼           ▼
              [Slack Notify]  [Slack Interactive]
              "Qualified       Accept/Deny buttons
               lead booked"    with lead details
```

---

## Workflow 1B: Lead Qualification Decision

**Trigger:** Slack button click (Accept or Deny)

```
[Slack Webhook] → [Parse Interaction]
                       │
                  [IF Accept?]
                    │        │
                   YES      NO
                    │        │
                    ▼        ▼
            [Notion:     [Cancel Calendly]
             Discovery        │
             Scheduled]  [Notion: Declined]
                    │        │
                    ▼   [Send Leadmatic Email]
            [Update       (100 Workflows PDF)
             Slack]           │
                         [Update Slack]
```

---

## Workflow 2: Post-Discovery Call Processing

**Trigger:** BlueDot webhook (discovery call transcript)

```
[BlueDot Webhook] → [Filter: "discovery"/"intro" in title]
                          │
                     [Extract BlueDot Data]
                     [Find Notion Contact (by email/name)]
                     [Match to Notion Contact]
                          │
                     [Create Google Drive Folder]
                     [Upload Transcript]
                          │
                     [Claude: Extract meeting notes]
                     - Meeting summary
                     - Action items
                     - Next steps
                     - Needs audit call?
                          │
                     [Update Notion Contact]
                     - Status: "Meeting Held"
                     - Notes, action items
                          │
                     [Create Notion Meeting Record]
                          │
                     [Slack: "Discovery call processed"]
```

---

## Workflow 3: Post-Audit Call + Proposal Generation

**Trigger:** BlueDot webhook (audit call transcript)

```
[BlueDot Webhook] → [Filter: "audit"/"RAPID" in title]
                          │
                     [Match to Notion Contact]
                     [Find/Create Drive Folder]
                          │
                     [Upload Audit Transcript]
                          │
                     [Claude: Generate Full Proposal]
                     - Pain points, solution, tech stack
                     - Workflow breakdown (per automation)
                     - ROI: hours saved, annual value
                     - ROI breakdown per process
                     - Cost estimate, milestones, timeline
                          │
                     [Copy Proposal Template → Populate → PDF]
                     [Upload PDF to Drive]
                          │
                     [Notion: "Proposal Draft"]
                     [Create Meeting Record]
                          │
                     [Slack: proposal details + [Send Proposal] button]
```

---

## Workflow 3B: Proposal Send

**Trigger:** Slack button click ("Send Proposal to Client")

```
[Slack Webhook] → [Parse] → [Export latest PDF (with edits)]
                                    │
                              [Email Proposal to Client]
                                    │
                              [Notion: "Proposal Sent"]
                              [Update Slack message]
```

---

## Workflow 4: Client Onboarding (Contract + Invoice)

**Trigger:** Anthony submits pre-filled n8n form

```
[n8n Form] → [Validate Financial Fields]
                   │
              [Build SignWell Fields] → [Send Contract]
                   │
              [Stripe: Customer] → [Invoice Item] → [Invoice (DRAFT)]
                   │
              [IF Retainer?]
                │         │
               YES       NO
                │         │
           [Price +       │
            Subscription  │
            (PAUSED)]     │
                │         │
                ▼         ▼
         [Notion: "Contract Sent"]
         [Create Notion Project]
         [Slack: "Contract sent"]
```

---

## Workflow 5: Daily Contract & Invoice Reminders

**Trigger:** Daily at 9 AM

```
[Schedule] → [Query Notion: "Contract Sent"]
                   │
              [Calculate days since sent]
              [Check if already reminded today]
                   │
              ┌────┼────────────┐
              ▼    ▼            ▼
         [< 14d] [14+d]      [30+d]
         Daily   Escalation  Auto-expire
         email   email +     Notion: "Declined"
                 Slack alert
              │    │            │
              ▼    ▼            ▼
         [Log reminder in Notion]
```

---

## Workflow 6: Post-Signing Full Onboarding

**Trigger:** SignWell webhook (document.completed)

```
[SignWell Webhook] → [Filter: completed] → [Match Notion Contact]
                                                  │
                          [Stripe: Find customer + draft invoice]
                          [Stripe: SEND invoice (half upfront)]
                          [Stripe: Resume retainer subscription]
                                                  │
                          [Download signed PDF → Upload to Drive]
                                                  │
                          [Create Slack channel (private)]
                          [Post welcome message]
                                                  │
                          [Send welcome email (kickoff link)]
                                                  │
                          [Notion: "Project Started"]
                          [Create Thursday calendar reminder (26 weeks)]
                                                  │
                          [Slack: "Fully onboarded!"]
```

---

## Workflow 7: Weekly Thursday Check-ins

**Trigger:** Every Thursday at 9 AM

```
[Schedule] → [Query Notion: Active Projects]
                   │
              [For each project: Build check-in template]
              - Project status (on track / at risk / blocked)
              - Completed this week
              - In progress
              - Blocked / needs from client
              - Needs from Anthony
              - Next week's priorities
                   │
              [Post templates to #onboarding-alerts]
              [Summary: "X projects need check-ins today"]

              Anthony fills in each template and posts to #client-{company}
```

---

## Architecture Rules

1. **Notion is the CRM and single source of truth.** All status tracking, contact data, and project data lives in Notion.
2. **Google Drive is the document store.** Transcripts, proposals, signed contracts.
3. **Stripe is the payment system.** Invoice created draft in WF4, sent in WF6. Retainer paused in WF4, resumed in WF6.
4. **One-way status flow.** Statuses only move forward.
5. **Manual gates are sacred.** Proposal review (WF3→WF3B) and form submission (WF4) always require Anthony's action.
6. **Fail loud.** Workflows throw errors on unexpected data rather than silently proceeding.
7. **Idempotency.** WF6 skips if already "Project Started". WF5 skips if reminded today.
8. **Credentials in n8n only.** All API keys via n8n credential storage.
