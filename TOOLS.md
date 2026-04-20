# TOOLS.md

Local environment notes live here.

Use this file for machine-specific details that should not live inside shared skills.
Examples: SSH hosts, device names, preferred voices, speaker names, or other local shortcuts.

## Servers

### Alibaba Cloud OpenClaw (47.119.177.99)

- SSH: `ssh -i /Users/jianfengxu/Downloads/has_jianfeng_key.pem root@47.119.177.99`
- Service management: systemd only
  - `systemctl status openclaw`
  - `systemctl restart openclaw`
  - `journalctl -u openclaw -f`
- Do not start OpenClaw with ad-hoc `nohup` or manual background commands on this server
- Feishu plugin hotfix exists as of 2026-04-16:
  - notes: `notes/feishu-plugin-auth-hotfix-2026-04-16.md`
  - patch: `notes/feishu-plugin-auth-hotfix-2026-04-16.patch`
  - archive: `notes/feishu-plugin-auth-hotfix-2026-04-16-files.tar.gz`
  - restore: `notes/restore-feishu-plugin-auth-hotfix.sh`
