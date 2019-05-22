#!/bin/bash

################################################################################

main() {
  local branch="${1:-master}"

  updateBibop
  updateBibopMassive "$branch"
}

updateBibop() {
  bash <(curl -fsSL https://apps.kaos.st/get) bibop &> /dev/null
  chmod +x bibop
  yes | mv bibop /usr/bin/ &> /dev/null
}

updateBibopMassive() {
  local branch="$1"

  curl -o /usr/bin/bibop-massive "https://raw.githubusercontent.com/essentialkaos/${branch}/develop/bibop-massive" &> /dev/null
  chmod +x /usr/bin/bibop-massive
}

################################################################################

main "$@"
