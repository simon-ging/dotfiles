#!/usr/bin/env bash

# ignore duplicates in history
# history commands:
#   !XX to run history command number XX
#   !! rerun last command
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
export HISTSIZE=100000
export HISTTIMEFORMAT="%Y-%m-%d %T "
export EDITOR=vim
umask 077 # newly created files / folders will be private

# setup fuzzy find if it exists
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# setup better ls colors if configured
if [[ -e ~/.dircolors ]]; then
  eval "$(dircolors -b ~/.dircolors)"
else
  eval "$(dircolors -b)"
fi

alias rc='${EDITOR} ~/.bashrc'

# ---------- datetime
alias datestamp='date +"%Y-%m-%d_%H-%M-%S"'
alias time_s='date +%s'
alias time_ns='date +%s%N'
alias time_ys='bc <<< "`date +%s%N` / 10^3"'
alias time_ms='bc <<< "`date +%s%N` / 10^6"'
alias datef="date +%y%m%d-%k%M%S"

# ---------- system info
alias ns='nvidia-smi && nvidia-smi -L && who'
alias nsi='for i in {0..7}; do nvidia-smi -i $i; done'
alias pi='ps -ef | grep python'

alias info_cpu='mpstat -P ALL; echo num cpus && cat /proc/cpuinfo | grep processor | wc -l'
alias info_memory='free -h'
alias info_dist='cat /etc/*-release | grep PRETTY && lsb_release && cat /proc/version && hostnamectl && echo $DESKTOP_SESSION && cat /etc/os-release'
alias info_processes='ps u -A | grep python'
alias info_ip="ip a"
alias info_ip2='curl -4 ifconfig.co'
alias info_ip3='curl -4 ifconfig.me'
alias info_pc='lshw'
alias info_audio="pacmd list-modules"
alias info_soundcard="sudo dmesg | grep snd"
alias info_path='echo ${PATH} | tr ":" "\n"'
alias info_shutdown="date -d @$(cat /run/systemd/shutdown/scheduled 2>/dev/null | head -n 1 | cut -c6-15) 2>/dev/null || echo no planned shutdown found"
alias toploop="while true; do top -b -n 1 | head -n 20; sleep 1; done"

# ---------- file / disk info
alias ..='cd ..'
alias ...='cd ../..'
alias countfiles='find . -type f | wc -l'
alias countfileendings="find . -type f | awk -F '.' '{print $NF}' | sort | uniq -c"
alias info_disk='df -h && lsblk'
alias duhflat='du -Pksh *. [^.] * | sort -n'  # show sizes without recursion
alias duh='du -d 1 -h'
alias duh1g='du -t 1073741824 -h -d 1 '
alias duh100m='du -t 104857600 -h -d 1 '
alias pwdp="readlink -f ."
alias mactrash='find . -name ".DS_Store" -delete -or -name "._*" -delete -or -name "__MACOSX" -exec rm -rfv {} +'

alias ld='ls -AlhXdv --color=auto' # show directories
alias ll="ls -AlhX --color=auto --time-style='+%Y-%m-%d %H:%M'"
function lf() { # find + ls
  find . -maxdepth 1 -name "$@" -type f -exec ls -AlhX {} \;
}
export -f lf

function grepr() {
  pattern=$1
  dir=$2
  if [[ "${pattern}" == "" ]]; then echo "syntax: cmd [pattern] [dir]"; return; fi
  grep -R --color=never "${pattern}" ${dir} | cat -A | cut -c -200
}


# ---------- chmod
# find requires -L to follow symlinks, so these commands do not follow symlinks.
# MUST expand the alias with C+M+e before running for it to work.
alias chmodd755='find . -type d -exec chmod u=rwx,go=rx {} \\;'
alias chmodd770='find . -type d -exec chmod ug=rwx,o= {} \\;'
alias chmodd750='find . -type d -exec chmod u=rwx,g=rx,o= {} \\;'
alias chmodd700='find . -type d -exec chmod u=rwx,go= {} \\;'
alias chmodf644='find . -type f -exec chmod u=rw,go=r {} \\;'
alias chmodf660='find . -type f -exec chmod ug=rw,o= {} \\;'
alias chmodf640='find . -type f -exec chmod u=rw,g=r,o= {} \\;'
alias chmodf600='find . -type f -exec chmod u=rw,go= {} \\;'

alias chmode755='find . -type f -executable -exec chmod u=rwx,go=rx {} \\;'
alias chmode700='find . -type f -executable -exec chmod u=rwx,go= {} \\;'
alias chmodne644='find . -type f -not -executable -exec chmod u=rw,go=r {} \\;'
alias chmodne600='find . -type f -not -executable -exec chmod u=rw,go= {} \\;'

# ---------- rsync
# easy rsync: --partial-dir stores and resumes interrupted downloads, works also for big files.
# --progress show progress, -h human readable, -t preserve mod times
alias rsy="rsync --partial-dir=.rsync-partial --progress -h -t"
alias rsynoimages='rsync --partial-dir=.rsync-partial --progress -h -t  --exclude \"*.jp*g\" --exclude \"*.JP*G\" --exclude \"*.png\" --exclude \"*.PNG\"'
alias rsyonlyjson='rsync --partial-dir=.rsync-partial --progress -h -t --include=\"*/\" --include=\"*/json\" --exclude \"*\"'


# ---------- unsorted
alias pj="python3 -m json.tool"
alias pt="python -m pytest"
alias ecd='export CUDA_VISIBLE_DEVICES='
alias bell='sleep 1 ; echo -e "\a"'

function killallother() {
  ps -u "$USER" -o pid=,comm=  | grep -vE 'grep|bash|ssh|tmux|ps|nvitop' | awk '{print $1}' | xargs kill -9
}
export -f killallother

alias pdfcompressghostscript="gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 \
   -dPDFSETTINGS=/ebook \
   -dDownsampleColorImages=true -dColorImageResolution=150 \
   -dDownsampleGrayImages=true  -dGrayImageResolution=150 \
   -dDownsampleMonoImages=true  -dMonoImageResolution=300 \
   -dDetectDuplicateImages=true -dNOPAUSE -dBATCH -dQUIET \
   -sPAPERSIZE=a4 -dFIXEDMEDIA \
   -sOutputFile=output_smaller.pdf"

alias i3c="ipdb3 -c continue"

