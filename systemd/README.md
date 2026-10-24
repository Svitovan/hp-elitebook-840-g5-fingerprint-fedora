# systemd services

The service units are supplied by the Fedora/COPR packages rather than duplicated in this repository.

Main services:

```text
python3-validity.service
open-fprintd.service
```

Check them with:

```bash
systemctl --no-pager -l status python3-validity
systemctl --no-pager -l status open-fprintd
```

Current-boot logs:

```bash
sudo journalctl -u python3-validity -b -n 100 --no-pager
sudo journalctl -u open-fprintd -b -n 100 --no-pager
```

Some installations also provide suspend/resume helpers. Discover them rather than assuming they exist:

```bash
systemctl list-unit-files 'open-fprintd-*'
```

If present and fingerprint support breaks after suspend, upstream documentation suggests enabling:

```bash
sudo systemctl enable open-fprintd-resume open-fprintd-suspend
```

Do not create replacement units unless there is a demonstrated Fedora-specific need. Keeping systemd ownership with the package makes upgrades and rollback much less exciting.
