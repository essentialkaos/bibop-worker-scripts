#!/bin/bash

################################################################################

SCRIPTS_DIR="/root"

################################################################################

main() {
  echo "Updating scripts…"

  curl -# -L -o $SCRIPTS_DIR/run.sh https://kaos.sh/bibop-worker-scripts/run.sh
  curl -# -L -o $SCRIPTS_DIR/dep.sh https://kaos.sh/bibop-worker-scripts/dep.sh
  curl -# -L -o $SCRIPTS_DIR/update.sh https://kaos.sh/bibop-worker-scripts/update.sh
  curl -# -L -o $SCRIPTS_DIR/self-update.sh https://kaos.sh/bibop-worker-scripts/self-update.sh

  chmod +x $SCRIPTS_DIR/*.sh

  echo "Scripts successfully updated"
}

################################################################################

main "$@"
