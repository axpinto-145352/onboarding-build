# Onboarding Build - Development Policies

## n8n Workflow Development

### Standing Policy: Always Use Native n8n Nodes

When building or modifying n8n workflows, **always use native n8n nodes** instead of HTTP Request nodes when a native node exists for the service. This applies to all current and future workflow development.

**Why:** Native nodes provide built-in credential management (more secure), better UI visibility, easier maintenance, and proper error handling.

**Native nodes to use:**
- **Notion**: `n8n-nodes-base.notion` (typeVersion 2.2) — for all database queries, page creates, and page updates
- **Google Sheets**: `n8n-nodes-base.googleSheets` — already in use
- **Google Drive**: `n8n-nodes-base.googleDrive` — already in use
- **Gmail**: `n8n-nodes-base.gmail` — already in use
- **Stripe**: `n8n-nodes-base.stripe` — for supported operations (customer create, charge, etc.)
- **Claude/Anthropic**: `@n8n/n8n-nodes-langchain.anthropic` — already in use

**HTTP Request is acceptable for:**
- Services with no native n8n node (Calendly v2 API, SignWell, Prosp.ai)
- Google Drive API operations not available in native node (file copy/conversion, export as PDF, permission setting)
- Stripe operations not supported by the native node (invoices, invoice items, prices, subscriptions)
- Generic file downloads

### Notion Credential Reference
All native Notion nodes should use:
```json
"credentials": {
  "notionApi": {
    "id": "YOUR_NOTION_CRED_ID",
    "name": "Notion account"
  }
}
```

### Notion Database IDs
- Contacts DB: `30371d52651c80b1b5f2d93203b3836b`
- Meetings DB: `30371d52651c80a9a9ffdfaf0b135480`
- Projects DB: `30371d52651c801d99dcddc8774d8f79`
- Tasks (Action Items) DB: `30371d52651c80e0abfae6557752a716`
