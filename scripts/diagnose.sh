#!/usr/bin/env bash
set -euo pipefail

run() {
  printf '\n$ %s\n' "$*"
  "$@" 2>&1 || true
}

printf 'HP EliteBook 840 G5 fingerprint diagnostics\n'
printf 'Generated: %s\n' "$(date --iso-8601=seconds 2>/dev/null || date)"
printf 'Review this output before sharing it publicly.\n'

run cat /etc/fedora-release
run uname -a
run lsusb
run rpm -q open-fprintd fprintd-clients fprintd-clients-pam python3-validity libfprint
run getenforce
run authselect current
run systemctl --no-pager -l status python3-validity
run systemctl --no-pager -l status open-fprintd
run systemctl list-unit-files 'open-fprintd-*'

printf '\n$ python3 validitysensor location\n'
python3 - <<'PY' 2>&1 || true
from pathlib import Path
try:
    import validitysensor
    print(Path(validitysensor.__file__).resolve())
except Exception as exc:
    print(f"Could not import validitysensor: {exc}")
PY

printf '\n$ udev rule match\n'
grep -nEi '138a.*00ab|00ab.*138a' /usr/lib/udev/rules.d/40-python3-validity.udev 2>&1 || true

run sudo journalctl -u python3-validity -b -n 150 --no-pager
run sudo journalctl -u open-fprintd -b -n 150 --no-pager
run sudo ausearch -m AVC -ts recent

printf '\nEnd of diagnostics.\n'
