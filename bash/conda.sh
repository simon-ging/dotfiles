#!/usr/bin/env bash

export __conda_cmd="conda"
alias caa="${__conda_cmd} activate"
alias cad="${__conda_cmd} deactivate"
alias car="${__conda_cmd} env remove -y -n"
alias cae="${__conda_cmd} env list"
alias cac="${__conda_cmd} create -y python=3.12 -n"
alias cax="${__conda_cmd} env export"
alias cals="${__conda_cmd} list"
