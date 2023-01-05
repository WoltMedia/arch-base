#!/bin/bash

# Efi-Installation
# Zwei Partitionen
#  1. Efi (fat32)  300MB 
#  2. ROOT (ext4)  Rest
#     ohne swap
#
####################################################################
# anpassen
#username=test
#userpassword=password
#hostname=test
####################################################################

# Auswahl der Spiegelserver
pacman -Sy

# Festplatte partitionieren
sgdisk -n 0:0:+300MiB -t 0:ef02 -c 0:EFI /dev/vda 
sgdisk -n 0:0:0 -t 0:8300 -c 0:ROOT /dev/vda

# Festplatte formatieren
mkfs.vfat /dev/vda1
mkfs.ext4 -L ROOT /dev/vda2


exit 0
