#!/bin/bash

sudo ./virt-install-fedora.sh kube-master 192.168.124.11
sudo ./virt-install-fedora.sh kube-node-01 192.168.124.12
sudo ./virt-install-fedora.sh kube-node-02 192.168.124.13

echo -n Sleeping for 10 seconds:
for i in {0..10}; do echo -n .; sleep 1; done
echo " done."

for host in kube-master kube-node-01 kube-node-02; do
  ssh-keygen -R $host
  ssh -o "StrictHostKeyChecking no" fedora@$host ls
done
