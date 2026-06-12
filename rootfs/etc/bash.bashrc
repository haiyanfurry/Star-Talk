# ╔══════════════════════════════════════════════════════════════╗
# ║     Star-Talk / 星语 — /etc/bash.bashrc                     ║
# ╚══════════════════════════════════════════════════════════════╝

# ── History ──────────────────────────────────────────────────────
HISTFILE="$HOME/.bash_history"
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups

# ── Aliases ──────────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -la --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

alias df='df -h'
alias du='du -h'
alias free='free -h'

alias ..='cd ..'
alias ...='cd ../..'

# ── Terminal title ───────────────────────────────────────────────
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;Star-Talk / 星语 — \w\a\]$PS1"
        ;;
esac

# ── Source local bashrc if it exists ─────────────────────────────
[ -f ~/.bashrc ] && . ~/.bashrc
