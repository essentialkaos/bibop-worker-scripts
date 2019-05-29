#!/usr/bin/env bash

################################################################################

REPO="https://github.com/essentialkaos/kaos-repo.git"
ERROR_DIR="/root/errors"
LOG_FILE="/root/bibop.log"

################################################################################

SUPPORTED_ARGS="!validate !prepare"
SHORT_ARGS="V:!validate P:!prepare"

################################################################################

main() {
  local branch="${1:-develop}"

  updatePackages

  if [[ $? -ne 0 ]] ; then
    exit 1
  fi

  checkout "$branch"

  if [[ -n "$prepare" ]] ; then
    exit $?
  fi

  if [[ -n "$validate" ]] ; then
    runValidation
  else
    runTests
  fi

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

  if ! yum -q clean expire-cache &> /dev/null ; then
    echo "Can't clean yum cache"
    return 1
  fi

  echo "Installing required repositories…"

  if ! yum install -q -y https://yum.kaos.st/get/$(uname -r).rpm &> /dev/null ; then
    echo "Can't install kaos-repo package"
    return 1
  fi

  if ! yum install -q -y epel-release &> /dev/null ; then
    echo "Can't install epel-release package"
    return 1
  fi

  echo "Updating system packages…"

  if ! yum -q clean expire-cache &> /dev/null ; then
    echo "Can't clean yum cache"
    return 1
  fi
  
  if ! yum -q -y update &> /dev/null ; then
    echo "Can't update system packages"
    return 1
  fi

  echo "Installing required packages…"

  if ! yum -q -y install nano mtl git tmux curl wget &> /dev/null ; then
    echo "Can't install required packages"
    return 1
  fi

  echo "Worker configuration successfully finished"
}

runValidation() {
  echo "System is ready. Running recipes validation…"

  bibop-massive -V /root/kaos-repo/tests

  return $?
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

## OPTIONS PARSING 4 ###########################################################

[[ $# -eq 0 ]] && main && exit $?

unset arg argn argm argv argt argk

argv="$*" ; argt=""

while [[ -n "$1" ]] ; do
  if [[ "$1" =~ \  && -n "$argn" ]] ; then
    declare "$argn=$1"

    unset argn && shift && continue
  elif [[ $1 =~ ^-{1}[a-zA-Z0-9]{1,2}+.*$ ]] ; then
    argm=${1:1}

    if [[ \ $SHORT_ARGS\  =~ \ $argm:!?([a-zA-Z0-9_]*) ]] ; then
      arg="${BASH_REMATCH[1]}"
    else
      declare -F showArgWarn &>/dev/null && showArgWarn "-$argm"
      shift && continue
    fi

    if [[ -z "$argn" ]] ; then
      argn=$arg
    else
      # shellcheck disable=SC2015
      [[ -z "$argk" ]] && ( declare -F showArgValWarn &>/dev/null && showArgValWarn "--$argn" ) || declare "$argn=true"
      argn=$arg
    fi

    if [[ ! $SUPPORTED_ARGS\  =~ !?$argn\  ]] ; then
      declare -F showArgWarn &>/dev/null && showArgWarn "-$argm"
      shift && continue
    fi

    if [[ ${BASH_REMATCH[0]:0:1} == "!" ]] ; then
      declare "$argn=true" ; unset argn ; argk=true
    else
      unset argk
    fi

    shift && continue
  elif [[ "$1" =~ ^-{2}[a-zA-Z]{1}[a-zA-Z0-9_-]+.*$ ]] ; then
    arg=${1:2}

    if [[ $arg == *=* ]] ; then
      IFS="=" read -ra arg <<< "$arg"

      argm="${arg[0]}" ; argm=${argm//-/_}

      if [[ ! $SUPPORTED_ARGS\  =~ $argm\  ]] ; then
        declare -F showArgWarn &>/dev/null && showArgWarn "--${arg[0]//_/-}"
        shift && continue
      fi

      # shellcheck disable=SC2015
      [[ -n "${!argm}" && $MERGEABLE_ARGS\  =~ $argm\  ]] && declare "$argm=${!argm} ${arg[*]:1:99}" || declare "$argm=${arg[*]:1:99}"

      unset argm && shift && continue
    else
      arg=${arg//-/_}

      if [[ -z "$argn" ]] ; then
        argn=$arg
      else
        # shellcheck disable=SC2015
        [[ -z "$argk" ]] && ( declare -F showArgValWarn &>/dev/null && showArgValWarn "--$argn" ) || declare "$argn=true"
        argn=$arg
      fi

      if [[ ! $SUPPORTED_ARGS\  =~ !?$argn\  ]] ; then
        declare -F showArgWarn &>/dev/null && showArgWarn "--${argn//_/-}"
        shift && continue
      fi

      if [[ ${BASH_REMATCH[0]:0:1} == "!" ]] ; then
        declare "$argn=true" ; unset argn ; argk=true
      else
        unset argk
      fi

      shift && continue
    fi
  else
    if [[ -n "$argn" ]] ; then
      # shellcheck disable=SC2015
      [[ -n "${!argn}" && $MERGEABLE_ARGS\  =~ $argn\  ]] && declare "$argn=${!argn} $1" || declare "$argn=$1"

      unset argn && shift && continue
    fi
  fi

  argt="$argt $1" ; shift

done

[[ -n "$argn" ]] && declare "$argn=true"

unset arg argn argm argk

# shellcheck disable=SC2015,SC2086
[[ -n "$KEEP_ARGS" ]] && main $argv || main ${argt:1}

########################################################################################
