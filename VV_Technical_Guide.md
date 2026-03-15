# Veteran Vectors — Technical Guide

## System Architecture Overview

This document describes the technical architecture of the 8-step LinkedIn-to-Client onboarding pipeline. It covers every service, how they connect, data flow between systems, and the technical decisions behind each choice.

---

## 1. Technology Stack

| Layer | Service | Role | Account Type |
|-------|---------|------|-------------|
| **Outreach Automation** | Prosp.ai | LinkedIn connection requests, messages, follow-up campaigns | Paid plan with webhook support |
| **CRM / Source of Truth** | Notion | Contacts, Projects, Meetings databases | Team or Business plan |
| **LinkedIn Scraping** | Apify | Mass LinkedIn Profile Scraper actor (`2SyF0bVxmgGr8IVCZ`) | Free tier (5 USD/month) or paid |
| **AI Processing** | Anthropic Claude | Loom scripts, meeting notes, proposal drafts, revenue estimation | API access (Sonnet 4.5) |
| **Scheduling** | Calendly | Discovery calls, audit calls, onboarding calls, check-ins | Professional plan (custom questions + webhooks) |
| **Meeting Transcription** | BlueDot AI | Auto-transcription with webhook delivery | Business plan with API webhooks |
| **Source Code & Docs** | GitHub | Client repos (proposals, implementation guides, Skills, transcripts) | Personal account with PAT |
| **E-Signatures** | SignWell | SOW/contract signing with completion webhooks | Business plan |
| **Payments** | Stripe | Invoices (draft → send), retainer subscriptions (paused → active) | Standard account |
| **Document Storage** | Google Drive | Client folders, transcripts, proposals, signed contracts, SOW generation (HTML→Doc→PDF) | Google Workspace |
| **Email** | Gmail (OAuth2) | Approval emails, cancellation emails, reminders, welcome emails | Google Workspace |
| **Notifications** | Slack | #onboarding-alerts channel for pipeline events | Workspace with Bot token |
| **Workflow Engine** | n8n | Orchestrates all 8 steps | Self-hosted or Cloud |
| **Prompt Storage** | Google Sheets | Loom Video Research Prompt (column N, "Prompts" tab) | Existing sheet: `1fe-WP...` |

---

## 2. Notion CRM Schema

### Contacts Database

| Property | Type | Set By | Description |
|----------|------|--------|-------------|
| Name | Title | STEP1 | Full name |
| Email | Email | STEP1/3C | Contact email |
| LinkedIn Profile | URL | STEP1 | LinkedIn profile URL (used for dedup) |
| Company | Rich Text | STEP1/WF0 | Company name |
| Title | Rich Text | STEP1/WF0 | Job title |
| Source | Select | STEP1 | "LI Loom Outreach", "Networking/Podcast", "Warm Outreach/Text" |
| Status | Select | All | Pipeline stage (see lifecycle below) |
| LI Connection Sent | Checkbox | STEP1 | Connection request sent via Prosp.ai |
| LI Connection Accepted | Checkbox | STEP1 | Connection accepted |
| Loom Sent | Checkbox | STEP2 | Loom video sent |
| Responded | Checkbox | STEP1/3C | Contact responded |
| Call Booked | Checkbox | STEP3C | Discovery call booked |
| Audit Call | Checkbox | STEP4B | Audit call completed |
| Invoice Paid | Checkbox | STEP6/Manual | Tracks whether initial invoice has been paid |
| GitHub Repo | Rich Text | STEP4 | Client GitHub repo name (used by STEP4B) |
| Last Contact Date | Date | All | Last interaction timestamp |
| Need to Follow Up Date | Date | STEP3A | Follow-up date |
| Notes | Rich Text | WF0/4 | Research brief, meeting notes |
| Drive Folder ID | Rich Text | STEP4 | Google Drive folder ID for this client |
| Meetings | Relation | STEP4/8 | Links to Meetings database |
| Projects | Relation | STEP5 | Links to Projects database |
| Free or Paid | Select | Manual | "Free" or "Paid" |

### Status Lifecycle (Select Values)

```
"Connection Sent" → "Connection Accepted" → "Research Complete" → "Loom Sent"
     STEP 1              STEP 1                  WF0                STEP 2
                                                                       │
                                                          ┌────────────┤
                                                          ▼            ▼
                                                  "Follow-Up      "Responded"
                                                   Sequence"        STEP 1
                                                   STEP 3A            │
                                                                      ├── "Pending Approval" (3C, low revenue)
                                                                      ▼
                                                              "Meeting Booked"
                                                                  STEP 3C
                                                                      │
"Project Started" ← "Contract Sent" ← "Proposal Sent" ← "Meeting Held"
     STEP 7              STEP 5           STEP 5            STEP 4

Side exits: "Declined" (3C disapprove, STEP6 30-day expire)
```

### Projects Database

| Property | Type | Set By |
|----------|------|--------|
| Project Name | Title | STEP5 |
| Client | Relation | STEP5 |
| Project Status | Select | STEP5→STEP7 ("Contract Sent" → "Active") |
| Project Cost | Number | STEP5 |
| Start Date | Date | STEP5 |
| Retainer | Number | STEP5 |
| Opportunity | Select | Manual |
| Dollars Received | Number | Manual |

### Meetings Database

| Property | Type | Set By |
|----------|------|--------|
| Meeting Title | Title | STEP4/8 |
| Date | Date | STEP4/8 |
| Contact | Relation | STEP4/8 |
| Meeting Category | Select | STEP8 ("Discovery", "Audit", "Onboarding", "Check-In") |
| Meeting Type | Select | STEP8 ("Scheduled", "Cancelled") |
| Attendee Email | Email | STEP8 |
| BlueDot Notes | Rich Text | STEP4 |
| Call Platform | Select | Manual |

---

## 3. Workflow Data Flow

### Prosp.ai Webhook Payload Structure

Prosp.ai sends webhooks for campaign events. The payload structure varies by event type:

```json
{
  "event": "connection_sent | connection_accepted | message_sent | reply_received",
  "prospect": {
    "name": "John Doe",
    "first_name": "John",
    "last_name": "Doe",
    "linkedin_url": "https://www.linkedin.com/in/john-doe/",
    "email": "john@company.com",
    "company": "Acme Corp",
    "title": "CEO"
  },
  "campaign": {
    "name": "Q1 Loom Outreach"
  },
  "message": {
    "content": "Hey John, I made a quick video for you: https://www.loom.com/share/abc123"
  }
}
```

### Apify LinkedIn Scraper Response

Actor `2SyF0bVxmgGr8IVCZ` returns:

```json
{
  "fullName": "John Doe",
  "headline": "CEO at Acme Corp | Veteran | Automation Enthusiast",
  "experiences": [
    {
      "companyName": "Acme Corp",
      "title": "Chief Executive Officer",
      "jobDescription": "Leading a team of 50+ in logistics automation..."
    }
  ],
  "profilePicture": "https://...",
  "location": "San Diego, CA"
}
```

### Priority Scoring Algorithm

| Factor | Points | Criteria |
|--------|--------|----------|
| Employee Count | 0-5 | 50-200=5, 20-49=4, 10-19=3, 200+=3, <10=1 |
| Revenue | 0-5 | $10M+=5, $5-10M=4, $1-5M=3, <$1M=1, Unknown+ICP=2 |
| Title/Seniority | 0-3 | CEO/Founder=3, VP/President=2, Director=1 |
| Industry Fit | 0-3 | Services/ops-heavy=3, manufacturing/retail=2, other=1 |
| Company Maturity | 0-2 | 2-25 years=2, 26-40=1 |
| Loom Script Ready | 0-2 | Full script=2, partial=1 |

**Tier Assignment:**
- Tier 1 (15+): Loom Video Priority
- Tier 2 (11-14): Loom Video
- Tier 3 (7-10): Personalized Text
- Tier 4 (<7): Template Outreach

---

## 4. Credential Architecture

All credentials are stored in n8n's credential manager. Never in workflow JSON files.

| Credential Name | Type | n8n Credential ID | Used In |
|----------------|------|-------------------|---------|
| VV Google Sheets account | Google Sheets OAuth2 | `wi6bAEK3LwBuXnNr` | Loom Research, WF0 |
| VV Google Sheets Trigger account | Google Sheets Trigger OAuth2 | `uIBJOZhW3WjUilpV` | Loom Research (trigger) |
| Apify account | Apify API | `8HrOAzWZHeGNrHbZ` | Loom Research, WF0 |
| VV Claude | Anthropic API | `au1c518sMzUt89ul` | Loom Research, WF0, STEP4 |
| VV - Calendly account | Calendly OAuth2 | `Htykkb3r14siqEFc` | STEP3C, STEP8 |
| VV - Calendly (OAuth2) | OAuth2 Generic | `uFXaP32GB3oPzqwu` | STEP3C (cancellation) |
| VV Gmail account | Gmail OAuth2 | `r13jnGsjwNOqcBvt` | STEP3C, STEP6, STEP7 |
| GitHub account | GitHub API (PAT) | (configure) | STEP4, STEP4B |
| Notion Integration | HTTP Header Auth | (configure) | All STEP workflows |
| Stripe | Stripe API | (configure) | STEP5, STEP7 |
| SignWell | HTTP Header Auth | (configure) | STEP5, STEP7 |
| Slack Bot | Slack OAuth2 | (configure) | Notifications |

---

## 5. Webhook Endpoints

| Webhook Path | Workflow | HTTP Method | Source |
|-------------|----------|-------------|--------|
| `/webhook/prosp-linkedin-events` | STEP1 | POST | Prosp.ai |
| `/webhook/prosp-loom-sent` | STEP2 | POST | Prosp.ai |
| `/webhook/calendly-approval` | STEP3C | GET | Email button clicks |
| `/webhook/bluedot-meeting-processed` | STEP4 | POST | BlueDot |
| `/webhook/signwell-document-completed` | STEP7 | POST | SignWell |
| Calendly native webhook | STEP3C | POST | Calendly |
| Calendly native webhook | STEP8 | POST | Calendly |

**n8n Webhook Base URL format:** `https://your-n8n-instance.com` (or `http://localhost:5678` for local)

---

## 6. Error Handling Strategy

| Error Type | Handling | Notification |
|-----------|----------|-------------|
| Webhook delivery failure | Prosp.ai/Calendly/SignWell retry automatically | n8n execution log |
| Notion API error | `onError: continueErrorOutput` → error collector node | Email to anthony@veteranvectors.io |
| Apify scraper timeout | `retryOnFail: true, maxTries: 3` | Retry with backoff |
| Claude API error | Retry 3x with 5s delay | Slack alert |
| Stripe API error | `onError: continueErrorOutput` | Email alert + Slack |
| SignWell PDF download failure | Check for empty URL before download | Slack alert |

---

## 7. Rate Limits & Throttling

| Service | Rate Limit | Our Approach |
|---------|-----------|-------------|
| Prosp.ai API | 100 requests/minute | Webhook-driven (no polling) |
| Notion API | 3 requests/second | Sequential processing with natural delays |
| Apify | Concurrent actor runs limited by plan | 2s wait between items |
| Claude API | Based on plan tier | Single sequential calls per workflow |
| Calendly | 120 requests/minute | Webhook-driven |
| Stripe | 100 requests/second | Well within limits |
| Google Drive | 1000 requests/100 seconds | Well within limits |

---

## 8. Idempotency Design

| Scenario | Guard | Implementation |
|----------|-------|---------------|
| Duplicate Prosp.ai webhooks | LinkedIn URL uniqueness check | STEP1 queries Notion by LinkedIn URL before creating |
| Duplicate BlueDot transcripts | Status check | STEP4 skips if contact already "Meeting Held" |
| Duplicate SignWell completions | Status check | STEP7 skips if already "Project Started" |
| Duplicate Calendly bookings | Meeting dedup by email + date | STEP8 creates meeting record (acceptable duplicates) |
| Duplicate contract reminders | Last Contact Date check | STEP6 only sends if not already reminded today |
| Duplicate Google Drive folders | Drive Folder ID persistence | STEP4 checks if folder ID exists in Notion first |

---

## 9. Google Sheets Integration (Legacy)

The existing Loom Research Script and WF0 Lead Scoring use Google Sheets as their data source:

**Google Sheet:** `1fe-WP2VK2JD_e6CZw34k5lc5m9T3lYuJEwbkqQz0yKw`

| Tab | Purpose | Key Columns |
|-----|---------|-------------|
| Loom Videos | Lead list for Loom outreach | Name, LI Profile, Script, Done?, Run |
| Prompts | AI prompt templates | Column N: "Loom Video Research Prompt" |

**Data Flow:** Google Sheets is the input source for the existing Loom Research Script. WF0 handles lead scoring and research via a Notion-based path while maintaining backward compatibility with the Google Sheets workflow.

---

## 10. Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    n8n Instance                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Webhook Server (port 5678)                         │  │
│  │  /webhook/prosp-linkedin-events    ← Prosp.ai     │  │
│  │  /webhook/prosp-loom-sent          ← Prosp.ai     │  │
│  │  /webhook/calendly-approval        ← Email clicks  │  │
│  │  /webhook/bluedot-meeting-processed ← BlueDot     │  │
│  │  /webhook/signwell-document-completed ← SignWell  │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌──────────┐      │
│  │ STEP1   │ │ STEP2   │ │ STEP3A  │ │ STEP3C   │      │
│  │ STEP4   │ │ STEP5   │ │ STEP6   │ │ STEP7    │      │
│  │ STEP8   │ │ WF0 Lead│ │         │ │          │      │
│  └─────────┘ └─────────┘ └─────────┘ └──────────┘      │
│                                                          │
│  Credential Store: Notion, Google, Stripe, SignWell...   │
└─────────────────────────────────────────────────────────┘
         │              │              │
         ▼              ▼              ▼
    ┌─────────┐   ┌──────────┐  ┌──────────┐
    │ Notion  │   │ Google   │  │ External │
    │ CRM     │   │ Drive    │  │ APIs     │
    │         │   │          │  │ (Stripe, │
    │ Contacts│   │ Client   │  │ SignWell,│
    │ Projects│   │ Folders  │  │ Apify,   │
    │ Meetings│   │          │  │ Claude)  │
    └─────────┘   └──────────┘  └──────────┘
```
