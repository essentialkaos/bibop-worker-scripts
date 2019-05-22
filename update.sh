#!/bin/bash

################################################################################

main() {
  updateBibop
  updateBibopMassive
}

updateBibop() {
  bash <(curl -fsSL https://apps.kaos.st/get) bibop 1.0.0 &> /dev/null
  chmod +x bibop
  yes | mv bibop /usr/bin/ &> /dev/null
}

updateBibopMassive() {
  curl -o /usr/bin/bibop-massive https://raw.githubusercontent.com/essentialkaos/bibop/develop/bibop-massive &> /dev/null
  chmod +x /usr/bin/bibop-massive
}

################################################################################

main "$@"
