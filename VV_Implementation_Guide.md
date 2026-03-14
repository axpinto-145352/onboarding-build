# Veteran Vectors — Step-by-Step Implementation Guide

## How to Set Up the Complete 8-Step Pipeline

This guide walks you through setting up every workflow, from creating accounts to testing the full pipeline end-to-end.

---

## Prerequisites Checklist

Before you start, make sure you have accounts and access to:

- [ ] **n8n** — Self-hosted instance or n8n Cloud (with webhook URL accessible from the internet)
- [ ] **Notion** — Workspace with Contacts, Projects, and Meetings databases
- [ ] **Prosp.ai** — Account with webhook support and API access
- [ ] **Calendly** — Professional plan (custom questions + webhook support)
- [ ] **Google Workspace** — Gmail, Drive, Sheets (with OAuth2 app configured)
- [ ] **Apify** — Account with LinkedIn scraper actor access
- [ ] **Anthropic** — Claude API key
- [ ] **Stripe** — Account for invoicing and subscriptions
- [ ] **SignWell** — Account for e-signatures
- [ ] **BlueDot AI** — Account with webhook delivery
- [ ] **Slack** — Workspace with #onboarding-alerts channel and Bot token
- [ ] **PDFco** — Account for PDF form filling

---

## Phase 1: Notion CRM Setup

### Step 1.1: Create the Contacts Database

If you don't already have one, create a new Notion database with these properties:

| Property Name | Property Type | Options |
|--------------|--------------|---------|
| Name | Title | — |
| Email | Email | — |
| LinkedIn Profile | URL | — |
| Company | Rich Text | — |
| Title | Rich Text | — |
| Source | Select | LI Loom Outreach, Networking/Podcast, Warm Outreach/Text |
| Status | Select | Connection Sent, Connection Accepted, Research Complete, Loom Sent, Follow-Up Sequence, Responded, Pending Approval, Meeting Booked, Meeting Held, Proposal Draft, Proposal Sent, Contract Sent, Project Started, Declined |
| LI Connection Sent | Checkbox | — |
| LI Connection Accepted | Checkbox | — |
| Loom Sent | Checkbox | — |
| Responded | Checkbox | — |
| Call Booked | Checkbox | — |
| Audit Call | Checkbox | — |
| Invoice Paid | Checkbox | — |
| GitHub Repo | Rich Text | — |
| Last Contact Date | Date | — |
| Need to Follow Up Date | Date | — |
| Notes | Rich Text | — |
| Drive Folder ID | Rich Text | — |
| Free or Paid | Select | Free, Paid |
| Meetings | Relation | → Meetings database |
| Projects | Relation | → Projects database |

**Get your database ID:** Open the database in Notion, look at the URL:
```
https://www.notion.so/YOUR_WORKSPACE/DATABASE_ID?v=...
```
The DATABASE_ID is the 32-character hex string. Copy it — you'll need it for every workflow.

### Step 1.2: Create the Projects Database

| Property Name | Property Type | Options |
|--------------|--------------|---------|
| Project Name | Title | — |
| Client | Relation | → Contacts database |
| Project Status | Select | Contract Sent, Active, Completed, Need Follow Up |
| Project Cost | Number | Currency (USD) |
| Retainer | Number | Currency (USD) |
| Start Date | Date | — |
| Opportunity | Select | Yes, Maybe, No |
| Dollars Received | Number | Currency (USD) |
| Audit Call Cost | Number | Currency (USD) |
| Months into Retainer | Number | — |
| Free or Paid | Select | Free, Paid |

### Step 1.3: Create the Meetings Database

| Property Name | Property Type | Options |
|--------------|--------------|---------|
| Meeting Title | Title | — |
| Date | Date | — |
| Contact | Relation | → Contacts database |
| Meeting Category | Select | Discovery, Audit, Onboarding, Check-In, Other |
| Meeting Type | Select | Scheduled, Cancelled, Completed |
| Attendee Email | Email | — |
| BlueDot Notes | Rich Text | — |
| Call Platform | Select | Calendly, Zoom, Google Meet |

### Step 1.4: Create the Notion Integration

1. Go to [https://www.notion.so/my-integrations](https://www.notion.so/my-integrations)
2. Click **New integration**
3. Name it "VV Pipeline Automation"
4. Select your workspace
5. Under **Capabilities**, enable: Read content, Update content, Insert content
6. Copy the **Internal Integration Token** (starts with `ntn_`)
7. **Share your databases:** Open each database (Contacts, Projects, Meetings), click "..." → "Connections" → Add your integration

---

## Phase 2: n8n Credential Setup

### Step 2.1: Notion Credentials

1. In n8n, go to **Credentials** → **New Credential**
2. Search for "Header Auth"
3. Name: `Notion Integration`
4. Header Name: `Authorization`
5. Header Value: `Bearer ntn_YOUR_INTEGRATION_TOKEN`

### Step 2.2: Google OAuth2 Credentials

Your existing credentials are already configured:
- **VV Google Sheets account** (ID: `wi6bAEK3LwBuXnNr`) — for Sheets read/write
- **VV Google Sheets Trigger account** (ID: `uIBJOZhW3WjUilpV`) — for polling triggers
- **VV Gmail account** (ID: `r13jnGsjwNOqcBvt`) — for sending emails

If you need new ones:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth2 credentials (Web Application type)
3. Add n8n redirect URL: `https://your-n8n-instance.com/rest/oauth2-credential/callback`
4. Enable APIs: Google Sheets, Gmail, Google Drive, Google Docs

### Step 2.3: Apify Credentials

Already configured:
- **Apify account** (ID: `8HrOAzWZHeGNrHbZ`)

### Step 2.4: Anthropic Claude Credentials

Already configured:
- **VV Claude** (ID: `au1c518sMzUt89ul`)

### Step 2.5: Calendly Credentials

Already configured:
- **VV - Calendly account** (ID: `Htykkb3r14siqEFc`) — OAuth2 trigger
- **VV - Calendly** (ID: `uFXaP32GB3oPzqwu`) — OAuth2 for API calls (cancellation)

### Step 2.6: Prosp.ai Credentials

1. Log into Prosp.ai → Settings → API
2. Copy your API key
3. In n8n: New Credential → Header Auth
4. Name: `Prosp.ai API`
5. Header Name: `Authorization`
6. Header Value: `Bearer YOUR_PROSP_API_KEY`

### Step 2.7: Stripe Credentials

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
2. Copy your Secret key (starts with `sk_live_`)
3. In n8n: New Credential → Stripe API
4. Secret Key: `sk_live_YOUR_KEY`

### Step 2.8: SignWell Credentials

1. Go to SignWell → Settings → API
2. Copy your API key
3. In n8n: New Credential → Header Auth
4. Name: `SignWell API`
5. Header Name: `X-Api-Key`
6. Header Value: `YOUR_SIGNWELL_API_KEY`

### Step 2.9: Slack Bot Credentials

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Create or select your app
3. OAuth & Permissions → Bot Token Scopes: `chat:write`, `channels:manage`, `groups:write`
4. Install to workspace, copy Bot Token (`xoxb-...`)
5. In n8n: New Credential → Slack OAuth2 API or Header Auth

### Step 2.10: GitHub Personal Access Token

1. Go to [GitHub Settings → Developer Settings → Personal Access Tokens → Fine-grained tokens](https://github.com/settings/tokens?type=beta)
2. Create a new token with:
   - **Repository access:** All repositories (or select specific ones)
   - **Permissions:** Repository: Contents (Read and Write), Administration (Read and Write — needed for repo creation)
3. Copy the token
4. In n8n: New Credential → GitHub API
5. Name: `GitHub account`
6. Access Token: paste your token

**Template Repo Setup:** Create a GitHub template repository named `vv-client-template` containing:
- `Skills/proposal SKILL.md`
- `Skills/agent SKILL.md`
- `Skills/smb SKILL.md`
- `Skills/doc polish SKILL.md`
- `Skills/ai check SKILL.md`
- `Skills/13 agents SKILL.md`
- `Skills/template-structure.md`
- `Skills/pdf-generation.md`
- `README.md`
- Mark it as a template in GitHub repo Settings

---

## Phase 3: Placeholder Replacement

Before importing any workflow, replace these placeholders in the JSON files:

### Global Replacements (all WF_STEP files)

| Find | Replace With | Where to Get It |
|------|-------------|----------------|
| `YOUR_NOTION_CONTACTS_DB_ID` | Your Contacts database ID (32-char hex) | Notion URL of Contacts DB |
| `YOUR_NOTION_PROJECTS_DB_ID` | Your Projects database ID | Notion URL of Projects DB |
| `YOUR_NOTION_MEETINGS_DB_ID` | Your Meetings database ID | Notion URL of Meetings DB |
| `YOUR_N8N_WEBHOOK_BASE_URL` | Your n8n instance URL (e.g., `https://n8n.yourdomain.com`) | Your n8n deployment |
| `YOUR_CLIENTS_FOLDER_ID` | Root "Clients" folder ID in Google Drive | Google Drive → right-click folder → Share → copy ID from URL |
| `YOUR_SIGNWELL_API_KEY` | Your SignWell API key | SignWell Settings |
| `YOUR_ANTHROPIC_API_KEY` | Your Claude API key | Anthropic Console |
| `YOUR_FOLLOWUP_CAMPAIGN_ID` | Prosp.ai follow-up campaign ID | Prosp.ai campaign settings |
| `YOUR_SOW_TEMPLATE_FILE_ID` | Google Drive file ID for SOW PDF template | Google Drive URL |
| `prod_YOUR_RETAINER_PRODUCT_ID` | Stripe Product ID for retainer services | Stripe Dashboard → Products |
| `YOUR_GITHUB_USERNAME` | Your GitHub username | GitHub profile |
| `YOUR_GITHUB_CRED_ID` | n8n GitHub credential ID | n8n Credentials page |
| `YOUR_AUDIT_CALENDLY_LINK` | Calendly audit call booking link | Calendly event type URL |

### Quick Replace Command

You can use this bash command to do all replacements at once:

```bash
# Run from the onboarding-build directory
for f in WF_STEP*.json; do
  sed -i 's/YOUR_NOTION_CONTACTS_DB_ID/PASTE_REAL_ID_HERE/g' "$f"
  sed -i 's/YOUR_NOTION_PROJECTS_DB_ID/PASTE_REAL_ID_HERE/g' "$f"
  sed -i 's/YOUR_NOTION_MEETINGS_DB_ID/PASTE_REAL_ID_HERE/g' "$f"
  sed -i 's|YOUR_N8N_WEBHOOK_BASE_URL|https://your-n8n.com|g' "$f"
  sed -i 's/YOUR_CLIENTS_FOLDER_ID/PASTE_REAL_ID_HERE/g' "$f"
  sed -i 's/YOUR_SIGNWELL_API_KEY/PASTE_REAL_KEY_HERE/g' "$f"
  sed -i 's/YOUR_ANTHROPIC_API_KEY/PASTE_REAL_KEY_HERE/g' "$f"
  sed -i 's/YOUR_FOLLOWUP_CAMPAIGN_ID/PASTE_REAL_ID_HERE/g' "$f"
  sed -i 's/YOUR_SOW_TEMPLATE_FILE_ID/PASTE_REAL_ID_HERE/g' "$f"
  sed -i 's/prod_YOUR_RETAINER_PRODUCT_ID/prod_PASTE_REAL_ID_HERE/g' "$f"
done
```

---

## Phase 4: Import Workflows (In Order)

### Step 4.1: Import STEP1 — LinkedIn Connection Tracking

1. In n8n: **Workflows** → **Import from File** → Select `WF_STEP1_Prosp_LinkedIn_Connection.json`
2. After import, open the workflow
3. For each HTTP Request node that uses Notion:
   - Click the node → Under **Authentication**, select your "Notion Integration" credential
4. Click **Save**
5. Click **Activate** (toggle to active)
6. Copy the webhook URL shown on the "Prosp.ai Webhook" node
7. **In Prosp.ai:** Go to your campaign → Settings → Webhooks → paste the n8n webhook URL

**Test it:** Create a test connection request in Prosp.ai. Check that:
- A new contact appears in Notion with Status = "Connection Sent"
- LI Connection Sent checkbox is checked

### Step 4.2: Import STEP2 — Loom Sent Tracking

1. Import `WF_STEP2_Loom_Sent.json`
2. Assign Notion credentials to HTTP Request nodes
3. Save and Activate
4. Copy webhook URL → Add to Prosp.ai webhook settings (message_sent events)

**Test it:** Send a message containing a loom.com link via Prosp.ai. Check Notion updates.

### Step 4.3: Import STEP3A — No-Response Follow-Up

1. Import `WF_STEP3A_No_Response_Followup.json`
2. Assign credentials:
   - Notion HTTP nodes → "Notion Integration"
   - Prosp.ai HTTP node → "Prosp.ai API"
3. Save and Activate
4. In Prosp.ai: Create a follow-up campaign with 3 messages (see messaging guide below)
5. Replace `YOUR_FOLLOWUP_CAMPAIGN_ID` in the workflow with the actual campaign ID

**Test it:** Manually create a Notion contact with Status = "Loom Sent" and Last Contact Date = 4 days ago. Wait for the 9 AM trigger or test manually.

### Step 4.4: Import STEP3C — Calendly Screening

1. Import `WF_STEP3C_Calendly_Screening.json`
2. Assign credentials:
   - Calendly Trigger → "VV - Calendly account"
   - Gmail nodes → "VV Gmail account"
   - Calendly cancel → "VV - Calendly" (OAuth2)
   - Notion HTTP nodes → "Notion Integration"
3. Save and Activate
4. **Set up Calendly custom questions** on your Discovery Call event type:
   - "What is your company's monthly revenue?" (Multiple choice: Under $5K, $5K-$25K, $25K-$100K, $100K-$500K, $500K+)
   - "How many employees does your company have?" (Text)
   - "What's your company name?" (Text)
   - "Are you the decision maker?" (Multiple choice: Yes, No)
   - "What's your biggest business challenge right now?" (Text)
   - "Do you have a budget allocated for automation?" (Multiple choice: Yes, exploring, No)

**Test it:** Book a test discovery call with revenue "Under $5K". Check that you receive an approval email.

### Step 4.5: Import STEP4 — Meeting Processing

1. Import `WF_STEP4_Meeting_Processing.json`
2. Assign credentials:
   - Notion HTTP nodes → "Notion Integration"
   - Google Drive nodes → Google Drive OAuth2
   - Claude HTTP node → Use existing "VV Claude" or set up HTTP Header Auth with `x-api-key`
3. Save and Activate
4. **In BlueDot:** Go to Settings → Webhooks → Add webhook URL from STEP4

**Test it:** Hold a short test call with BlueDot recording. When transcript is ready, check:
- Google Drive folder created
- Notion contact updated to "Meeting Held"
- Meeting record created in Notion

### Step 4.5b: Import STEP4B — Audit Call Processing

1. Import `WF_STEP4B_Audit_Call_Processing.json`
2. Assign credentials:
   - Notion nodes → Notion account
   - Google Drive → Google Drive OAuth2
   - GitHub nodes → GitHub account
   - Claude AI → VV Claude
3. Save and Activate

**Test it:** After running STEP4 for a client (which creates a GitHub repo), paste an audit call transcript in the STEP4B form. Enter the GitHub repo name from STEP4. Check:
- Audit transcript uploaded to Drive and GitHub
- Proposal and implementation guide updated (overwritten) in GitHub
- Meeting record created with Category = "Audit"

### Step 4.6: Import STEP5 — SOW/Contract Creation

1. Import `WF_STEP5_SOW_Contract.json`
2. Assign credentials:
   - Google Drive → OAuth2
   - PDFco → PDFco API credential
   - SignWell → "SignWell API"
   - Stripe → Stripe API
   - Notion → "Notion Integration"
3. **Prepare your SOW PDF template:**
   - Upload your SOW template to Google Drive
   - Make sure it has fillable form fields matching the field names in the PDFco node
   - Copy the file ID from the Drive URL
4. **Create a Stripe Product:**
   - Stripe Dashboard → Products → Create → "Veteran Vectors Retainer"
   - Copy the `prod_xxx` Product ID
5. Save and Activate

**Test it:** Access the form URL (shown in n8n after activation). Fill out test data and submit.

### Step 4.7: Import STEP6 — Contract & Invoice Reminders

1. Import `WF_STEP6_Contract_Reminders.json`
2. Assign Notion and Gmail credentials to all nodes
3. **Important:** Add `Invoice Paid` checkbox property to your Notion Contacts database (required for invoice reminder branch)
4. Save and Activate

**Reminder schedule:** Daily for first 7 days, then every 3 days. Auto-expires at 30 days.

**Test it:**
- Contract reminders: Create a test contact with Status = "Contract Sent" and Last Contact Date = yesterday
- Invoice reminders: Create a test contact with Status = "Project Started" and Invoice Paid = unchecked

### Step 4.8: Import STEP7 — Post-Signing Onboarding

1. Import `WF_STEP7_Post_Signing.json`
2. Assign credentials:
   - Notion → "Notion Integration"
   - Google Drive → OAuth2
   - Gmail → "VV Gmail account"
   - Stripe → Stripe API
3. Save and Activate
4. **In SignWell:** Go to Settings → Webhooks → Add webhook URL from STEP7

**Test it:** Sign a test contract in SignWell. Check:
- Signed PDF uploaded to Google Drive
- Welcome email sent
- Notion contact updated to "Project Started"
- Notion project updated to "Active"

### Step 4.9: Import STEP8 — Calendly-Notion Sync

1. Import `WF_STEP8_Calendly_Notion_Sync.json`
2. Assign Calendly and Notion credentials
3. Save and Activate

**Test it:** Book any Calendly call. Check that a Meeting record appears in Notion linked to the contact.

---

## Phase 5: Prosp.ai Campaign Setup

### Main Outreach Campaign

Set up your main LinkedIn outreach campaign with these webhook triggers:

1. Go to Prosp.ai → Campaigns → Your outreach campaign
2. Settings → Webhooks:
   - **Connection Sent:** `https://your-n8n.com/webhook/prosp-linkedin-events`
   - **Connection Accepted:** `https://your-n8n.com/webhook/prosp-linkedin-events`
   - **Message Sent:** `https://your-n8n.com/webhook/prosp-loom-sent`
   - **Reply Received:** `https://your-n8n.com/webhook/prosp-linkedin-events`

### Follow-Up Campaign (3 Messages)

Create a new campaign in Prosp.ai for the 3-day no-response follow-up:

**Message 1 (Day 4 after Loom):**
```
Hey {first_name}, just wanted to check — did you get a chance to watch that quick video I sent over? I put together some specific ideas for {company} that I think could save you serious time.
```

**Message 2 (Day 7):**
```
{first_name} — I wanted to share a quick case study. We helped a similar company automate their [relevant process] and saved them 20+ hours/week. Would love to show you what that could look like for {company}. Worth a quick chat?
```

**Message 3 (Day 10):**
```
Last one from me, {first_name}. I put together a free guide on automation best practices that I think would be valuable regardless — here's the link: [guide URL]. If you ever want to explore what's possible, I'm always around.
```

Copy the campaign ID and use it in STEP3A's `YOUR_FOLLOWUP_CAMPAIGN_ID` placeholder.

---

## Phase 6: Calendly Setup

### Discovery Call Event Type

1. Go to Calendly → Event Types → Create New
2. Name: "Veteran Vectors Discovery Call"
3. Duration: 30 minutes
4. Add custom questions (see Step 4.4 above)
5. Under **Notifications**, add the webhook URL from STEP3C
6. Under **Integrations**, connect your Calendly to the n8n Calendly trigger

### Onboarding Call Event Type

1. Create another event type: "Veteran Vectors Onboarding"
2. Duration: 45 minutes
3. This URL goes in the welcome email template in STEP7

---

## Phase 7: End-to-End Testing

### Test the Full Pipeline

1. **STEP 1:** Add a test prospect in Prosp.ai → verify Notion contact created
2. **STEP 2:** Send a Loom message via Prosp.ai → verify "Loom Sent" in Notion
3. **STEP 3A:** Wait 3 days (or manually backdate) → verify follow-up triggers
4. **STEP 3C:** Book a discovery call on Calendly:
   - With revenue < $5K → verify approval email received → test approve and disapprove
   - With revenue > $5K → verify auto-qualified in Notion
5. **STEP 4:** Hold a discovery call with BlueDot → verify transcript processed, Drive folder created
6. **STEP 5:** Submit the SOW form → verify contract sent via SignWell
7. **STEP 6:** Wait for reminder schedule → verify emails sent
8. **STEP 7:** Sign the test contract → verify welcome email and Notion updates
9. **STEP 8:** Book any call → verify Notion meeting record created

### Monitoring

- **n8n Execution Log:** Check for failed executions daily
- **Slack #onboarding-alerts:** Monitor for pipeline notifications
- **Notion CRM:** Verify contacts move through statuses correctly

---

## Phase 8: Go Live Checklist

- [ ] All placeholders replaced in all WF_STEP*.json files
- [ ] All credentials configured and tested in n8n
- [ ] All Notion databases created with correct property names
- [ ] Prosp.ai webhooks pointing to n8n
- [ ] Calendly webhooks pointing to n8n
- [ ] BlueDot webhook pointing to n8n
- [ ] SignWell webhook pointing to n8n
- [ ] SOW PDF template uploaded with fillable fields
- [ ] Stripe product created for retainer
- [ ] Google Drive "Clients" root folder created
- [ ] Slack #onboarding-alerts channel exists
- [ ] All 8 workflows activated in n8n
- [ ] End-to-end test completed successfully
- [ ] Error notification email (anthony@veteranvectors.io) receiving test alerts

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Webhook not firing | n8n URL not accessible | Ensure n8n is publicly accessible (use tunnel for local) |
| Notion "property not found" | Property name mismatch | Check exact spelling + capitalization in Notion vs workflow |
| "Cannot read property" in Code node | Upstream node failed silently | Check if previous node has `onError: continueErrorOutput` |
| Duplicate contacts | No dedup check | STEP1 checks LinkedIn URL; ensure URL is consistent |
| SignWell PDF not downloading | URL expired or empty | Check for empty URL in webhook payload |
| Calendly trigger not working | OAuth2 token expired | Re-authorize Calendly in n8n credentials |
| Stripe subscription failed | Missing product ID | Verify `prod_` ID matches your Stripe product |
