---
name: 20-agents-skill
version: 2.6
description: A 19-lens review team managed by a dedicated Orchestrator. The Orchestrator is a first-class process controller — not a lens — that runs before, during, and after the agents. It decides which lenses fire, at what depth, in what order, and self-corrects based on what agents return. Lenses 1–19 are the specialists. Includes purpose-built lenses for Sales & Persuasion (17), Conversation & Discovery Quality (18), and Decision Support Quality (19). Quick Mode is the default for anything under 100 lines or not explicitly client-facing. All 🔴 Critical and 🟡 Important findings are implemented automatically after the report. Trigger on "run review agents team", "comprehensive review", or any request for multi-dimensional critique.
---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 2.6 | 2026-03-09 | Renamed to 20-agents-skill. Pulled Orchestrator out of numbered lens list — now a first-class conductor wrapping the entire process. Added Orchestrator self-improvement loop (learns from blocked/weak agent responses). Quick Mode is now default for <100 lines or non-client-facing. N/A and zero-issue lenses produce no output — silently skipped. Priority Matrix capped at 7 rows. Announcement compressed to one line. Auto-implement scope: 🔴 and 🟡 only; 🟢 listed but not implemented unless requested. Lenses renumbered 1–19. |
| 2.5 | 2026-03-09 | Added lenses 17–20 (Sales & Persuasion, Conversation & Discovery, Decision Support, Orchestrator). Raised token budget to 8,000. Updated auto-weight table. |
| 2.4 | 2026-03-09 | Fixed severity/CRITICAL collision. Added auto-implement Step 5. Sensitive content check. Low-confidence majority rule. |
| 2.3 | 2026-03-01 | Added lenses 14–16 (Code Quality, Compliance, Cybersecurity). |
| 2.2–2.0 | — | Earlier versions. |

---

# 20 Agents Skill

A 19-lens specialist review team managed by a dedicated Orchestrator. The Orchestrator is not a lens — it is the conductor. It decides which agents fire, at what depth, and in what order. It monitors execution, handles blockages, and self-improves based on what agents return. Agents do not act without Orchestrator direction.

---

## The Orchestrator

The Orchestrator runs in three phases: **Pre-flight → Execution → Quality Control.** It is always active. It has no token budget of its own — it operates inside the overall budget by keeping its own output minimal and letting the agents do the work.

### Phase 1 — Pre-Flight (runs before any lens)

The Orchestrator reads the input and produces a one-line execution plan before any agent fires:

> `[Type: Proposal | Mode: Deep | Active lenses: 1,3,6,11,17 (Heavy), 2,4,7 (Standard) | Skipping: 8,9,10,13,14,15,16,18,19 | Sensitive content: none detected]`

That's it. No paragraphs, no explanation. One line. Agents begin immediately after.

Pre-flight decisions:
- **Existing state scan (runs first)** — before any lens fires, scan the current file/content and build an internal map of what is already configured: colors, hex values, layout structure, logic branches, field mappings, API endpoints, trigger types, error handling, naming conventions, and any other non-default setting. This map is the **User Intent Registry**. Any recommendation from any lens that would modify something in the Registry is automatically flagged for approval — never auto-implemented. Output as one line only: `[User Intent Registry: 12 existing choices logged — findings touching these require approval]`
- **Content type** — classify against the auto-weight table. Pick the closest match.
- **Mode** — Quick if input is under 100 lines OR not explicitly client-facing or production-bound. Deep otherwise. If the user said "quick review" on a client deliverable, fire Deep anyway and note the override.
- **Lens tiers** — assign every lens one of: Heavy / Standard / Skip. Skip means zero output. The Orchestrator records this assignment internally and enforces it.
- **Sensitive content** — scan for PII, credentials, confidential markings. If found, append to the one-line announcement: `[⚠️ Sensitive content detected: PII in lines 4–7. Recommend removing before sharing report.]`

### Phase 2 — Execution (monitors as agents run)

The Orchestrator watches agent output as it comes in and intervenes when needed. Three triggers:

**Trigger 1 — Cascading weight adjustment.** If an agent's findings raise the stakes for another agent, the Orchestrator upgrades that agent's tier before it runs. Example: Security (lens 8) finds exposed API keys → Cybersecurity (lens 16) upgrades from Standard to Heavy. The Orchestrator notes the upgrade inline: `[Orchestrator: upgrading Cybersecurity to Heavy based on Security findings.]`

**Trigger 2 — Blocked agent.** If an agent cannot produce a specific, evidence-based finding — because the input lacks information, the domain is outside competence, or external access is needed — the Orchestrator flags it and skips rather than letting it pad: `[Orchestrator: Lens 15 blocked — no regulatory framework identifiable from input. Skipped.]` The agent produces no output.

**Trigger 3 — Vague output rejection.** If an agent produces a finding that doesn't cite specific evidence or gives an unactionable recommendation ("consider improving X"), the Orchestrator rejects it and re-runs with a single instruction: `[Orchestrator: Lens 6 output too vague. Re-run: cite specific cost figures, state who acts by when.]` Maximum one re-run per lens. If the second attempt is still vague, skip and flag.

### Phase 3 — Quality Control (runs after all agents, before report delivery)

- Verify the Priority Matrix reflects actual severity scores — no severity-2 finding in 🔴 Critical
- Identify conflicting recommendations across lenses — surface them in Cross-Cutting Themes, don't let both stand silently
- Confirm the Low-Confidence Majority Rule: if 6+ lenses score LOW confidence, prepend the report with the confidence warning
- Final go/no-go: if more than 2 lenses were rejected and re-run, note it in the report header: `[Review quality: 2 lenses required re-run]`

### Orchestrator Self-Improvement Loop

After every review, the Orchestrator evaluates its own pre-flight decisions against what actually happened:

- Did any lens it marked Skip produce a finding that mattered? → Adjust the auto-weight table mentally for this content type.
- Did any lens it marked Heavy produce zero findings? → Note the over-allocation for next time.
- Did any agent get blocked or rejected? → Record the pattern: what type of content, which lens, what failed. Use this to inform future tier assignments for similar content.
- Did any cascading weight adjustment catch something critical that would have been missed? → Reinforce that trigger pattern.

The Orchestrator does not output this log unless the user asks. It runs silently and informs the next pre-flight. Over repeated use, tier assignments for familiar content types should become increasingly accurate and token-efficient.

---

## Auto-Weight Table

The Orchestrator uses this to assign lens tiers during pre-flight.

| Content Type | Heavy Lenses |
|---|---|
| n8n Workflows | Security, Guardrails, AI Safety, Data Integrity, Code Quality, Cybersecurity |
| Companies / Business Plans | Legal, Current State, Future Strategy, Cost Effectiveness, Compliance |
| Social Media / Content Strategy | Legal, Ethical, Time Effectiveness, AI Safety, Compliance |
| Products / Services | Legal, Security, AI Safety, Client UX, Maintainability, Cybersecurity |
| Client Deliverables (Guides, SOPs) | Guardrails, Client UX, Maintainability, Sales & Persuasion, Compliance |
| Proposals | Sales & Persuasion, Client UX, Legal, Cost Effectiveness, Guardrails |
| Internal Skills / SOPs / Prompt Templates | Guardrails, Maintainability, Client UX, AI Safety |
| Email Sequences / Outreach | Legal, Ethical, Client UX, Time Effectiveness, Sales & Persuasion |
| API Documentation / Technical Specs | Security, Data Integrity, Maintainability, Client UX, Code Quality, Cybersecurity |
| Codebases / Scripts / Automations | Code Quality, Security, Cybersecurity, Maintainability, Data Integrity |
| Defense / Government / DIB Deliverables | Compliance, Cybersecurity, Security, Legal, Data Integrity, Guardrails |
| Transcripts (sales, discovery, coaching) | Conversation & Discovery Quality, Sales & Persuasion, Client UX, Ethical |
| Dashboards / Reports / Analytics | Decision Support Quality, Data Integrity, Client UX, Code Quality |

**Fallback:** If the type doesn't match, pick the 3–4 lenses most relevant to the content's risk profile. Append to the pre-flight line: `[Type: unclassified — weighting Security, Guardrails, Client UX based on production deployment risk.]`

---

## Token Budget

| Mode | Budget | Notes |
|---|---|---|
| Quick | ~600 tokens | Priority Matrix + Executive Summary + Top 3 only |
| Deep | ~5,000 tokens | Full dimensional analysis. Excludes implementation log and output file. |

**Allocation rules (Deep Mode):**
- Heavy lenses: ~250–350 tokens each
- Standard lenses: ~75–100 tokens each
- Skipped lenses: 0 tokens — no output at all
- Zero-issue lenses: 0 tokens — silently omitted from the report

The Orchestrator monitors running token usage. If approaching the budget before all active lenses complete, it compresses remaining Standard lenses to one sentence each and flags: `[Orchestrator: budget pressure — Standard lenses compressed.]`

---

## Custom Lenses

Up to 3 user-defined lenses. Same rules as standard lenses.

To add: `"Add custom lens: [Name] — [1-sentence scope]"`

Custom lenses appear after lens 19 as lenses 20, 21, 22. Included in Priority Matrix if findings warrant.

**Persistence:** Carry custom lenses forward across turns automatically. If uncertain: `"Keeping [lens names] from earlier. Correct?"`

---

## The 19 Lenses

Agents only run when the Orchestrator assigns them Heavy or Standard. Skipped agents produce no output.

**1. Legal** — Contracts, liability, IP, regulatory compliance, jurisdiction, TOS violations, data privacy laws (GDPR, CCPA, HIPAA). License compatibility, third-party legal exposure, indemnification gaps.

**2. Ethical** — Fairness, bias, manipulation risk, transparency, stakeholder harm, alignment with stated values. Consent mechanisms, power asymmetry, unintended consequences on vulnerable groups.

**3. Logistical** — Feasibility, resource requirements, dependencies, sequencing, bottlenecks, single points of failure. Environment assumptions, prerequisite access, deployment complexity.

**4. Current State** — What exists, what's working, what's solid. Benchmark against similar implementations where possible. Do not overlook strengths.

**5. Future Strategy** — Scalability, adaptability, competitive positioning, long-term viability. Migration paths, sunset risks, technology lifecycle alignment.

**6. Cost Effectiveness** — Direct costs, hidden costs, opportunity costs, ROI. Quantify in dollars. Include token/API costs for AI-dependent workflows.

**7. Time Effectiveness** — Time-to-value, maintenance burden, process efficiency, missed automation opportunities. Estimate hours saved or spent.

**8. Security** — Data exposure, access controls, authentication, encryption, attack surface, credential handling. Secret rotation, least-privilege adherence, logging of sensitive operations.

**9. Guardrails & Governance** — Error handling, monitoring, alerting, audit trails, rollback capability, approval workflows, human oversight. Failure notification paths, degraded-mode behavior.

**10. AI Safety & Responsible AI** — Prompt injection risk, hallucination blast radius, PII in prompts, output validation, human-in-the-loop requirements, model dependency risk. Findings here are probabilistic — flag where expert review is needed before acting.

**11. Client Experience & Usability** — Onboarding friction, error message quality, edge case UX, documentation clarity, accessibility, user confidence. First-run experience, cognitive load.

**12. Maintainability & Handoff Readiness** — Client self-sufficiency post-handoff, knowledge transfer completeness, vendor lock-in risk, modifiability, dependency mapping, technical debt. Bus factor.

**13. Data Integrity & Quality** — Input validation, transformation accuracy, duplicate handling, data loss risk, schema drift resilience, upstream change tolerance. Backup/recovery, data lineage.

**14. Code Quality & Architecture** — Structure, modularity, separation of concerns, naming conventions, DRY/SOLID adherence, error handling patterns. Complexity (cyclomatic), dead code, unused imports. Testing coverage, defensive coding. For n8n: node organization, expression complexity, sub-workflow decomposition. Technical debt. Performance: N+1 queries, blocking operations, memory leaks.

**15. Regulatory Compliance** — CMMC/NIST 800-171 (defense), SOC 2 (SaaS), HIPAA (healthcare), PCI-DSS (payments), FedRAMP (government cloud), SOX (financial). Audit readiness, gap analysis, record retention, mandatory reporting. For SMBs: identify what actually applies — don't load a 20-person shop with Fortune 500 compliance theater.

**16. Cybersecurity** — Threat modeling, attack vectors. Network exposure: open ports, public endpoints, webhook security. Auth: MFA, token handling, session management, OAuth, API key rotation. Input sanitization: SQL/XSS/command/prompt injection, file upload, deserialization. Infrastructure: CVEs, supply chain risk, patch currency. Incident response: detection, response plan, RTO. Encryption in transit and at rest. For n8n: credential storage, webhook auth, execution data exposure, node-level permissions.

**17. Sales & Persuasion Effectiveness** — *Primary use: proposals, client materials, outreach, email sequences.*
Does this content move someone toward a yes? Evaluate: opening hook (client's problem first or vendor credentials first), pricing psychology (anchoring, value-before-price sequencing), objection anticipation (are the top 3 objections addressed before the reader raises them), proof point specificity (real numbers vs. vague claims), CTA clarity (is the next step unambiguous and low-friction), and narrative arc (does the document build momentum or just present information). Flag anywhere the content talks about the vendor instead of the client's outcome.

**18. Conversation & Discovery Quality** — *Primary use: sales transcripts, discovery calls, coaching sessions, client meeting notes.*
Did the conversation do what it needed to do? Evaluate: problem discovery depth (root cause or surface-level), missed signals (what the client revealed that wasn't followed up on), commitments made (explicit and implied — who, what, by when), qualification completeness (budget, authority, timeline, need), next step clarity (unambiguous to both parties), and missed pivot moments. For coaching: did the session achieve its goal, did the client leave with actionable clarity, were any threads left unresolved. All findings must cite verbatim examples from the transcript.

**19. Decision Support Quality** — *Primary use: dashboards, reports, analytics outputs, KPI trackers, executive summaries.*
Does this output support the decisions it's supposed to inform? Evaluate: metric relevance (right things measured, not just easy things), decision alignment (for each metric, what decision does it enable — flag if unclear), audience calibration (right level of detail for who reads this), actionability (can someone look at this and know what to do next), timeframe appropriateness (leading vs. lagging balance, right baseline periods), missing context (what's absent that would change interpretation), and visual hierarchy (does layout direct attention or require viewer assembly).

---

## Lens Rules (applies to all 19)

- Every finding cites specific evidence — no generic observations
- Every recommendation is actionable: who does what, by when, how
- Quantify: "$X/month" not "expensive"; "3 manual steps" not "time-consuming"
- Don't soften critical findings
- If a lens genuinely doesn't apply: Orchestrator marks it Skip — agent produces zero output
- If a lens has zero issues: agent produces zero output — Orchestrator silently notes it clean
- If domain expertise is insufficient: "Low confidence — [reason]. Recommend expert validation." Do not fabricate.

---

## Confidence & Severity Scoring

Each active lens assigns:
- **Rating:** PASS / CAUTION / FAIL
- **Confidence:** HIGH / MEDIUM / LOW
- **Severity (CAUTION/FAIL only):** 1–5 where 1 = minor polish, 2 = meaningful gap, 3 = significant risk, 4 = high impact, 5 = critical/blocking

**Priority Matrix mapping:**
- Severity 4–5 → 🔴 Critical
- Severity 2–3 → 🟡 Important
- Severity 1 → 🟢 Nice to Have

---

## Assessment Report Format

**Report header** — one line each: title, date, type, mode, overall risk level.

**Executive Summary** — 3–5 sentences: what was reviewed, top 3 findings, verdict.

**Priority Matrix** — max 7 rows. Columns: Priority, Finding (specific), Lens, Confidence, Effort, Impact. If fewer than 3 findings, note the review is clean and list what exists.

**Top 3 Actions** — specific enough to execute without reading the full report. If no critical findings: "No critical actions. Improvement opportunities: [list]."

**[Quick Mode: stop here]**

**Dimensional Analysis** (Deep Mode) — active lenses only, in order. Skipped lenses do not appear. Header format: `### 4. Current State — PASS | Confidence: HIGH` or `### 17. Sales & Persuasion — CAUTION | Confidence: HIGH | Severity: 3`

**Cross-Cutting Themes** — patterns across multiple lenses. Conflicts between lens recommendations named explicitly here.

---

## Auto-Implement (Step 5)

After the report, implement findings immediately. No permission needed.

**Scope:**
- 🔴 Critical → implement automatically
- 🟡 Important → implement automatically
- 🟢 Nice to Have → list in the log, do NOT implement unless the user explicitly asks

**Implementation log format:**
> ✅ Fixed: [what changed, where]
> ⚠️ Skipped: [item] — [reason: user decision needed / external access required / conflicts with fix #X]
> 📋 Listed (not implemented): [Nice to Have items]

**What's implementable:** Text, prose, prompts, skill files, SOPs, guides, emails, code, scripts, workflows, structural gaps. Edit directly. Deliver updated file via `present_files`.

**What's not:** Decisions requiring user input, changes needing credentials or live system access. Flag and skip.

**Destructive changes** — implement but flag:
> ⚠️ Review before keeping: [what changed and why]

**Protected choices — NEVER auto-implement. Flag for user approval instead.**

Assume any of the following reflect intentional decisions by the user unless explicitly told otherwise:

*Visual & Design*
- Colors, hex values, gradients, themes, dark/light mode
- Layout, spacing, component positioning, grid structure
- Typography (fonts, sizes, weights)
- Branding elements (logos, icons, imagery)

*Functionality & Logic*
- Workflow routing, branching logic, conditional paths
- Data transformations, field mappings, output formats
- API call structure, endpoint choices, payload shape
- Trigger types, scheduling, execution order
- Error handling behavior, retry logic, fallback paths
- Node configurations, credential references, connection structure

*Architecture & Structure*
- File/folder organization, naming conventions already in use
- Module boundaries, sub-workflow decomposition choices
- Integration choices (which tools connect to what)
- Any setting that was clearly configured by the user, not defaulted

If a finding would change any of the above, output this instead of implementing:
> 🛑 Approval required: [what the agent wants to change] → [reason] — approve or reject?

Do NOT implement until the user explicitly says yes.

If the current file already differs from what the agent wants to "fix" (meaning the user likely already set it intentionally), flag as:
> 🔁 Previously set by user: [what] is already configured this way. Skipping — confirm if you want this changed.

**Delivery:**
1. One-line Orchestrator pre-flight announcement
2. Assessment Report
3. Implementation log
4. Updated file via `present_files`
5. One-line summary: "Applied [X] fixes. Skipped [Y]. Listed [Z] Nice to Have."

---

## Low-Confidence Majority Rule

If 6+ lenses score LOW confidence, prepend the report:

> "⚠️ Confidence Warning: Majority of lenses are LOW confidence. Treat findings as directional. Validate flagged lenses with a qualified expert before acting."

---

## Quality Standards

- 5 sharp findings beat 20 generic ones
- No filler: "it's important to note", "as mentioned above", "it should be noted"
- Strengths backed by evidence — not token gestures
- Every recommendation survives the "so what do I actually do?" test
- Conflicts between lenses named explicitly — never left to stand silently
- Quick Mode: ~600 tokens max
- Deep Mode: ~5,000 tokens max (excluding implementation log and output file)
