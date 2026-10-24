# How it works

## Target hardware

This project is intentionally narrow:

```text
Laptop: HP EliteBook 840 G5
USB:    138a:00ab Validity Sensors, Inc.
Sensor: Synaptics/Validity VFS7552 family
Type:   0xd51
```

Do not assume the same procedure is safe for another USB ID merely because the laptop looks similar.

## Software path

```text
GNOME / sudo / other PAM consumers
                │
                ▼
             fprintd
        (open-fprintd build)
                │ D-Bus
                ▼
         python-validity
                │ PyUSB/libusb
                ▼
       138a:00ab fingerprint sensor
```

`python-validity` implements the device protocol in userspace. A custom kernel module is not required.

## Why stock support fails

The `0xd51` hardware differs from older Validity devices in its capture interrupt sequence. During capture it does not emit the older `b[0] == 2` finger-detected event. It can move directly from the start acknowledgement to `b[0] == 3` capture events.

Older `python-validity` code waits indefinitely for the missing event, which makes enrollment or verification appear to hang even though the USB device is alive.

Upstream PR #256 adds device-specific handling for `0xd51`, together with:

- USB identity `138a:00ab`;
- firmware metadata;
- a working profile alias for the sensor;
- capture interrupt handling specific to `0xd51`;
- a udev auto-start rule.

The project currently pins commit:

```text
128a9ebc9e7e21b12d606b636d839906473dee18
```

That commit belongs to the `SimpleX-T/python-validity` branch used by upstream PR #256.

## Device-side matching

The sensor performs important matching work on-chip. Linux enrollment templates can coexist with Windows Hello templates, but the device compares against all stored templates. In dual-boot configurations this can create template competition for the same finger.

For that reason this project recommends using different fingers for Windows and Linux rather than deleting device data.

## Fedora integration

Fedora authentication is managed through `authselect`. This project deliberately does not modify PAM automatically. Once `fprintd-enroll` and `fprintd-verify` both work, enable the Fedora feature with:

```bash
sudo authselect enable-feature with-fingerprint
sudo authselect apply-changes
```

Check the current profile first:

```bash
sudo authselect current
```

## SELinux

SELinux should remain enabled. The Fedora/COPR package provides the supporting integration used by the base installation. If SELinux blocks a path, diagnose the denial instead of switching the whole system to permissive mode.

Useful commands:

```bash
getenforce
sudo ausearch -m AVC -ts recent
```

## References

- https://github.com/uunicorn/python-validity
- https://github.com/uunicorn/python-validity/pull/256
- https://github.com/uunicorn/open-fprintd
