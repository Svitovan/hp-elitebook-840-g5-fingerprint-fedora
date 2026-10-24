#!/usr/bin/env bash
set -euo pipefail

TARGET_USB_ID="138a:00ab"

section() {
  printf '\n== %s ==\n' "$1"
}

section "USB device"
if command -v lsusb >/dev/null 2>&1; then
  lsusb | grep -i "$TARGET_USB_ID" || printf 'Target device %s not found.\n' "$TARGET_USB_ID"
else
  printf 'lsusb unavailable.\n'
fi

section "python3-validity"
systemctl --no-pager -l status python3-validity || true

section "open-fprintd"
systemctl --no-pager -l status open-fprintd || true

section "Installed implementation"
python3 - <<'PY' || true
from pathlib import Path
try:
    import validitysensor
    print(Path(validitysensor.__file__).resolve())
except Exception as exc:
    print(f"Could not import validitysensor: {exc}")
PY

section "Recent python3-validity log"
sudo journalctl -u python3-validity -b -n 30 --no-pager || true

printf '\nStatus check complete.\n'
