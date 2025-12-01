########################################
# .zshrc — clean, safe, and fast
########################################

# ---------- 0) Foundations (early PATH + env) ----------
# Homebrew (universal; works on Apple Silicon, Intel, Linuxbrew)
if command -v brew >/dev/null 2>&1; then
  eval "$(/usr/bin/env brew shellenv)"
fi

# XDG base dir
export XDG_CONFIG_HOME="$HOME/.config"

# jenv (early so JAVA_HOME/PATH are ready)
if command -v jenv >/dev/null 2>&1; then
  eval "$(jenv init -)"
fi

# ---------- 1) Multiplexer / Terminal integration ----------
# Zellij autostart (runs only in interactive shells and not inside zellij)
# Only run on fresh shell startup, not when sourcing .zshrc
if [[ -z "$ZSHRC_SOURCED" ]] && [[ -z "$ZELLIJ" ]] && [[ $- == *i* ]]; then
  # Kill all existing sessions and start fresh (ensures only one active session)
  zellij kill-all-sessions -y 2>/dev/null
  zellij
  # Exit the shell after leaving Zellij (optional)
  if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
    exit
  fi
fi

# Ghostty shell integration (harmless if Ghostty isn’t running)
# Uncomment when you’ve got Ghostty’s integration present:
# if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
#   builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration" 2>/dev/null
# fi

# ---------- 2) Cloud SDK (before compinit so completion can register cleanly) ----------
if [ -f '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc' ]; then
  . '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'
fi
# Only load completion on fresh shell startup (it runs bashcompinit which can interfere)
if [[ -z "$ZSHRC_SOURCED" ]] && [ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]; then
  . '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'
fi

# ---------- 3) fzf + completion ----------
# fzf adds keybindings/completion; then run compinit so everything is indexed once
# Only initialize fzf and completion on fresh shell startup (fzf disables aliases!)
if [[ -z "$ZSHRC_SOURCED" ]]; then
  [ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
  autoload -Uz compinit && compinit -C   # -C trusts cached .zcompdump for speed
fi

# ---------- 4) Quality-of-life shell options ----------
HISTFILE=$HOME/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt HIST_IGNORE_DUPS HIST_FIND_NO_DUPS HIST_REDUCE_BLANKS INC_APPEND_HISTORY
# setopt SHARE_HISTORY             # enable if you want history shared across terminals
# setopt AUTO_CD                   # 'cd' by typing a dir name (optional)

# ---------- 5) Prompt (Starship) with preexec guard ----------
autoload -Uz add-zsh-hook

# Guard: (re)define Starship’s helper if some script nukes it
starship_preexec_guard() {
  if ! typeset -f __starship_get_time >/dev/null; then
    zmodload zsh/datetime 2>/dev/null
    zmodload zsh/mathfunc 2>/dev/null
    __starship_get_time() { (( STARSHIP_CAPTURED_TIME = int(rint(EPOCHREALTIME * 1000)) )); }
  fi
}
# Clean hook management: remove existing hook before adding
if add-zsh-hook -L preexec | grep -q 'starship_preexec_guard'; then
  add-zsh-hook -d preexec starship_preexec_guard
fi
add-zsh-hook preexec starship_preexec_guard

# Initialize Starship (only if not already initialized)
if [[ $- == *i* ]] && [[ $TERM != dumb ]] && command -v starship >/dev/null 2>&1; then
  if [[ -z "$STARSHIP_SHELL" ]] && [[ -z "$ZSHRC_SOURCED" ]]; then
    eval "$(starship init zsh)"
  fi
fi

# Un-monkey-patch guard (keep only if you actually hit the bug that injects a 'cd' here)
if typeset -f prompt_starship_precmd | grep -qE '(^|[^[:alnum:]_])cd[[:space:]]+~?/repos/else'; then
  prompt_starship_precmd () {
    STARSHIP_CMD_STATUS=$? STARSHIP_PIPE_STATUS=(${pipestatus[@]})
    if (( ${+STARSHIP_START_TIME} )); then
      __starship_get_time && (( STARSHIP_DURATION = STARSHIP_CAPTURED_TIME - STARSHIP_START_TIME ))
      unset STARSHIP_START_TIME STARSHIP_DURATION STARSHIP_CMD_STATUS STARSHIP_PIPE_STATUS
    fi
    STARSHIP_JOBS_COUNT=${#jobstates}
  }
fi

# ---------- 6) One-time per-shell banners ----------
# Show fastfetch once per shell (not exported -> child shells can still show it)
if [[ $- == *i* && -z "$FASTFETCH_PRINTED" ]]; then
  # If the logo truncates on startup, a tiny delay can help:
  # sleep 0.05
  command -v fastfetch >/dev/null 2>&1 && fastfetch
  FASTFETCH_PRINTED=1
fi


# ---------- 8) Optional plugins (auto-detect Homebrew paths) ----------
# zsh-autosuggestions (only load if not already loaded)
if [ -r "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && [[ -z "$ZSH_AUTOSUGGEST_STRATEGY" ]]; then
  source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
# zsh-syntax-highlighting (recommended last, only load if not already loaded)
if [ -r "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && [[ -z "$ZSH_HIGHLIGHT_HIGHLIGHTERS" ]]; then
  source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# ---------- 9) Aliases & functions (after all initialization) ----------
# Function to ensure critical aliases are always available
_restore_critical_aliases() {
  alias s='source ~/.zshrc'
  alias eb='nvim ~/.zshrc'
}

# Always-available reloader (non-leaky)
_restore_critical_aliases

# Files/dirs
alias ll='ls -lah'
alias path='print -l $path'
alias ports='lsof -i -P -n | grep LISTEN'
alias updatebrew='brew update && brew upgrade && brew cleanup'
alias weather='curl wttr.in'
alias nv='nvim'

# Search history helper
alias hist='history | grep'

# Dev navigation
alias mine='cd ~/repos/mine'
alias else='cd ~/repos/else'
alias etc='cd ~/repos/etc'
alias gdev='cd ~/repos/mine/GoApps'
alias rdev='cd ~/repos/mine/RustApps'
alias wdev='cd ~/repos/mine/WebApps'
alias jdev='cd ~/repos/mine/JavaApps'
alias pdev='cd ~/repos/mine/PythonApps'
alias ddev='cd ~/repos/mine/DevOps/'
alias ~='cd ~/'
alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'

# Zellij launcher that gracefully falls back if layout missing
devTerm() {
  if ! command -v zellij >/dev/null 2>&1; then
    echo "zellij not installed" >&2; return 1
  fi
  local layout_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zellij/layouts"
  if [ -f "$layout_dir/dev.kdl" ]; then
    zellij --layout dev
  else
    echo "(hint) No dev.kdl found in $layout_dir — launching default zellij." >&2
    zellij
  fi
}

# Git helpers
gbr() { git rev-parse --abbrev-ref HEAD 2>/dev/null; }
gc()  { git commit -m "$*"; }               # preserves spaces in message
alias gs='git status'
alias ga='git add -u'
alias gaa='git add .'
alias gco='git checkout'
alias gcb='git checkout -b'
alias glog='git log --oneline --graph --decorate --all'
alias gpl='git pull --ff-only'
alias gpo='git pull origin "$(gbr)"'
alias gp='git push -u origin "$(gbr)"'
alias gsync='git fetch origin && git pull origin "$(gbr)"'

# ---------- 10) Prompt (fallback if you ever disable starship) ----------
# PROMPT='%F{cyan}%n@%m%f:%F{yellow}%~%f$ '

# Ensure critical aliases are always available (final restoration)
_restore_critical_aliases

# Mark that .zshrc has been fully sourced (not exported, stays in current shell only)
ZSHRC_SOURCED=1


# bun completions
[ -s "/Users/cfanch06/.bun/_bun" ] && source "/Users/cfanch06/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/devDeps/zig:$PATH"
