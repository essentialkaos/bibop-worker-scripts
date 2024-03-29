#!/usr/bin/env bash

################################################################################

APP="run.sh"
VER="1.4.1"

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

# shellcheck disable=SC2034
CL_NORM="\e[${NORM}m"
# shellcheck disable=SC2034
CL_BOLD="\e[0;${BOLD};49m"
# shellcheck disable=SC2034
CL_UNLN="\e[0;${UNLN};49m"
# shellcheck disable=SC2034
CL_RED="\e[0;${RED};49m"
# shellcheck disable=SC2034
CL_GREEN="\e[0;${GREEN};49m"
# shellcheck disable=SC2034
CL_YELLOW="\e[0;${YELLOW};49m"
# shellcheck disable=SC2034
CL_BLUE="\e[0;${BLUE};49m"
# shellcheck disable=SC2034
CL_MAG="\e[0;${MAG};49m"
# shellcheck disable=SC2034
CL_CYAN="\e[0;${CYAN};49m"
# shellcheck disable=SC2034
CL_GREY="\e[0;${GREY};49m"
# shellcheck disable=SC2034
CL_DARK="\e[0;${DARK};49m"
# shellcheck disable=SC2034
CL_BL_RED="\e[1;${RED};49m"
# shellcheck disable=SC2034
CL_BL_GREEN="\e[1;${GREEN};49m"
# shellcheck disable=SC2034
CL_BL_YELLOW="\e[1;${YELLOW};49m"
# shellcheck disable=SC2034
CL_BL_BLUE="\e[1;${BLUE};49m"
# shellcheck disable=SC2034
CL_BL_MAG="\e[1;${MAG};49m"
# shellcheck disable=SC2034
CL_BL_CYAN="\e[1;${CYAN};49m"
# shellcheck disable=SC2034
CL_BL_GREY="\e[1;${GREY};49m"

################################################################################

REPO="https://github.com/essentialkaos/kaos-repo.git"
MAIN_DIR="/bibop"
ERROR_DIR="$MAIN_DIR/errors"
MARKER_FILE="$MAIN_DIR/.bibop-worker"
LOG_FILE="$MAIN_DIR/bibop.log"

################################################################################

SUPPORTED_OPTS="!validate !prepare !recheck !verbose !no_color !help !version"
SHORT_OPTS="V:!validate P:!prepare R:!recheck nc:!no_color h:!help v:!version"

################################################################################

os_version=""

################################################################################

# Main function
#
# *: All arguments passed to script
#
# Code: No
# Echo: No
main() {
  if [[ -n "$no_color" || -n "$NO_COLOR" ]] ; then
    unset NORM BOLD UNLN RED GREEN YELLOW BLUE MAG CYAN GREY DARK
    unset CL_NORM CL_BOLD CL_UNLN CL_RED CL_GREEN CL_YELLOW CL_BLUE CL_MAG CL_CYAN CL_GREY CL_DARK
    unset CL_BL_RED CL_BL_GREEN CL_BL_YELLOW CL_BL_BLUE CL_BL_MAG CL_BL_CYAN CL_BL_GREY CL_BL_DARK
    no_color=true
  fi

  if [[ -n "$version" ]] ; then
    about
    exit 0
  fi

  if [[ -n "$help" ]] ; then
    usage
    exit 0
  fi

  if [[ $(id -u) != "0" ]] ; then
    error "You must run this script as root"
    exit 1
  fi

  prepare
  start "$@"

  exit $?
}

# Check system before starting tests
#
# 1: Variable Description (Type)
#
# Code: No
# Echo: No
prepare() {
  os_version=$(grep 'CPE_NAME' /etc/os-release | tr -d '"' | cut -d':' -f5)

  case "$os_version" in
    "7"|"8"|"9") ;;
    *) error "Unknown or unsupported OS"
       exit 1 ;;
  esac
}

# Start testing process
#
# 1: Branch name (String)
#
# Code: No
# Echo: No
start() {
  local branch="${1:-develop}"

  if ! updatePackages ; then
    exit 1
  fi

  checkout "$branch"

  if [[ -n "$prepare" ]] ; then
    exit 0
  fi

  if [[ -n "$validate" ]] ; then
    runValidation
  else
    runTests "$branch"
  fi

  return $?
}

# Checkout the latest changes from git repository
#
# 1: Branch name (String)
#
# Code: No
# Echo: No
checkout() {
  local branch="$1"
  local status

  pushd "$MAIN_DIR" &> /dev/null || return

  if [[ ! -e kaos-repo ]] ; then
    if [[ -n "$branch" ]] ; then
      show "Checkout repository (branch: $branch)…" $BOLD
      git clone --depth=1 -b "$branch" "$REPO" &> /dev/null
      status=$?
    else
      show "Checkout repository…" $BOLD
      git clone --depth=1 "$REPO" &> /dev/null
      status=$?
    fi
  else
    pushd kaos-repo &> /dev/null || return

    show "Fetching the latests changes from repository…" $BOLD
    
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

# Update system packages to the latest versions
#
# Code: No
# Echo: No
updatePackages() {
  if [[ -f "$MARKER_FILE" ]] ; then
    return
  fi

  show "Cleaning cache…" $BOLD

  if ! execCmd yum clean all ; then
    error "Can't clean yum/dnf cache"
    return 1
  fi

  show "Installing required repositories…" $BOLD

  if ! rpm -q kaos-repo &> /dev/null ; then
    if ! execCmd yum install -y "https://pkgs.kaos.st/kaos-repo-latest.el${os_version}.noarch.rpm" ; then
      error "Can't install kaos-repo package"
      return 1
    fi
  fi

  if ! rpm -q epel-release &> /dev/null ; then
    if ! execCmd yum install -y epel-release ; then
      error "Can't install epel-release package"
      return 1
    fi
  fi

  if [[ $os_version -eq 7 ]] ; then
    if ! execCmd yum install -y yum-plugin-priorities ; then
      error "Can't install yum-plugin-priorities package"
      return 1
    fi
  fi

  # Try to enable CodeReady Builder repository
  if [[ $os_version -eq 9 ]] ; then
    execCmd dnf config-manager --set-enabled crb
    execCmd dnf config-manager --set-enabled ol9_codeready_builder
  fi

  if ! removeConflictingPackages ; then
    return 1
  fi

  show "Updating system packages…" $BOLD

  if ! execCmd yum clean expire-cache ; then
    error "Can't clean yum/dnf cache"
    return 1
  fi

  # Try to update almalinux-release with new keys before updating all package
  if rpm -q almalinux-release &> /dev/null ; then
    execCmd yum -y update almalinux-release
  fi
  
  if ! execCmd yum -y update ; then
    error "Can't update system packages"
    return 1
  fi

  if ! removeConflictingPackages ; then
    return 1
  fi

  show "Installing required packages…" $BOLD

  if ! execCmd yum -y install nano git curl wget gcc ; then
    error "Can't install required packages"
    return 1
  fi

  show "Disable SELinux…" $BOLD

  if ! setenforce 0 ; then
    error "Can't disable SELinux"
    return 1
  fi

  touch "$MARKER_FILE"

  show "Worker configuration successfully finished!" $GREEN
}

# Removes all incompatible packages
#
# Code: Yes
# Echo: No
removeConflictingPackages() {
  if rpm -q cloud-init &> /dev/null ; then
    if ! execCmd yum remove -y cloud-init ; then
      error "Can't remove cloud-init package"
    fi
  fi

  if [[ $os_version -le 8 ]] ; then
    if rpm -q libevent &> /dev/null ; then
      show "Removing libevent package…" $BOLD
      if ! execCmd yum remove -y libevent ; then
        error "Can't remove libevent package"
        return 1
      fi
    fi
  fi

  return 0
}

# Validate all tests
#
# Code: Yes
# Echo: No
runValidation() {
  show "System is ready. Running recipes validation…" $GREY

  bibop-massive -V "$MAIN_DIR/kaos-repo/tests"

  return $?
}

# Start tests
#
# 1: Branch name (String)
#
# Code: Yes
# Echo: No
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
  bibop-massive -e "$ERROR_DIR" -l "$LOG_FILE" $opts "$MAIN_DIR/kaos-repo/tests"

  return $?
}

# Run command
#
# *: Command with all options
#
# Code: Yes
# Echo: No
execCmd() {
  local ec

  if [[ -n "$verbose" ]] ; then
    show ""
    # shellcheck disable=SC2048
    $*
    ec=$?
    show ""

    return $ec
  fi

  # shellcheck disable=SC2048
  $* &> /dev/null
  return $?
}

# Show message
#
# 1: Message (String)
# 2: Message color (Number) [Optional]
#
# Code: No
# Echo: No
show() {
  if [[ -n "$2" && -z "$no_color" ]] ; then
    echo -e "\e[${2}m${1}\e[0m"
  else
    echo -e "$*"
  fi
}

# Print error message
#
# 1: Message (String)
# 2: Message color (Number) [Optional]
#
# Code: No
# Echo: No
error() {
  show "$*" $RED 1>&2
}

# Print usage info
#
# Code: No
# Echo: No
usage() {
  show ""
  show "${CL_BOLD}Usage:${CL_NORM} ./$APP ${CL_GREEN}{options}${CL_NORM} branch"
  show ""
  show "Options" $BOLD
  show ""
  show "  ${CL_GREEN}--prepare, -P${CL_NORM} ${CL_DARK}....${CL_NORM} Prepare system for tests"
  show "  ${CL_GREEN}--validate, -V${CL_NORM} ${CL_DARK}...${CL_NORM} Validate recipes ${CL_DARK}(dry run)${CL_NORM}"
  show "  ${CL_GREEN}--recheck, -R${CL_NORM} ${CL_DARK}....${CL_NORM} Recheck failed tests"
  show "  ${CL_GREEN}--verbose${CL_NORM} ${CL_DARK}........${CL_NORM} Verbose output"
  show "  ${CL_GREEN}--no-color, -nc${CL_NORM} ${CL_DARK}..${CL_NORM} Disable colors in output"
  show "  ${CL_GREEN}--help, -h${CL_NORM} ${CL_DARK}.......${CL_NORM} Show this help message"
  show "  ${CL_GREEN}--version, -v${CL_NORM} ${CL_DARK}....${CL_NORM} Show information about version"
  show ""
  show "Examples" $BOLD
  show ""
  show "  ./$APP --prepare"
  show "  Prepare system for tests" $DARK
  show ""
  show "  ./$APP master"
  show "  Run bibop tests from master branch of kaos-repo" $DARK
  show ""
}

# Show info about version
#
# Code: No
# Echo: No
about() {
  show ""
  show "${CL_BL_CYAN}$APP${CL_NORM} ${CL_CYAN}$VER${CL_NORM} - Script for running ${CL_BIBOP}bibop${CL_NORM} tests over kaos-repo"
  show ""
  show "Copyright (C) 2009-$(date +%Y) ESSENTIAL KAOS" $DARK
  show "Apache License, Version 2.0 <https://www.apache.org/licenses/LICENSE-2.0>" $DARK
  show ""
}

# Show warning message about unsupported option
#
# 1: Option name (String)
#
# Code: No
# Echo: No
showOptWarn() {
  error "Unknown option $1"
  exit 1
}

## OPTIONS PARSING 5 ###########################################################

if [[ $# -eq 0 ]] ; then
  main
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

################################################################################
