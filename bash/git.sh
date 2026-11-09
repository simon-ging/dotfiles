#!/usr/bin/env bash

alias gitlinehistory="git blame --date=format:%Y%m%d"

# various aliases and functions for git
alias diffbetter="git --no-pager diff --no-index"

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

function gitlog2() {
  # instead use pretty format to replace oneline
  git log \
    --pretty=format:"%C(bold blue)%h%C(reset) %C(green)%ad%C(reset) %C(auto)%d%C(reset) %s %C(dim italic white)%an%C(reset)" \
    --date=format:'%Y-%m-%d %H:%M' $*
  # --graph --oneline --simplify-by-decoration \
}

alias glt="gitlog2 --graph --simplify-by-decoration" # only tagged / refed
alias gla="gitlog2 --graph --all"                    # all branches
alias glta="gitlog2 --graph --simplify-by-decoration --all"
alias gl="gitlog2 --graph -n 20"             # current branch only
alias glb="gitlog2 --graph --boundary origin/main.." # only commits not on origin/main, plus the fork point
alias glo="gitlog2 --graph --branches -n 20" # all local branches
alias glof="gitlog2 --graph --branches"      # no -n
alias glto="gitlog2 --graph --simplify-by-decoration --branches"
alias gst='git status'
alias gsti='git status --ignored'
alias gp='git push'
alias ga='git add .'
alias gpl='git pull --no-edit'
alias gplm='git pull --no-rebase --no-edit'
alias ge='git checkout'
alias gfe='git fetch -p'
# stops the commit aliases below while a merge or rebase has unresolved files or a changed file
# still holds conflict markers, which `ga` would otherwise stage and commit. Whitespace errors are
# no reason to stop, so --check runs with them switched off
function _gnoconflict() {
  local u m
  u=$(git ls-files -u) && [ -n "$u" ] && { echo "unresolved: $(git diff --name-only --diff-filter=U | tr '\n' ' ')" >&2; return 1; }
  m=$(git -c core.whitespace=-blank-at-eol,-space-before-tab,-indent-with-non-tab,-tab-in-indent,-blank-at-eof,-cr-at-eol diff HEAD --check) || { echo "$m" >&2; return 1; }
}
alias gph='_gnoconflict && ga && { git commit -m no-message ; git push ; }'
alias gcl='_gnoconflict && ga && { git commit -m no-message ; git rebase --continue ; git pull --no-edit ; }'
alias gclm='_gnoconflict && ga && { git commit -m no-message ; git pull --no-rebase --no-edit ; }'
# && not ;, so a pull that stops on a conflict is not followed by the push
alias gclp='gcl && gph'
alias gbr='git fetch --all --tags --prune --prune-tags && git branch -a'
alias gitdiffless='git diff --color=always | less -R'
alias gbrso="git push -u origin HEAD"

function gcm() {
  if [[ $# == 0 ]]; then msg="no message"; else msg="$*"; fi
  git commit -m "$msg"
}


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


function gitprunebranches() {
  # list local branches whose name exists on no remote, then after a y remove their worktrees
  # and delete them. skips branches checked out in the main worktree or in a worktree with
  # changes or untracked files.
  # the number in front counts commits on no remote, after deletion only the reflog keeps them
  git fetch --all --prune || return 1
  git worktree prune
  local main b wt answer todo="" listing="" skipped=""
  main=$(git worktree list --porcelain | awk 'NR == 1 {print substr($0, 10)}')
  for b in $(git for-each-ref --format="%(refname:short)" refs/heads |
    grep -vxF -f <(git for-each-ref --format="%(refname:lstrip=3)" refs/remotes)); do
    wt=$(_gitbranchworktree "$main" "$b")
    if [[ "$wt" == "$main" ]]; then
      skipped+="$b (checked out in the main worktree)"$'\n'
    elif [[ -n "$wt" && -n "$(git -C "$wt" status --porcelain)" ]]; then
      skipped+="$b (changes or untracked files in $wt)"$'\n'
    else
      todo+="$b"$'\n'
      listing+="$(printf "%4s %s" "$(git rev-list --count "$b" --not --remotes)" "$(git branch -vv --list "$b")")"$'\n'
    fi
  done
  if [[ -n "$skipped" ]]; then
    echo "---------- skipped"
    printf "%s" "$skipped"
  fi
  if [[ -z "$todo" ]]; then
    echo "no local branches to delete"
    return 0
  fi
  echo "---------- local branches without a remote"
  printf "%s" "$listing"
  printf "remove their worktrees and delete them with git branch -D? [y/N] "
  read -r answer
  [[ "$answer" == y ]] || return 0
  # run from the main worktree, the current folder may be one of the removed worktrees
  for b in $(printf "%s" "$todo"); do
    wt=$(_gitbranchworktree "$main" "$b")
    if [[ -n "$wt" ]]; then
      git -C "$main" worktree remove "$wt" && echo "Removed worktree $wt"
    fi
  done
  printf "%s" "$todo" | xargs git -C "$main" branch -D
}

function gitrebaseworktrees() (
  # Check every worktree before rebasing; pin each lease so background fetches cannot weaken it.
  if [[ $# != 0 ]]; then
    echo "usage: gitrebaseworktrees" >&2
    return 2
  fi
  local listing main wt b upstream head remote_head base urls gitdir state dirty
  local -a plan=()
  listing=$(git worktree list --porcelain) || return 1
  main=${listing%%$'\n'*}
  main=${main#worktree }
  urls=$(git remote get-url --all origin) || return 1
  if [[ "$urls" == *$'\n'* || "$urls" != "$(git remote get-url --push --all origin)" ]]; then
    echo "stop: origin must have one matching fetch/push URL" >&2
    return 1
  fi
  git fetch --quiet --no-tags --prune origin '+refs/heads/*:refs/remotes/origin/*' || return 1
  base=$(git rev-parse --verify refs/remotes/origin/main) || return 1
  while IFS= read -r wt; do
    [[ "$wt" == 'worktree '* ]] || continue
    wt=${wt#worktree }
    b=$(git -C "$wt" symbolic-ref --quiet --short HEAD) || {
      echo "stop: detached or unavailable worktree: $wt" >&2
      return 1
    }
    if [[ "$wt" == "$main" && "$b" == main ]]; then
      printf '%s (%s): skipped main checkout\n' "$wt" "$b"
      continue
    fi
    if [[ "$b" != simon/* ]]; then
      echo "stop: $b in $wt does not start with simon/" >&2
      return 1
    fi
    gitdir=$(git -C "$wt" rev-parse --absolute-git-dir) || return 1
    for state in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD sequencer BISECT_LOG index.lock; do
      if [[ -e "$gitdir/$state" ]]; then
        echo "stop: $b has an operation in progress ($state)" >&2
        return 1
      fi
    done
    dirty=$(git -C "$wt" status --porcelain --untracked-files=all --ignore-submodules=none) || return 1
    if [[ -n "$dirty" ]]; then
      echo "stop: $b has changes or untracked files in $wt" >&2
      return 1
    fi
    upstream=$(git -C "$wt" for-each-ref --format='%(upstream:remotename) %(upstream:remoteref)' "refs/heads/$b") || return 1
    if [[ "$upstream" != "origin refs/heads/$b" ]]; then
      echo "stop: $b must track origin/$b" >&2
      return 1
    fi
    head=$(git -C "$wt" rev-parse HEAD) || return 1
    remote_head=$(git rev-parse --verify "refs/remotes/origin/$b") || return 1
    if ! git merge-base --is-ancestor "$remote_head" "$head"; then
      echo "stop: origin/$b has commits missing locally" >&2
      return 1
    fi
    if ! git merge-base "$base" "$head" >/dev/null; then
      echo "stop: $b and origin/main have unrelated histories" >&2
      return 1
    fi
    plan+=("$wt" "$b" "$head" "$remote_head")
  done <<< "$listing"

  if (( ${#plan[@]} == 0 )); then
    echo "no worktrees to rebase"
    return 0
  fi
  set -- "${plan[@]}"
  while (( $# )); do
    wt=$1 b=$2 head=$3 remote_head=$4
    shift 4
    if [[ "$(git -C "$wt" symbolic-ref --quiet --short HEAD)" != "$b" || "$(git -C "$wt" rev-parse HEAD)" != "$head" ]]; then
      echo "stop: branch changed during preflight in $wt" >&2
      return 1
    fi
    dirty=$(git -C "$wt" status --porcelain --untracked-files=all --ignore-submodules=none) || return 1
    if [[ -n "$dirty" ]]; then
      echo "stop: $b changed during preflight" >&2
      return 1
    fi
    if ! git merge-base --is-ancestor "$base" "$head"; then
      git -C "$wt" -c rerere.enabled=false rebase --quiet --rebase-merges --no-update-refs --no-autostash --no-fork-point --empty=stop "$base" || {
        echo "stop: rebase failed in $wt; resolve and continue there, or git rebase --abort" >&2
        return 1
      }
    fi
    head=$(git -C "$wt" rev-parse HEAD) || return 1
    if [[ "$head" == "$remote_head" ]]; then
      printf '%s (%s): up to date\n' "$wt" "$b"
      continue
    fi
    git -C "$wt" -c remote.origin.mirror=false push --quiet --no-follow-tags --recurse-submodules=no \
      "--force-with-lease=refs/heads/${b}:${remote_head}" origin "${head}:refs/heads/$b" || {
      echo "stop: push failed for $b; its local rebase remains, later worktrees were not touched" >&2
      return 1
    }
    printf '%s (%s): updated and pushed\n' "$wt" "$b"
  done
)

function _gitbranchworktree() {
  # print the folder of the worktree that has branch $2 checked out, run from worktree $1
  git -C "$1" worktree list --porcelain |
    awk -v ref="branch refs/heads/$2" '/^worktree / {p = substr($0, 10)} $0 == ref {print p}'
}


alias gitfilehistory='git log -p --follow -- '

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


function gitlastchange() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: [filename]"
    return 1
  fi  
  file="$1"
  git diff $(git rev-list -n 1 HEAD -- $file)^ -- $file
}


