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
passwd gentoo # For setting Timezone graphically via ISO
ln -sf /etc/init.d/agetty /etc/init.d/agetty.ttyS0
rc-update add agetty.ttyS0 default
rc-service agetty.ttyS0 start
```
### Slackware - sysvinit
```bash
dhcpcd # For Networking (not enabled in ISO)
passwd
exec setsid getty 115200 ttyS0 vt100 &
# Alternative, use dropbear and inspect ip to SSH from
# /etc/rc.d/rc.dropbear start
# ip a
```
### Void - runit
```bash
sudo su
chsh -s /bin/bash
bash
passwd
ln -sf /etc/sv/agetty-ttyS0 /var/service
```