![proxmox-dietpi](https://user-images.githubusercontent.com/67932890/213890139-61bd9c23-4ed2-49f2-a627-0b303d0a4f8f.png)

# Proxmox DietPi Installer

A Proxmox Helper Script to install DietPi in Proxmox.

## How to use

### Oneline installer directly from GitHub

```sh
bash <(curl -sSfL https://raw.githubusercontent.com/rapjul/proxmox-dietpi-installer/production/dietpi-install.sh)
```

### Download the script to your Proxmox host by cloning the repo or using `wget`

```sh
git clone --branch production --single-branch https://github.com/rapjul/proxmox-dietpi-installer
```

cd into the folder, make the file executable then run the script

```sh
cd proxmox-dietpi-installer
chmod +x dietpi-install.sh
./dietpi-install.sh
```

### You can also download the script with `wget`

```sh
wget https://raw.githubusercontent.com/rapjul/proxmox-dietpi-installer/production/dietpi-install.sh
```

Make the file executable then run the script

```sh
cd proxmox-dietpi-installer
chmod +x dietpi-install.sh
./dietpi-install.sh
```

The installer will ask you several questions to setup the Virtual Machine. These include where to import the VM disk, how much RAM to allocate and the number of processor cores. The rest of the setup process is automatic, including adding `qemu-guest-agent` and other programs into the VM image.
Default values are 4GB of RAM and 2 CPU Cores.

## This is VERY basic, i'm sure there is better ways of doing it but this works fine. Tested and confirmed working with Proxmox 7.3

For more helper scripts like this but much better check out [tteck's Proxmox Helper Scripts](https://tteck.github.io/Proxmox/)
