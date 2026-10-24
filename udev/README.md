# udev integration

The Fedora/COPR `python3-validity` package installs:

```text
/usr/lib/udev/rules.d/40-python3-validity.udev
```

The experimental `0xd51` support used by this project includes a matching rule for:

```text
138a:00ab
```

`scripts/install.sh` installs the rule from the same pinned upstream commit as the Python driver code, then reloads udev.

To inspect the installed rule:

```bash
grep -nEi '138a.*00ab|00ab.*138a' /usr/lib/udev/rules.d/40-python3-validity.udev
```

To reload rules manually:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger --attr-match=idVendor=138a --attr-match=idProduct=00ab
```

This repository intentionally does not maintain a divergent copy of the upstream rule unless a Fedora-specific change becomes necessary.
