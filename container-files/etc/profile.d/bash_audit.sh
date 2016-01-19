#This file must be sourced by '~/.bashrc', which is the last runned startup script for bash invocation for login interactive, login non-interactive and non-login interactive shells.
#

if [ "${SHELL##*/}" != "bash" ]; then
  return
fi

#to avoid sourcing this file more than once
if [ -n "${OSTYPE##solaris*}" ]; then #following not working in solaris
  #do not source this file twice; also do not source it if we are in forcecommand.sh, source it later from "-bash-li"
  #if we would source it from forcecommand.sh, the environment would be lost after the call of 'exec -l bash -li'
  if [ "$AUDIT_INCLUDED" == "$$" ] || { [ -z "$SSH_ORIGINAL_COMMAND" ] && [ "$(cat /proc/$$/cmdline)" == 'bash-c"/etc/forcecommand.sh"' ]; }; then
    return
  else
    declare -rx AUDIT_INCLUDED="$$"
  fi
fi


#'history' options
declare -rx HISTFILE="$HOME/.bash_history"
declare -rx HISTSIZE=500000                                 #nbr of cmds in memory
declare -rx HISTFILESIZE=500000                             #nbr of cmds on file
declare -rx HISTCONTROL=""                                  #does not ignore spaces or duplicates
declare -rx HISTIGNORE=""                                   #does not ignore patterns
declare -rx HISTCMD                                         #history line number
#following line is commented to avoid following issue: loading the history during the sourcing of this file (non-interactive bash) is also loading history lines that begin with '#', but then during the trap DEBUG calls it reloads the whole history without '#'-lines and produces an double-length history.
#history -r                                                  #to reload history from file if a prior HISTSIZE has truncated it

#following 2 lines commented because 'history -r' was still loading '#'-lines
#shopt -s extglob                                            #enable extended pattern matching operators
#HISTIGNORE="*([ \t])#*"; history -r                         #reload history without commented lines; this force non-interactive bash to behave like interactive bash, without this AUDIT_HISTLINE will get a wrong initial value, leading then to a small issue where empty bash sessions are actually logging the last command of history

if [ -n "${OSTYPE##solaris*}" ]; then #following not working in solaris
  if groups | grep -q root; then
    declare -x TMOUT=43200                                    #timeout for root's sessions
    chattr +a "$HISTFILE"                                     #set append-only
  fi
fi
shopt -s histappend
shopt -s cmdhist

#history substitution ask for a confirmation
shopt -s histverify

#add timestamps in history - obsoleted with logger/syslog
#'http://www.thegeekstuff.com/2008/08/15-examples-to-master-linux-command-line-history/#more-130'
#declare -rx HISTTIMEFORMAT='%F %T '

#enable forward search ('ctrl-s')
#'http://ruslanspivak.com/2010/11/25/bash-history-incremental-search-forward/'
if shopt -q login_shell && [ -t 0 ]; then
  stty -ixon
fi



#bash audit & traceability
#
#
#
declare -rx AUDIT_LOGINUSER="$(who -mu | awk '{print $1}')"
declare -rx AUDIT_LOGINPID="$(who -mu | awk '{print $6}')"
declare -rx AUDIT_USER="$USER"                              #defined by pam during su/sudo
declare -rx AUDIT_PID="$$"
declare -rx AUDIT_TTY="$(who -mu | awk '{print $2}')"
declare -rx AUDIT_SSH="$([ -n "$SSH_CONNECTION" ] && echo "$SSH_CONNECTION" | awk '{print $1":"$2"->"$3":"$4}')"
declare -rx AUDIT_STR="[audit $AUDIT_LOGINUSER/$AUDIT_LOGINPID as $AUDIT_USER/$AUDIT_PID on $AUDIT_TTY/$AUDIT_SSH]"
declare -x AUDIT_LASTHISTLINE=""                            #to avoid logging the same line twice
declare -rx AUDIT_SYSLOG="1"                                #to use a local syslogd
#
#
#
#the logging at each execution of command is performed with a trap DEBUG function
#and having set the required history options (HISTCONTROL, HISTIGNORE)
#and to disable the trap in functions, command substitutions or subshells.
#it turns out that this solution is simple and works well with piped commands, subshells, aborted commands with 'ctrl-c', etc..
set +o functrace                                            #disable trap DEBUG inherited in functions, command substitutions or subshells, normally the default setting already
shopt -s extglob                                            #enable extended pattern matching operators
function AUDIT_DEBUG() {
  if [ -z "$AUDIT_LASTHISTLINE" ]; then                     #initialization
    local AUDIT_CMD="$(fc -l -1 -1)"                        #previous history command
    AUDIT_LASTHISTLINE="${AUDIT_CMD%%+([^ 0-9])*}"
  else
    AUDIT_LASTHISTLINE="$AUDIT_HISTLINE"
  fi
  local AUDIT_CMD="$(history 1)"                            #current history command
  AUDIT_HISTLINE="${AUDIT_CMD%%+([^ 0-9])*}"
  if [ "${AUDIT_HISTLINE:-0}" -ne "${AUDIT_LASTHISTLINE:-0}" ] || [ "${AUDIT_HISTLINE:-0}" -eq "1" ]; then  #avoid logging unexecuted commands after 'ctrl-c', 'empty+enter', or after 'ctrl-d'
    echo -ne "${_backnone}${_frontgrey}"                    #disable prompt colors for the command's output
    #remove in last history cmd its line number (if any) and send to syslog
    if [ -n "$AUDIT_SYSLOG" ]; then
      if ! logger -p user.info -t "$AUDIT_STR $PWD" "${AUDIT_CMD##*( )?(+([0-9])?(\*)+( ))}"; then
        echo error "$AUDIT_STR $PWD" "${AUDIT_CMD##*( )?(+([0-9])?(\*)+( ))}"
      fi
    else
      echo $( date +%F_%H:%M:%S ) "$AUDIT_STR $PWD" "${AUDIT_CMD##*( )?(+([0-9])?(\*)+( ))}" >>/var/log/userlog.info
    fi
    #echo "===cmd:$BASH_COMMAND/subshell:$BASH_SUBSHELL/fc:$(fc -l -1)/history:$(history 1)/histline:${AUDIT_CMD%%+([^ 0-9])*}/last_histline:${AUDIT_LASTHISTLINE}===" #for debugging
    return 0
  else
    return 1
  fi
}
#
#
#
#audit the session closing
function AUDIT_EXIT() {
  local AUDIT_STATUS="$?"
  if [ -n "$AUDIT_SYSLOG" ]; then
    logger -p user.info -t "$AUDIT_STR" "#=== session closed ==="
  else
    echo $( date +%F_%H:%M:%S ) "$AUDIT_STR" "#=== session closed ===" >>/var/log/userlog.info
  fi
  exit "$AUDIT_STATUS"
}
#
#
#
#make audit trap functions readonly; disable trap DEBUG inherited (normally the default setting already)
declare -frx +t AUDIT_DEBUG
declare -frx +t AUDIT_EXIT
#
#
#
#audit the session opening
if [ -n "$AUDIT_SYSLOG" ]; then
  logger -p user.info -t "$AUDIT_STR" "#=== session opened ===" #audit the session openning
else
  echo $( date +%F_%H:%M:%S ) "$AUDIT_STR" "#=== session opened ===" >>/var/log/userlog.info
fi
#
#
#
#when a bash command is executed it launches first the AUDIT_DEBUG(),
#then the trap DEBUG is disabled to avoid a useless rerun of AUDIT_DEBUG() during the execution of pipes-commands;
#at the end, when the prompt is displayed, re-enable the trap DEBUG
	#declare -rx PROMPT_COMMAND="AUDIT_DONE=; trap 'AUDIT_DEBUG && AUDIT_DONE=1; trap DEBUG' DEBUG; [ -n \"\$AUDIT_DONE\" ] && echo '-----------------------------'"
	#NOK: declare -rx PROMPT_COMMAND="echo "-----------------------------"; trap 'AUDIT_DEBUG; trap DEBUG' DEBUG; echo '-----------------------------'"
	#OK:  declare -rx PROMPT_COMMAND="echo "-----------------------------"; trap 'AUDIT_DEBUG; trap DEBUG' DEBUG"
#declare -rx PROMPT_COMMAND="[ -n \"\$AUDIT_DONE\" ] && echo '-----------------------------'; AUDIT_DONE=; trap 'AUDIT_DEBUG && AUDIT_DONE=1; trap DEBUG' DEBUG"
declare -rx PROMPT_COMMAND="AUDIT_DONE=; trap 'AUDIT_DEBUG && AUDIT_DONE=1; trap DEBUG' DEBUG"
declare -rx BASH_COMMAND                                    #current command executed by user or a trap
declare -rx SHELLOPT                                        #shell options, like functrace
trap AUDIT_EXIT EXIT                                        #audit the session closing

#time format for thunderbird
#export LC_TIME=en_DK.utf8


#terminal/window's size:
#http://docstore.mik.ua/orelly/unix/upt/ch42_05.htm
#retrieve terminal size: resize
#recheck the window's size after every command:
shopt -s checkwinsize
#force to recheck window's size: kill -WINCH $$
#set it manually, e.g.: stty rows 24 columns 80
#verify with: set | egrep ‘(COLUMNS|LINES)’
#or with: stty size

