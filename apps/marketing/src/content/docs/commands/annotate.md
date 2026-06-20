---
title: "Annotate"
description: "The /plannotator-annotate slash command for annotating any markdown file."
sidebar:
  order: 12
section: "Commands"
---

The `/plannotator-annotate` command opens any markdown file, demo notes, generated report, spec, or agent artifact in the Plannotator annotation UI.

## Usage

### Slash command (inside an agent session)

```
/plannotator-annotate path/to/file.md
```

The agent runs `plannotator annotate <file>` under the hood. The annotation UI opens in always-on-top Glimpse when enabled or in the browser fallback. When you submit, feedback is returned to the agent as structured output.

### Standalone CLI (outside an agent session)

```bash
plannotator annotate path/to/file.md
```

This starts a local server, opens always-on-top Glimpse when enabled or a browser fallback, and blocks until you submit. The formatted feedback is printed to stdout.

## How it works

```
User runs /plannotator-annotate README.md
        ↓
CLI reads README.md from disk
        ↓
Annotate server starts (random port)
        ↓
Always-on-top Glimpse or browser opens, loads annotation UI
        ↓
/api/plan returns { plan: markdown, mode: "annotate" }
        ↓
User annotates → Send Annotations
        ↓
POST /api/feedback with exported feedback
        ↓
Server prints feedback to stdout, exits
```

## Annotate mode differences

The annotation UI in annotate mode works the same as plan review, with a few changes:

- The "Approve" button is hidden (there's nothing to approve)
- "Send Feedback" becomes **"Send Annotations"**
- `Cmd/Ctrl+Enter` sends annotations instead of approving
- The completion screen says "Annotations Sent" instead of "Plan Approved"

All annotation types work identically — deletions, replacements, comments, insertions, global comments, and image attachments.

Use annotate mode for artifacts that should stay inside the human-in-the-loop review path: demos, generated markdown, specs, release notes, implementation notes, reports, and other reviewable outputs.

## Feedback format

When you send annotations, they're exported as structured markdown:

```markdown
# Plan Feedback

I've reviewed this plan and have 2 pieces of feedback:

## 1. Remove this
` ` `
the selected text
` ` `
> I don't want this in the plan.

## 2. Feedback on: "some highlighted text"
> This needs more detail about error handling.

---
```

The agent receives this and can act on each annotation.

## Server API

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/plan` | GET | Returns `{ plan, mode: "annotate", filePath }` |
| `/api/feedback` | POST | Submit annotations |
| `/api/image` | GET | Serve image by path |
| `/api/upload` | POST | Upload image attachment |

## Environment variables

The annotate server respects the same environment variables as plan review. See the [environment variables reference](/docs/reference/environment-variables/).
