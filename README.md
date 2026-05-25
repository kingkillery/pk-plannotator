<p align="center">
  <img src="apps/marketing/public/og-image.webp" alt="Plannotator" width="80%" />
</p>

# pk-plannotator

Private PK build of Plannotator for interactive plan and code review with AI coding agents. Mark up plans or code diffs in a visual UI, review revisions, and send structured feedback back to **Claude Code**, **Copilot CLI**, **Gemini CLI**, **OpenCode**, **Pi**, and **Codex**.

## Quickstart

### 1. Install the CLI

Use npm if you already have Node and Bun installed:

```bash
npm install -g pk-plannotator
```

Or use the hosted installer:

```bash
curl -fsSL https://plan.artificialgarden.org/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://plan.artificialgarden.org/install.ps1 | iex
```

### 2. Verify the command

The npm package installs both command names, and both resolve to this PK build:

```bash
pk-plannotator --version
plannotator --version
```

Both should print `pk-plannotator 0.19.22-pk.1`.

### 3. Add the Claude Code plugin

In Claude Code:

```text
/plugin marketplace add kingkillery/pk-plannotator
/plugin install plannotator@plannotator
```

Restart Claude Code after installing the plugin.

### 4. Start reviewing

Use plan mode normally, or run one of the helper commands:

```text
/plannotator-review
/plannotator-review <github-pr-url>
/plannotator-annotate <file.md>
/plannotator-last
```

Share links are hash-only by default for small plans. Large-plan upload is disabled unless you configure `PLANNOTATOR_PASTE_URL`; when configured, uploaded plans are encrypted before they leave the browser.

**Plan Mode Demos:**
<table>
<tr>
<td align="center" width="50%">
<h3>Claude Code</h3>
<a href="https://www.youtube.com/watch?v=a_AT7cEN_9I">
<img src="apps/marketing/public/youtube.png" alt="Claude Code Demo" width="100%" />
</a>
<p><a href="https://www.youtube.com/watch?v=a_AT7cEN_9I">Watch Demo</a></p>
</td>
<td align="center" width="50%">
<h3>OpenCode</h3>
<a href="https://youtu.be/_N7uo0EFI-U">
<img src="apps/marketing/public/youtube-opencode.png" alt="OpenCode Demo" width="100%" />
</a>
<p><a href="https://youtu.be/_N7uo0EFI-U">Watch Demo</a></p>
</td>
</tr>
</table>

**New:** [Code Review](https://github.com/kingkillery/pk-plannotator)


### Features

<table>
<tr><td><strong>Visual Plan Review</strong></td><td>Built-in hook</td><td>Approve or deny agent plans with inline annotations</td></tr>
<tr><td><strong>Plan Diff</strong></td><td>Automatic</td><td>See what changed when the agent revises a plan</td></tr>
<tr><td><strong>Code Review</strong></td><td><code>/plannotator-review</code></td><td>View git diffs or remote PRs. Package annotations and ask AI about the code as you review.</td></tr>
<tr><td><strong>Annotate Any File</strong></td><td><code>/plannotator-annotate</code></td><td>Annotate any markdown file and send feedback to your agent</td></tr>
<tr><td><strong>Annotate Last Message</strong></td><td><code>/plannotator-last</code></td><td>Annotate the agent's last response and send structured feedback</td></tr>
</table>

#### Sharing Plans

Plannotator lets you privately share plans, annotations, and feedback with colleagues. For example, a colleague can annotate a shared plan, and you can import their feedback to send directly back to the coding agent.

**Small plans** are encoded entirely in the URL hash. No server involved, nothing stored anywhere.

**Large plans** can use a short link service with **end-to-end encryption** when `PLANNOTATOR_PASTE_URL` is configured. Your plan is encrypted with AES-256-GCM in your browser before upload. The server stores only ciphertext it cannot read. The decryption key lives only in the URL you share. Without a configured paste service, sharing falls back to hash-only URLs and uploads nothing.

- Zero-knowledge storage, similar to [PrivateBin](https://privatebin.info/)
- Fully open source and **self-hostable** ([see docs](apps/marketing/src/content/docs/guides/sharing-and-collaboration.md))

## Install

- [Claude Code](#install-for-claude-code)
- [Copilot CLI](#install-for-copilot-cli)
- [Gemini CLI](#install-for-gemini-cli)
- [OpenCode](#install-for-opencode)
- [Pi](#install-for-pi)
- [Codex](#install-for-codex)

## Install for Claude Code

**Install the `plannotator` command:**

**macOS / Linux / WSL:**

```bash
curl -fsSL https://plan.artificialgarden.org/install.sh | bash
```

**Windows PowerShell:**

```powershell
irm https://plan.artificialgarden.org/install.ps1 | iex
```

**Then in Claude Code:**

```
/plugin marketplace add kingkillery/pk-plannotator
/plugin install plannotator@plannotator

# IMPORTANT: Restart Claude Code after plugin install
```

See [apps/hook/README.md](apps/hook/README.md) for detailed installation instructions including a `manual hook` approach.

---

## Install for Copilot CLI

**Install the `plannotator` command:**

**macOS / Linux / WSL:**

```bash
curl -fsSL https://plan.artificialgarden.org/install.sh | bash
```

**Windows PowerShell:**

```powershell
irm https://plan.artificialgarden.org/install.ps1 | iex
```

**Then in Copilot CLI:**

```
/plugin marketplace add kingkillery/pk-plannotator
/plugin install plannotator-copilot@plannotator
```

Restart Copilot CLI after plugin install. Plan review activates automatically when you use plan mode (`Shift+Tab` to enter plan mode).

See [apps/copilot/README.md](apps/copilot/README.md) for details.

---

## Install for Gemini CLI

**Install the `plannotator` command:**

**macOS / Linux / WSL:**

```bash
curl -fsSL https://plan.artificialgarden.org/install.sh | bash
```

**Windows PowerShell:**

```powershell
irm https://plan.artificialgarden.org/install.ps1 | iex
```

The installer auto-detects Gemini CLI (checks for `~/.gemini`) and configures the plan review hook and policy. It also installs `/plannotator-review` and `/plannotator-annotate` slash commands.

**Then in Gemini CLI:**

```
/plan                              # Enter plan mode — plans open in your browser
/plannotator-review                # Code review for current changes
/plannotator-review <pr-url>       # Review a GitHub pull request
/plannotator-annotate <file.md>    # Annotate a markdown file
```

Requires Gemini CLI 0.36.0 or later.

See [apps/gemini/README.md](apps/gemini/README.md) for details.

---

## Install for OpenCode

Add to your `opencode.json`:

```json
{
  "plugin": ["@plannotator/opencode@latest"]
}
```

**Run the install script** to get `/plannotator-review`:

```bash
curl -fsSL https://plan.artificialgarden.org/install.sh | bash
```

**Windows:**
```powershell
irm https://plan.artificialgarden.org/install.ps1 | iex
```

This also clears any cached plugin versions. Then restart OpenCode.

---

## Install for Pi

```bash
pi install npm:@plannotator/pi-extension
```

Then start Pi with `--plan` to enter plan mode, or toggle it during a session with `/plannotator`.

See [apps/pi-extension/README.md](apps/pi-extension/README.md) for full usage details, commands, and flags.

---

## Install for Codex

**Install the `plannotator` command:**

**macOS / Linux / WSL:**

```bash
curl -fsSL https://plan.artificialgarden.org/install.sh | bash
```

**Windows PowerShell:**

```powershell
irm https://plan.artificialgarden.org/install.ps1 | iex
```

**Then in Codex — feedback flows back into the agent loop automatically:**

```
!plannotator review           # Code review for current changes
!plannotator review <pr-url>  # Review a GitHub pull request
!plannotator annotate file.md # Annotate a markdown file
!plannotator last             # Annotate the last agent message
```

Plan mode is not yet supported.

See [apps/codex/README.md](apps/codex/README.md) for details.

---

## How It Works

When your AI agent finishes planning, Plannotator:

1. Opens the Plannotator UI in your browser
2. Lets you annotate the plan visually (delete, insert, replace, comment)
3. **Approve** → Agent proceeds with implementation
4. **Request changes** → Your annotations are sent back as structured feedback

(Similar flow for code review, except you can also comment on specific lines of code diffs)

---

## License

Copyright 2025-2026 kingkillery

This project is licensed under either of

- [Apache License, Version 2.0](LICENSE-APACHE) ([http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0))
- [MIT license](LICENSE-MIT) ([http://opensource.org/licenses/MIT](http://opensource.org/licenses/MIT))

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in this project by you, as defined in the Apache-2.0 license,
shall be dual licensed as above, without any additional terms or conditions.
