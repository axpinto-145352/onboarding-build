# Veteran Vectors — Pipeline Flowmap v3

## Full Pipeline: Calendly → Notion CRM → Client Onboarding

```
════════════════════════════════════════════════════════════════════════════════
 WF1: DISCOVERY CALL BOOKED + LEAD QUALIFICATION          Trigger: Calendly
════════════════════════════════════════════════════════════════════════════════

 Calendly webhook → Filter bookings → Extract data + qualify → Create Notion
 Contact → IF qualified → Slack notify | IF not → Slack Accept/Deny buttons

════════════════════════════════════════════════════════════════════════════════
 WF1B: QUALIFICATION DECISION                     Trigger: Slack button click
════════════════════════════════════════════════════════════════════════════════

 Slack button → Parse → IF Accept: Notion "Discovery Scheduled"
                         IF Deny: Cancel Calendly + Send Leadmatic + Notion "Declined"

════════════════════════════════════════════════════════════════════════════════
 WF2: POST-DISCOVERY CALL                             Trigger: BlueDot
════════════════════════════════════════════════════════════════════════════════

 BlueDot webhook → Filter discovery → Match Notion → Create Drive folder →
 Upload transcript → Claude extract notes → Update Notion (Meeting Held) →
 Create Meeting record → Slack notify

════════════════════════════════════════════════════════════════════════════════
 WF3: POST-AUDIT CALL + PROPOSAL                     Trigger: BlueDot
════════════════════════════════════════════════════════════════════════════════

 BlueDot webhook → Filter audit → Match Notion → Find/create Drive folder →
 Upload transcript → Claude generate proposal + ROI → Copy + populate template →
 Export PDF → Upload to Drive → Notion "Proposal Draft" → Create Meeting →
 Slack with [Send Proposal] button

════════════════════════════════════════════════════════════════════════════════
 WF3B: PROPOSAL DELIVERY                          Trigger: Slack button click
════════════════════════════════════════════════════════════════════════════════

 Slack button → Export latest PDF → Email to client → Notion "Proposal Sent" →
 Update Slack message

════════════════════════════════════════════════════════════════════════════════
 WF4: CLIENT ONBOARDING (CONTRACT + INVOICE)          Trigger: n8n Form
════════════════════════════════════════════════════════════════════════════════

 Form submit → Validate → SignWell contract → Stripe customer + invoice (DRAFT) →
 IF retainer: Stripe subscription (PAUSED) → Notion "Contract Sent" →
 Create Notion Project → Slack notify

════════════════════════════════════════════════════════════════════════════════
 WF5: CONTRACT & INVOICE REMINDERS                    Trigger: Daily 9 AM
════════════════════════════════════════════════════════════════════════════════

 Query Notion "Contract Sent" → Calculate days → Daily reminder email →
 14-day Slack escalation → 30-day auto-expire → Log in Notion

════════════════════════════════════════════════════════════════════════════════
 WF6: POST-SIGNING FULL ONBOARDING                   Trigger: SignWell
════════════════════════════════════════════════════════════════════════════════

 SignWell webhook → Match Notion → Stripe send invoice + resume retainer →
 Upload signed PDF → Create Slack channel → Welcome email →
 Notion "Project Started" → Thursday calendar → Slack confirmation

════════════════════════════════════════════════════════════════════════════════
 WF7: WEEKLY THURSDAY CHECK-INS                       Trigger: Thursday 9 AM
════════════════════════════════════════════════════════════════════════════════

 Query Active Projects → Build check-in template per project →
 Post to #onboarding-alerts → Anthony fills in and posts to client channel
```

---

## Gate Chain

```
Calendly     Anthony      BlueDot       Anthony      BlueDot
booking      conducts     processes     books        processes
discovery    discovery    transcript    audit call   transcript
  │            │             │             │             │
  ▼            ▼             ▼             ▼             ▼
┌────┐ GATE ┌──────┐ GATE ┌────┐ GATE ┌──────┐ GATE ┌────┐
│WF1 │─────►│MANUAL│─────►│WF2 │─────►│MANUAL│─────►│WF3 │
│WF1B│      │ CALL │      │    │      │ CALL │      │    │
└────┘      └──────┘      └────┘      └──────┘      └────┘
                                                        │
  Anthony      Anthony      Client        SignWell     Weekly
  reviews      submits      signs         webhook      auto
  proposal     form         contract        │            │
     │            │            │             ▼            ▼
     ▼            ▼            ▼          ┌────┐      ┌────┐
  ┌─────┐ GATE ┌────┐ GATE ┌────┐ GATE  │WF6 │ auto │WF7 │
  │WF3B │─────►│WF4 │─────►│WF5 │──────►│    │─────►│    │
  └─────┘      └────┘      └────┘       └────┘      └────┘
```

---

## Notion CRM Status Lifecycle

```
"Pending Review" → "Discovery Scheduled" → "Meeting Held" → "Proposal Draft"
     WF1              WF1/WF1B                 WF2               WF3
       │
       └─► "Declined" (deny or 30-day expire)

"Proposal Draft" → "Proposal Sent" → "Contract Sent" → "Project Started"
     WF3               WF3B               WF4               WF6
```

---

## Placeholder Reference

| Placeholder | Workflows | What to Put |
|-------------|-----------|-------------|
| `YOUR_NOTION_CONTACTS_DB_ID` | WF1, WF2, WF3, WF5, WF6 | Notion Contacts database ID |
| `YOUR_NOTION_PROJECTS_DB_ID` | WF4, WF6, WF7 | Notion Projects database ID |
| `YOUR_NOTION_MEETINGS_DB_ID` | WF2, WF3 | Notion Meetings database ID |
| `YOUR_CLIENTS_FOLDER_ID` | WF2, WF3, WF6 | Root Clients folder in Google Drive |
| `YOUR_PROPOSAL_TEMPLATE_DOC_ID` | WF3 | Google Doc proposal template ID |
| `YOUR_SIGNWELL_TEMPLATE_ID` | WF4 | SignWell template ID |
| `YOUR_CALENDLY_LINK` | WF6 | Kickoff call Calendly link |
| `YOUR_CALENDLY_PERSONAL_TOKEN` | WF1B | Calendly API token for cancellations |
| Slack Bot Token | WF1, WF1B, WF3, WF3B, WF6 | xoxb- Slack Bot token |
| Stripe Secret Key | WF4, WF6 | sk_live_ Stripe key |
| Anthropic API Key | WF2, WF3 | Claude API key |

---

## Import Order

| Order | File | Reason |
|-------|------|--------|
| 1 | WF1_Discovery_Qualification.json | Entry point, no dependencies |
| 2 | WF1B_Qualification_Decision.json | Handles WF1 buttons |
| 3 | WF2_Discovery_Call_Processing.json | Post-discovery |
| 4 | WF3_Audit_Proposal.json | Post-audit |
| 5 | WF3B_Proposal_Send.json | Handles WF3 button |
| 6 | WF4_Client_Onboarding.json | Contract + invoice |
| 7 | WF5_Reminders.json | Daily reminders |
| 8 | WF6_Post_Signing.json | Full onboarding |
| 9 | WF7_Weekly_Checkins.json | Thursday check-ins |
