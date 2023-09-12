#!/bin/bash

# FUNCTIONS 
get_first_system_id_with_timeout() {
    local max_wait_time=300
    local sleep_interval=10
    local elapsed_time=0
    local system_ids

    while [ $elapsed_time -lt $max_wait_time ]; do
        system_ids=$(maas admin machines read | jq -r ".[] | .system_id")

        if [ -n "$system_ids" ]; then
            echo "$system_ids" | head -n 1
            return 0
        fi

        sleep $sleep_interval
        elapsed_time=$((elapsed_time + sleep_interval))
    done

    echo "No system_id found after $max_wait_time seconds"
    return 1
}

wait_for_status() {
    local system_id="$1"
    local status="$2"
    local max_wait_time=300
    local sleep_interval=10
    local elapsed_time=0

    while [ $elapsed_time -lt $max_wait_time ]; do
        machine_info=$(maas admin machine read "$system_id")

        status_name=$(echo "$machine_info" | jq -r ".status_name")

        if [ "$status_name" == "$status" ]; then
            return 0
        fi

        sleep $sleep_interval
        elapsed_time=$((elapsed_time + sleep_interval))
    done

    return 1
}

# EXECUTE
echo "Updating.."
sudo apt-get update

# Install utilities
echo "Installing utilities.."
sudo snap install jq

# Configure postgres and create database
echo "Configuring database.."
MAAS_DBUSER=maas
MAAS_DBPASS=maas
MAAS_DBNAME=maasdb

# LXD setup
echo "Configuring lxd.."
lxd init --auto
lxc network create net-test --type=bridge ipv4.address=12.0.1.1/24 ipv4.dhcp=false

# Create empty VM
lxc init --empty --vm vm01 -c security.secureboot=false -c volatile.eth0.hwaddr=00:16:3e:4a:03:01 -c limits.memory=2GiB
lxc config device add vm01 eth0 nic network=net-test name=eth0  boot.priority=10

# Install and configure maas
echo "Installing and configuring maas.."
sudo snap install --channel=latest/edge maas
sudo maas init region+rack --maas-url http://localhost:5240/MAAS --database-uri "postgres://$MAAS_DBUSER:$MAAS_DBPASS@localhost/$MAAS_DBNAME"
sudo maas createadmin --username maas --password maas --email test@example.com
sudo maas apikey --username=maas > /tmp/api-key-file
maas login admin http://localhost:5240/MAAS `cat /tmp/api-key-file`
export SUBNET=12.0.1.0/24
export FABRIC_ID=$(maas admin subnet read "$SUBNET" | jq -r ".vlan.fabric_id")
export VLAN_TAG=$(maas admin subnet read "$SUBNET" | jq -r ".vlan.vid")
export PRIMARY_RACK=$(maas admin rack-controllers read | jq -r ".[] | .system_id")
maas admin subnet update $SUBNET gateway_ip=12.0.1.1
maas admin ipranges create type=dynamic start_ip=12.0.1.200 end_ip=12.0.1.254
maas admin vlan update $FABRIC_ID $VLAN_TAG dhcp_on=True primary_rack=$PRIMARY_RACK
maas admin maas set-config name=upstream_dns value=8.8.8.8
maas admin rack-controller import-boot-images $PRIMARY_RACK


ssh-keygen -q -t rsa -N "" -f "/tmp/id_rsa"
chown ubuntu:ubuntu /tmp/id_rsa /tmp/id_rsa.pub
chmod 600 /tmp/id_rsa
chmod 644 /tmp/id_rsa.pub
maas admin sshkeys create key="$(cat /tmp/id_rsa.pub)"


# Test deployments
echo "Starting VM01"
lxc start vm01

MACHINE_SYSTEM_ID=$(get_first_system_id_with_timeout)
echo "Machine has been enlisted!"

if wait_for_status "$MACHINE_SYSTEM_ID" "New"; then
    echo "Status is New!."
else
    echo "Timeout: Status is still not Ready or an error occurred."
    exit 1
fi

maas admin machine update $MACHINE_SYSTEM_ID power_type=manual

echo "Start commissioning"
maas admin machine commission $MACHINE_SYSTEM_ID
lxc start vm01

if wait_for_status "$MACHINE_SYSTEM_ID" "Ready"; then
    echo "Status is Ready!."
else
    echo "Timeout: Status is still not Ready or an error occurred."
    exit 1
fi

echo "Start deployment"
maas admin machine deploy $MACHINE_SYSTEM_ID
lxc start vm01

if wait_for_status "$MACHINE_SYSTEM_ID" "Deployed"; then
    echo "Status is Deployed."
else
    echo "Timeout: Status is stilli not Deployed or an error occurred."
    exit 1
fi

ssh ubuntu@12.0.1.2 -i /tmp/id_rsa id

