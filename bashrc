#! /bin/bash

# PROMPT
function parse_git_branch()
{
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
if [ `whoami` = "root" ]
then
    export PS1='\[\033[01;47;31m\]\h\[\033[40;31m\] \u \[\033[37m\]\W \$ \[\033[00m\]'
else
    export PS1='\[\033[01;33m\]\u\[\033[01;35m\]@\[\033[00;31m\]\h\[\033[00m\]:\[\033[0;33m\] \W \[\033[01;35m\]$(parse_git_branch)\[\033[0;33m\] \[\033[0m\]\$ '
fi
unset PROMPT_COMMAND

# TERM
if [ -r /usr/share/terminfo/x/xterm-256color ]
then
    export TERM='xterm-256color'
else
    export TERM='xterm-color'
fi
eval $(dircolors ~/.dir_colors)

# BELL
[ ! -z $DISPLAY ] && xset b 0

# VIMMODE
set -o vi

shopt -s autocd

# COLORLS
OSNAME=`uname`
case $OSNAME in
    Linux)
        alias ls="ls --color=auto -F -b -T 0"
        alias ll="ls -l --color=auto -F -b -T 0"
        ;;
    FreeBSD)
        LSCOLOR="3x5x2x3x1x464301060203"
        alias ls="ls -GF"
        export LSCOLORS
        ;;
    OpenBSD)
        alias ls="colorls -F -G"
        export PKG_PATH="ftp://mirror.switch.ch/mirror/OpenBSD/4.0/packages/i386/"
        ;;
esac

# ENV
function set_if_not_in()
{
    env_var=$1
    arg=$2
    IFS=":";
    for p in ${!env_var}; do if [ $p == $arg ]; then IFS=" "; return 0; fi done
    IFS=" ";
    export ${env_var}=$arg:${!env_var}
}

function export_if_exists()
{
    _TMP=`which $2 2>/dev/null`
    [ -z ${_TMP} ] && _TMP=$3
    eval "export $1=$_TMP"
}

[ -r /etc/profile.d/undistract-me.sh ] && source /etc/profile.d/undistract-me.sh

# prepend ~/bin to path if not already there
HOME_=$(readlink -f ${HOME%/})
export PATH=${HOME_}/bin:${PATH#${HOME_}/bin:}
export_if_exists 'PAGER' 'less' '/bin/more'
export EDITOR=vim
# RUBY
export GEM_HOME="${HOME_}/.gem/ruby/2.5.0"
set_if_not_in 'PATH' ${GEM_HOME}/bin

# catch and eval dmalloc output
#function dmalloc { eval `command dmalloc -b $*`; }
alias vim="nvim -u ~/.vimrc"
alias vimdiff="nvim -d -u ~/.vimrc"
alias fuck='eval $(thefuck $(fc -ln -1)); history -r'

# FUNCTIONS
function lip () {    # local ips
    ip -c addr | sed -n '/^[1-9]:/p;/inet /p'
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

function xtract() {
    if [ -f "$1" ] ; then
        case "$1" in
            *.tar.bz2)   tar xvjf "$1"                    ;;
            *.tar.gz)    tar xvzf "$1"                    ;;
            *.bz2)       bunzip2 "$1"                     ;;
            *.rar)       unrar x "$1"                     ;;
            *.gz)        gunzip "$1"                      ;;
            *.tar)       tar xvf "$1"                     ;;
            *.tbz2)      tar xvjf "$1"                    ;;
            *.tgz)       tar xvzf "$1"                    ;;
            *.zip)       unzip "$1"                       ;;
            *.ZIP)       unzip "$1"                       ;;
            *.pax)       cat "$1" | pax -r                ;;
            *.pax.Z)     uncompress "$1" —stdout | pax -r ;;
            *.Z)         uncompress "$1"                  ;;
            *.7z)        7z x "$1"                        ;;
            *)           echo "don't know how to extract '$1'..." ;;
        esac
    else
        echo "extract: error: $1 is not valid"
    fi
}

# SSH
SSH_ENV=${HOME}/.ssh/environment
function start_agent {
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > ${SSH_ENV}
    chmod 600 ${SSH_ENV}
    . ${SSH_ENV} > /dev/null
    # /usr/bin/ssh-add $(ls ~/.ssh/*.pub | sed 's/\.pub.*//g' | tr '\n' ' ')
}
if [ -e "${SSH_ENV}" ]
then
    . ${SSH_ENV} > /dev/null
    ps ux | grep ssh-agent$ | grep ${SSH_AGENT_PID} >/dev/null || {
        # kill old agents
        PIDS=`pidof ssh-agent`
        if [ ! -z "${PIDS}" ]; then
            for PID in ${PIDS}; do
                kill ${PID} 2>/dev/null
            done
        fi
        start_agent;
    }
else
    start_agent
fi
