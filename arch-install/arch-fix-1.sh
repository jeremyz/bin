#! /bin/bash

echo "PACMAN"
pacman-db-upgrade
pacman -Syu
pacman -S --noconfirm grub efibootmgr mkinitcpio linux linux-firmware

echo "GRUB"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub_uefi --recheck
grub-mkconfig -o /boot/grub/grub.cfg
