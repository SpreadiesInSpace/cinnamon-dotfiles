#!/bin/bash
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/vda2 /mnt/ 
mkdir -p /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@home /dev/vda2 /mnt/home 
mkdir -p /mnt/boot/efi
mount /dev/vda1 /mnt/boot/efi
cp --dereference /etc/resolv.conf /mnt/etc/
mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev
mount --bind /run /mnt/run
mount --make-slave /mnt/run
chroot /mnt /bin/bash

source /etc/profile
# nano /etc/fstab
su f16poom

cd
# rm -rf cinnamon-dotfiles/
# git clone https://github.com/SpreadiesInSpace/cinnamon-dotfiles
cd cinnamon-dotfiles/
sudo bash Setup-Gentoo.sh
