#!/usr/bin/env bash
set -euo pipefail

log() { printf '\n>> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ ${EUID:-$(id -u)} -ne 0 ]] || die "Run this script as your normal user, not with sudo."
[[ -r /etc/os-release ]] || die "/etc/os-release not found."
. /etc/os-release
[[ "${ID:-}" == "fedora" ]] || die "This rollback targets Fedora."

if ! rpm -q python3-validity >/dev/null 2>&1; then
  die "python3-validity is not installed, so there is no Fedora package to restore."
fi

log "Stopping fingerprint services"
sudo systemctl stop python3-validity.service 2>/dev/null || true
sudo systemctl stop open-fprintd.service 2>/dev/null || true

log "Restoring files owned by the Fedora/COPR python3-validity package"
sudo dnf reinstall -y python3-validity

log "Reloading udev and services"
sudo udevadm control --reload-rules
sudo udevadm trigger --attr-match=idVendor=138a --attr-match=idProduct=00ab || true
sudo systemctl daemon-reload
sudo systemctl restart python3-validity.service 2>/dev/null || true
sudo systemctl restart open-fprintd.service 2>/dev/null || true

cat <<'EOF'

The experimental source overlay has been removed by reinstalling the packaged
python3-validity files.

This rollback intentionally does NOT:
  - delete enrolled fingerprints;
  - run a factory reset;
  - disable fingerprint authentication in authselect;
  - remove open-fprintd or python3-validity packages;
  - disable the COPR repository.

If you enabled authselect fingerprint support and want to disable it separately:
  sudo authselect disable-feature with-fingerprint
  sudo authselect apply-changes
EOF
