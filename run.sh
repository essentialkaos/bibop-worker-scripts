#!/usr/bin/env bash
# shellcheck disable=SC1117,SC2034,SC2154,SC2181

################################################################################

REPO="https://github.com/essentialkaos/kaos-repo.git"
ERROR_DIR="/root/errors"
MARKER_FILE="/root/.bibop-worker"
LOG_FILE="/root/bibop.log"

################################################################################

SUPPORTED_OPTS="!validate !prepare"
SHORT_OPTS="V:!validate P:!prepare"

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
    runTests "$branch"
  fi

  exit $?
}

checkout() {
  local branch="$1"
  local status

  pushd /root &> /dev/null || return

  if [[ ! -e kaos-repo ]] ; then
    if [[ -n "$branch" ]] ; then
      echo "Checkout repository (branch: $branch)…"
      git clone --depth=1 -b "$branch" "$REPO" &> /dev/null
      status=$?
    else
      echo "Checkout repository…"
      git clone --depth=1 "$REPO" &> /dev/null
      status=$?
    fi
  else
    pushd kaos-repo &> /dev/null || return

    echo "Fetching the latests changes from repository…"
    git pull &> /dev/null
    status=$?

    popd &> /dev/null || return
  fi

  if [[ $status -ne 0 ]] ; then
    echo "Can't checkout repository with specs and recipes"
    exit 1
  else
    echo "The latests version of specs and recipes successfully fetched"
  fi

  popd &> /dev/null || return
}

updatePackages() {
  if [[ -f "$MARKER_FILE" ]] ; then
    return
  fi

  if ! yum -q clean expire-cache &> /dev/null ; then
    echo "Can't clean yum cache"
    return 1
  fi

  echo "Installing required repositories…"

  if ! rpm -q kaos-repo &> /dev/null ; then
    # shellcheck disable=SC2046
    if ! yum install -q -y https://yum.kaos.st/get/$(uname -r).rpm &> /dev/null ; then
      echo "Can't install kaos-repo package"
      return 1
    fi
  fi

  if ! rpm -q epel-release &> /dev/null ; then
    if ! yum install -q -y epel-release &> /dev/null ; then
      echo "Can't install epel-release package"
      return 1
    fi
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

  touch "$MARKER_FILE"

  echo "Worker configuration successfully finished"
}

runValidation() {
  echo "System is ready. Running recipes validation…"

  bibop-massive -V /root/kaos-repo/tests

  return $?
}

runTests() {
  echo "System is ready. Running tests…"

  local opts
  local branch="$1"

  if [[ -e "$ERROR_DIR" ]] ; then
    rm -rf "$ERROR_DIR"
  fi

  mkdir "$ERROR_DIR"

  if [[ "$branch" == "develop" ]] ; then
    opts="-ER kaos-testing"
  fi

  # shellcheck disable=SC2086
  bibop-massive -e "$ERROR_DIR" -l "$LOG_FILE" $opts /root/kaos-repo/tests

  return $?
}

## OPTIONS PARSING 5 ###################################################################

if [[ $# -eq 0 ]] ; then
  main
  exit $?
fi

unset opt optn optm optv optt optk

optv="$*" ; optt=""

while [[ -n "$1" ]] ; do
  if [[ "$1" =~ \  && -n "$optn" ]] ; then
    declare "$optn=$1"

    unset optn && shift && continue
  elif [[ $1 =~ ^-{1}[a-zA-Z0-9]{1,2}+.*$ ]] ; then
    optm=${1:1}

    if [[ \ $SHORT_OPTS\  =~ \ $optm:!?([a-zA-Z0-9_]*) ]] ; then
      opt="${BASH_REMATCH[1]}"
    else
      declare -F showOptWarn &>/dev/null && showOptWarn "-$optm"
      shift && continue
    fi

    if [[ -z "$optn" ]] ; then
      optn=$opt
    else
      # shellcheck disable=SC2015
      [[ -z "$optk" ]] && ( declare -F showOptValWarn &>/dev/null && showOptValWarn "--$optn" ) || declare "$optn=true"
      optn=$opt
    fi

    if [[ ! $SUPPORTED_OPTS\  =~ !?$optn\  ]] ; then
      declare -F showOptWarn &>/dev/null && showOptWarn "-$optm"
      shift && continue
    fi

    if [[ ${BASH_REMATCH[0]:0:1} == "!" ]] ; then
      declare "$optn=true" ; unset optn ; optk=true
    else
      unset optk
    fi

    shift && continue
  elif [[ "$1" =~ ^-{2}[a-zA-Z]{1}[a-zA-Z0-9_-]+.*$ ]] ; then
    opt=${1:2}

    if [[ $opt == *=* ]] ; then
      IFS="=" read -ra opt <<< "$opt"

      optm="${opt[0]}" ; optm=${optm//-/_}

      if [[ ! $SUPPORTED_OPTS\  =~ $optm\  ]] ; then
        declare -F showOptWarn &>/dev/null && showOptWarn "--${opt[0]//_/-}"
        shift && continue
      fi

      # shellcheck disable=SC2015
      [[ -n "${!optm}" && $MERGEABLE_OPTS\  =~ $optm\  ]] && declare "$optm=${!optm} ${opt[*]:1:99}" || declare "$optm=${opt[*]:1:99}"

      unset optm && shift && continue
    else
      # shellcheck disable=SC2178
      opt=${opt//-/_}

      if [[ -z "$optn" ]] ; then
        # shellcheck disable=SC2128
        optn=$opt
      else
        # shellcheck disable=SC2015
        [[ -z "$optk" ]] && ( declare -F showOptValWarn &>/dev/null && showOptValWarn "--$optn" ) || declare "$optn=true"
        # shellcheck disable=SC2128
        optn=$opt
      fi

      if [[ ! $SUPPORTED_OPTS\  =~ !?$optn\  ]] ; then
        declare -F showOptWarn &>/dev/null && showOptWarn "--${optn//_/-}"
        shift && continue
      fi

      if [[ ${BASH_REMATCH[0]:0:1} == "!" ]] ; then
        declare "$optn=true" ; unset optn ; optk=true
      else
        unset optk
      fi

      shift && continue
    fi
  else
    if [[ -n "$optn" ]] ; then
      # shellcheck disable=SC2015
      [[ -n "${!optn}" && $MERGEABLE_OPTS\  =~ $optn\  ]] && declare "$optn=${!optn} $1" || declare "$optn=$1"

      unset optn && shift && continue
    fi
  fi

  optt="$optt $1" ; shift

done

[[ -n "$optn" ]] && declare "$optn=true"

unset opt optn optm optk

# shellcheck disable=SC2015,SC2086
[[ -n "$KEEP_OPTS" ]] && main $optv || main ${optt:1}

########################################################################################
