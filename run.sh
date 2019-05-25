#!/usr/bin/env bash

################################################################################

REPO="https://github.com/essentialkaos/kaos-repo.git"
ERROR_DIR="/root/errors"
LOG_FILE="/root/bibop.log"

################################################################################

main() {
  local branch="${1:-develop}"

  updatePackages
  checkout "$branch"
  runTests

  exit $?
}

checkout() {
  local branch="$1"

  pushd /root &> /dev/null

  if [[ ! -e kaos-repo ]] ; then
    echo "Checkout repository…"
    git clone "$REPO" &> /dev/null
  fi

  if [[ -n "$branch" ]] ; then
    pushd kaos-repo &> /dev/null

      echo "Switching current branch to ${branch}…"
      git checkout "$branch" &> /dev/null

      echo "Fetching the latest changes…"
      git pull &> /dev/null

    popd &> /dev/null
  fi

  popd &> /dev/null
}

updatePackages() {
  if rpm -q kaos-repo &> /dev/null ; then
    return
  fi

  yum -q clean expire-cache &> /dev/null

  echo "Installing required repositories…"

  yum install -q -y https://yum.kaos.st/get/$(uname -r).rpm &> /dev/null
  yum install -q -y epel-release &> /dev/null

  echo "Updating system packages…"

  yum -q clean expire-cache &> /dev/null
  yum -q -y update &> /dev/null

  echo "Installing required packages…"

  yum -q -y install nano mtl git tmux curl wget &> /dev/null

  echo "Worker configuration successfully finished"
}

runTests() {
  echo "System is ready. Running tests…"

  if [[ ! -e "$ERROR_DIR" ]] ; then
    mkdir "$ERROR_DIR"
  fi

  bibop-massive -e "$ERROR_DIR" \
                -l "$LOG_FILE" \
                -ER kaos-testing \
                /root/kaos-repo/tests

  return $?
}

################################################################################

main "$@"
