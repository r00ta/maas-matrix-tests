#! /bin/bash

get_first_system_id_with_timeout() {
    local max_wait_time=600
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
    local max_wait_time=600
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

set -x

echo "Logging in.."
maas login admin http://localhost:5240/MAAS `cat /tmp/maas/api-key-file`

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

echo $MACHINE_SYSTEM_ID
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

ssh -o StrictHostKeyChecking=no ubuntu@12.0.1.2 -i /tmp/maas/id_rsa id
