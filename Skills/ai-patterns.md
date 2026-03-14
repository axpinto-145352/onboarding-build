# AI Detection Patterns Reference

Comprehensive catalog of AI-generated content patterns, organized by category with severity ratings, scoring guidance, and calibration anchors.

---

## How to Use This File

For each flag found during a scan, record: the exact text, its location, which category below it falls into, its severity (HIGH / MEDIUM / LOW), and the suggested fix. Severity drives the score weight and determines Fix Critical eligibility.

---

## Category 1 — Dead Giveaway Words and Phrases

These are vocabulary choices that real humans almost never use in conversational or business writing but that AI models default to constantly.

**Severity: HIGH**

| AI Word/Phrase | Why It's a Tell | Replace With |
|---|---|---|
| leverage (as a verb) | No one says "leverage your network" in real conversation | use, tap into, make the most of |
| utilize | Always "use" in real writing | use |
| streamline | Corporate filler, means nothing specific | cut, simplify, speed up [specific thing] |
| robust | Used by AI to mean "good" or "complete" | strong, solid, complete, reliable |
| seamlessly | Almost never true, always AI | smoothly, without friction, without interruption |
| comprehensive | AI's favorite word for "thorough" | thorough, complete, full, covers everything |
| delve | No human uses this word in business writing | dig into, look at, explore |
| multifaceted | AI filler for "complex" | complex, layered, involves several things |
| nuanced | Overused AI qualifier | specific, subtle, more complicated than it looks |
| holistic | Means nothing in most contexts | complete, end-to-end, covers all of it |
| synergy / synergies | Corporate/AI filler | [describe what actually happens] |
| foster | AI's word for "build" or "create" | build, create, encourage, grow |
| facilitate | AI's word for "help" or "make possible" | help, enable, make possible |
| paramount | AI's word for "important" | critical, essential, the most important thing |
| imperative | Same as paramount | critical, essential, you need to |
| ensure | AI's hedge word | make sure, confirm, guarantee |
| endeavor | Never used in real conversation | try, work to, aim to |
| commence | Nobody says this | start, begin |
| prior to | AI's version of "before" | before |
| in order to | AI padding | to |
| it is worth noting | AI throat-clearing | [just say the thing] |
| it is important to note | Same | [just say the thing] |
| at the end of the day | AI cliché | ultimately, in practice, what it comes down to |
| in today's landscape | AI scene-setting cliché | right now, today, these days |
| in today's fast-paced world | Peak AI opener cliché | [rewrite the opener entirely] |
| game-changer | Overused AI hype | [describe the actual impact] |
| cutting-edge | AI hype filler | current, new, latest, advanced |
| state-of-the-art | Same | current, best available, latest |
| best-in-class | Same | top, leading, strongest |
| empower | AI's word for "help" or "let" | help, let, enable, give [person] the ability to |
| unlock | AI's word for "access" or "get" | access, reach, get to, open up |
| dive deep / deep dive | AI cliché | look closely at, examine, go through |
| pivot | Overused in AI business writing | shift, change direction, move to |
| harness | AI's word for "use" | use, apply, take advantage of |
| navigate | AI filler for "handle" or "deal with" | handle, deal with, get through, manage |
| landscape | AI's vague scene word | market, space, field, industry, situation |
| ecosystem | AI's word for "group of tools/companies" | tools, companies, industry, network |
| actionable | AI qualifier that adds nothing | [just say the action] |
| impactful | AI's vague positive | [say what the impact actually is] |
| moving forward | AI transition filler | from here, going forward, next |
| going forward | Same | next, from here, after this |

**Severity: MEDIUM**

| AI Word/Phrase | Why It's a Tell | Replace With |
|---|---|---|
| moreover | Overused AI connector | also, and, on top of that |
| furthermore | Same | also, and, beyond that |
| nevertheless | AI's word for "but" or "still" | but, still, even so |
| consequently | AI's word for "so" | so, as a result, that's why |
| subsequently | AI's word for "then" or "after" | then, after that, next |
| in conclusion | AI report outro | [just end the piece or say "the bottom line is"] |
| to summarize | Same | [just summarize without announcing it] |
| in summary | Same | [just summarize] |
| overall | AI wrap-up filler | [just make the point] |
| when it comes to | AI wind-up phrase | for, with, on |
| in terms of | AI filler | for, on, about, regarding |
| with regard to | Same | about, on, for |
| as previously mentioned | AI callback filler | [just say it again or don't] |
| as mentioned above | Same | [just reference directly] |

---

## Category 2 — Structural Patterns

These are document-level patterns that reveal AI authorship even when word choice is fine.

**Severity: HIGH**

- **Uniform paragraph length**: Every paragraph is 3-5 sentences. Real writing has one-liners, short punchy paragraphs, and occasionally longer ones. AI defaults to identical paragraph sizes.

- **Sweeping opener → specific narrowing**: AI almost always opens with a broad statement ("In today's world of X, businesses face Y..."), then narrows to the specific point. Real writers often open with the specific point immediately.

- **Tidy restating conclusion**: AI ends documents with a summary paragraph that essentially repeats what was just said. Real writing either ends with a call to action, a question, a final insight, or just stops.

- **Perfect parallel structure throughout**: Every list item follows the exact same grammar structure. Every section has the same opening → evidence → conclusion format. Real writing breaks structure occasionally.

- **Tripling**: AI constantly groups things in threes: "efficiency, effectiveness, and impact." Real writing doesn't have this compulsion.

- **Every section has a heading**: AI over-structures everything with headers, even for short content that doesn't need navigation aids.

**Severity: MEDIUM**

- **Numbered lists for everything**: AI converts natural prose into numbered lists even when sequence doesn't matter.

- **Consistent transition placement**: Every paragraph opens with a transition word. Real writing uses transitions selectively.

- **Balanced section lengths**: Every section in a document is approximately the same length. Real documents have short sections and long ones based on content needs.

- **No tangents or digressions**: AI stays perfectly on-topic. Real human writing occasionally includes a related aside or personal note.

---

## Category 3 — Punctuation and Symbol Tells

**Severity: HIGH**

- **Em dash overuse**: Using em dashes (—) more than once or twice in a short document, or using them in every other sentence. AI uses em dashes as a default connector instead of choosing the right punctuation. **Kill all em dashes in body text. Replace with: period, comma, colon, semicolon, or restructured sentence.** Em dashes are acceptable in headlines/titles only as a visual separator.

- **Ellipsis abuse**: Using ... to create fake suspense or trailing thoughts. Real writers use periods.

- **Excessive parenthetical asides**: AI constantly adds (note: ...) or (see above) or (this is important) inside sentences.

**Severity: MEDIUM**

- **Oxford comma everywhere, perfectly consistent**: AI is robotically consistent about punctuation rules. Real human writers are occasionally inconsistent.

- **Perfect quotation mark usage**: AI never gets confused about single vs. double quotes. Human writers sometimes do.

- **Colon + list pattern**: AI overuses "here are the three things: [list]" structures in body text where prose would read better.

---

## Category 4 — Sentence Construction Patterns

**Severity: HIGH**

- **Passive voice clustering**: More than 2-3 passive constructions per page. AI defaults to passive when describing processes ("The data is processed by...") where humans say "it processes the data."

- **Gerund opener clusters**: Starting multiple consecutive paragraphs or sentences with "-ing" words ("Leveraging the platform...", "Building on this...", "Implementing these steps...").

- **The [noun] of [noun] construction**: "The power of automation," "The importance of strategy," "The value of consistency." AI uses this constantly. Real writers name the thing directly.

- **Verb-less "importantly" sentences**: "Importantly, this means..." or "Notably, the system..." AI uses these as emphasis markers. Real writers build emphasis through sentence structure.

**Severity: MEDIUM**

- **If-then construction overuse**: AI loves "If X, then Y" constructions. Fine occasionally, but clusters of them signal AI.

- **"This means that" connectors**: AI uses "This means that..." to link ideas instead of just making the next point.

- **"Not only... but also"**: Classic AI construction. Real writers just make both points.

- **Sentence length uniformity**: Every sentence is 15-25 words. Real writing mixes 4-word punches with longer explanations.

---

## Category 5 — Transition and Connector Overuse

AI transitions feel mechanical because they're inserted with perfect regularity rather than when they're actually needed.

**Severity: HIGH**

| AI Transition | Problem | Fix |
|---|---|---|
| However, | Used to start almost every paragraph that introduces any qualification | [make the contrast clear from the sentence itself, or use "but"] |
| Additionally, | AI's default "and also" | [just continue the thought, or use "also," "and," "on top of that"] |
| Furthermore, | Formal academic connector used in business writing | [same as above] |
| In addition, | Same as additionally | [same] |
| Therefore, | AI's logical connector | so, that's why, which means |
| Thus, | Same | so, which means, that's why |
| Hence, | Same | so, that's why |
| Ultimately, | AI's wrap-up word | [just make the final point] |
| Notably, | AI's emphasis marker | [build emphasis through sentence structure] |
| Importantly, | Same | [same] |
| Significantly, | Same | [same] |
| Essentially, | AI's summarizer | basically, in short, what this means is |
| Specifically, | AI's detail introducer | [just get specific] |

**Severity: MEDIUM**

- **"First... Second... Third..." for non-sequential items**: Using numbered connectors when the items aren't actually in order.
- **"On the other hand"**: Overused AI contrast marker.
- **"In contrast"**: Same.
- **"As a result"**: Fine occasionally; flags when it appears more than twice per page.

---

## Category 6 — Hedging and Qualification Patterns

AI hedges excessively to appear balanced. Real confident writing makes assertions.

**Severity: HIGH**

- **"It's worth noting that..."** — AI throat-clearing. Remove entirely and just say the thing.
- **"It's important to remember that..."** — Same.
- **"One might argue that..."** — Academic hedging in non-academic content.
- **"While this may vary..."** — Unnecessary qualification of stated facts.
- **"In most cases..."** / **"Generally speaking..."** — Fine once; flags when clustered.
- **"It depends on X, Y, and Z"** without actually explaining the dependencies — vague hedging.

**Severity: MEDIUM**

- **Double qualification**: "It can often be helpful to consider potentially..." — stacked hedges.
- **"Some might say"** / **"Many experts believe"** — anonymous authority hedging.
- **"This is not to say that..."** — AI preemptive defense against pushback.

---

## Category 7 — Tone Patterns

**Severity: HIGH**

- **Uniform formal register**: The tone never changes throughout a document. Real writing shifts slightly — more casual in examples, more precise in technical sections.

- **No personality, opinion, or voice**: AI produces content that could have been written by anyone. There are no distinctive phrases, no opinions, no moments that reveal the writer's perspective. If you can imagine anyone else writing it, flag it.

- **Excessive positivity**: AI avoids stating that anything is bad, broken, wrong, or a mistake. Everything is "an opportunity," a "challenge," or a "learning." Real writing calls things what they are.

- **No contractions in formal contexts**: AI sometimes avoids contractions entirely to sound professional. Real professional writing uses contractions naturally.

- **"Perfect" examples**: All examples in AI content work out cleanly and positively. Real examples sometimes fail or have complications.

**Severity: MEDIUM**

- **Consistent sentence formality**: Real writers occasionally write a short punchy sentence that breaks the formal tone. AI maintains consistent formality throughout.

- **No humor, sarcasm, or dry wit**: Unless the context is purely technical, complete absence of any personality is a moderate flag.

---

## Category 8 — Formatting Tells

**Severity: HIGH**

- **Bold for every important phrase**: AI bolds 5-10 phrases per page. Real documents bold sparingly — only for genuine navigation or critical callouts.

- **Bullet point everything**: Converting information that would read naturally as prose into bullet lists. If every section is a bulleted list, the document is probably AI-generated.

- **Identical bullet structure**: Every bullet follows the same grammatical format (noun phrase, or verb phrase, or sentence). Real lists are occasionally inconsistent.

- **Headers for sections that don't need them**: A 3-paragraph email doesn't need "Introduction," "Key Points," and "Conclusion" headers.

**Severity: MEDIUM**

- **Table for everything**: AI converts data that would be fine as prose into tables.
- **Numbered lists for non-sequential items**: Using "1. 2. 3." when the items have no particular order.
- **Consistent emoji placement**: If emojis appear at consistent positions (always at line start, always after bullets), it's a formatting tell.

---

## Scoring Guide

### Base Score Calculation

Start at 0. Add points for each flag found:

| Severity | Points Per Flag |
|---|---|
| HIGH | 8-12 points |
| MEDIUM | 3-5 points |
| LOW | 1-2 points |

Adjust for density: if flags are clustered (3+ HIGH flags in a single paragraph), add 5 bonus points. If the document is otherwise clean with only 1-2 isolated flags, subtract 5 points.

Cap at 100.

### Score Labels

| Score | Label | Action |
|---|---|---|
| 0-15 | Clearly human | Pass. Note any isolated flags in chat. No fixes needed unless user requests. |
| 16-30 | Likely human with minor flags | Light pass. Fix HIGH flags only unless Full Fix requested. |
| 31-50 | Uncertain — mixed signals | Full Fix recommended. Significant AI patterns present alongside human elements. |
| 51-70 | Likely AI-generated | Full Fix required. Multiple categories flagged. |
| 71-85 | Strongly AI-generated | Full Fix required. Consider whether surgical fixes are enough or if rewrite is needed. |
| 86-100 | Obviously AI-generated | Recommend ground-up rewrite. Still attempt fixes if user wants them. |

### Score Confidence

| Content Length | Confidence |
|---|---|
| Under 50 words | LOW — single phrases distort the score |
| 50-200 words | MEDIUM — directionally accurate |
| 200-500 words | HIGH — reliable score |
| Over 500 words | VERY HIGH — strong signal |

### Calibration Anchors

**Score ~15 (Clearly human):** Natural voice throughout, short and long sentences mixed, occasional imperfect transition, no AI vocabulary. Might have one "however" or one "ensure." Clearly one person's voice.

**Score ~25 (Likely human):** Mostly natural voice with 2-3 minor flags. Maybe one "leverage" or slightly uniform paragraph lengths. Feels real but has been lightly polished.

**Score ~50 (Uncertain):** Uniform paragraph lengths, 3-5 AI vocabulary flags, some structural repetition ("Furthermore... Additionally... In conclusion..."), but genuine personal examples or insights mixed in. Could go either way.

**Score ~75 (Strongly AI):** Multiple HIGH category hits — em dashes throughout, AI vocabulary (leverage, streamline, robust), uniform 3-5 sentence paragraphs, sweeping opener, tidy restating conclusion, bold phrases every few sentences, no personality or tangents.

**Score ~90 (Obviously AI):** Hits nearly every category. Perfect structure, AI vocabulary in every paragraph, em dashes and bold throughout, opener is a cliché, conclusion restates everything, no voice whatsoever.

---

## False Positive Rules

These are patterns that look like AI flags but may be legitimate. Apply genre awareness before flagging.

- **Semicolons in legal, academic, or formal reports**: Normal. Only flag semicolons in conversational content like emails or LinkedIn posts.
- **Headers in long documents (5+ pages)**: Legitimate navigation aid, not a formatting tell.
- **Numbered lists for actual processes**: If the items are genuinely sequential steps, numbered lists are correct.
- **Formal register in contracts, legal briefs, medical documentation**: Expected. Formality is not an AI tell in these genres.
- **Technical precision language in technical documentation**: "Utilize" in an API spec is less of a tell than in a client email.
- **Single "Additionally" or "However" in a long document**: Not a flag. Only flag when these appear more than 2-3 times per page.
