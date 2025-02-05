#!/usr/bin/env bash

# various aliases and functions for git

# problem: git format strings cannot be expanded with ctrl alt e, because then the quotes, brackets are lost.
# it either works before or after expansion but never both
# solution: separate formatting functions and aliases that use those functions
# note: aliases can never use quotes and brackets, so %x20 for spaces, and colors only red blue green reset.
function gitlog() {
  # hash, date, branch/tag, commit message, author
  git log \
    --date=format:"%y-%m-%d %H:%M" \
    --format="format:%C(bold blue)%h%C(reset) %C(green)%ad%C(reset) %C(auto)%d%C(reset) %s %C(dim italic white)%an%C(reset)" \
    --oneline $*
  # #  format from above, without author
  # git log --graph --oneline --date=format:"%y-%m-%d %H:%M" --format="format:%C(bold blue)%h%C(reset) %C(green)%ad%C(reset) %C(auto)%d%C(reset) %s%C(reset)" $*
}
export -f gitlog
function gitlog2() {
  # instead use pretty format to replace oneline
  git log \
    --pretty=format:"%C(bold blue)%h%C(reset) %C(green)%ad%C(reset) %C(auto)%d%C(reset) %s %C(dim italic white)%an%C(reset)" \
    --date=format:'%Y-%m-%d %H:%M' $*
  # --graph --oneline --simplify-by-decoration \
}
export -f gitlog2
alias glt="gitlog2 --graph --simplify-by-decoration" # only tagged / refed
alias gla="gitlog2 --graph --all"                    # all branches
alias glta="gitlog2 --graph --simplify-by-decoration --all"
alias glo="gitlog2 --graph --branches -n 20" # all local branches
alias glof="gitlog2 --graph --branches"      # no -n
alias glto="gitlog2 --graph --simplify-by-decoration --branches"
alias gst='git status'
alias gsti='git status --ignored'
alias gp='git push'
alias ga='git add .'
alias gpl='git pull'
alias gple='git pull --no-edit'
alias ge='git checkout'
alias gfe='git fetch -p'
alias gph='ga ; git commit -m autoupdate ; git push'
alias gbr='git fetch -p && git branch -a'
alias gitdiffless='git diff --color=always | less -R'
function gc() {
  if [[ $# == 0 ]]; then msg="no message"; else msg="$*"; fi
  git commit -m "$msg"
}
export -f gc

function gitpullall() {
  # pull all branches
  current_branch=$(git branch --show-current)
  echo "---------- current branch: ${current_branch}"
  for i in $(git branch --format="%(refname:short)"); do
    echo "---------- pulling branch $i"
    git checkout $i
    git pull
  done
  echo "---------- going back to current branch ${current_branch}"
  git checkout $current_branch
}
export -f gitpullall

function gitupdateindex() {
  # if the files have been changed e.g. by rsync, but the index is old, update the index
  current_branch=$(git branch --show-current)
  echo "---------- status of branch: ${current_branch}"
  git status
  echo "---------- current commit"
  git log -n 1
  echo "---------- fetch"
  git fetch
  echo "---------- update index"
  git reset --soft origin/${current_branch}
  echo "---------- add all and status"
  git add .
  git status
  echo "---------- new commit"
  git log -n 1
  echo "---------- to delete overflowing files: status, C-s, V, mark, enter, move to awk"
  echo "awk '{print \$3}'"
}
export -f gitupdateindex

function gitfork() {
  # create a fork, where the "fork" branch points to the forked repo, and the default branch points
  # to the original repo.
  #
  # 1. fork the repo using github website.
  # 2. cd to the target folder that should contain the repository local files
  # 3. run this function, it will clone and setup the fork repository
  # 4. change the default branch to "fork" on the github website
  # 5. run this function again, it should recreate the default branch to point to the original repo.
  #
  # sync the fork: git checkout default ; git pull ; git checkout fork ; git rebase main ; git push
  if [[ $# -lt 2 ]]; then
    echo "Usage: gitfork FORK-OWNER https://github.com/ORIGINAL-OWNER/ORIGINAL-REPOSITORY.git"
    return 1
  fi
  forkowner="$1"
  url="$2"
  url="${url#https://github.com/}"
  url="${url%.git}"
  owner="${url%%/*}"
  repository="${url##*/}"
  if [[ -z "$owner" || -z "$repository" ]]; then
    echo "Error: Owner or repository is empty. URL not of correct format?"
    echo "Expected https://github.com/ORIGINAL-OWNER/ORIGINAL-REPOSITORY.git"
    echo "Got $1"
    return
  fi
  default_branch=$(curl -s https://api.github.com/repos/${owner}/${repository} | grep '"default_branch"' | awk -F '"' '{print $4}')
  if [[ -n "$default_branch" && "$default_branch" =~ ^[a-zA-Z0-9_\-]+$ ]]; then
    echo "Default branch is: $default_branch"
  else
    echo "Error: Got invalid branch name from github api: {$default_branch}"
    exit 1
  fi
  if [[ -d "${repository}" ]]; then
    echo "${repository} already exists"
  else
    git clone "git@github.com:${forkowner}/$repository.git"
  fi
  cd "${repository}" || return
  # default_branch=$(git branch --no-color --show-current) || return
  echo "${default_branch}"
  git checkout fork
  git remote add upstream https://github.com/${owner}/${repository}.git
  if [[ $? -ne 0 ]]; then
    echo fork branch does not exist yet, running step 1
    git remote add upstream https://github.com/${owner}/${repository}.git
    git remote -v
    git checkout -b fork
    git push -u origin fork
    echo now change the default branch from ${default_branch} to fork in the github web app
    # git push origin :${default_branch}
  else
    echo fork branch exists, running step 2
    git checkout -b "${default_branch}"
    git fetch upstream ${default_branch}
    git branch --set-upstream-to=upstream/${default_branch} ${default_branch}
    git push origin :${default_branch}
    git config pull.rebase true
    echo
    git branch -a
    echo
    echo if above shows defaultbranch, fork, remote origin HEAD origin fork, remote origin fork, remote upstream defaultbranch, it is correct
  fi
  cd ..
}
