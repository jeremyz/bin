#! /bin/bash

modprobe efivarfs
mount -t efivarfs efivarfs /sys/firmware/efi/efivars

parted /dev/sda set 1 bios_grub on

echo "MOUNT"
mount /dev/sda2 /mnt
mount /dev/sda1 /mnt/boot
mount /dev/sda3 /mnt/home

echo "SWAPFS"
dd if=/dev/zero of=/mnt/swapfile bs=1M count=512 || exit 1
chmod 600 /mnt/swapfile || exit 1
mkswap /mnt/swapfile || exit 1
swapon /mnt/swapfile || exit 1

genfstab -U -p /mnt >> /mnt/etc/fstab2

arch-chroot /mnt
