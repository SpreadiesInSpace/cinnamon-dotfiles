## Enable Serial Console (ttyS0) on various Linux Distributions

### systemd
```bash
sudo su
passwd
systemctl enable --now getty@ttyS0
```
### Gentoo - OpenRC
```bash
sudo su
passwd
exec setsid agetty 115200 ttyS0 vt100 &
```
### Slackware - sysvinit
```bash
dhcpcd # For Networking (not enabled in ISO)
passwd
exec setsid getty 115200 ttyS0 vt100 &
```
### Void - runit
```bash
sudo su
chsh -s /bin/bash
bash
passwd
ln -sf /etc/sv/agetty-ttyS0 /var/service
```