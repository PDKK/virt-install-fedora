#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if ! [ $# -eq 1 ]; then
    echo "Usage: $0 <node-name>"
    exit 1
fi

# Make sure you have all dependencies:
# yum -y install libguestfs-tools virt-install

# Directory where everything happens
DIR=/home/Paul.Knox-Kennedy/Images
# The image downloaded from the http://fedoraproject.org/en/get-fedora#clouds site
# You can use this command:
# mkdir -p ~/work/virt-install && cd ~/work/virt-install && wget http://download.fedoraproject.org/pub/fedora/linux/releases/20/Images/x86_64/Fedora-x86_64-20-20131211.1-sda.qcow2  
IMAGE=$DIR/Fedora-Cloud-Base-23-20151030.x86_64.qcow2
# Amount of RAM in MB
MEM=1024
# Number of virtual CPUs
CPUS=2

# Start the vm afterwards?
RUN_AFTER=true
# Resize the disk? By default it's a 2GB HDD
RESIZE_DISK=true
DISK_SIZE=10G

# You can change this too, but it's OK to leave it as-is
USER_DATA=user-data
META_DATA=meta-data
CI_ISO=$1-cidata.iso
DISK=$1.qcow2

rm -rf $DIR/$1
mkdir -p $DIR/$1

pushd $DIR/$1 > /dev/null
  touch $1.log

  echo "$(date -R) Destroying the $1 domain..."

  # Remove domain with the same name
  virsh destroy $1 &>> $1.log
  virsh undefine $1 &>> $1.log

# cloud-init config: set the password, remove itself and power off

#  echo -e "#cloud-config\npassword: fedora\nchpasswd: {expire: False}\nssh_pwauth: True\nruncmd:\n  - [ yum, -y, remove, cloud-init ]\n  - [ poweroff ]" > $USER_DATA

  cat > $USER_DATA << EOF
#cloud-config
password: fedora
chpasswd: {expire: False}
ssh_pwauth: True
runcmd:
 - [ systemctl, mask, cloud-init.service ]
 - [ systemctl, mask, cloud-config.service ]
 - [ sleep, 5 ]
 - [ sync ]
 - [ poweroff ]
EOF

  cat > $META_DATA << EOF
instance-id: $1
local-hostname: $1
public-keys:
 - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+6kRY1WbqgY824rybwf/ki3NtoAXCb/DXMNr6RgqJmffsWFqBl8K2rGVxCpXNIuVxxezOj94wea0Lp5pPEn3ISWprqtDpVPmmfjkOYs9pANnSAp6vcD2QDr8zNljxuFPbZADvcYjb3L9TRcrin6CfNWZYS/J5r5w9Aedux1SWA89rgDUNQMz0/HDD9ewkElPK9PrKgBrg9jMtwL5QBjl8nCm0b+kL7y0ZhBjJzPpW+bLn3ahuicCYZk2vIVRNWBTCEiVdUCi1c69a0VMUWgxRc3JfX8FAYCKSJEwjqFh7awqvWK1Qt7TvhMBDv1yX6b2UElCI35Vpt7R/HqF2YtUZ Paul.Knox-Kennedy@pdkk-linux.eng.telsis.local
EOF

  cp $IMAGE $DISK

  echo "$(date -R) Generating ISO for cloud-init..."

  genisoimage -output $CI_ISO -volid cidata -joliet -r $USER_DATA $META_DATA &>> $1.log

  echo "$(date -R) Installing the domain and adjusting the configuration..."
  virt-install --import --name $1 --ram $MEM --vcpus $CPUS --disk $DISK,format=qcow2,bus=virtio --disk $CI_ISO,device=cdrom --network bridge=virbr0,model=virtio --os-type=linux --nographics >> $1.log

  echo "$(date -R) Cleaning up cloud-init..."
  # virt-customize --add $DISK --run-command "systemctl mask cloud-init.service" 
  # We're not interested in having the cloud-init data still loaded, let's clean this up
  # Eject cdrom
  virsh change-media $1 hda --eject --config >> $1.log
  # Remove the unnecessary cloud init files
  rm $USER_DATA $META_DATA $CI_ISO

  if $RESIZE_DISK; then
    echo "$(date -R) Resizing the disk..."

    virt-filesystems --long -h --all -a $DISK >> $1.log
    qemu-img create -f qcow2 -o preallocation=metadata $DISK.new $DISK_SIZE >> $1.log
    virt-resize --quiet --expand /dev/sda1 $DISK $DISK.new >> $1.log
    mv $DISK.new $DISK
  fi

  if $RUN_AFTER; then
    echo "$(date -R) Launching the $1 domain..."

    virsh start $1 >> $1.log

    mac=`virsh dumpxml $1 | grep "mac address" | tr -s \' ' '  | awk ' { print $3 } '`

    while true; do
      ip=`arp -na | grep $mac | awk '{ print $2 }' | tr -d \( | tr -d \)`

      if [ "$ip" = "" ]; then
        sleep 1
      else
        break
      fi
    done

    echo "$(date -R) DONE, ssh to the $ip host using 'fedora' username and 'fedora' password"
  fi
popd > /dev/null
