# Research notes

This file records why the project uses its current implementation. Update it when the pinned upstream revision changes.

## Device

```text
USB ID:          138a:00ab
Vendor string:   Validity Sensors, Inc.
Laptop:          HP EliteBook 840 G5
Real sensor type: 0xd51
Sensor identity: 57K0 FM- 154-120 (reported upstream)
```

## Upstream support

As of 2026-10-24, support for this hardware is being developed in:

- PR: https://github.com/uunicorn/python-validity/pull/256
- head repository: https://github.com/SimpleX-T/python-validity
- branch: `feat/sensor-type-0xd51`
- pinned commit: `128a9ebc9e7e21b12d606b636d839906473dee18`

PR #256 is still open, so this project does not track the branch tip automatically. Pinning a tested commit makes installation reproducible and prevents a future experimental change from silently altering a working laptop.

## What PR #256 changes

For `138a:00ab`, the patch adds or changes:

- USB device support;
- firmware metadata;
- `0xd51` sensor handling;
- a temporary/working `0x199` profile alias for downstream tables;
- capture-event handling for the `0xd51` interrupt sequence;
- udev auto-start matching.

The key protocol issue is that `0xd51` does not provide the same finger-detected interrupt sequence expected by older driver code. It can move directly to the capture event. The patch preserves that event rather than waiting forever for an event that never arrives.

## Validation reported upstream

PR #256 reports end-to-end validation on `138a:00ab` / HP EliteBook 840 G5, including:

- service startup;
- real multi-stage enrollment;
- positive verification for the enrolled finger;
- negative verification for a different finger;
- PAM-based `sudo` authentication.

## Safety finding: reset procedures

Older `python-validity` documentation contains a generic `factory-reset.py` recovery path. PR #256 explicitly warns not to use that generic procedure for `138a:00ab`, `06cb:00b7` or `06cb:00cb`.

The d51 family requires device-specific handling and identity checks. Therefore this repository:

- never invokes `factory-reset.py`;
- never invokes an erase script;
- does not expose a `--force-reset` convenience option;
- treats provisioning/recovery as a separate upstream debugging task.

## Windows Hello interoperability

Upstream investigation also documents template competition on chips using on-device matching. A Windows Hello template for the same finger may score above a Linux template.

The least destructive workaround is to use different fingers in each OS. Erasing device templates is intentionally outside this project's normal installation flow.

## Fedora base packages

The main `python-validity` README documents Fedora installation through the COPR repository:

```bash
sudo dnf copr enable sneexy/python-validity
sudo dnf install open-fprintd fprintd-clients fprintd-clients-pam python3-validity
```

The Fedora package supplies systemd, udev, configuration and SELinux integration. This project uses that package as the base, then overlays the pinned Python source and matching udev rule from PR #256 until the support is available through a suitable packaged release.

## Upgrade policy

Before changing `PYTHON_VALIDITY_COMMIT` in `scripts/install.sh`:

1. inspect the upstream PR/commit;
2. verify the commit still targets `138a:00ab / 0xd51`;
3. check reset/database behavior for regressions;
4. test enrollment and verification on the target laptop;
5. update this file with the new commit and reason.
