#! /bin/bash

echo "LOCALTIME"
rm /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Zurich /etc/localtime

echo "LOCALE"
locale-gen

echo "MKINITCPIO"
mkinitcpio -p linux

echo "NETWORK"
systemctl enable dhcpcd.service
systemctl start dhcpcd.service

echo "PACMAN"
pacman-db-upgrade

echo "GRUB"
pacman -Syu
pacman -S --noconfirm grub efibootmgr
#grub-install --target=i386-pc --recheck /dev/sda
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub_uefi --recheck

grub-mkconfig -o /boot/grub/grub.cfg

pacman -S vim
