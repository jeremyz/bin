#! /bin/bash

# PROMPT
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

PS1='`hostname`:`pwd`# '
if [ `whoami` = "root" ]; then	# effective uid
    export PS1='\[\033[01;47;31m\]\h\[\033[40;31m\] \u \[\033[37m\]\W \$ \[\033[00m\]'
else
    # export PS1='\[\033[01;47;31m\]\h\[\033[40;34m\] \u \[\033[37m\]\W $(parse_git_branch) \$ \[\033[00m\]'
    export PS1='\[\033[01;33m\]\u\[\033[01;35m\]@\[\033[00;31m\]\h\[\033[00m\]:\[\033[0;33m \w $(parse_git_branch) \[\033[00m\]\$ '
fi
PS2='> '
unset PROMPT_COMMAND

# TERM
if [ -r /usr/share/terminfo/x/xterm-256color ]; then
    export TERM='xterm-256color'
else
    export TERM='xterm-color'
fi

# BELL
if [ ! -z $DISPLAY ]; then
    xset b 0
fi
if [ ! -z `which setterm 2>/dev/null` ]; then
    setterm -blength 0
fi

# VIMMODE
set -o vi

# ALIASES
#alias vimb="vim -u $HOME/.vimrc-bepo"

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
HOME_=${HOME%/}

set_if_not_in( ) {
    env_var=$1
    arg=$2
    IFS=":";
    for p in ${!env_var}; do if [ $p == $arg ]; then IFS=" "; return 0; fi done
    IFS=" ";
    export ${env_var}=$arg:${!env_var}
}

LIBS=/var/lib
LOCALGIT=${HOME_}/usr/git
LOCALLIB=${HOME_}/lib

# GREP
export GREP_OPTIONS=--color

# GIT
# export GIT_PAGER=cat
# export GIT_BASE=${LOCALGIT}

# PYTHON
export PYTHONPATH=${HOME_}/lib/python:/opt/efl/lib/python2.7/site-packages/

# PERL
export PERL5LIB=${LIBS}/perl/lib
# set_if_not_in "PATH" "${LIBS}/perl/bin"

# RUBY
# export RB_USER_INSTALL=1    # see /usr/local/lib/ruby/1.8/i386-freebsd7/rbconfig.rb
export RUBYOPT=rubygems
export GEM_HOME="$HOME/.gem/ruby/1.9.1"
export RUBYLIB=${LOCALLIB}/ruby/
set_if_not_in 'PATH' ${GEM_HOME}/bin

# JAVA
export CLASSPATH=${HOME_}/lib/java

# PIDGIN
export NSS_SSL_CBC_RANDOM_IV=0

SHARE=${HOME_}/share

# LATEX
TEXBASE=${SHARE}/tex
export TEXMFHOME=${TEXBASE}/texmf
export TEXMFVAR=${TEXBASE}/texmf-var
export TEXMFCONFIG=${TEXBASE}/texmf-config
# export TEXINPUTS=${TEXBASE}/texmf/ext:
# export MFINPUTS=${TEXBASE}/texmf/fonts

# prepend ~/bin to path if not already there
export PATH=${HOME}/bin:${PATH#${HOME}/bin:}

export PKG_PATH=`which pkg-config 2>/dev/null`
export LOCATEDB=$HOME/etc/locate.`hostname`.db

my_export()
{
    _TMP=`which $2 2>/dev/null`
    if [ -z ${_TMP} ]; then
        _TMP=$3
    fi
    eval "export $1=$_TMP"
}

# PAGER
my_export 'PAGER' 'less' '/bin/more'
my_export 'EDITOR' 'vim' '/usr/bin/vi'

# catch and eval dmalloc output
#function dmalloc { eval `command dmalloc -b $*`; }
#alias lss="ls -l"

# MISC
export SDL_AUDIODRIVER="pulse"
export PA_RUNTIME_PATH=/tmp/pulse-jeyzu
export OOO_FORCE_DESKTOP=gnome
export OGGOPTS="-b 160 -q 4"
if [ ! -z `which ncmpc 2>/dev/null` ]; then
    export MPD_HOST=bigdaddy;
fi

#
SSH_ENV=${HOME}/.ssh/environment
#
function start_agent {
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > ${SSH_ENV}
    chmod 600 ${SSH_ENV}
    . ${SSH_ENV} > /dev/null
    /usr/bin/ssh-add $(ls ~/.ssh/*.pub | sed 's/\.pub.*//g' | tr '\n' ' ')
}
#
if [ -e "${SSH_ENV}" ]; then
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

