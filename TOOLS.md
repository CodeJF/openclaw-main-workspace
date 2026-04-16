# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.


## Servers

### Alibaba Cloud OpenClaw (47.119.177.99)

- SSH: `ssh -i /Users/jianfengxu/Downloads/has_jianfeng_key.pem root@47.119.177.99`
- OpenClaw service management: **systemd only**
  - `systemctl status openclaw`
  - `systemctl restart openclaw`
  - `journalctl -u openclaw -f`
- **Do not** use manual `nohup openclaw gateway` or other ad-hoc start methods on this server.
  - Reason: this previously caused duplicate `openclaw` / `openclaw-gateway` processes, port conflicts on `18789`, and restart issues with the systemd-managed `openclaw.service`.
- Feishu plugin on this server has a local hotfix applied as of 2026-04-16.
  - Hotfix notes: `notes/feishu-plugin-auth-hotfix-2026-04-16.md`
  - Patch archive: `notes/feishu-plugin-auth-hotfix-2026-04-16.patch`
  - Full file archive: `notes/feishu-plugin-auth-hotfix-2026-04-16-files.tar.gz`
  - Restore script: `notes/restore-feishu-plugin-auth-hotfix.sh`
- Hotfix purpose:
  - allow non-owner users to complete Feishu OAuth for themselves
  - allow non-owner users to use their own UAT-backed tools after authorization
  - allow self-service batch authorization
  - route explicit "authorize me" requests to real auth card flow instead of manual URL explanation
