#!/usr/bin/env bash
# shellcheck disable=SC1117,SC2034,SC2154,SC2181

################################################################################

NORM=0
BOLD=1
UNLN=4
RED=31
GREEN=32
YELLOW=33
BLUE=34
MAG=35
CYAN=36
GREY=37
DARK=90

CL_NORM="\e[0m"
CL_BOLD="\e[0;${BOLD};49m"
CL_UNLN="\e[0;${UNLN};49m"
CL_RED="\e[0;${RED};49m"
CL_GREEN="\e[0;${GREEN};49m"
CL_YELLOW="\e[0;${YELLOW};49m"
CL_BLUE="\e[0;${BLUE};49m"
CL_MAG="\e[0;${MAG};49m"
CL_CYAN="\e[0;${CYAN};49m"
CL_GREY="\e[0;${GREY};49m"
CL_DARK="\e[0;${DARK};49m"
CL_BL_RED="\e[1;${RED};49m"
CL_BL_GREEN="\e[1;${GREEN};49m"
CL_BL_YELLOW="\e[1;${YELLOW};49m"
CL_BL_BLUE="\e[1;${BLUE};49m"
CL_BL_MAG="\e[1;${MAG};49m"
CL_BL_CYAN="\e[1;${CYAN};49m"
CL_BL_GREY="\e[1;${GREY};49m"

################################################################################

REPO="https://github.com/essentialkaos/kaos-repo.git"
ERROR_DIR="/root/errors"
MARKER_FILE="/root/.bibop-worker"
LOG_FILE="/root/bibop.log"

################################################################################

SUPPORTED_OPTS="!validate !prepare !recheck"
SHORT_OPTS="V:!validate P:!prepare R:!recheck"

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
      show "Checkout repository (branch: $branch)…"
      git clone --depth=1 -b "$branch" "$REPO" &> /dev/null
      status=$?
    else
      show "Checkout repository…"
      git clone --depth=1 "$REPO" &> /dev/null
      status=$?
    fi
  else
    pushd kaos-repo &> /dev/null || return

    show "Fetching the latests changes from repository…"
    git pull &> /dev/null
    status=$?

    popd &> /dev/null || return
  fi

  if [[ $status -ne 0 ]] ; then
    error "Can't checkout repository with specs and recipes"
    exit 1
  else
    show "The latests version of specs and recipes successfully fetched" $GREEN
  fi

  popd &> /dev/null || return
}

updatePackages() {
  if [[ -f "$MARKER_FILE" ]] ; then
    return
  fi

  if ! yum -q clean expire-cache &> /dev/null ; then
    error "Can't clean yum cache"
    return 1
  fi

  show "Installing required repositories…"

  if ! rpm -q kaos-repo &> /dev/null ; then
    # shellcheck disable=SC2046
    if ! yum install -q -y https://yum.kaos.st/get/$(uname -r).rpm &> /dev/null ; then
      error "Can't install kaos-repo package"
      return 1
    fi
  fi

  if ! rpm -q epel-release &> /dev/null ; then
    if ! yum install -q -y epel-release &> /dev/null ; then
      error "Can't install epel-release package"
      return 1
    fi
  fi

  show "Updating system packages…"

  if ! yum -q clean expire-cache &> /dev/null ; then
    error "Can't clean yum cache"
    return 1
  fi
  
  if ! yum -q -y update &> /dev/null ; then
    error "Can't update system packages"
    return 1
  fi

  show "Installing required packages…"

  if ! yum -q -y install nano mtl git tmux curl wget &> /dev/null ; then
    error "Can't install required packages"
    return 1
  fi

  touch "$MARKER_FILE"

  show "Worker configuration successfully finished!" $GREEN
}

runValidation() {
  show "System is ready. Running recipes validation…"

  bibop-massive -V /root/kaos-repo/tests

  return $?
}

runTests() {
  show "System is ready. Running tests…"

  local opts
  local branch="$1"

  if [[ -e "$ERROR_DIR" ]] ; then
    rm -rf "$ERROR_DIR"
  fi

  mkdir "$ERROR_DIR"

  if [[ "$branch" == "develop" ]] ; then
    opts="-ER kaos-testing"
  fi

  if [[ -n "$recheck" ]] ; then
    opts="$opts -R"
  fi

  # shellcheck disable=SC2086
  bibop-massive -e "$ERROR_DIR" -l "$LOG_FILE" $opts /root/kaos-repo/tests

  return $?
}

show() {
  if [[ -n "$2" && -z "$no_colors" ]] ; then
    echo -e "\e[${2}m${1}\e[0m"
  else
    echo -e "$*"
  fi
}

error() {
  show "$@" $RED 1>&2
}

showArgWarn() {
  error "Unknown option $1" $RED
  exit 1
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
