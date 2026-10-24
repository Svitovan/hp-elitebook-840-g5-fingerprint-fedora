# HP EliteBook 840 G5 fingerprint on Fedora

Experimental, reproducible setup for the **Validity/Synaptics `138a:00ab` fingerprint reader** found in the HP EliteBook 840 G5, using [`python-validity`](https://github.com/uunicorn/python-validity) and [`open-fprintd`](https://github.com/uunicorn/open-fprintd) on Fedora GNOME.

> [!WARNING]
> This project targets one specific device family: `138a:00ab`, sensor type `0xd51`. Do **not** run the generic `factory-reset.py` procedure from older `python-validity` documentation on this sensor. Do not erase the fingerprint database unless you explicitly accept losing enrolled Windows Hello fingerprints.

## Status

- Hardware: HP EliteBook 840 G5
- USB ID: `138a:00ab Validity Sensors, Inc.`
- Sensor type: `0xd51`
- OS target: Fedora Workstation / GNOME
- Backend: `python-validity` + `open-fprintd`
- Upstream support: [`uunicorn/python-validity#256`](https://github.com/uunicorn/python-validity/pull/256), currently open
- Pinned known-good upstream commit: [`128a9ebc9e7e21b12d606b636d839906473dee18`](https://github.com/SimpleX-T/python-validity/commit/128a9ebc9e7e21b12d606b636d839906473dee18)

The pinned upstream change has been verified end-to-end on an HP EliteBook 840 G5 with `138a:00ab`: enrollment, verification and PAM authentication.

## Architecture

```text
GNOME / PAM
    │
    ▼
open-fprintd
    │
    ▼
python-validity
    │
    ▼
USB / Validity 138a:00ab
```

This is a userspace driver stack. No custom kernel module is required.

## Quick start

### 1. Check the hardware

```bash
./scripts/check-hardware.sh
```

You should see:

```text
138a:00ab Validity Sensors, Inc.
```

### 2. Install

Read the safety notes first, then run:

```bash
./scripts/install.sh
```

The installer:

1. verifies Fedora and the USB device;
2. enables the `sneexy/python-validity` COPR repository;
3. installs `open-fprintd`, Fedora integration and the packaged `python3-validity` base;
4. overlays the pinned `0xd51` support from upstream PR #256;
5. installs the matching udev rule;
6. reloads udev and restarts the services.

It does **not** run a factory reset, erase fingerprint templates, disable SELinux or change PAM configuration automatically.

### 3. Check service health

```bash
./scripts/status.sh
```

For a more complete diagnostic report:

```bash
./scripts/diagnose.sh > fingerprint-diagnostics.txt
```

Review the file before sharing it publicly.

### 4. Enroll and verify

```bash
fprintd-enroll
fprintd-verify
```

### 5. Enable fingerprint authentication in Fedora

Only after enrollment and verification work:

```bash
sudo authselect current
sudo authselect enable-feature with-fingerprint
sudo authselect apply-changes
```

Then test in a second terminal before relying on it for authentication:

```bash
sudo -k
sudo whoami
```

Keep password authentication available while testing.

## Windows dual-boot note

The sensor stores templates on the device. Windows Hello templates may compete with Linux templates for the same finger. The safest approach is to enroll **different fingers in Windows and Linux**.

Do not erase the on-device database unless you intentionally want to remove templates used by both operating systems.

## Repository layout

```text
.
├── .github/workflows/shellcheck.yml
├── docs/
│   ├── how-it-works.md
│   ├── research.md
│   └── troubleshooting.md
├── patches/
│   └── README.md
├── scripts/
│   ├── check-hardware.sh
│   ├── diagnose.sh
│   ├── install.sh
│   ├── status.sh
│   └── uninstall.sh
├── systemd/
│   └── README.md
├── udev/
│   └── README.md
├── .editorconfig
├── .gitignore
├── LICENSE
└── README.md
```

## Safety principles

This repository deliberately avoids a few tempting shortcuts:

- no generic `factory-reset.py` for `138a:00ab`;
- no automatic deletion of fingerprint templates;
- no automatic SELinux disablement or permissive mode;
- no blind edits under `/etc/pam.d`;
- no unpinned checkout of an experimental driver branch during installation.

If the pinned commit changes in this repository, the change should be documented in `docs/research.md` and tested on the target hardware first.

## Troubleshooting

Start with:

```bash
./scripts/status.sh
sudo journalctl -u python3-validity -b -n 100 --no-pager
sudo journalctl -u open-fprintd -b -n 100 --no-pager
```

Then see [docs/troubleshooting.md](docs/troubleshooting.md).

## Upstream references

- [`uunicorn/python-validity`](https://github.com/uunicorn/python-validity)
- [`uunicorn/python-validity#256`](https://github.com/uunicorn/python-validity/pull/256)
- [`uunicorn/open-fprintd`](https://github.com/uunicorn/open-fprintd)
- [`SimpleX-T/python-validity` `feat/sensor-type-0xd51`](https://github.com/SimpleX-T/python-validity/tree/feat/sensor-type-0xd51)

## License

MIT. See [LICENSE](LICENSE).

This repository contains setup code and documentation. `python-validity` and `open-fprintd` are separate upstream projects with their own copyright and licensing.