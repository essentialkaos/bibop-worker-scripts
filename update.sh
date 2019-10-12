#!/usr/bin/env bash

################################################################################

main() {
  local branch="${1:-master}"

  echo "Updating bibop binary and helpers…"

  updateBibop
  updateBibopMassive "$branch"
  updateBibopMultiCheck "$branch"

  echo "Bibop binary and helper scripts successfully updated"
}

updateBibop() {
  bash <(curl -fsSL https://apps.kaos.st/get) bibop
  chmod +x bibop
  yes | mv bibop /usr/bin/ &> /dev/null
}

updateBibopMassive() {
  local branch="$1"

  curl -# -o /usr/bin/bibop-massive "https://raw.githubusercontent.com/essentialkaos/bibop/${branch}/bibop-massive"

  chmod +x /usr/bin/bibop-massive
}

updateBibopMultiCheck() {
  local branch="$1"

  curl -# -o /usr/bin/bibop-multi-check "https://raw.githubusercontent.com/essentialkaos/bibop/${branch}/bibop-multi-check"

  chmod +x /usr/bin/bibop-multi-check
}

################################################################################

main "$@"
