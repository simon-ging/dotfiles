#!/usr/bin/env bash

# note: requires to source the 00-colors.sh script first

# ---------- add git branch and virtualenv -----------
# from https://gist.github.com/miki725/9783474
# determine git branch name
function parse_git_branch() {
  git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
# Determine the branch/state information for this git repository.
function get_git_branch() {
  echo ""$(parse_git_branch)
}
# Determine active Python virtualenv details.
function get_virtualenv() {
  if test -z "$VIRTUAL_ENV"; then
    # venv empty, check conda
    if test -z "$CONDA_DEFAULT_ENV"; then
      # conda also empty
      :
    else
      # echo conda
      echo "<"${CONDA_DEFAULT_ENV}"> "
    fi
  else
    PYTHON_VIRTUALENV="$(basename \"$VIRTUAL_ENV\")"
    echo "["${PYTHON_VIRTUALENV}"] "
  fi
}

# ---------- right aligned prompt ----------
# stuff after the prompt must be escaped colors: otherwise cursor position will be wrong
# stuff in the right column better be non-escaped colors, those are easier to correct for

# do stuff that doesnt change outside
right_blank="$C_DEFAULT$C_DEFAULT"
# no username in the title (dont care about that) only host
title="\[\e]0;\h:\w - Terminal\a\]" # title host:cwd (no user)
last=${C_WHITE_MASKED}"λ "
host="$(hostname)"
host_uname="$C_RED$(whoami)@$host$C_WHITE_MASKED:"
min_len=80
first=4
branch=""

prompt() {
  # setup right column
  retcode="[$?]" # must be first line in the function otherwise is always 0

  # proflier
  #    PS4='+ $(date "+%s.%N")\011 '
  #    exec 3>&2 2>/tmp/bashstart/bashstart.$$.log
  #    set -x

  date="$(date +"%y-%m-%d %H:%M:%S")"
  right="$C_DEFAULT$retcode $C_LIGHT_BLUE$date"
  #    right_blank="$C_DEFAULT$C_DEFAULT"

  # title
  #    title="\[\e]0;\h:\w\a\]" # title host:cwd (no user)

  # prompt
  #    last=${C_WHITE_MASKED}"λ "

  # setup left column
  venv="$C_YELLOW $(get_virtualenv)"

  branch="$C_MAGENTA$(get_git_branch)"
  ## DISABLED GIT (slow)

  #    host="$(hostname)"
  #    host_uname="$C_RED$(whoami)@$host$C_WHITE_MASKED:"
  # pwd_res=$(pwd)
  pwd_res=$(dirs +0) # with tilde

  # # howto use dirs
  # dir=...    # <- Use your own here.
  # # Switch to the given directory; Run "dirs" and save to variable.
  # # "cd" in a subshell does not affect the parent shell.
  # dir_with_tilde=$(cd "$dir" && dirs +0)

  # disable right content if window too small

  # shorten directory if too long
  cols=$(tput cols)
  #    min_len=20
  #    first=4
  target_len=$((cols + 30))
  target_len_right_column=$((cols + 12))
  pwd_total="$host_uname$C_GREEN$pwd_res$branch$venv"
  str_len=${#pwd_total}

  # disable right content if window too small
  if [[ $target_len_right_column -le $str_len ]]; then right=${right_blank}; fi

  # actually cut the pwd if it is really small
  if [[ $target_len -le $min_len ]]; then target_len=$min_len; fi
  if [[ $target_len -lt $str_len ]]; then
    # only display first 8, last target_len-5 and a " ... " in between
    last_num=$((target_len - first - 3))
    start=$((str_len - last_num))
    pwd_res="${pwd_res:0:8}...${pwd_res:${start}:${str_len}}"
    right=${right_blank}
  fi
  wd="$C_GREEN$pwd_res"

  # finish left column
  left="$host_uname$wd$branch$venv\n$last$C_DEFAULT_MASKED"

  # make up for fixed size color commands on the right, 6 per 4bit color, 12 per 8bit color
  diff=+12
  len=$((cols + diff))
  #    PS1=${title}$(printf "%*s\r%s" "$(tput cols)" "$right" "$left")
  #    right="neg"
  PS1=${title}$(printf "%*s\r%s" "$len" "$right" "$left")

  # end profiling
  #    set +x
  #    exec 2>&3 3>&-

}
export PROMPT_COMMAND=prompt

# # dead backup code
# PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}:${PWD/#$HOME/~}\007"'
# export PS1="\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n"$
# c_yellow="\[\e[33m\]"
# c_blue="\[\e[96m\]"
# user_host="\[\e[32m\]\u@\h"
# wd="$c_green\w"
# colon="\[\e[31m\]:"
# # last="λ "
# exit_code="\[\e[97m\]\$? "
# export PS1="$title$exit_code$user_host$colon$wd $last"
# export PS1="$wd\n$last$c_default"
# export PS2='> '
# export PS1="$ "
