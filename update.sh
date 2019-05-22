#!/bin/bash

################################################################################

main() {
  local branch="${1:-master}"

  echo "Updating bibop apps…"

  updateBibop
  updateBibopMassive "$branch"

  echo "Apps successfully updated"
}

updateBibop() {
  bash <(curl -fsSL https://apps.kaos.st/get) bibop
  chmod +x bibop
  yes | mv bibop /usr/bin/ &> /dev/null
}

updateBibopMassive() {
  local branch="$1"

  curl -# -o /usr/bin/bibop-massive "https://raw.githubusercontent.com/essentialkaos/${branch}/develop/bibop-massive"
  chmod +x /usr/bin/bibop-massive
}

################################################################################

main "$@"
