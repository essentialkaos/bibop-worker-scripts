#!/usr/bin/env bash
# shellcheck disable=SC1117,SC2034,SC2154,SC2181

################################################################################

APP="dep.sh"
VER="1.1.0"

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
CL_BIBOP="\e[38;5;85m"

################################################################################

SUPPORTED_OPTS="enablerepo disablerepo !no_colors !help !version"
SHORT_OPTS="ER:enablerepo DR:disablerepo nc:!no_colors h:!help v:!version"

################################################################################

# Main function
#
# *: All arguments passed to script
#
# Code: No
# Echo: No
main() {
  if [[ -n "$no_colors" || -n "$NO_COLOR" ]] ; then
    unset NORM BOLD UNLN RED GREEN YELLOW BLUE MAG CYAN GREY DARK
    unset CL_NORM CL_BOLD CL_UNLN CL_RED CL_GREEN CL_YELLOW CL_BLUE CL_MAG CL_CYAN CL_GREY CL_DARK
    unset CL_BL_RED CL_BL_GREEN CL_BL_YELLOW CL_BL_BLUE CL_BL_MAG CL_BL_CYAN CL_BL_GREY CL_BL_DARK
  fi

  if [[ -n "$version" ]] ; then
    about
    exit 0
  fi

  if [[ -n "$help" || $# -eq 0 ]] ; then
    usage
    exit 0
  fi

  if [[ $(id -u) != "0" ]] ; then
    error "You must run this script as root"
    exit 1
  fi

  doAction "$@"

  exit $?
}

# Run action
#
# 1: Action (String)
# 2: Path to recipe (String)
#
# Code: Yes
# Echo: No
doAction() {
  local action="$1"
  local recipe="$2"

  case $action in
    "install"|"i"|"I")   installPackages "$recipe" ;;
    "reinstall"|"r"|"R") reinstallPackages "$recipe" true ;;
    "uninstall"|"u"|"U") uninstallPackages ;;
    *)                   error "Unknown action $action" ;;
  esac

  return $?
}

# Install packages required for recipe
#
# 1: Path to recipe (String)
# 2: Reinstall flag (Boolean)
#
# Code: Yes
# Echo: No
installPackages() {
  local recipe="$1"
  local reinstall="$2"
  local opts pkgs

  if [[ -z "$recipe" || ! -e "$recipe" ]] ; then
    error "You should define recipe"
    return 1
  fi

  pkgs=$(bibop -L "$recipe" 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')

  if [[ -z "$pkgs" ]] ; then
    show "This recipe doesn't have any dependencies" $YELLOW
    exit 0
  fi

  show "${CL_BOLD}Installing packages:${CL_NORM} $pkgs"

  if [[ -n "$enablerepo" ]] ; then
    opts="--enablerepo=$enablerepo"
  fi

  if [[ -n "$disablerepo" ]] ; then
    opts="--disablerepo=$disablerepo"
  fi

  # shellcheck disable=SC2086
  yum $opts clean expire-cache

  if [[ -z "$reinstall" ]] ; then
    # shellcheck disable=SC2086
    yum $opts install $pkgs
  else
    # shellcheck disable=SC2086
    yum $opts reinstall $pkgs
  fi

  return $?
}

# Unistall all packages installed by previous transaction
#
# Code: Yes
# Echo: No
uninstallPackages() {
  yum history undo last
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
  if [[ -n "$2" && -z "$no_colors" ]] ; then
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
  show "${CL_BOLD}Usage:${CL_NORM} ./$APP ${CL_GREEN}{options}${CL_NORM} ${CL_MAG}{action}${CL_NORM} <recipe>"
  show ""
  show "Actions" $BOLD
  show ""
  show "  ${CL_MAG}install${CL_NORM}, ${CL_MAG}i${CL_NORM} ${CL_DARK}....${CL_NORM} Install packages"
  show "  ${CL_MAG}reinstall${CL_NORM}, ${CL_MAG}r${CL_NORM} ${CL_DARK}..${CL_NORM} Reinstall packages"
  show "  ${CL_MAG}uninstall${CL_NORM}, ${CL_MAG}u${CL_NORM} ${CL_DARK}..${CL_NORM} Uninstall packages"
  show ""
  show "Options" $BOLD
  show ""
  show "  ${CL_GREEN}--enablerepo, -ER${CL_NORM} ${CL_GREY}repo${CL_NORM} ${CL_DARK}...${CL_NORM} Enable repository"
  show "  ${CL_GREEN}--disablerepo, -DR${CL_NORM} ${CL_GREY}repo${CL_NORM} ${CL_DARK}..${CL_NORM} Disable repository"
  show "  ${CL_GREEN}--no-color, -nc${CL_NORM} ${CL_DARK}..........${CL_NORM} Disable colors in output"
  show "  ${CL_GREEN}--help, -h${CL_NORM} ${CL_DARK}...............${CL_NORM} Show this help message"
  show "  ${CL_GREEN}--version, -v${CL_NORM} ${CL_DARK}............${CL_NORM} Show information about version"
  show ""
  show "Examples" $BOLD
  show ""
  show "  ./$APP install --enablerepo kaos-testing myapp.recipe"
  show "  Install packages for myapp recipe with enabled kaos-testing repository" $DARK
  show ""
  show "  ./$APP uninstall"
  show "  Uninstall all packages installed by previous transaction" $DARK
  show ""
}

# Show info about version
#
# Code: No
# Echo: No
about() {
  show ""
  show "${CL_BL_CYAN}$APP${CL_NORM} ${CL_CYAN}$VER${CL_NORM} - Script for installing/uninstalling ${CL_BIBOP}bibop${CL_NORM} recipe dependencies"
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

################################################################################
