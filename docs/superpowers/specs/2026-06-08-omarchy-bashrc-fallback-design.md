# Omarchy bashrc Fallback Design

**Date:** 2026-06-08  
**Scope:** `dot_bashrc` only — desktop configs unchanged

## Goal

Make the shell layer work on non-Omarchy machines (WSL2, headless Linux) without touching or risking the existing Omarchy workflow on desktop machines.

## Approach

Wrap the existing Omarchy source in a file-existence check. If Omarchy is installed, source it as today. If not, an inline fallback block provides equivalent shell config.

```bash
if [[ -f ~/.local/share/omarchy/default/bash/rc ]]; then
  source ~/.local/share/omarchy/default/bash/rc
else
  # inline fallback
fi
```

**Omarchy machines:** zero change to behaviour.  
**Non-Omarchy machines:** get a standalone shell config.

## Fallback Content

Drawn from `basecamp/omarchy` `default/bash/{envs,shell,aliases,init}` and `default/bash/fns/*`, with omarchy-specific pieces stripped.

### envs
- `BAT_THEME=ansi`
- `MANPAGER` set to bat for coloured man pages
- `SUDO_EDITOR="$EDITOR"`
- No `OMARCHY_PATH` or omarchy `PATH` additions

### shell
- `shopt -s histappend`, `HISTCONTROL=ignoreboth`, `HISTSIZE=32768`
- Bash completion (guarded: `/usr/share/bash-completion/bash_completion`)
- `set +h` (required for mise shims)

### aliases
- eza: `ls`, `lsa`, `lt`, `lta` (guarded: `command -v eza`)
- fzf file-find: `ff`, `eff`, `sff()` (guarded: `command -v fzf`)
- Directory shortcuts: `..`, `...`, `....`
- `open()` via `xdg-open` (background, discard output)
- `cd` zoxide wrapper `zd()` (guarded: `command -v zoxide`)
- Git: `g`, `gcm`, `gcam`, `gcad`
- Tools: `t` (tmux attach/new), `d` (docker), `r` (rails), `n()` (nvim)
- Omitted: `c`/`cx`/`ic`/`ix`/`icx` (opencode/claude shortcuts — personal, not core shell)

### functions
- Tmux AI layouts: `tdl`, `tds`, `tdlm`, `tsl`
- Git worktrees: `ga`, `gd`
- Compression: `compress`, `decompress`
- SSH port forwarding: `fip`, `dip`, `lip`
- Omitted: `iso2sd`, `format-drive` (omarchy-specific drive tooling), all `transcode-*` functions

### init
- `mise activate bash` (guarded: `command -v mise`) — deduplicated with existing line
- `starship init bash` (guarded: `command -v starship`)
- `zoxide init bash` (guarded: `command -v zoxide`)
- fzf completions + key-bindings (guarded, sourced from `/usr/share/fzf/`)

## Personal overrides (unchanged, kept after the if/else)
- `alias vim='nvim'`
- `export EDITOR=vim`
- `export PATH="$HOME/.local/bin:$PATH"`
- pnpm PATH block

## What's not changing
- Desktop configs (`hypr/`, `waybar/`, `mako/`, etc.) — already gated by `desktop = true` in chezmoi, untouched
- `.chezmoiignore` — no changes
- Any other chezmoi-managed file

## Risk
None to Omarchy machines — the existing `source` line runs identically when the file exists. The fallback only activates when Omarchy is absent.
