# virt-install-fedora
Script to create fedora cloud image as virtual machine, automating cloud-init local source

Cloned from script referenced here : https://goldmann.pl/blog/2014/01/16/running-fedora-cloud-images-on-kvm/

Run using sudo ./virt-install-fedora <name> <ip>


On fedora cloud image, to get ready for an anisble install, make sure that the proxy is set correctly in dnf,
then run 
    dnf install -y python2 python2-dnf libselinux-python


On an atomic image behind a proxy, make sure the proxy line is set in /etc/ostree/remotes.d/fedora-atomic.conf

Once all this is done, it should be ready for an ansible install of kubernetes


== Changelog ==

* PDKK - 20150108 - Changed to use static ip address in cloud config






