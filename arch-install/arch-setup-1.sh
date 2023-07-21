#! /bin/bash

echo "LOCALTIME"
rm /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Zurich /etc/localtime
hwclock --systohc --utc

echo "LOCALE"
locale-gen

echo "PACMAN"
pacman-db-upgrade
pacman -Syu
pacman -S --noconfirm grub efibootmgr mkinitcpio linux linux-firmware vim

echo "MKINITCPIO"
mkinitcpio -p linux

echo "GRUB"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub_uefi --recheck
grub-mkconfig -o /boot/grub/grub.cfg


ETH=$(ip add | grep '^2' | cut -d ':' -f2 | sed 's/ //g')
cat > /etc/systemd/network/10-wired.network << EOF
[Match]
Name=$ETH

[Network]
DHCP=yes
EOF

systemctl enable systemd-networkd
systemctl start systemd-networkd

ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

systemctl enable systemd-resolved
systemctl start systemd-resolved

resolvectl status

systemctl enable systemd-timesyncd
systemctl start systemd-timesyncd

echo " !!! set your root password !!!"
