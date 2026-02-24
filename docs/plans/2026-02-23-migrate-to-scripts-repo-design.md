# Migrate shell-scripts to scripts repo

## Context

The `shell-scripts` repo is being consolidated into the `scripts` repo — the new central repository for all personal scripts (Python CLI tools in `src/`, bash scripts in `bin/`).

## Scope

- **Move:** `duplicity-restore.bash` → `scripts/bin/duplicity-restore.bash`
- **Discard:** `sourced/` library scripts (formatting, prompting, randomization) — obsolete; Python is the preferred approach for code reuse
- **Discard:** `gcp/` scripts (create_gcp_service_account, assign_gcp_service_account_iam_roles) — obsolete
- **Archive:** the `shell-scripts` GitHub repo

## Steps

### 1. Modernize and move duplicity-restore.bash

Copy `duplicity-restore.bash` to `scripts/bin/duplicity-restore.bash` with these changes:

- Remove the MIT license header block (lines 3-23) — covered by the repo's license
- Add `set -o noclobber` (missing vs other bin/ scripts)
- Wrap imperative code in `main()` function per CLAUDE.md bash conventions
- Keep the `help()` function as-is (already well-structured)

No functional changes to the duplicity restore logic itself.

### 2. Update scripts repo CLAUDE.md

Add a `duplicity-restore.bash` section to the `scripts` CLAUDE.md documenting:

- Purpose: error-resilient duplicity backup restore wrapper
- Usage examples (already in the help function)
- Location: `bin/duplicity-restore.bash`

### 3. Update shell-scripts README with archive notice

Replace `shell-scripts/README.md` content with a notice:

- State the repo is archived
- Point to the `scripts` repo as the new home
- Note that `duplicity-restore.bash` moved to `scripts/bin/`
- Note that `sourced/` and `gcp/` scripts are retired

### 4. Archive the shell-scripts repo on GitHub

```bash
gh repo archive webyneter/shell-scripts --yes
```

## Bash vs Python analysis

All existing bash scripts in `scripts/bin/` are correctly written in bash. The deciding factor:

| Use bash when | Use Python when |
|---------------|-----------------|
| Wrapping CLI tools (passing flags, env vars) | Parsing structured data (JSON, CSV, YAML) |
| System orchestration (apt, systemctl, ufw) | API interactions (GCP, AWS SDKs) |
| Tmux/terminal session management | Complex error handling with typed exceptions |
| Interactive prompts + simple I/O | Type safety, testing, structured output |
| The script is essentially a `exec` with flags | Business logic beyond flag passing |

### Per-script verdict

| Script | Language | Rationale |
|--------|----------|-----------|
| `duplicity-restore.bash` | Bash | Thin wrapper — passes resilience flags to `duplicity` CLI |
| `bin/tm` | Bash | Tmux API is inherently shell commands |
| `bin/ubuntu-upgrade` | Bash | System-level ops (apt, systemctl, pg_upgradecluster) |
| `bin/cast-to-tv.bash` | Bash | CLI wrapper around `catt` + `fzf` device selection |
| `bin/create-vbox-vm` | Bash | VBoxManage CLI orchestration |
| `remote-access/*.sh` | Bash | System setup (apt, ufw, sshd config deployment) |
| `src/audit/**` | Python | API clients, data models, structured analysis — already Python |
| `src/workspace/**` | Python | Typed installers, Pydantic models, test coverage — already Python |
