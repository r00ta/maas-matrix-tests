#!/bin/bash

set -x

script_dir_path=$(dirname "${BASH_SOURCE[0]}")
. ${script_dir_path}/../functions/common.sh

echo "Logging in.."
maas login admin http://localhost:5240/MAAS `cat /tmp/maas/api-key-file`

echo "Reading Machine ID.."
MACHINE_SYSTEM_ID=`cat /tmp/maas/vm_system_id`

IP_ADDRESS=$(maas admin machine read $MACHINE_SYSTEM_ID | jq -r .ip_addresses[0])

# Retry SSH connection for up to 300 seconds
retry_count=0
retry_limit=300
retry_interval=10

while [ $retry_count -lt $retry_limit ]; do
    ssh_result=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@$IP_ADDRESS -i /tmp/maas/id_rsa id)

    if [[ $ssh_result == *"ubuntu"* ]]; then
        echo "SSH login successful. User is 'ubuntu'."
        exit 0
    else
        echo "SSH login failed or user is not 'ubuntu'. Retrying..."
        sleep $retry_interval
        retry_count=$((retry_count + retry_interval))
    fi
done

echo "Critical: failed to ssh"
exit 1
