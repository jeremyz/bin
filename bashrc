#! /bin/bash

# PROMPT
function parse_git_branch()
{
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
export PS1='\[\033[01;33m\]\u\[\033[01;35m\]@\[\033[00;31m\]\h\[\033[00m\]:\[\033[0;33m\] \W \[\033[01;35m\]$(parse_git_branch)\[\033[0;33m\] \[\033[0m\]\$ '
unset PROMPT_COMMAND

# COLORS
if [ -r /usr/share/terminfo/x/xterm-256color ]
then
    export TERM='xterm-256color'
else
    export TERM='xterm-color'
fi
[ -r ~/.dir_colorss ] && eval $(dircolors ~/.dir_colors)
alias ls="ls --color=auto -F -b -T 0"
alias ll="ls -l --color=auto -F -b -T 0"

# BELL
[ ! -z $DISPLAY ] && xset b 0

# VIMMODE
set -o vi

# DPI
export QT_FONT_DPI=100

# ENV
HOME_=$(readlink -f ${HOME%/})
export PATH=${HOME_}/bin:${PATH#${HOME_}/bin:}
export EDITOR=nvim
export GEM_HOME="${HOME_}/.gem/ruby/3.0.0"
export QT_SCALE_FACTOR=2
export PATH=$PATH:$GEM_HOME/bin

# catch and eval dmalloc output
#function dmalloc { eval `command dmalloc -b $*`; }
alias vim=nvim
alias gvim='nvim --listen godothost .'
alias vimdiff="nvim -d"
alias sf='systemctl --user restart pipewire*'
alias fuck='eval $(thefuck $(fc -ln -1)); history -r'
alias tt='clear && task'
alias kk='khal calendar'
alias ki='khal interactive'
alias zz='clear && khal calendar && task -old'
alias ddu='zcat ~/.cache/ncdu-data.gz | ncdu -f-'

# FUNCTIONS
function lip () {    # local ips
    ip -4 -c addr | sed -n '/^[1-9]:/p;/inet/p'
}

function xip () {    # external ip
    dig +short myip.opendns.com @resolver1.opendns.com
}

function rman () {   # centered man
    env COLUMNS=$(($COLUMNS/3*2)) man "${@}" | pr -o $((COLUMNS/3/2)) | less
}

function xcon () {   # external established connections
    ss -t -o state established '( dport = :443 || dport = :80  )' \
        | grep -Po '([0-9a-z:.]*)(?=:http[s])' | sort -u  \
        | netcat whois.cymru.com 43 | grep -v "AS Name" | sort -t'|' -k3
}

# SSH
ssh-add -l &>/dev/null
if [ $? -ne 0 ]
then
    [ -r ~/.ssh/agent ] && eval "$(<~/.ssh/agent)" >/dev/null
    ssh-add -l &>/dev/null
    if [ $? -ne 0 ]
    then
        (umask 066; ssh-agent > ~/.ssh/agent)
        eval "$(<~/.ssh/agent)" >/dev/null
    fi
fi
