# PowerShell 7 Setup

Make PowerShell 7 on Windows feel like my fish setup (almost-stock fish +
`jethrokuan/fzf`, `jethrokuan/z`, `pure-fish/pure`). Snapshot as of 2026-07-19.

## Overview

| Piece | Choice | fish equivalent |
|---|---|---|
| Shell | PowerShell 7 (`pwsh`, installed from Microsoft Store) | fish |
| Prompt | starship (config shared with fish in WSL) | pure-fish/pure |
| Fuzzy find | fzf + PSFzf module (`Ctrl+T` / `Ctrl+R` / `Alt+C`) | jethrokuan/fzf |
| Dir jumping | zoxide (`z`, abbr `j`) | jethrokuan/z |
| Code search | ripgrep (`rg`, abbr `ag`) | ag (the silver searcher) |
| File find | fd (replaces `ag -g`, [why](https://caillou.ch/blog/2026-07-19-replacing-ag-with-rg-and-fd/)) | fd |
| Abbreviations | hand-rolled PSReadLine key handlers in profile | fish `abbr` |
| Autosuggestions | PSReadLine (built-in, on by default in pwsh 7.6+) | fish built-in |
| Autocd (`..`, `../..`, `src`) | `CommandNotFoundAction` hook in profile | fish built-in |
| Git worktrees | worktrunk (`git-wt`; bare `wt` is shadowed by Windows Terminal, see below) | none |

## File locations

| What | Path |
|---|---|
| pwsh 7 profile | `C:\Users\<user>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| Windows PowerShell 5.1 profile (legacy, kept for old shell) | `C:\Users\<user>\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` |
| starship config (shared with fish/WSL) | `~\.config\starship.toml` |
| Command history (shared by 5.1 and 7) | `%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt` |
| pwsh 7 user modules (PSFzf, …) | `C:\Users\<user>\Documents\PowerShell\Modules\` |

Two gotchas:

- PowerShell 5.1 and PowerShell 7 are separate programs with **separate**
  profile/module folders (`WindowsPowerShell` vs `PowerShell`), but they share
  history. Modules must be installed once per shell edition.
- If your organization redirects Documents with OneDrive **Known Folder Move**,
  the profile paths above land under `C:\Users\<user>\OneDrive - <Company>\Documents\...`
  instead — `$PROFILE` is hard-wired to the Documents known folder and follows
  the redirection. Check with `Split-Path $PROFILE`.

## Reproduce from scratch

```powershell
# 1. Tools (winget)
winget install Microsoft.PowerShell        # or from Microsoft Store
winget install Starship.Starship
winget install junegunn.fzf
winget install ajeetdsouza.zoxide
winget install BurntSushi.ripgrep.MSVC
winget install sharkdp.fd

# Tools for Claude Code
winget install jqlang.jq
winget install pnpm.pnpm
winget install max-sixty.worktrunk

# 2. Modules (run inside pwsh 7 — restart terminal first so PATH is fresh)
Install-PSResource -Name PSFzf -Scope CurrentUser -TrustRepository -AcceptLicense

# 3. Config files — copy from this repo (see below), then open a new tab.

# 4. Windows Terminal: Settings > Startup > Default profile = "PowerShell"
```

Copy the files in this repo to their targets:

| Repo file | Target |
|---|---|
| [`profiles/PowerShell/Microsoft.PowerShell_profile.ps1`](profiles/PowerShell/Microsoft.PowerShell_profile.ps1) | `(Split-Path $PROFILE)` in pwsh 7 |
| [`profiles/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`](profiles/WindowsPowerShell/Microsoft.PowerShell_profile.ps1) | `(Split-Path $PROFILE)` in Windows PowerShell 5.1 |
| [`starship.toml`](starship.toml) | `~\.config\starship.toml` |

## The profile

[`profiles/PowerShell/Microsoft.PowerShell_profile.ps1`](profiles/PowerShell/Microsoft.PowerShell_profile.ps1)
does five things: starship prompt, PSFzf key chords, zoxide init, fish-style
autocd, and fish-style abbreviations — a `$global:abbrs` table plus two
PSReadLine key handlers that expand the first word on `Space` (editable before
you run) or `Enter` (expand, then run).

Autocd hooks `$ExecutionContext.InvokeCommand.CommandNotFoundAction`: when a
typed command doesn't exist but names a directory, it `Set-Location`s there.
Generic — no per-pattern aliases — so `..`, `../..`, `..\..`, `~`, `src`,
`./build` all work. Two gotchas baked into the snippet: PowerShell retries a
failed lookup as `get-<name>` before the bare name (and `get-../..` passes
`Test-Path` on Windows, so that pass must be skipped), and the replacement
script block receives no arguments (hence the closure). Quoted paths
(`'C:\Program Files'`) are string expressions to the parser and just echo —
use `cd` for those.

The [5.1 profile](profiles/WindowsPowerShell/Microsoft.PowerShell_profile.ps1)
is the same **minus** the PSFzf and zoxide lines (PSFzf is only installed for
pwsh 7). Autocd and abbreviation changes are maintained in both copies.

Caveat: avoid abbreviations that shadow built-in PowerShell aliases (e.g. `gc`
is `Get-Content`, `gp` is `Get-ItemProperty` — check with `Get-Alias <name>`).

## Claude Code tooling

The shared Claude Code setup (`~/.claude`, synced across machines) expects
these on the PATH:

- `jqlang.jq` — jq. The memory-sync hook, the statusline and the install
  script parse JSON with it.
- `pnpm.pnpm` — pnpm. The from-devops-ticket script installs its dependencies
  with it.
- `max-sixty.worktrunk` — worktrunk. Git worktree manager; nothing in the
  setup depends on it. winget adds both `wt` and `git-wt`, but on Windows
  bare `wt` keeps resolving to Windows Terminal (`WindowsApps\wt.exe` comes
  first in the user PATH), so call it as `git-wt` or move the worktrunk
  package directory ahead of `WindowsApps` in the user PATH.

Claude Code's Bash tool is Git for Windows bash (`C:\Program Files\Git\usr\bin\bash.exe`),
not pwsh. winget installs land in the *user* PATH, which a running Claude Code
session does not re-read: restart Claude Code after installing.

**Developer Mode** is required so Git Bash (and the setup's install script)
can create real symlinks without admin rights. Settings > System > For
developers > Developer Mode. Check the state from any shell:

```powershell
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense
```

`0x1` means on; `0x0` or "unable to find the specified registry key or
value" means off. Without it, `MSYS=winsymlinks:nativestrict ln -s t l` in Git
Bash fails with `Operation not permitted`. (From Git Bash, prefix the
`reg query` with `MSYS_NO_PATHCONV=1`, otherwise `/v` is mangled into a path.)

## starship.toml

[`starship.toml`](starship.toml) — shared with fish in WSL, so changes affect
both. A minimal config with the git dirty/state indicators grafted from
`starship preset pure-preset`.

> ⚠️ Six "empty-looking" `git_status` values in the file are **zero-width
> spaces** (U+200B), copied from the pure preset: any dirty state collapses
> into the single `*`. Copy the file itself, not retyped text — or regenerate
> those six lines with `[char]0x200B` if in doubt.

## Daily-driver cheat sheet

| Key / command | Does |
|---|---|
| `Ctrl+R` | fuzzy history search (fzf) |
| `Ctrl+T` | fuzzy file picker, inserts path (fzf) |
| `Alt+C` | fuzzy-pick a directory and cd into it (fzf) |
| `z <fragment>` / `j <fragment>` | jump to a frecent directory (zoxide) |
| `zi <fragment>` | zoxide jump with interactive fzf picker |
| `→` | accept the gray inline autosuggestion |
| `F2` | toggle autosuggestion view: list ↔ inline (profile defaults to list) |
| `abbr` + `Space`/`Enter` | expand abbreviation (see table in profile) |
| `..` / `../..` / `<dir>` | cd there — any directory typed as a command (autocd) |
| `fd <pattern>` | find files by name (recursive, .gitignore-aware) |
| `rg <pattern>` | search file contents (abbr `ag` expands to `rg -S`) |

## Versions at time of writing

pwsh 7.6.3 · PSReadLine 2.4.5 · starship (system-wide, Program Files) ·
fzf 0.74.0 · zoxide 0.10.0 · ripgrep 15.2.0 · fd 10.4.2 · PSFzf 2.7.12

2026-09-28 (Claude Code tooling): pwsh 7.6.6 · winget 1.29.380 · Git for
Windows 2.55.0 (bash 5.3.15) · Claude Code 2.1.283 · node 24.15.0 · pnpm 11.24.0 ·
jq 1.8.2 · worktrunk 0.80.0 · ripgrep 15.2.0 · fd 10.4.2 · azure-cli 2.88.0

## Leftovers / TODO

- zoxide starts with an empty database; it learns directories as you `cd`/`z`
  around. (Optionally `zoxide import` from the WSL fish db.)
