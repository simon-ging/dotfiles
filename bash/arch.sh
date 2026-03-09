archupgradeall() {
  sudo pacman -Syu
  sudo -v
  yay --noconfirm --noredownload --norebuild --answerclean n --answerdiff n --answeredit n --answerupgrade y "$@" -Syu
}

archwhich() {
  local cmd="$1"
  if [[ -z "$cmd" ]]; then
    echo "usage: archwhich <command>" >&2
    return 2
  fi

  local bin pkg repo inst_date helper msg
  bin="$(command -v -- "$cmd" 2>/dev/null)" || true
  if [[ -z "$bin" ]]; then
    echo "$cmd: not found in PATH" >&2
    return 127
  fi

  # Resolve symlinks where possible
  if command -v readlink >/dev/null 2>&1; then
    bin="$(readlink -f -- "$bin" 2>/dev/null || echo "$bin")"
  fi

  # Who owns the binary?
  if ! msg="$(pacman -Qo -- "$bin" 2>/dev/null)"; then
    echo "$cmd -> $bin"
    echo "owner: none (not managed by pacman)  [possible: manual install / AppImage / flatpak]"
    if command -v flatpak >/dev/null 2>&1; then
      local fp
      fp="$(flatpak list --app 2>/dev/null | awk -v IGNORECASE=1 -v c="$cmd" '$0 ~ c {print}')"
      [[ -n "$fp" ]] && echo "flatpak: possible match: $fp"
    fi
    return 0
  fi

  # Parse package name from pacman -Qo output: "<path> is owned by <pkg> <ver>"
  pkg="$(awk '{print $(NF-1)}' <<<"$msg")"

  repo="$(pacman -Si -- "$pkg" 2>/dev/null | awk -F': *' '/^Repository/ {print $2; exit}')"
  [[ -z "$repo" ]] && repo="local/unknown"

  inst_date="$(pacman -Qi -- "$pkg" 2>/dev/null | awk -F': *' '/^Install Date/ {print $2; exit}')"

  # Best-effort guess of AUR helper involvement
  helper="pacman"
  if command -v yay >/dev/null 2>&1 && yay -Q -- "$pkg" >/dev/null 2>&1; then
    helper="yay"
  elif command -v paru >/dev/null 2>&1 && paru -Q -- "$pkg" >/dev/null 2>&1; then
    helper="paru"
  elif command -v pikaur >/dev/null 2>&1 && pikaur -Q -- "$pkg" >/dev/null 2>&1; then
    helper="pikaur"
  fi

  echo "$cmd -> $bin"
  echo "package: $pkg"
  echo "repo:    $repo"
  [[ -n "$inst_date" ]] && echo "installed: $inst_date"
  echo "via:     $helper"

  # Show last pacman transaction lines involving this package (install/upgrade)
  if [[ -r /var/log/pacman.log ]]; then
    local last line
    last="$(grep -nE "(installed|upgraded) ${pkg} " /var/log/pacman.log 2>/dev/null | tail -n 1)"
    if [[ -n "$last" ]]; then
      line="${last%%:*}"
      echo "pacman.log:"
      sed -n "$((line-2)),$((line+2))p" /var/log/pacman.log 2>/dev/null
    fi
  fi
}

