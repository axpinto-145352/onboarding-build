---
name: proposal-generator
description: "Use this skill whenever the user wants to create, draft, or generate a client proposal, automation proposal, consulting proposal, SOW, or project pitch document. Trigger when users say 'write a proposal', 'create a proposal', 'draft a proposal', 'make a proposal for [client]', 'proposal template', 'build a proposal PDF', or provide client/project information and ask for a professional proposal. Also trigger when users mention 'SOW', 'statement of work', 'project quote', 'engagement letter', or 'client pitch deck' that should follow the Veteran Vectors branded proposal format. Trigger aggressively — if a user provides client details and deliverables and wants a professional document out of it, use this skill."
---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2026-03-09 | Updated all specs to match live onboarding proposal implementation. Logo on navy band replaces plain text header. Corrected all colors, styles, font sizes, spacing. Company name is Veteran Vectors (no LLC). Added logo helper functions, BulletBody + CaseStudyTitle + Callout styles, make_kv_table pattern. |
| 1.0 | — | Original skill |

# Proposal Generator

Turn provided client/project information into a professionally formatted, branded proposal PDF. The output is a polished, client-ready document.

## When This Skill Triggers

A user provides information about a client engagement (client name, deliverables, pricing, timelines, etc.) and wants it turned into a formatted proposal. The user may provide this as notes, a brief, bullet points, or a conversation summary.

## Dependencies

```bash
pip install reportlab Pillow --break-system-packages -q
```

If install fails (network disabled), inform the user that ReportLab is required and ask them to enable network access.

---

## Brand Spec — Single Source of Truth

All proposals must match this exactly. Do not deviate.

### Colors

```python
BLUE        = HexColor("#6CB4EE")   # Section titles, cover title, cover names, links, blue bold labels
BLUE_BOLD   = HexColor("#5A9FD4")   # KV table label column (slightly deeper)
DARK_TEXT   = HexColor("#333333")   # All body text
MUTED_TEXT  = HexColor("#999999")   # Cover labels ("Prepared for"), date, footer CONFIDENTIAL, closing contact line
HEADER_BG   = HexColor("#E8F0F8")   # Table header row background (light blue-gray)
ROW_ALT     = HexColor("#F5F8FB")   # Alternating table row (very subtle)
BORDER_COLOR= HexColor("#D0D5DD")   # Table borders (light gray)
WHITE       = HexColor("#FFFFFF")
RULE_COLOR  = HexColor("#CCCCCC")   # Horizontal rule under logo on cover
NAVY        = HexColor("#1A2B4A")   # Logo band background on cover and last page
```

### Layout

```python
from reportlab.lib.pagesizes import letter
PAGE_W, PAGE_H = letter   # 612 x 792 points
MARGIN    = 0.85 * inch
CONTENT_W = PAGE_W - 2 * MARGIN   # ~638 points available
```

### Logo

```python
LOGO_PATH = '/home/claude/vv-logo.png'   # Copy from /mnt/user-data/uploads/vv-logo.png if not present
LOGO_W    = 2.0 * inch
LOGO_H    = LOGO_W / 3.03   # Preserve aspect ratio (logo is 627x207px)
```

The logo has a black background. Always place it on a navy band (`#1A2B4A`) so it reads correctly. Never place the raw logo on a white background.

### Company Config

```python
CONSULTANT = {
    'name':          'Anthony Pinto',
    'title':         'Founder',
    'company':       'Veteran Vectors',        # NO "LLC" — this is correct
    'email':         'anthony@veteranvectors.io',
    'company_short': 'VETERAN VECTORS',        # Used in page header
}
```

---

## Complete Boilerplate — Copy This Every Time

This is the full, tested implementation. Start every proposal from this base. Fill in content only — do not change colors, fonts, sizes, or structure.

### Imports and Setup

```python
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.lib.colors import HexColor
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable, Image as RLImage
)

LOGO_PATH = '/home/claude/vv-logo.png'
LOGO_W    = 2.0 * inch
LOGO_H    = LOGO_W / 3.03

PAGE_W, PAGE_H = letter
MARGIN    = 0.85 * inch
CONTENT_W = PAGE_W - 2 * MARGIN

BLUE         = HexColor("#6CB4EE")
BLUE_BOLD    = HexColor("#5A9FD4")
DARK_TEXT    = HexColor("#333333")
MUTED_TEXT   = HexColor("#999999")
HEADER_BG    = HexColor("#E8F0F8")
ROW_ALT      = HexColor("#F5F8FB")
BORDER_COLOR = HexColor("#D0D5DD")
WHITE        = HexColor("#FFFFFF")
RULE_COLOR   = HexColor("#CCCCCC")
NAVY         = HexColor("#1A2B4A")

CONSULTANT = {
    'name':          'Anthony Pinto',
    'title':         'Founder',
    'company':       'Veteran Vectors',
    'email':         'anthony@veteranvectors.io',
    'company_short': 'VETERAN VECTORS',
}
```

### Paragraph Styles

```python
styles = {
    # Body styles
    'SectionTitle': ParagraphStyle('SectionTitle',
        fontName='Helvetica-Bold', fontSize=14, textColor=BLUE,
        spaceBefore=18, spaceAfter=8, leading=18),

    'SubsectionTitle': ParagraphStyle('SubsectionTitle',
        fontName='Helvetica-Bold', fontSize=11, textColor=BLUE,
        spaceBefore=12, spaceAfter=5, leading=15),

    'Body': ParagraphStyle('Body',
        fontName='Helvetica', fontSize=10, textColor=DARK_TEXT,
        spaceBefore=4, spaceAfter=4, leading=14),

    'BodyBold': ParagraphStyle('BodyBold',
        fontName='Helvetica-Bold', fontSize=10, textColor=DARK_TEXT,
        spaceBefore=4, spaceAfter=4, leading=14),

    'Muted': ParagraphStyle('Muted',
        fontName='Helvetica', fontSize=9, textColor=MUTED_TEXT,
        spaceBefore=2, spaceAfter=2, leading=12),

    'BulletBody': ParagraphStyle('BulletBody',
        fontName='Helvetica', fontSize=10, textColor=DARK_TEXT,
        spaceBefore=2, spaceAfter=2, leading=14, leftIndent=12),

    'CaseStudyTitle': ParagraphStyle('CaseStudyTitle',
        fontName='Helvetica-Bold', fontSize=10, textColor=BLUE,
        spaceBefore=10, spaceAfter=4, leading=14),

    'Callout': ParagraphStyle('Callout',
        fontName='Helvetica-Bold', fontSize=11, textColor=BLUE,
        spaceBefore=8, spaceAfter=8, leading=15),

    # Cover page styles — all centered
    'CoverDocType': ParagraphStyle('CoverDocType',
        fontName='Helvetica', fontSize=11, textColor=MUTED_TEXT,
        alignment=TA_CENTER, spaceBefore=16, spaceAfter=4, leading=14),

    'CoverTitle': ParagraphStyle('CoverTitle',
        fontName='Helvetica-Bold', fontSize=26, textColor=BLUE,
        alignment=TA_CENTER, spaceBefore=2, spaceAfter=4, leading=32),

    'CoverSubtitle': ParagraphStyle('CoverSubtitle',
        fontName='Helvetica', fontSize=12, textColor=BLUE,
        alignment=TA_CENTER, spaceBefore=2, spaceAfter=20, leading=16),

    'CoverLabel': ParagraphStyle('CoverLabel',
        fontName='Helvetica', fontSize=10, textColor=MUTED_TEXT,
        alignment=TA_CENTER, spaceBefore=16, spaceAfter=2),

    'CoverName': ParagraphStyle('CoverName',
        fontName='Helvetica-Bold', fontSize=11, textColor=BLUE,
        alignment=TA_CENTER, spaceBefore=2, spaceAfter=1),

    'CoverDetail': ParagraphStyle('CoverDetail',
        fontName='Helvetica', fontSize=10, textColor=DARK_TEXT,
        alignment=TA_CENTER, spaceBefore=1, spaceAfter=1),

    'CoverEmail': ParagraphStyle('CoverEmail',
        fontName='Helvetica', fontSize=10, textColor=BLUE,
        alignment=TA_CENTER, spaceBefore=1, spaceAfter=1),

    'CoverDate': ParagraphStyle('CoverDate',
        fontName='Helvetica', fontSize=10, textColor=DARK_TEXT,
        alignment=TA_CENTER, spaceBefore=16, spaceAfter=0),
}
```

### Page Header/Footer Callback

Runs on every page. Header: `VETERAN VECTORS` (blue bold) + `| CONFIDENTIAL` (gray) top-right. Footer: `Page X` (Page in dark, number in blue) bottom-center.

```python
def on_all_pages(canvas, doc):
    canvas.saveState()
    right_edge = PAGE_W - doc.rightMargin
    y = PAGE_H - 0.45 * inch

    conf_text = "|  CONFIDENTIAL"
    vv_text   = f"{CONSULTANT['company_short']}  "
    conf_w    = canvas.stringWidth(conf_text, 'Helvetica', 8)

    canvas.setFont('Helvetica', 8)
    canvas.setFillColor(MUTED_TEXT)
    canvas.drawRightString(right_edge, y, conf_text)

    canvas.setFont('Helvetica-Bold', 8)
    canvas.setFillColor(BLUE)
    canvas.drawRightString(right_edge - conf_w, y, vv_text)

    page_label_w = canvas.stringWidth("Page ", 'Helvetica', 9)
    num_text     = str(doc.page)
    total_w      = page_label_w + canvas.stringWidth(num_text, 'Helvetica', 9)
    start_x      = (PAGE_W - total_w) / 2

    canvas.setFont('Helvetica', 9)
    canvas.setFillColor(DARK_TEXT)
    canvas.drawString(start_x, 0.45 * inch, "Page ")
    canvas.setFillColor(BLUE)
    canvas.drawString(start_x + page_label_w, 0.45 * inch, num_text)

    canvas.restoreState()
```

### Logo Helper Functions

Two versions: full size for cover, 80% for the last page closing block.

```python
def make_logo_table():
    """Full-size logo on navy band — cover page."""
    logo_img = RLImage(LOGO_PATH, width=LOGO_W, height=LOGO_H)
    t = Table([[logo_img]], colWidths=[CONTENT_W])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), NAVY),
        ('ALIGN',      (0,0), (-1,-1), 'CENTER'),
        ('VALIGN',     (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 14),
        ('BOTTOMPADDING', (0,0), (-1,-1), 14),
    ]))
    return t

def make_logo_table_last():
    """80% logo on navy band — last page closing block."""
    logo_img = RLImage(LOGO_PATH, width=LOGO_W * 0.8, height=LOGO_H * 0.8)
    t = Table([[logo_img]], colWidths=[CONTENT_W])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), NAVY),
        ('ALIGN',      (0,0), (-1,-1), 'CENTER'),
        ('VALIGN',     (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
    ]))
    return t
```

### Table Builders

Two types. Use the right one.

**Standard data table** — has a header row with `HEADER_BG`, alternating rows, gray borders:

```python
def make_table(data, col_widths, has_header=True):
    cell_style   = ParagraphStyle('Cell',       fontName='Helvetica',      fontSize=9, textColor=DARK_TEXT, leading=12)
    header_style = ParagraphStyle('HeaderCell', fontName='Helvetica-Bold', fontSize=9, textColor=DARK_TEXT, leading=12)
    wrapped = []
    for i, row in enumerate(data):
        s = header_style if (i == 0 and has_header) else cell_style
        wrapped.append([Paragraph(str(c), s) for c in row])
    t = Table(wrapped, colWidths=col_widths, repeatRows=1 if has_header else 0)
    cmds = [
        ('VALIGN',        (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING',    (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING',   (0,0), (-1,-1), 8),
        ('RIGHTPADDING',  (0,0), (-1,-1), 8),
        ('GRID',          (0,0), (-1,-1), 0.5, BORDER_COLOR),
    ]
    if has_header:
        cmds.append(('BACKGROUND', (0,0), (-1,0), HEADER_BG))
    start = 1 if has_header else 0
    for i in range(start, len(data)):
        if (i - start) % 2 == 1:
            cmds.append(('BACKGROUND', (0,i), (-1,i), ROW_ALT))
    t.setStyle(TableStyle(cmds))
    return t
```

**Key-value table** — no header row, first column is `BLUE_BOLD` bold labels, second is regular body text:

```python
def make_kv_table(data, col_widths):
    label_style = ParagraphStyle('KVLabel', fontName='Helvetica-Bold', fontSize=9, textColor=BLUE_BOLD, leading=12)
    value_style = ParagraphStyle('KVValue', fontName='Helvetica',      fontSize=9, textColor=DARK_TEXT, leading=12)
    wrapped = []
    for row in data:
        wrapped.append([Paragraph(str(row[0]), label_style), Paragraph(str(row[1]), value_style)])
    t = Table(wrapped, colWidths=col_widths, repeatRows=0)
    cmds = [
        ('VALIGN',        (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING',    (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING',   (0,0), (-1,-1), 8),
        ('RIGHTPADDING',  (0,0), (-1,-1), 8),
        ('GRID',          (0,0), (-1,-1), 0.5, BORDER_COLOR),
    ]
    for i in range(len(data)):
        if i % 2 == 1:
            cmds.append(('BACKGROUND', (0,i), (-1,i), ROW_ALT))
    t.setStyle(TableStyle(cmds))
    return t
```

### Section Builder

Wraps heading + content in `KeepTogether` if small enough to avoid orphaned headers:

```python
def add_section(story, heading, elements):
    block = [Paragraph(heading, styles['SectionTitle'])]
    block.extend(elements)
    est = 24
    for el in elements:
        if isinstance(el, Table):
            est += 30 + len(el._cellvalues) * 30
        elif isinstance(el, Paragraph):
            est += 18
        elif isinstance(el, Spacer):
            est += getattr(el, 'height', 12)
    if est < 380:
        story.append(KeepTogether(block))
    else:
        story.append(KeepTogether(block[:2]))
        for el in block[2:]:
            story.append(el)
```

### Blue Bold Inline Label Helper

For callout labels within body paragraphs like `Processing is ephemeral.` or `What the retainer covers:`:

```python
def B(text):
    return f'<font color="#6CB4EE"><b>{text}</b></font>'

# Usage:
Paragraph(f"{B('What the retainer covers:')}", styles['Body'])
Paragraph(f"{B('Processing is ephemeral.')} When client intake data...", styles['Body'])
```

---

## Cover Page Structure

Logo on a navy band, then a horizontal rule, then centered proposal metadata. No plain text company name — the logo replaces it.

```python
story.append(Spacer(1, 30))
story.append(make_logo_table())                  # Navy band with logo
story.append(Spacer(1, 18))
story.append(HRFlowable(width="100%", thickness=1, color=RULE_COLOR, spaceBefore=0, spaceAfter=0))
story.append(Spacer(1, 16))
story.append(Paragraph("AUTOMATION PROPOSAL", styles['CoverDocType']))   # Doc type — gray, all caps
story.append(Paragraph("[Proposal Title]",    styles['CoverTitle']))     # Blue, 26pt bold
story.append(Paragraph("[Tagline]",           styles['CoverSubtitle'])) # Blue, 12pt
story.append(Paragraph("Prepared for",        styles['CoverLabel']))    # Gray label
story.append(Paragraph("[Client Name]",       styles['CoverName']))     # Blue bold
story.append(Paragraph("Prepared by",         styles['CoverLabel']))    # Gray label
story.append(Paragraph(f"{CONSULTANT['name']}, {CONSULTANT['title']}", styles['CoverName']))
story.append(Paragraph(CONSULTANT['company'], styles['CoverDetail']))   # Dark text
story.append(Paragraph(CONSULTANT['email'],   styles['CoverEmail']))    # Blue
story.append(Paragraph("[Date]  |  CONFIDENTIAL", styles['CoverDate']))
story.append(PageBreak())
```

---

## Last Page Closing Block

Always end with this pattern — "Ready to get started?" bold, then the logo on navy, then the contact line in muted gray:

```python
Spacer(1, 16),
Paragraph("<b>Ready to get started?</b>", styles['Body']),
Spacer(1, 8),
make_logo_table_last(),
Spacer(1, 8),
Paragraph(f"{CONSULTANT['name']}  |  {CONSULTANT['email']}  |  {CONSULTANT['company']}", styles['Muted']),
```

---

## Column Width Quick Reference

Always express widths as fractions of `CONTENT_W` and verify they sum to `1.0`.

| Table Type | Columns | Split |
|---|---|---|
| 2-col deliverables | Item / Details | 45% / 55% |
| 2-col KV (pricing, engagement) | Label / Value | 35% / 65% |
| 2-col KV (savings, impact) | Label / Value | 30% / 70% |
| 3-col ROI | Category / Hours / Value | 45% / 27.5% / 27.5% |
| 3-col pricing bundle | Item / Individual / Bundle | 40% / 30% / 30% |
| 3-col timeline | Week / Focus / Deliverable | 12% / 44% / 44% |
| 3-col rebrand/transition | Component / What Changes / Effort | 30% / 45% / 25% |

---

## Workflow

### Step 1 — Gather Information

Minimum required: client name and contact(s), what's being proposed, pricing.

If missing, ask before proceeding. Nice-to-haves that can be estimated: hours-saved estimates, ROI, timeline, case studies.

### Step 2 — Check Logo File

```python
import os
if not os.path.exists('/home/claude/vv-logo.png'):
    import shutil
    shutil.copy('/mnt/user-data/uploads/vv-logo.png', '/home/claude/vv-logo.png')
```

### Step 3 — Build the PDF

Use the boilerplate above. Build sections with `add_section()`. Use `make_table()` for data tables, `make_kv_table()` for label/value pairs, and `B()` for inline blue bold labels.

Key requirements:
- `KeepTogether` on all heading + content pairs (handled by `add_section()`)
- `repeatRows=1` on all standard tables
- `on_all_pages` runs on every page including cover
- Logo appears on cover AND last page
- Company name is always **Veteran Vectors** — never "Veteran Vectors LLC"

### Step 4 — Validate

Render every page to images and inspect visually:

```bash
pdftoppm -jpeg -r 150 proposal.pdf qa-page
```

Check every `qa-page-XX.jpg` via the `view` tool:
- Cover: logo on navy band, horizontal rule, centered metadata, no text overflow
- Body pages: section headings in blue, body text dark gray, tables clean
- Last page: logo on navy band before contact line
- Header every page: `VETERAN VECTORS` (blue) + `| CONFIDENTIAL` (gray), top-right
- Footer every page: `Page X` bottom-center, number in blue

If anything looks wrong, fix the script and re-render. Max 3 cycles.

### Step 5 — AI Check (MANDATORY)

Run `ai-check` skill in Full Fix mode before delivering. Extract proposal text, voice-correct against the Anthony/Veteran Vectors voice profile, rebuild with corrected content.

AI check score format: `AI check: [before] → [after]`

### Step 6 — Doc Polish (MANDATORY — auto-triggered after AI check)

Doc-polish fires automatically after AI check completes. Do not wait for the user to ask.

Delivery chain: **Generate → AI check (voice) → Doc-polish (layout) → Deliver**

### Step 7 — Deliver

Present the final PDF. One or two sentences max. Include the AI check score.

---

## Content Generation Rules

1. **Use provided facts verbatim** — Never invent client names, prices, deliverables, or metrics.
2. **Generate connective prose** — Executive summaries, transitions, and "why us" sections written to match the voice guide.
3. **Case studies** — Use Veteran Vectors standard set (defense consulting firm, national insurance FMO, AI talent marketplace) unless user provides alternatives.
4. **ROI estimates** — Use provided numbers. If none given, offer ranges clearly marked as estimates for user confirmation before building.
5. **Pricing** — Never invent. Always use what the user provides.

## Voice Rules

- Direct and conversational — like talking to a colleague, not presenting to a boardroom
- Short sentences. Mix of punchy one-liners and longer connective sentences.
- First person: "I" not "we" unless the full team was involved
- Real numbers always — "2-3 days" not "significant time"
- Call things what they are — if something is broken, say it's broken
- No em dashes in body text — use commas, periods, or colons
- No corporate jargon — no "leverage," "utilize," "streamline," "robust," "seamlessly," "holistic"

## Edge Cases

**Single-system proposal:** Drop bundle comparison columns, "Why Combined" section, and bundle savings table. One deliverables table, one price.

**No case studies:** Skip entirely if user says so (existing clients, small add-ons).

**Non-automation proposal:** Adjust deliverable tables and ROI framing. Cover, structure, and branding stay identical.

**User provides a full brief:** Extract all structured information, map into template, don't ask for what's already there.

## Error Handling

| Error | Cause | Fix |
|---|---|---|
| ReportLab not installed | Missing dependency | `pip install reportlab Pillow --break-system-packages` |
| Logo file not found | Not copied to /home/claude | Copy from /mnt/user-data/uploads/vv-logo.png |
| PDF renders blank | Story list empty or PageBreak only | Verify sections are appended after PageBreak |
| Table overflows page | Col widths exceed CONTENT_W | Recalculate — widths must sum to CONTENT_W exactly |
| Font not found | Helvetica missing (rare) | Use reportlab.lib.fonts registered defaults |
| Network disabled | Can't pip install | Inform user, ask them to enable network |
