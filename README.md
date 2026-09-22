# Hey Claudex

**Wake Claude and/or Codex at the times you choose, so their 5-hour usage
window resets land on your peak hours instead of wherever your first message
of the day happens to start them.**

Runs on GitHub Actions - your machine can be off. Works the same on Mac,
Windows and Linux, because nothing runs locally after a one-time setup step.

---

## The problem

Both **Claude Pro/Max** (via Claude Code) and **ChatGPT Plus/Pro with Codex**
meter usage in a rolling **~5-hour window that starts on your first message**,
not on a fixed clock. Sit down and type at 8:30am, and your window quietly
runs out at 1:30pm - often mid-task, and often hours before you'd naturally
take a break.

The trick (a lot of people already do this by hand): send a throwaway message
*before* you actually need the AI, timed so the window's five hours later
lands right when you want it warm. Hey Claudex automates that.

```
            6am    7     8     9    10    11    12    1pm    2     3     4     5    6pm
             |     |     |     |     |     |     |     |     |     |     |     |     |

Without:                    [============ window ============]
                              work ~8:30am-11am  ░░░ dead until 1:30 ░░░

        wake fires
             │
             ▼
With:        [========== window =========]
              idle          work ~8:30am-11am, window resets right on time
```

## What Hey Claudex actually does

At each configured time, it sends one near-zero-content prompt - literally
`"Hey Claude"` or `"Hey Codex"` - using the cheapest model that still counts
toward that account's usage meter. That's it. No tools, no context, no
conversation. Just enough to anchor a fresh window at a time you picked.

- **Both backends, independently.** Enable Claude only, Codex only, or both -
  see the FAQ below.
- **Targets specific clock times**, not "keep it warm 24/7." You choose when
  the reset should land; it doesn't fire into a window you've already started
  yourself (it checks the account's real usage meter first and skips if one's
  already running, so it never wastes a send).
- **Runs on GitHub's servers.** No cron, no Task Scheduler, no "grant this app
  permission to run unattended" on your own PC.

## Is this against the rules?

No - it only ever sends from your own subscription, at the same cost a manual
"hi" would have. It doesn't extract extra quota, doesn't touch anyone else's
account, and doesn't bypass any limit; it just chooses *when* your own first
message of the day lands.

---

## Setup (about 10 minutes)

### 0. Prerequisites

- A GitHub account
- A Claude **Pro or Max** subscription, and/or a ChatGPT subscription with
  **Codex** access
- The `claude` and/or `codex` CLI installed locally (only needed once, to mint
  your token) - see [claude.com/code](https://claude.com/code) or
  [platform.openai.com/docs/codex](https://platform.openai.com/docs/codex)
- The [GitHub CLI](https://cli.github.com) (`gh`), for setting secrets

These are the same three tools on Mac, Windows and Linux - only one command
below differs (noted).

### 1. Get your own copy

Click **Use this template** on the GitHub repo page (not "Fork" - GitHub only
runs scheduled workflows from a repository's own default branch, and a
template gives you that cleanly).

### 2. Add your secrets

> **The most common mistake:** minting a token while logged into a different
> account than the one you actually use day to day. The workflow will run
> green forever while warming the wrong account. Before running the commands
> below, make sure your CLI is logged into the account your Claude/Codex apps
> actually use.

**Claude:**

```bash
claude setup-token
gh secret set CLAUDE_CODE_OAUTH_TOKEN --repo <you>/<your-repo>
# paste the sk-ant-oat... token when prompted
```

**Codex:**

```bash
codex login
gh secret set CODEX_AUTH_JSON --repo <you>/<your-repo> < ~/.codex/auth.json
```

PowerShell (Windows) equivalent for that last line:

```powershell
Get-Content -Raw "$env:USERPROFILE\.codex\auth.json" | gh secret set CODEX_AUTH_JSON --repo <you>/<your-repo>
```

> **Do not run `codex login` a second time anywhere after this**, including
> on your own machine. OpenAI issues one refresh-token family per account -
> a second login revokes the session you just uploaded, and CI starts
> failing with `token_revoked`. If that happens, the fix is just to repeat
> the two commands above once. (Claude doesn't have this problem -
> `claude setup-token` exists specifically for headless/CI use.)

Only want one backend? Just add that one secret - the other job in
`.github/workflows/warm.yml` skips itself automatically (see the FAQ).

**Recommended, optional** - lets Codex survive its own token rotation instead
of slowly going stale on an ephemeral runner:

```bash
gh secret set GH_PAT --repo <you>/<your-repo>
# a fine-grained PAT with "Secrets: read and write" on this repo
```

### 3. Test it

```bash
gh workflow run warm.yml --repo <you>/<your-repo>
gh run watch --repo <you>/<your-repo>
```

A manual run always sends for real. Green `warm-claude` / `warm-codex` means
that account just received a message. Open the Claude or Codex app *before
typing anything* - you should see a session already in progress instead of
"send a message to start."

---

## Adjusting your schedule

GitHub Actions cron entries must be literal UTC times written directly into
`.github/workflows/warm.yml` (they can't be computed at runtime), so you edit
the `- cron:` lines under `on.schedule` to match **your own** peak hours.

The shipped defaults target four resets, chosen so each one lands at a likely
peak and the last one clears out of the way before the next natural cycle:

| Wake fires (local) | Window resets (local) | Why |
|---|---|---|
| ~4:59am | ~10:00am | first peak - mid-morning, fully in work mode |
| ~10:00am | ~3:00pm | second peak - after lunch |
| ~3:01pm | ~8:00pm | third peak - after dinner |
| ~8:02pm | ~1:00am | wind-down - last stretch of the day |

**Tip:** if you have regular automation work that should stop before the next
cycle starts, add a 5th wake around 11:30am so it winds down by ~1am without
colliding with the following day's first window. There's a commented-out
example slot in `warm.yml` for this.

> This copy's `warm.yml` already has the four targets above converted to UTC
> for one specific timezone, and only the Claude backend is active
> (`CODEX_AUTH_JSON` isn't set). If you use this repo as a template, re-convert
> the cron lines for **your own** timezone first - see below.

Convert each local time to UTC (e.g. via
[crontab.guru](https://crontab.guru) or `TZ=UTC date -d '10:00 -0800'`) and
replace the placeholder `- cron:` lines. Note: the window anchors to the
*exact minute* of the wake message, not floored to the hour, so pick round
target times.

---

## FAQ

**I have both a Claude and a Codex subscription (and both CLIs installed) -
which one does this use? Can it be both?**

Both, independently, or just one - your choice, controlled entirely by which
secret(s) you add in step 2. `warm-claude` only runs if
`CLAUDE_CODE_OAUTH_TOKEN` is set; `warm-codex` only runs if `CODEX_AUTH_JSON`
is set. Having both CLIs installed locally does not force both jobs to run -
only the secrets do. If the `if:` guard on either job ever misbehaves for you,
the fallback is just deleting the unwanted job block from `warm.yml` directly.

**Do I even need this for Claude specifically?**

Maybe not - Claude Code Web now has a built-in
[Scheduled Task](https://claude.ai/code/scheduled) feature that can send a
timed wake-up natively, no external repo required. Hey Claudex is still
useful if you want Codex covered too, want both backends managed from one
place, or don't want to depend on that feature.

**Why does my Codex warm-up keep failing to actually reset anything, even
though the run is green?**

Almost certainly the model. `scripts/send-codex.sh` defaults to `gpt-5.6-sol`
at low reasoning effort on purpose - **not** a "mini" model. Mini-tier Codex
usage bills a separate bucket that does not register on the account's 5-hour
meter at all: the send succeeds, returns a reply, and never starts a window.
If you change `HEYCLAUDEX_CODEX_MODEL`, verify with step 3 above that a
window actually opens before trusting it.

**How do I know it's warming *my* account and not a stale/wrong login?**

Same check as step 3: open the app before sending anything yourself. A
session already "in progress" with a reset time that isn't 5 hours from now
means it's working.

**Will this stop working if I ignore the repo for a couple of months?**

No - the `heartbeat` job commits once a day specifically so GitHub doesn't
auto-disable the schedule after 60 days of inactivity (its actual trigger for
disabling scheduled workflows).

**How will I know if something breaks?**

You'll get a GitHub notification. A real failure (all 3 retries exhausted)
makes the `notify` job open one issue with the exact recovery commands; it
auto-closes the next time a run succeeds.

**Will rate-limit policies described here change?**

Yes, and they already have mid-2026 - OpenAI has toggled Codex's 5-hour
window off and back on more than once. Treat the schedule here as a
best-effort alignment tool, not a guarantee, and re-check after either
provider announces usage-limit changes.

---

## Prior art

Hey Claudex isn't the first tool built around this idea - credit where due:

- [**vdsmon/claude-warmup**](https://github.com/vdsmon/claude-warmup) - the
  target-time approach this project's scheduling is based on (Claude only).
- [**viseshb/claude-codex-warmer**](https://github.com/viseshb/claude-codex-warmer) -
  covers both Claude and Codex with a continuous always-warm chain; several
  of this project's reliability patterns (retry/backoff, the `notify` and
  `heartbeat` jobs, the live usage-meter check, and the critical
  "don't use a mini model for Codex" finding) come from there.

What's different here: both backends, independently toggleable, targeting
*specific* clock times you choose rather than chaining continuously.

---

## Security notes

- No API keys, no plaintext credentials in the repo - auth lives only in
  encrypted GitHub Actions secrets (masked in logs).
- [`.gitignore`](.gitignore) blocks local `auth.json` / `.env` / token files
  from ever being committed by accident.
- Consider a branch protection ruleset (Settings → Rules → Rulesets) blocking
  force-push and branch deletion on `main`, since the workflow pushes
  heartbeat commits there.

## License

[MIT](LICENSE) - use it, fork it, ship it.
