#!/usr/bin/env bash
# shellcheck disable=SC1117,SC2034,SC2154,SC2181

################################################################################

APP="update.sh"
VER="1.2.0"

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

BIBOP_REPO="https://raw.githubusercontent.com/essentialkaos/bibop"

################################################################################

SUPPORTED_OPTS="branch bibop_version !help !version"
SHORT_OPTS="b:branch B:bibop_version h:!help v:!version"

################################################################################

branch="master"
bibop_version=""

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

  if [[ -n "$help" ]] ; then
    usage
    exit 0
  fi

  if [[ $(id -u) != "0" ]] ; then
    error "You must run this script as root"
    exit 1
  fi

  update
}

# Start update process
#
# Code: No
# Echo: No
update() {
  showm "Updating ${CL_BIBOP}bibop${CL_NORM} & scripts: "

  updateBibop
  updateScripts

  show " DONE" $GREEN
}

# Update bibop binary
#
# Code: No
# Echo: No
updateBibop() {
  if [[ -z "$bibop_version" ]] ; then
    bash <(curl -fsSL https://apps.kaos.st/get) bibop &> /dev/null
  else
    bash <(curl -fsSL https://apps.kaos.st/get) bibop "$bibop_version" &> /dev/null
  fi

  if [[ $? -ne 0 ]] ; then
    printStatusDot true
    show " ERROR" $RED
    error "Can't download bibop binary"
    exit 1
  fi

  chmod +x bibop

  # shellcheck disable=SC2216
  yes | mv bibop /usr/bin/ &> /dev/null

  printStatusDot
}

# Update helper scripts
#
# Code: No
# Echo: No
updateScripts() {
  local script

  for script in "bibop-massive" "bibop-dep" "bibop-multi-check" "bibop-so-exported" "bibop-libtest-gen" ; do
    download "${branch}/scripts/${script}" "/usr/bin/$script"

    if [[ $? -ne 0 ]] ; then
      printStatusDot true
      show " ERROR" $RED
      error "Can't download $script script"
      exit 1
    fi

    chmod +x "/usr/bin/$script"

    printStatusDot
  done
}

# Download file from GitHub repository
#
# 1: Path to file (String)
# 2: Output file (String)
#
# Code: Yes
# Echo: No
download() {
  local path="$1"
  local output="$2"
  local rnd http_code

  rnd=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w8 | head -n1)

  http_code=$(curl -s -L -w "%{http_code}" -o "$output" "$BIBOP_REPO/${path}?r${rnd}")

  if [[ "$http_code" != "200" ]] ; then
    return 1
  fi

  return 0
}

# Print status dot
#
# 1: Error flag (Boolean) [Optional]
#
# Code: No
# Echo: No
printStatusDot() {
  if [[ -z "$1" ]] ; then
    showm "•" $GREEN
  else
    showm "•" $RED
  fi
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

# Show message without new line
#
# 1: Message (String)
# 2: Message color (Number) [Optional]
#
# Code: No
# Echo: No
showm() {
  if [[ -n "$2" && -z "$no_colors" ]] ; then
    echo -e -n "\e[${2}m${1}\e[0m"
  else
    echo -e -n "$*"
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
  show "${CL_BOLD}Usage:${CL_NORM} ./$APP ${CL_GREEN}{options}${CL_NORM}"
  show ""
  show "Options" $BOLD
  show ""
  show "  ${CL_GREEN}--branch, -b${CL_NORM} ${CL_GREY}branch${CL_NORM} ${CL_DARK}..........${CL_NORM} Source branch ${CL_DARK}(default: master)${CL_NORM}"
  show "  ${CL_GREEN}--bibop-version, -B${CL_NORM} ${CL_GREY}version${CL_NORM} ${CL_DARK}..${CL_NORM} Bibop version ${CL_DARK}(default: latest)${CL_NORM}"
  show "  ${CL_GREEN}--help, -h${CL_NORM} ${CL_DARK}...................${CL_NORM} Show this help message"
  show ""
  show "Examples" $BOLD
  show ""
  show "  ./$APP --branch develop --bibop-version 4.7.0"
  show "  Update scripts to versions from master brach and download bibop 4.7.0" $DARK
  show ""
}

# Show info about version
#
# Code: No
# Echo: No
about() {
  show ""
  show "${CL_BL_CYAN}$APP${CL_NORM} ${CL_CYAN}$VER${CL_NORM} - Script for updating ${CL_BIBOP}bibop${CL_NORM} and helper scripts"
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
