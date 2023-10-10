# !/bin/bash

echo "Installing LXD.."
sudo snap install --channel=latest/stable lxd

echo "Configuring LXD.."
lxd init --auto
lxc network create net-test --type=bridge ipv4.address=12.0.1.1/24 ipv4.dhcp=false ipv6.address=none

echo "Creating empty LXD VM.."
lxc init --empty --vm vm01 -c security.secureboot=false -c volatile.eth0.hwaddr=00:16:3e:4a:03:01 -c limits.memory=4GiB
lxc config device add vm01 eth0 nic network=net-test name=eth0  boot.priority=10

