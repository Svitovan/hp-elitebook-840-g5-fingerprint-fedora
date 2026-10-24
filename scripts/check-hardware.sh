#!/usr/bin/env bash
set -euo pipefail

TARGET_USB_ID="138a:00ab"

section() {
  printf '\n== %s ==\n' "$1"
}

section "Operating system"
if [[ -r /etc/os-release ]]; then
  # System-provided file, not part of this repository.
  # shellcheck disable=SC1091
  . /etc/os-release
  printf '%s\n' "${PRETTY_NAME:-Unknown Linux}"
else
  uname -a
fi

section "Kernel"
uname -r

section "Fingerprint USB device"
if command -v lsusb >/dev/null 2>&1; then
  if lsusb | grep -qi "$TARGET_USB_ID"; then
    lsusb | grep -i "$TARGET_USB_ID"
    printf 'Target device detected.\n'
  else
    printf 'Target device %s was NOT detected.\n' "$TARGET_USB_ID" >&2
    exit 2
  fi
else
  printf 'lsusb is not installed. Install usbutils and run this script again.\n' >&2
  exit 3
fi

section "Relevant RPM packages"
for package in open-fprintd fprintd-clients fprintd-clients-pam python3-validity libfprint; do
  if rpm -q "$package" >/dev/null 2>&1; then
    rpm -q "$package"
  else
    printf '%-24s %s\n' "$package" 'not installed'
  fi
done

section "SELinux"
if command -v getenforce >/dev/null 2>&1; then
  getenforce
else
  printf 'getenforce is unavailable.\n'
fi

section "Authentication profile"
if command -v authselect >/dev/null 2>&1; then
  authselect current || true
else
  printf 'authselect is unavailable.\n'
fi

printf '\nHardware check complete. No system changes were made.\n'
