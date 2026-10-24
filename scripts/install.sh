#!/usr/bin/env bash
set -euo pipefail

TARGET_USB_ID="138a:00ab"
PYTHON_VALIDITY_REPO="https://github.com/SimpleX-T/python-validity.git"
PYTHON_VALIDITY_COMMIT="128a9ebc9e7e21b12d606b636d839906473dee18"
UDEV_RULE="/usr/lib/udev/rules.d/40-python3-validity.udev"

log() { printf '\n>> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ ${EUID:-$(id -u)} -ne 0 ]] || die "Run this script as your normal user, not with sudo. It will request sudo when needed."

[[ -r /etc/os-release ]] || die "/etc/os-release not found."
# System-provided file, not part of this repository.
# shellcheck disable=SC1091
. /etc/os-release
[[ "${ID:-}" == "fedora" ]] || die "This installer targets Fedora. Detected: ${PRETTY_NAME:-unknown}."

command -v sudo >/dev/null || die "sudo is required."
command -v dnf >/dev/null || die "dnf is required."
command -v git >/dev/null || {
  log "Installing git and USB utilities"
  sudo dnf install -y git usbutils
}
command -v lsusb >/dev/null || sudo dnf install -y usbutils

if ! lsusb | grep -qi "$TARGET_USB_ID"; then
  die "Target fingerprint reader $TARGET_USB_ID is not visible in lsusb. No changes were made to the fingerprint stack."
fi

log "Target device detected"
lsusb | grep -i "$TARGET_USB_ID"

log "Enabling python-validity COPR"
if ! dnf copr --help >/dev/null 2>&1; then
  die "The 'dnf copr' command is unavailable. Install Fedora's COPR DNF plugin, then rerun this script."
fi
sudo dnf copr enable -y sneexy/python-validity

log "Installing Fedora integration and base packages"
sudo dnf install -y open-fprintd fprintd-clients fprintd-clients-pam python3-validity git usbutils

TMPDIR_PV="$(mktemp -d -t hp840g5-python-validity.XXXXXX)"
cleanup() { rm -rf "$TMPDIR_PV"; }
trap cleanup EXIT

log "Fetching pinned python-validity revision"
git -C "$TMPDIR_PV" clone --quiet "$PYTHON_VALIDITY_REPO" source
git -C "$TMPDIR_PV/source" checkout --quiet --detach "$PYTHON_VALIDITY_COMMIT"
ACTUAL_COMMIT="$(git -C "$TMPDIR_PV/source" rev-parse HEAD)"
[[ "$ACTUAL_COMMIT" == "$PYTHON_VALIDITY_COMMIT" ]] || die "Unexpected upstream revision: $ACTUAL_COMMIT"

SITE_PACKAGE_DIR="$(python3 - <<'PY'
from pathlib import Path
import validitysensor
print(Path(validitysensor.__file__).resolve().parent)
PY
)"
[[ -d "$SITE_PACKAGE_DIR" ]] || die "Could not locate installed validitysensor package."

log "Stopping fingerprint services before overlay"
sudo systemctl stop python3-validity.service 2>/dev/null || true
sudo systemctl stop open-fprintd.service 2>/dev/null || true

log "Overlaying pinned 0xd51 implementation"
printf 'RPM package directory: %s\n' "$SITE_PACKAGE_DIR"
sudo cp -a "$TMPDIR_PV/source/validitysensor/." "$SITE_PACKAGE_DIR/"

[[ -f "$TMPDIR_PV/source/debian/python3-validity.udev" ]] || die "Pinned source does not contain the expected udev rule."
log "Installing matching udev rule"
sudo install -m 0644 "$TMPDIR_PV/source/debian/python3-validity.udev" "$UDEV_RULE"

log "Reloading udev"
sudo udevadm control --reload-rules
sudo udevadm trigger --attr-match=idVendor=138a --attr-match=idProduct=00ab || true

log "Restarting services"
sudo systemctl daemon-reload
sudo systemctl enable --now python3-validity.service
sudo systemctl restart open-fprintd.service 2>/dev/null || sudo systemctl start open-fprintd.service

log "Service state"
systemctl --no-pager -l status python3-validity.service || true
systemctl --no-pager -l status open-fprintd.service || true

cat <<EOF

Installation overlay complete.

Pinned python-validity commit:
  $PYTHON_VALIDITY_COMMIT

Next steps:
  ./scripts/status.sh
  fprintd-enroll
  fprintd-verify

Only after enrollment and verification succeed, enable Fedora fingerprint auth:
  sudo authselect current
  sudo authselect enable-feature with-fingerprint
  sudo authselect apply-changes

This script did NOT factory-reset the sensor, erase templates, disable SELinux,
or modify PAM/authselect configuration.
EOF
