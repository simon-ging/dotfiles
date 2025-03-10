#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/bash/00-colors.sh"
source "$SCRIPT_DIR/bash/bash.sh"
source "$SCRIPT_DIR/bash/conda.sh"
source "$SCRIPT_DIR/bash/git.sh"
source "$SCRIPT_DIR/bash/prompt.sh"
source "$SCRIPT_DIR/bash/setfacl.sh"
source "$SCRIPT_DIR/bash/slurm.sh"
source "$SCRIPT_DIR/bash/tmux.sh"
source "$SCRIPT_DIR/bash/zstd.sh"
