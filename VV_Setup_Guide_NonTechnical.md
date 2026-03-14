# Veteran Vectors — Service Setup Guide

A plain-English, step-by-step guide to setting up Notion, BlueDot, Prosp.ai, and Calendly so your automation workflows work correctly.

---

## 1. NOTION SETUP

### 1A. Create Your Notion Integration (gives the automations permission to read/write)

1. Open your browser and go to **notion.so/my-integrations**
2. Click **"New integration"**
3. Name it **"VV Pipeline Automation"**
4. Select your workspace from the dropdown
5. Under Capabilities, make sure these are checked:
   - Read content
   - Update content
   - Insert content
6. Click **Submit**
7. You'll see an **Internal Integration Token** that starts with `ntn_` — copy it and save it somewhere safe (you'll paste it into n8n later)

### 1B. Create the Three Databases

You need three databases in Notion. Create them as full-page databases (not inline).

**DATABASE 1: Contacts**

Create a new page, choose "Database - Full page", name it **"Contacts"**. Add these columns:

| Column Name | Type | Notes |
|------------|------|-------|
| Name | Title | This is the default first column |
| Email | Email | |
| LinkedIn Profile | URL | |
| Company | Text | |
| Title | Text | Job title |
| Source | Select | Add options: "LI Loom Outreach", "Networking/Podcast", "Warm Outreach/Text" |
| Status | Select | Add options: "Connection Sent", "Connection Accepted", "Research Complete", "Loom Sent", "Follow-Up Sequence", "Responded", "Pending Approval", "Meeting Booked", "Meeting Held", "Proposal Draft", "Proposal Sent", "Contract Sent", "Project Started", "Declined" |
| LI Connection Sent | Checkbox | |
| LI Connection Accepted | Checkbox | |
| Loom Sent | Checkbox | |
| Responded | Checkbox | |
| Call Booked | Checkbox | |
| Audit Call | Checkbox | |
| Invoice Paid | Checkbox | |
| GitHub Repo | Text | |
| Last Contact Date | Date | |
| Need to Follow Up Date | Date | |
| Notes | Text | |
| Drive Folder ID | Text | |
| Free or Paid | Select | Add options: "Free", "Paid" |

**DATABASE 2: Projects**

Create another full-page database called **"Projects"**:

| Column Name | Type | Notes |
|------------|------|-------|
| Project Name | Title | Default first column |
| Client | Relation | Link to your Contacts database |
| Project Status | Select | Add options: "Contract Sent", "Active", "Completed", "Need Follow Up" |
| Project Cost | Number | Format as currency (USD) |
| Retainer | Number | Format as currency (USD) |
| Start Date | Date | |
| Opportunity | Select | Add options: "Yes", "Maybe", "No" |
| Dollars Received | Number | Format as currency (USD) |
| Audit Call Cost | Number | Format as currency (USD) |
| Months into Retainer | Number | |
| Free or Paid | Select | Add options: "Free", "Paid" |

**DATABASE 3: Meetings**

Create another full-page database called **"Meetings"**:

| Column Name | Type | Notes |
|------------|------|-------|
| Meeting Title | Title | Default first column |
| Date | Date | |
| Contact | Relation | Link to your Contacts database |
| Meeting Category | Select | Add options: "Discovery", "Audit", "Onboarding", "Check-In", "Other" |
| Meeting Type | Select | Add options: "Scheduled", "Cancelled", "Completed" |
| Attendee Email | Email | |
| BlueDot Notes | Text | |
| Call Platform | Select | Add options: "Calendly", "Zoom", "Google Meet" |

### 1C. Connect the Integration to Your Databases

This step is easy to forget but critical — without it, the automation can't access your data.

1. Open your **Contacts** database
2. Click the **"..."** menu in the top-right corner
3. Click **"Connections"**
4. Search for **"VV Pipeline Automation"** (the integration you created)
5. Click it to connect
6. **Repeat this for the Projects and Meetings databases**

### 1D. Copy Your Database IDs

For each database, you need the ID from the URL:

1. Open a database in your browser
2. Look at the URL — it looks like: `https://www.notion.so/yourworkspace/abc123def456...?v=...`
3. The long string of letters and numbers after your workspace name and before the `?v=` is your **Database ID**
4. Copy and save these three IDs — label them clearly:
   - Contacts DB ID
   - Projects DB ID
   - Meetings DB ID

---

## 2. BLUEDOT SETUP

BlueDot records your calls and sends the transcript to your automation via webhook.

### 2A. Install BlueDot

1. Go to **bluedot.io** and create an account
2. Install the **BlueDot Chrome extension**
3. Make sure it has permission to access Google Meet (or Zoom, whichever you use)

### 2B. Set Up the Webhook (connects BlueDot to your workflows)

1. Log into your BlueDot dashboard
2. Go to **Settings** (gear icon)
3. Find **Webhooks** or **Integrations**
4. Click **"Add Webhook"**
5. You need TWO webhooks — one for discovery calls, one for audit calls:

**Webhook 1 — Discovery Calls:**
- Name it: "VV Discovery Call Processing"
- URL: Your WF4 webhook URL (you'll get this from n8n after importing the workflow)
- Events: Transcript ready / Recording completed

**Webhook 2 — Audit Calls:**
- Name it: "VV Audit Call Processing"
- URL: Your WF4B webhook URL (from n8n)
- Events: Same as above

### 2C. How to Use BlueDot on Calls

1. Before joining a call, make sure the BlueDot Chrome extension is active (you'll see its icon)
2. Join your Google Meet / Zoom call — BlueDot starts recording automatically
3. After the call ends, BlueDot processes the transcript (usually takes 2-5 minutes)
4. Once ready, BlueDot automatically sends it to your n8n workflow via the webhook
5. You don't need to do anything manually — the workflow handles everything

---

## 3. PROSP.AI SETUP

Prosp.ai handles your LinkedIn outreach automation — sending connection requests, tracking acceptances, and detecting replies.

### 3A. Set Up Your Main Outreach Campaign

1. Log into **Prosp.ai**
2. Go to **Campaigns** and either create a new one or open your existing outreach campaign
3. Set up your connection request message and follow-up sequence as usual

### 3B. Connect Webhooks (tells your automation when things happen on LinkedIn)

1. In your campaign, go to **Settings** → **Webhooks**
2. Add these webhook URLs (you'll get the exact URLs from n8n after importing):

| Event | Webhook URL | What It Does |
|-------|------------|-------------|
| Connection Sent | `https://your-n8n.com/webhook/prosp-linkedin-events` | Creates a new contact in Notion |
| Connection Accepted | `https://your-n8n.com/webhook/prosp-linkedin-events` | Updates contact + adds to Loom sheet |
| Reply Received | `https://your-n8n.com/webhook/prosp-linkedin-events` | Marks contact as "Responded" |
| Message Sent | `https://your-n8n.com/webhook/prosp-loom-sent` | Detects when Loom video is sent |

### 3C. Create the Follow-Up Campaign

This is a separate campaign that triggers automatically when someone doesn't respond within 3 days:

1. Create a **new campaign** in Prosp.ai
2. Name it: "3-Day No Response Follow-Up"
3. Add 3 messages:
   - **Message 1 (Day 4):** Quick check-in asking if they watched the video
   - **Message 2 (Day 7):** Share a relevant case study
   - **Message 3 (Day 10):** Soft close with a free resource link
4. After creating, find the **Campaign ID** (usually visible in the URL or settings)
5. Save this ID — you'll need it when setting up the workflows

### 3D. Get Your API Key

1. Go to Prosp.ai → **Settings** → **API**
2. Copy your API key
3. Save it — you'll paste it into n8n as a credential

---

## 4. CALENDLY SETUP

Calendly handles booking links for your discovery calls and onboarding calls.

### 4A. Create Your Discovery Call Event Type

1. Log into **Calendly**
2. Go to **Event Types** → **Create New Event Type**
3. Set it up:
   - **Name:** "Veteran Vectors Discovery Call" (or whatever you prefer)
   - **Duration:** 30 minutes
   - **Location:** Google Meet or Zoom (your preference)

### 4B. Add Custom Questions (required for screening)

This is important — the screening workflow reads these answers to decide if a lead qualifies.

1. In your Discovery Call event type, go to **Invitee Questions**
2. Add these questions:

| Question | Type | Options |
|----------|------|---------|
| "What is your company's monthly revenue?" | Dropdown | Under $5K, $5K-$25K, $25K-$100K, $100K-$500K, $500K+ |
| "How many employees does your company have?" | Short text | — |
| "What's your company name?" | Short text | — |
| "Are you the decision maker?" | Dropdown | Yes, No |
| "What's your biggest business challenge right now?" | Paragraph | — |
| "Do you have a budget allocated for automation?" | Dropdown | Yes, Exploring, No |

3. Make sure the revenue question is **required** — this is the main qualification gate

### 4C. Create Your Audit Call Event Type

1. Create another event type
2. Name it: "Veteran Vectors Audit Call"
3. Duration: 45 minutes
4. Copy this booking link — you'll paste it into the proposal email template

### 4D. Create Your Onboarding Call Event Type

1. Create another event type
2. Name it: "Veteran Vectors Onboarding"
3. Duration: 45-60 minutes
4. Copy this booking link — it goes in the welcome email sent after contract signing

### 4E. Connect Calendly to n8n

1. In **n8n**, when you import WF3C (Calendly Screening), it will have a Calendly Trigger node
2. Click the Calendly Trigger node → select your Calendly OAuth2 credential
3. Set the trigger to fire on: **invitee.created**
4. Select your Discovery Call event type
5. Save and activate the workflow

---

## 5. HOW EVERYTHING CONNECTS (the big picture)

Here's the plain-English flow of what happens:

1. **Prosp.ai sends a LinkedIn connection request** → WF1 creates a contact in Notion
2. **Person accepts the connection** → WF1 updates Notion + adds them to the Loom sheet for you to record a video
3. **You record and send a Loom video** → WF2 marks "Loom Sent" in Notion
4. **No response after 3 days** → WF3A auto-starts the 3-message follow-up in Prosp.ai
5. **Person books a discovery call via Calendly** → WF3C screens their revenue. If under $5K, you get an approval email. If over $5K, auto-qualifies.
6. **You have the discovery call (BlueDot records it)** → WF4 processes the transcript with AI, creates a Google Drive folder, GitHub repo, and drafts a proposal email
7. **You have the audit call** → WF4B refines the proposal based on feedback
8. **You send the SOW/contract** → WF5 creates the PDF, sends for signing, sets up Stripe billing
9. **Waiting for signature** → WF6 sends daily reminders for 7 days, then every 3 days
10. **Client signs** → WF7 sends first invoice, welcome email, creates Slack channel, marks "Project Started"

---

## 6. QUICK REFERENCE: What to Have Ready Before Going to n8n

Before you start importing workflows into n8n, make sure you have these written down:

| Item | Where You Got It | Used In |
|------|-----------------|---------|
| Notion Integration Token (`ntn_...`) | Notion integrations page | All workflows |
| Contacts Database ID | Notion URL | All workflows |
| Projects Database ID | Notion URL | WF5, WF7 |
| Meetings Database ID | Notion URL | WF3C, WF4, WF4B |
| Prosp.ai API Key | Prosp settings | WF1, WF3A |
| Prosp.ai Follow-Up Campaign ID | Prosp campaign URL | WF3A |
| Calendly Discovery Call Link | Calendly event type | Proposal emails |
| Calendly Audit Call Link | Calendly event type | WF4 proposal email |
| Calendly Onboarding Call Link | Calendly event type | WF7 welcome email |
| Google Drive "Clients" Folder ID | Drive URL | WF4, WF4B, WF5 |
| Stripe Secret Key (`sk_live_...`) | Stripe dashboard | WF5, WF7 |
| Stripe Retainer Product ID (`prod_...`) | Stripe products page | WF5 |
| SignWell API Key | SignWell settings | WF5, WF7 |
| PDFco API Key | PDFco dashboard | WF5 |
| GitHub Personal Access Token | GitHub settings | WF4, WF4B |
| SOW PDF Template File ID | Google Drive URL | WF5 |

---

## 7. COMMON MISTAKES TO AVOID

1. **Forgetting to connect the Notion integration to each database** — The integration exists, but it can't see anything unless you explicitly share each database with it (Step 1C above)

2. **Misspelling Notion property names** — The automation looks for exact column names like "LI Connection Sent" not "LinkedIn Connection Sent". Copy them exactly.

3. **Not adding the revenue question to Calendly** — Without this, the screening workflow (WF3C) can't determine if a lead qualifies

4. **Forgetting to set up both BlueDot webhooks** — You need one for discovery calls (WF4) and a separate one for audit calls (WF4B)

5. **Using the wrong Prosp.ai webhook URL** — Connection events and message events go to different webhook URLs. Double-check the table in Section 3B.

6. **Not creating the "Clients" root folder in Google Drive** — WF4 creates subfolders inside this folder. If it doesn't exist, the workflow will error.
