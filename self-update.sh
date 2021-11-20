#!/usr/bin/env bash

################################################################################

REPO="https://kaos.sh/bibop-worker-scripts"
SCRIPTS_DIR="/root"

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

main() {
  if [[ $(id -u) != "0" ]] ; then
    error "You must run this script as root"
    exit 1
  fi

  showm "Updating bibop worker scripts: "

  download "run.sh"
  download "dep.sh"
  download "update.sh"
  download "self-update.sh"

  show " DONE" $GREEN
}

# Download file from remote repository
#
# 1: File name (String)
#
# Code: No
# Echo: No
download() {
  local file="$1"

  curl -L -o "$SCRIPTS_DIR/$file" "$REPO/$file" &> /dev/null

  if [[ $? -ne 0 ]] ; then
    printStatusDot true
    show " ERROR" $RED
    error "Can't download $file script"
    exit 1
  fi

  printStatusDot

  chmod +x "$SCRIPTS_DIR/$file"
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

################################################################################

main "$@"
