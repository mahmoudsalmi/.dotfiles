---
name: sd-notify
description: Notify the user outside the terminal (macOS terminal-notifier and/or ntfy.sh push). Use when a long-running agent is blocked, waiting for approval, failed, or finished.
---

# sd-notify

Run `scripts/notify.sh "<title>" "<message>" [priority] [url]`
(priority: `low` | `default` | `high`; url is opened on click).

Channels (both used when available):
- **terminal-notifier** (macOS desktop).
- **ntfy** when `SD_NTFY_TOPIC` is set (`SD_NTFY_SERVER` defaults to `https://ntfy.sh`).

If no channel is configured, ask the user **once** for an ntfy topic and tell
them to persist it (`export SD_NTFY_TOPIC=...` in their shell rc). Never
hard-code a topic in prompts or repos — anyone knowing it can read the messages.

## When to notify
- `high`: waiting for approval / blocked / failure.
- `default`: iteration or whole task finished, PR created/updated.
- Never for routine progress.

Message style: `<key>: <what happened> — <what you need from the user>`.
