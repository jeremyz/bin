#! /bin/bash

echo "LINKS"
for l in /lib /lib64 /usr/lib64
do
    if [ "$(readlink -f $l)" != "/usr/lib" ]
    then
        echo "must manually fix : $l     (ln -s /usr/lib $l)"
        exit 1
    fi
done

echo "PACMAN"
pacman-db-upgrade
pacman -Syu
pacman -S --noconfirm grub efibootmgr mkinitcpio linux linux-firmware

echo "GRUB"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub_uefi --recheck
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -p linux
