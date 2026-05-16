# CLAUDE.md

See `AGENTS.md` for full project conventions. This file exists for backward
compatibility with Claude Code's CLAUDE.md auto-load.

## Pushing changes

Direct push to `main` is policy-blocked. When `git push origin main` is denied
with a direct-push-to-main reason, do NOT surface that as a dead end. Fall
back automatically: create a topic branch at HEAD, reset local `main` to
`origin/main`, push the branch, and open a PR with `gh pr create`. See
`AGENTS.md` → "Pushing changes" for the full rule.
