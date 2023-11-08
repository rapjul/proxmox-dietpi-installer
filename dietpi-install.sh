#!/bin/bash

# Variables
IMAGE_URL='https://dietpi.com/downloads/images/DietPi_Proxmox-x86_64-Bookworm.qcow2.xz'
# RAM=2048
RAM=4096
CORES=2
VMNAME='DietPi-VM'
# Get a list of storage to display as a selection list
storageList=$(pvesm status)
# Get the next available VMID
ID=$(pvesh get /cluster/nextid)
UUID=$(cat /proc/sys/kernel/random/uuid)

# Initialize an empty array for the list of storage options
storageListArray=()

# Loop through each line of the storage list
while read -r -a columns; do
    # Assign each column to a variable
    pveName=${columns[0]}
    pveType=${columns[1]}
    pveStatus=${columns[2]}
    pveTotal=${columns[3]}
    pveUsed=${columns[4]}
    pveAvailable=${columns[5]}
    pvePercentUsed=${columns[6]}

    # Generate a list into a new array (skipping the title line)
    if [ $pveName != 'Name' ]; then
      storageListArray+=( "$pveName" "$pvePercentUsed Storage Used" OFF)
    fi
done <<< "$storageList"

# Prompt for download URL
IMAGE_URL=$(whiptail --inputbox 'Enter the URL for the DietPi image (default: https://dietpi.com/downloads/images/DietPi_Proxmox-x86_64-Bookworm.qcow2.xz):' 8 78 $IMAGE_URL --title 'DietPi Installation' 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
  whiptail --title 'Cancelled' --msgbox 'Cancelling process' 8 78
  exit
fi

# Prompt for amount of RAM
RAM=$(whiptail --inputbox 'Enter the amount of RAM (in MB) for the new virtual machine (default: 2048):' 8 78 $RAM --title 'DietPi Installation' 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
  whiptail --title 'Cancelled' --msgbox 'Cancelling process' 8 78
  exit
fi

# Prompt for core count
CORES=$(whiptail --inputbox 'Enter the number of cores for the new virtual machine (default: 2):' 8 78 $CORES --title 'DietPi Installation' 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
  whiptail --title 'Cancelled' --msgbox 'Cancelling process' 8 78
  exit
fi

# Prompt for VMID (pre-populate with next ID available)
ID=$(whiptail --inputbox 'Enter the VM ID you wish to use:' 8 78 $ID --title 'DietPi Installation' 3>&1 1>&2 2>&3)
if [ $exitstatus != 0 ]; then
  whiptail --title 'Cancelled' --msgbox 'Cancelling process' 8 78
  exit
fi

# Prompt to select the storage to use from a radio list
STORAGE=$(whiptail --title 'DietPi Installation' --radiolist --separate-output \
'Select the storage name where the image should be imported:' 20 78 4 \
"${storageListArray[@]}" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
  whiptail --title 'Cancelled' --msgbox 'Cancelling process' 8 78
  exit
fi

# Prompt for the display name of the VM
VMNAME=$(whiptail --inputbox 'Enter the Display Name you wish to use:' 8 78 $VMNAME --title 'DietPi Installation' 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus != 0 ]; then
  whiptail --title 'Cancelled' --msgbox 'Cancelling process' 8 78
  exit
fi

touch "/etc/pve/qemu-server/$ID.conf"


# Download DietPi image
DOWNLOADED_FILE='DietPi_Proxmox-x86_64-Bookworm.qcow2.xz'
echo -e "\n\n"
if [[ -f "${DOWNLOADED_FILE}" ]]; then
	echo -e "Will NOT download \"${DOWNLOADED_FILE}\", as it already exists.";
else
	echo -e "Download \'${DOWNLOADED_FILE}\'.";
	wget "${IMAGE_URL}";
fi



# Install `xz-utils` if missing
dpkg-query -s xz-utils &> /dev/null || { echo "Installing 'xz-utils' for DietPi image decompression"; apt-get update; apt-get -y install xz-utils; }


# Decompress the image (overwrite output file if it already exists)
IMAGE_NAME=${IMAGE_URL##*/}
xz -d "${IMAGE_NAME}"
IMAGE_NAME=${IMAGE_NAME%.xz}
sleep 3


# Check if `virt-customize` is installed
# dpkg-query -l libguestfs-tools
if [[ "$(which virt-customize)" != '/usr/bin/virt-customize' ]]; then
	echo -e "\nInstalling 'virt-customize'\n"
	apt install libguestfs-tools -y;
fi

# Install `qemu-guest-agent` and other programs into the virtual machine image
echo -e "\nInstalling 'qemu-guest-agent' and other programs into the VM image.\n"
virt-customize -a "${IMAGE_NAME}.qcow2" \
  --install qemu-guest-agent \
  --install exa \
  --install ripgrep \
  --install fd-find \
  --install micro

# Add the first boot options file to the image, if it exists in the current folder
BOOT_FILE=./dietpi.txt
if [[ -f "${BOOT_FILE}" ]]; then
	echo -e "\nAdding the first boot file to the image.\n"
	virt-customize -a "${IMAGE_NAME}" --upload "${BOOT_FILE}":/boot
fi
echo -e "\n\n"


# Import the qcow2 file to the default virtual machine storage
qm importdisk "$ID" "$IMAGE_NAME" "$STORAGE"

# Set virtual machine settings
qm set "$ID" --cores "$CORES"
qm set "$ID" --memory "$RAM"
qm set "$ID" --balloon "$( python3 -c "print(${RAM} // 4)" )"
qm set "$ID" --net0 'virtio,bridge=vmbr0'
qm set "$ID" --scsi0 "$STORAGE:vm-$ID-disk-0"
qm set "$ID" --boot order='scsi0'
qm set "$ID" --scsihw virtio-scsi-single
qm set "$ID" --machine q35
qm set "$ID" --ostype l26
qm set "$ID" --name "$VMNAME"
qm set "$ID" --smbios1 uuid="$UUID"

# Enable/disable communication with the QEMU Guest Agent and its properties
qm set "$ID" --agent 1
qm set "$ID" --description "## [DietPi](https://dietpi.com)
### [DietPi Forums](https://dietpi.com/forum)
### [DietPi Software](https://dietpi.com/docs/software/)
"

# Tell user the virtual machine is created
echo -e "VM $ID Created."

whiptail --yesno "Should the VM $ID be started?" 8 78 --yes-button "Start VM" --no-button "Finish" --title 'DietPi Installation' 3>&1 1>&2 2>&3
exitstatus=$?
if [ $exitstatus != 0 ]; then
  # Start the virtual machine
  qm start "$ID"
fi
