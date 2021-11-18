#!/usr/bin/env bash

################################################################################

REPO="https://kaos.sh/bibop-worker-scripts"
SCRIPTS_DIR="/root"

################################################################################

main() {
  if [[ $(id -u) != "0" ]] ; then
    echo "You must run this script as root"
    exit 1
  fi

  echo "Updating scripts…"

  download "run.sh"
  download "dep.sh"
  download "update.sh"
  download "self-update.sh"

  echo "All scripts successfully updated"
}

download() {
  local file="$1"

  curl -# -L -o "$SCRIPTS_DIR/$file" "$REPO/$file"

  if [[ -f "$SCRIPTS_DIR/$file" ]] ; then
    chmod +x "$SCRIPTS_DIR/$file"
  fi
}

################################################################################

main "$@"
