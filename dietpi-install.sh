#!/bin/bash

# Variables
IMAGE_URL=$(whiptail --inputbox 'Enter the URL for the DietPi image (default: https://dietpi.com/downloads/images/DietPi_Proxmox-x86_64-Bullseye.7z):' 8 78 'https://dietpi.com/downloads/images/DietPi_Proxmox-x86_64-Bullseye.7z' --title 'DietPi Installation' 3>&1 1>&2 2>&3)
RAM=$(whiptail --inputbox 'Enter the amount of RAM (in MB) for the new virtual machine (default: 2048):' 8 78 2048 --title 'DietPi Installation' 3>&1 1>&2 2>&3)
CORES=$(whiptail --inputbox 'Enter the number of cores for the new virtual machine (default: 2):' 8 78 2 --title 'DietPi Installation' 3>&1 1>&2 2>&3)
ON_BOOT=$(whiptail --yesno 'Should the VM be started during system bootup?' 8 78 --title 'DietPi Installation' 3>&1 1>&2 2>&3)

# Get the next available VMID
ID_NEXT=$(pvesh get /cluster/nextid)
ID=$(whiptail --inputbox 'Enter the desired ID number of the VM:' 8 78 "$ID_NEXT" --title 'DietPi Installation' 3>&1 1>&2 2>&3)

touch "/etc/pve/qemu-server/$ID.conf"

# Get the storage name from the user
STORAGE=$(whiptail --inputbox 'Enter the storage name where the image should be imported:' 8 78 --title 'DietPi Installation' 3>&1 1>&2 2>&3)

# Download DietPi image
wget "$IMAGE_URL"

# Extract the image
IMAGE_NAME=${IMAGE_URL##*/}
IMAGE_NAME=${IMAGE_NAME%.7z}
7zr e "$IMAGE_NAME.7z" "$IMAGE_NAME.qcow2"
sleep 3

# import the qcow2 file to the default virtual machine storage
qm importdisk "$ID" "$IMAGE_NAME.qcow2" "$STORAGE"

# Set vm settings
qm set "$ID" --cores "$CORES"
qm set "$ID" --memory "$RAM"
qm set "$ID" --net0 'virtio,bridge=vmbr0'
qm set "$ID" --scsi0 "$STORAGE:vm-$ID-disk-0"
qm set "$ID" --boot order='scsi0'
qm set "$ID" --scsihw virtio-scsi-pci
qm set "$ID" --onboot "$ON_BOOT"
qm set "$ID" --agent enabled=1
qm set "$ID" --name "dietpi" >/dev/null
qm set "$ID" --description "### [DietPi](https://dietpi.com)
### [DietPi Forums](https://dietpi.com/forum)
### [DietPi Software](https://dietpi.com/docs/software/)" >/dev/null

# Tell user the virtual machine is created
echo "VM $ID Created."

# Start the virtual machine
qm start "$ID"
