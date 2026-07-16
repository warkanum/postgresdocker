#!/bin/sh
# Runs from the Void live ISO. The bootstrap wrapper mounts this payload ISO.
set -eu
disk=/dev/vda
mountpoint=/mnt
wipefs -af "$disk"
parted -s "$disk" mklabel gpt mkpart ESP fat32 1MiB 513MiB set 1 esp on mkpart root ext4 513MiB 100%
mkfs.vfat "${disk}1"
mkfs.ext4 -F "${disk}2"
mount "${disk}2" "$mountpoint"
mkdir -p "$mountpoint/boot/efi"
mount "${disk}1" "$mountpoint/boot/efi"
xbps-install -Sy -r "$mountpoint" base-system grub-x86_64-efi openssh sudo
cp /etc/resolv.conf "$mountpoint/etc/resolv.conf"
echo pgza-void >"$mountpoint/etc/hostname"
echo 'ansible ALL=(ALL) NOPASSWD: ALL' >"$mountpoint/etc/sudoers.d/ansible"
chmod 440 "$mountpoint/etc/sudoers.d/ansible"
chroot "$mountpoint" useradd -m -G wheel ansible
chroot "$mountpoint" passwd -d ansible
chroot "$mountpoint" ln -s /etc/sv/sshd /var/service
chroot "$mountpoint" grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Void
chroot "$mountpoint" grub-mkconfig -o /boot/grub/grub.cfg
