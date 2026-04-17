# OpenClaw Git Workflow

## Repositories

This OpenClaw setup is split into 3 GitHub repositories:

1. `openclaw-main-workspace`
   - Local path: `~/.openclaw/workspace`
   - Purpose: main assistant workspace, shared scripts, deployment docs, hotfix notes

2. `openclaw-interviewer`
   - Local path: `~/.openclaw/workspace-interviewer`
   - Purpose: interviewer business workspace and recruiter pipeline

3. `openclaw-resume-intake`
   - Local path: `~/.openclaw/workspace-resume-intake`
   - Purpose: resume intake business docs, scripts, and pipeline assets

## Source of Truth

- Future development happens **locally on macOS**.
- Alibaba Cloud server should normally **only `git pull`**.
- Avoid editing server business files directly unless doing emergency hotfix work.

## Daily Workflow

### Local development

For whichever workspace you changed:

```bash
cd ~/.openclaw/workspace
# or ~/.openclaw/workspace-interviewer
# or ~/.openclaw/workspace-resume-intake

git status
git add .
git commit -m "your message"
git push
```

### Server update

On Alibaba Cloud server, update the corresponding workspace:

```bash
cd /root/.openclaw/workspace
git pull
```

For interviewer:

```bash
cd /root/.openclaw/workspace-interviewer
git pull
```

For resume-intake:

```bash
cd /root/.openclaw/workspace-resume-intake
git pull
```

If OpenClaw main service needs reload/restart:

```bash
systemctl restart openclaw
```

## What should NOT be committed

Do not commit runtime state, secrets, or machine-local artifacts.

Examples:

- `MEMORY.md`
- `memory/`
- `qr.txt`
- `runtime/`
- `.venv/`
- `__pycache__/`
- `config.local.json`
- OAuth/auth profile files
- credentials/tokens
- tar.gz backup bundles
- temporary patch scripts unless intentionally archived

## Workspace ownership notes

### Main workspace

Keep here:
- main assistant rules
- deployment docs
- shared operational notes
- hotfix documentation
- general scripts

Do not keep here long-term:
- resume-intake business pipelines
- temporary migration dumps
- local-only secrets

### Interviewer workspace

Keep here:
- recruiter pipeline
- interviewer business logic
- JD and automation related files

Do not commit:
- runtime outputs
- local virtualenvs
- local config with secrets

### Resume-intake workspace

Keep here:
- resume intake docs
- intake pipeline scripts
- attachment flow rules
- related archived temporary migration scripts if intentionally preserved

## Conflict handling

If local and remote diverge:

```bash
git fetch origin
git status
git pull --rebase
```

If there are conflicts:
1. resolve files manually
2. `git add <files>`
3. `git rebase --continue`

If the server diverges unexpectedly, prefer treating **local GitHub state as canonical** unless a deliberate server-side hotfix was made.

## Server rules

For Alibaba Cloud OpenClaw:
- Use systemd only
- Do not start OpenClaw with ad-hoc `nohup`
- Preferred service management:

```bash
systemctl status openclaw
systemctl restart openclaw
journalctl -u openclaw -f
```

## Migration note

As of 2026-04-17:
- Alibaba Cloud business state was published to GitHub
- local macOS was reorganized into 3 repos
- future workflow is local edit/push, server pull
