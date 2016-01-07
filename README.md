# virt-install-fedora
Script to create fedora cloud image as virtual machine, automating cloud-init local source

Cloned from script referenced here : https://goldmann.pl/blog/2014/01/16/running-fedora-cloud-images-on-kvm/

Run using sudo ./virt-install-fedora <name> <ip>

ip is the last byte of the 192.168.124.x address, and used as the last byte of the MAC address

To get ready for an anisble install, make sure that the proxy is set correctly in dnf,
then run 
    dnf install -y python2 python2-dnf libselinux-python



# Ideas to move forward

* Apply all this to an atomic image
* Assign network addresses by setting the mac address on virt-install, then using virsh-netupdate

For example

```
net-update default delete ip-dhcp-host "<host mac='52:54:00:e3:da:6a' />" --live --config
net-update default add-last ip-dhcp-host "<host mac='52:54:00:e3:da:6a' name='kube-node-02' ip='192.168.124.13'/>" --live --config
```

This is for setting ip addresses within the default nat virtual network.
Requires dhcp range to be reduced

```
<network>
  <name>default</name>
  <uuid>29e972d8-e019-4ec5-bc5f-d565676c55ac</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:0f:97:8e'/>
  <ip address='192.168.124.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.124.100' end='192.168.124.254'/>
      <host mac='52:54:00:c1:b6:45' name='kube-master' ip='192.168.124.11'/>
      <host mac='52:54:00:66:80:7e' name='kube-node-01' ip='192.168.124.12'/>
      <host mac='52:54:00:e3:da:6a' name='kube-node-02' ip='192.168.124.13'/>
    </dhcp>
  </ip>
</network>
```

