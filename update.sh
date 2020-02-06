#!/usr/bin/env bash

################################################################################

SOURCE_URL="https://raw.githubusercontent.com/essentialkaos/bibop"

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

  # shellcheck disable=SC2216
  yes | mv bibop /usr/bin/ &> /dev/null
}

updateBibopMassive() {
  local branch="$1"

  download "${branch}/bibop-massive" "/usr/bin/bibop-massive"

  chmod +x /usr/bin/bibop-massive
}

updateBibopMultiCheck() {
  local branch="$1"

  download "${branch}/bibop-multi-check" "/usr/bin/bibop-multi-check"

  chmod +x /usr/bin/bibop-multi-check
}

download() {
  local path="$1"
  local output="$2"
  local rnd

  rnd=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w8 | head -n1)

  curl -# -o "$output" "$SOURCE_URL/${path}?r${rnd}"

  return $?
}

################################################################################

main "$@"
