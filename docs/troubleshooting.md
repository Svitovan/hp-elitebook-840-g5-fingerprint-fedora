# Troubleshooting

Start with read-only diagnostics. Avoid changing multiple layers at once.

## 1. Confirm the USB device

```bash
lsusb | grep -i '138a:00ab'
```

Expected:

```text
138a:00ab Validity Sensors, Inc.
```

If the device is absent, this repository is not the right debugging layer yet. Check BIOS settings, USB visibility and hardware state first.

## 2. Check services

```bash
systemctl --no-pager -l status python3-validity
systemctl --no-pager -l status open-fprintd
```

Then inspect current-boot logs:

```bash
sudo journalctl -u python3-validity -b -n 100 --no-pager
sudo journalctl -u open-fprintd -b -n 100 --no-pager
```

Or run:

```bash
./scripts/diagnose.sh
```

## 3. `NoSuchDevice` / `list_devices failed`

Typical symptoms include:

```text
GDBus.Error:net.reactivated.Fprint.Error.NoSuchDevice
```

Check, in this order:

```bash
lsusb | grep -i '138a:00ab'
rpm -q open-fprintd python3-validity
systemctl is-active python3-validity
systemctl is-active open-fprintd
```

Then verify the installed udev rule mentions `138a` and `00ab`:

```bash
grep -nEi '138a.*00ab|00ab.*138a' /usr/lib/udev/rules.d/40-python3-validity.udev
```

## 4. Enrollment hangs or loops

The `0xd51` sensor needs the capture-event handling from upstream PR #256. Confirm the project is using the pinned implementation rather than only the older COPR source.

The known-good commit documented by this repository is:

```text
128a9ebc9e7e21b12d606b636d839906473dee18
```

Re-run `./scripts/install.sh` if the packaged source overwrote the experimental overlay during a package update.

## 5. Enrollment succeeds but verification fails

If the machine dual-boots Windows, the sensor may contain Windows Hello templates. The on-device matcher evaluates stored templates, and a Windows template for the same finger can outscore the Linux enrollment.

Preferred workaround:

- enroll one finger in Windows;
- enroll a different finger in Linux.

Do not erase the sensor database merely to test this theory unless losing Windows Hello fingerprint enrollment is acceptable.

## 6. SELinux denials

Do not disable SELinux as a debugging shortcut.

Check mode:

```bash
getenforce
```

Inspect recent AVC messages:

```bash
sudo ausearch -m AVC -ts recent
```

Also inspect service logs. A real SELinux issue should be fixed with an appropriate policy adjustment, not by making the entire system permissive.

## 7. Fingerprint works until suspend

Upstream `python-validity` documentation recommends enabling the open-fprintd suspend/resume units when needed:

```bash
sudo systemctl enable open-fprintd-resume open-fprintd-suspend
```

Check that these units actually exist on the installed Fedora package before enabling them:

```bash
systemctl list-unit-files 'open-fprintd-*'
```

## 8. PAM authentication does not use fingerprints

First confirm the lower layers work:

```bash
fprintd-verify
```

Only then inspect Fedora authentication configuration:

```bash
sudo authselect current
```

Enable the supported Fedora feature rather than manually editing generated PAM files:

```bash
sudo authselect enable-feature with-fingerprint
sudo authselect apply-changes
```

Keep an authenticated terminal or password path available while testing.

## 9. Do not use the old generic factory-reset instructions

For `138a:00ab / 0xd51`, upstream PR #256 explicitly warns against the generic `factory-reset.py` procedure documented for older devices. This project intentionally does not automate any factory reset.

If the sensor is genuinely in an unusual flash/provisioning state, collect read-only diagnostics and compare them with upstream PR #256 before performing device-specific recovery.

## Useful report

```bash
./scripts/diagnose.sh > fingerprint-diagnostics.txt
```

Review the resulting file before publishing it. Logs can contain usernames, hostnames and other local metadata.
