#!/bin/bash

# Efi-Installation
# Zwei Partitionen
#  1. Efi (fat32)  300MB 
#  2. ROOT (ext4)  Rest
#     ohne swap
#
####################################################################
# anpassen
username=test
userpassword=password
hostname=test
####################################################################

# Auswahl der Spiegelserver
pacman -Sy
pacman -S --noconfirm reflector
reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Festplatte partitionieren
sgdisk -n 0:0:+300MiB -t 0:ef02 -c 0:EFI /dev/sda 
sgdisk -n 0:0:0 -t 0:8300 -c 0:ROOT /dev/sda

# Festplatte formatieren
mkfs.vfat /dev/sda1
mkfs.ext4 -L ROOT /dev/sda2

# Einbinden der Partitionen
mount -L ROOT /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

# Installation der Basispakete
pacstrap /mnt base base-devel linux linux-firmware

# fstab erzeugen
genfstab -Up /mnt > /mnt/etc/fstab

# Systemkonfiguration
echo $hostname > /mnt/etc/hostname               
echo LANG=de_DE.UTF-8 > /mnt/etc/locale.conf     
echo de_DE.UTF-8 UTF-8 >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

echo KEYMAP=de-latin1-nodeadkeys > /mnt/etc/vconsole.conf
ln -sf /mnt/usr/share/zoneinfo/Europe/Berlin /mnt/etc/localtime  

# /etc/hosts anpassen
echo "127.0.0.1    $hostname.localdomain    $hostname" >> /mnt/etc/hosts
echo "::1        $hostname.localdomain    $hostname" >> /mnt/etc/hosts
echo "127.0.1.1    $hostname.localdomain    $hostname" >> /mnt/etc/hosts

# Initramfs erzeugen
arch-chroot /mnt mkinitcpio -p linux

# Installation des GRUB Bootloaders
arch-chroot /mnt pacman -S --noconfirm grub efibootmgr dosfstools
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Sudo einrichten
echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers

# Einen Benutzer mit Root-Rechten anlegen
pass=$(perl -e 'print crypt($ARGV[0], "password")' $userpassword)
arch-chroot /mnt useradd -m -p $pass -g users -G wheel -s /bin/bash $username

# Dienste aktivieren
arch-chroot /mnt systemctl enable systemd-timesyncd.service
arch-chroot /mnt hwclock --hctosys
arch-chroot /mnt systemctl enable fstrim.timer

# X-Server installieren
arch-chroot /mnt pacman -S --noconfirm xorg

# xfce-Desktop
arch-chroot /mnt pacman -S --noconfirm xfce4
arch-chroot /mnt pacman -S --noconfirm xfce4-goodies

# Login-Manager
arch-chroot /mnt pacman -S --noconfirm sddm
#arch-chroot /mnt pacman -S --noconfirm lightdm-gtk-greeter
arch-chroot /mnt systemctl enable sddm.service

# Netzwerk
arch-chroot /mnt pacman -S --noconfirm networkmanager
arch-chroot /mnt pacman -S --noconfirm network-manager-applet
arch-chroot /mnt systemctl enable NetworkManager.service

# Anwendungen
arch-chroot /mnt pacman -S --noconfirm firefox
#arch-chroot /mnt pacman -S --noconfirm firefox-i18n-de
#arch-chroot /mnt pacman -S --noconfirm firefox-ublock-origin
#arch-chroot /mnt pacman -S --noconfirm firefox-noscript

# Editor
arch-chroot /mnt pacman -S --noconfirm geany
arch-chroot /mnt pacman -S --noconfirm vim
arch-chroot /mnt pacman -S --noconfirm nano
      
# Tools
arch-chroot /mnt pacman -S --noconfirm wget
arch-chroot /mnt pacman -S --noconfirm git
arch-chroot /mnt pacman -S --noconfirm openssh
arch-chroot /mnt pacman -S --noconfirm htop
arch-chroot /mnt pacman -S --noconfirm neofetch
arch-chroot /mnt pacman -S --noconfirm bash-completion

exit 0
