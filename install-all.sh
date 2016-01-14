#!/bin/bash

sudo ./virt-install-fedora kube-master 192.168.124.11
sudo ./virt-install-fedora kube-node-01 192.168.124.12
sudo ./virt-install-fedora kube-node-02 192.168.124.13

for host in kube-master kube-node-01 kube-node-02; do
  ssh-keygen -R $host
  ssh -o "StrictHostKeyChecking no" fedora@$host ls
done
