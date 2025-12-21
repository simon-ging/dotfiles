#!/usr/bin/env bash

if [ -n "$BASH_SOURCE" ]; then
  SCRIPT_SOURCE="${BASH_SOURCE[0]}"
elif [ -n "$ZSH_VERSION" ]; then
  SCRIPT_SOURCE="${(%):-%N}"
else
  SCRIPT_SOURCE="$0"
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd -P)"

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/bash/00-colors.sh"
source "$SCRIPT_DIR/bash/bash.sh"
source "$SCRIPT_DIR/bash/conda.sh"
source "$SCRIPT_DIR/bash/git.sh"
source "$SCRIPT_DIR/bash/setfacl.sh"
source "$SCRIPT_DIR/bash/slurm.sh"
source "$SCRIPT_DIR/bash/tmux.sh"
source "$SCRIPT_DIR/bash/zstd.sh"
