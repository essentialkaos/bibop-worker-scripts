#!/bin/bash

################################################################################

REPO="https://github.com/essentialkaos/kaos-repo.git"
ERROR_DIR="/root/errors"
LOG_FILE="/root/bibop.log"

################################################################################

main() {
  local branch="$1"

  checkout "$branch"
  updatePackages
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
    echo "Switching current branch to ${branch}…"
    pushd kaos-repo &> /dev/null
      git checkout "$branch" &> /dev/null
      git pull &> /dev/null
    popd &> /dev/null
  fi

  popd &> /dev/null
}

updatePackages() {
  echo "Updating system packages…"

  yum -q clean expire-cache &> /dev/null
  yum -q -y update &> /dev/null

  echo "Packages successfully updated"
}

runTests() {
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
