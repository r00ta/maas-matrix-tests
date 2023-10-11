# !/bin/bash

echo "Installing LXD.."
sudo snap install --channel=latest/stable lxd

echo "Configuring LXD.."
cat <<EOF | sudo lxd init --preseed
config:
  core.https_address: '[::]:8443'
networks:
- config:
    ipv4.address: auto
    ipv6.address: auto
  description: ""
  name: lxdbr0
  type: ""
  project: default
storage_pools:
- config:
    size: 30GiB
  description: ""
  name: default
  driver: zfs
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
projects: []
cluster: null
EOF

lxc config set core.trust_password fuffapassword
lxc network create net-test --type=bridge ipv4.address=12.0.1.1/24 ipv4.dhcp=false ipv6.address=none

echo "Creating empty LXD VM.."
lxc init --empty --vm vm01 -c security.secureboot=false -c volatile.eth0.hwaddr=00:16:3e:4a:03:01 -c limits.memory=4GiB
lxc config device add vm01 eth0 nic network=net-test name=eth0  boot.priority=10

