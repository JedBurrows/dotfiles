# Omarchy bashrc Fallback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite `dot_bashrc` so Omarchy machines source their existing `bash/rc` unchanged, while non-Omarchy machines (WSL2/headless) get an inline equivalent.

**Architecture:** Single file change — wrap the existing `source omarchy` line in a file-existence guard; add a self-contained `else` block containing the extracted envs, shell settings, aliases, functions, and init calls. Personal overrides remain after the if/else, unchanged.

**Tech Stack:** bash, chezmoi

---

### Task 1: Rewrite dot_bashrc

**Files:**
- Modify: `/home/jed/.local/share/chezmoi/dot_bashrc`

- [ ] **Step 1: Replace the file contents**

Write the following as the complete new content of `/home/jed/.local/share/chezmoi/dot_bashrc`:

```bash
# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

if [[ -f ~/.local/share/omarchy/default/bash/rc ]]; then
  source ~/.local/share/omarchy/default/bash/rc
else
  # ============ envs ============
  export SUDO_EDITOR="$EDITOR"
  export BAT_THEME=ansi
  export MANROFFOPT="-c"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"

  # ============ shell ============
  shopt -s histappend
  HISTCONTROL=ignoreboth
  HISTSIZE=32768
  HISTFILESIZE="${HISTSIZE}"

  if [[ ! -v BASH_COMPLETION_VERSINFO && -f /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
  fi

  set +h

  # ============ aliases ============
  if command -v eza &> /dev/null; then
    alias ls='eza -lh --group-directories-first --icons=auto'
    alias lsa='ls -a'
    alias lt='eza --tree --level=2 --long --icons --git'
    alias lta='lt -a'
  fi

  if command -v fzf &> /dev/null; then
    if [[ "$TERM" == "xterm-kitty" ]]; then
      alias ff="fzf --preview 'case \$(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'"
    else
      alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
    fi
    alias eff='$EDITOR "$(ff)"'
    sff() {
      if [ $# -eq 0 ]; then echo "Usage: sff <destination> (e.g. sff host:/tmp/)"; return 1; fi
      local file
      file=$(find . -type f -printf '%T@\t%p\n' | sort -rn | cut -f2- | ff) && [ -n "$file" ] && scp "$file" "$1"
    }
  fi

  if command -v zoxide &> /dev/null; then
    alias cd="zd"
    zd() {
      if (( $# == 0 )); then
        builtin cd ~ || return
      elif [[ -d $1 ]]; then
        builtin cd "$1" || return
      else
        if ! z "$@"; then
          echo "Error: Directory not found"
          return 1
        fi
        printf "\U000F17A9 "
        pwd
      fi
    }
  fi

  open() (
    xdg-open "$@" >/dev/null 2>&1 &
  )

  alias ..='cd ..'
  alias ...='cd ../..'
  alias ....='cd ../../..'

  alias g='git'
  alias gcm='git commit -m'
  alias gcam='git commit -a -m'
  alias gcad='git commit -a --amend'

  alias t='tmux attach || tmux new -s Work'
  alias d='docker'
  alias r='rails'

  n() { if [ "$#" -eq 0 ]; then command nvim . ; else command nvim "$@"; fi; }

  # ============ functions ============

  # Tmux: dev layout with editor + AI pane(s)
  tdl() {
    [[ -z $1 ]] && { echo "Usage: tdl <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
    [[ -z $TMUX ]] && { echo "You must start tmux to use tdl."; return 1; }
    local current_dir="${PWD}"
    local editor_pane ai_pane ai2_pane
    local ai="$1"
    local ai2="$2"
    editor_pane="$TMUX_PANE"
    tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"
    tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir"
    ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
    if [[ -n $ai2 ]]; then
      ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
      tmux send-keys -t "$ai2_pane" "$ai2" C-m
    fi
    tmux send-keys -t "$ai_pane" "$ai" C-m
    tmux send-keys -t "$editor_pane" "$EDITOR ." C-m
  }

  # Tmux: square layout with editor, diff watch, terminal, opencode
  tds() {
    [[ -n $1 ]] && { echo "Usage: tds"; return 1; }
    [[ -z $TMUX ]] && { echo "You must start tmux to use tds."; return 1; }
    local current_dir="${PWD}"
    local editor_pane diff_pane terminal_pane opencode_pane
    editor_pane="$TMUX_PANE"
    tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"
    terminal_pane=$(tmux split-window -v -p 50 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
    diff_pane=$(tmux split-window -h -p 50 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
    opencode_pane=$(tmux split-window -h -p 50 -t "$terminal_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$editor_pane" -l "nvim ."
    tmux send-keys -t "$editor_pane" C-m
    tmux send-keys -t "$diff_pane" -l "hunk diff --watch"
    tmux send-keys -t "$diff_pane" C-m
    tmux send-keys -t "$opencode_pane" -l "opencode"
    tmux send-keys -t "$opencode_pane" C-m
    tmux select-pane -t "$editor_pane"
  }

  # Tmux: open tdl in each subdirectory as a separate window
  tdlm() {
    [[ -z $1 ]] && { echo "Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
    [[ -z $TMUX ]] && { echo "You must start tmux to use tdlm."; return 1; }
    local ai="$1"
    local ai2="$2"
    local base_dir="$PWD"
    local first=true
    tmux rename-session "$(basename "$base_dir" | tr '.:' '--')"
    for dir in "$base_dir"/*/; do
      [[ -d $dir ]] || continue
      local dirpath="${dir%/}"
      if $first; then
        tmux send-keys -t "$TMUX_PANE" "cd '$dirpath' && tdl $ai $ai2" C-m
        first=false
      else
        local pane_id
        pane_id=$(tmux new-window -c "$dirpath" -P -F '#{pane_id}')
        tmux send-keys -t "$pane_id" "tdl $ai $ai2" C-m
      fi
    done
  }

  # Tmux: swarm layout — same command in N panes
  tsl() {
    [[ -z $1 || -z $2 ]] && { echo "Usage: tsl <pane_count> <command>"; return 1; }
    [[ -z $TMUX ]] && { echo "You must start tmux to use tsl."; return 1; }
    local count="$1"
    local cmd="$2"
    local current_dir="${PWD}"
    local -a panes
    tmux rename-window -t "$TMUX_PANE" "$(basename "$current_dir")"
    panes+=("$TMUX_PANE")
    while (( ${#panes[@]} < count )); do
      local new_pane
      new_pane=$(tmux split-window -h -t "${panes[-1]}" -c "$current_dir" -P -F '#{pane_id}')
      panes+=("$new_pane")
      tmux select-layout -t "${panes[0]}" tiled
    done
    for pane in "${panes[@]}"; do
      tmux send-keys -t "$pane" "$cmd" C-m
    done
    tmux select-pane -t "${panes[0]}"
  }

  # Git worktrees
  ga() {
    if [[ -z "$1" ]]; then echo "Usage: ga [branch name]"; return 1; fi
    local branch="$1"
    local base="$(basename "$PWD")"
    local wt_path="../${base}--${branch}"
    git worktree add -b "$branch" "$wt_path"
    mise trust "$wt_path"
    cd "$wt_path"
  }

  gd() {
    if gum confirm "Remove worktree and branch?"; then
      local cwd base branch root worktree
      cwd="$(pwd)"
      worktree="$(basename "$cwd")"
      root="${worktree%%--*}"
      branch="${worktree#*--}"
      if [[ "$root" != "$worktree" ]]; then
        cd "../$root"
        git worktree remove "$cwd" --force || return 1
        git branch -D "$branch"
      fi
    fi
  }

  # Compression
  compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
  alias decompress="tar -xzf"

  # SSH port forwarding
  fip() {
    (( $# < 2 )) && echo "Usage: fip <host> <port1> [port2] ..." && return 1
    local host="$1"
    shift
    for port in "$@"; do
      ssh -f -N -L "$port:localhost:$port" "$host" && echo "Forwarding localhost:$port -> $host:$port"
    done
  }

  dip() {
    (( $# == 0 )) && echo "Usage: dip <port1> [port2] ..." && return 1
    for port in "$@"; do
      pkill -f "ssh.*-L $port:localhost:$port" && echo "Stopped forwarding port $port" || echo "No forwarding on port $port"
    done
  }

  lip() {
    pgrep -af "ssh.*-L [0-9]+:localhost:[0-9]+" || echo "No active forwards"
  }

  # ============ init ============
  if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
  fi

  if [[ $- == *i* ]] && [[ ${TERM:-} != "dumb" ]] && command -v starship &> /dev/null; then
    eval "$(starship init bash)"
  fi

  if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
  fi

  if command -v fzf &> /dev/null; then
    [[ -f /usr/share/fzf/completion.bash ]] && source /usr/share/fzf/completion.bash
    [[ -f /usr/share/fzf/key-bindings.bash ]] && source /usr/share/fzf/key-bindings.bash
  fi
fi

# ============ personal ============
alias vim='nvim'

export EDITOR=vim

export PATH="$HOME/.local/bin:$PATH"

eval "$(mise activate bash)"

# pnpm
export PNPM_HOME="/home/jed/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
```

- [ ] **Step 2: Apply via chezmoi and verify the rendered file**

```bash
chezmoi apply ~/.bashrc
grep -n "omarchy\|mise activate\|HISTSIZE\|alias ls\|tdl\|EDITOR" ~/.bashrc
```

Expected output shows: the if/else guard on line ~3, HISTSIZE, eza alias, tdl function, mise activate in both the else-block init and the personal section, EDITOR set.

- [ ] **Step 3: Smoke-test in a new bash shell**

```bash
bash -i -c "type tdl; type ga; alias ls; echo HISTSIZE=\$HISTSIZE" 2>&1
```

Expected: `tdl is a function`, `ga is a function`, `ls aliased to 'eza ...'` (if eza installed) or no output for ls, `HISTSIZE=32768`. No errors about missing files.

- [ ] **Step 4: Verify mise/node still works**

```bash
bash -i -c "node --version" 2>&1
```

Expected: a node version string (e.g. `v26.3.0`). No `command not found`.

- [ ] **Step 5: Commit**

```bash
git -C ~/.local/share/chezmoi add dot_bashrc
git -C ~/.local/share/chezmoi commit -m "feat(bash): replace omarchy source with conditional fallback for non-omarchy machines"
```
