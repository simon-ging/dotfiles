#!/usr/bin/env bash

# use system tmux if version >= 3.4 otherwise use conda tmux
#
# setup conda tmux: conda create -n tmux -c conda-forge tmux -y

function condatmux() {
  if [[ "$CONDA_DEFAULT_ENV" != "tmux" ]]; then
    conda activate tmux
  fi
  tmux $*
}

function adaptivetmux() {
  version_output=$(tmux -V 2>/dev/null)
  if [[ $? -eq 0 ]]; then
    version_number=$(echo "$version_output" | grep -oP '\d+\.\d+')
    if (($(echo "$version_number >= 3.4" | bc -l))); then
      # found a tmux version >= 3.4, run that
      tmux $*
      return
    fi
  fi
  # no proper tmux on this system, run conda tmux
  condatmux $*
}

alias t="adaptivetmux"
alias ta="adaptivetmux a"
alias tn='adaptivetmux new -s $(hostname)'
