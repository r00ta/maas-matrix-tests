#! /bin/bash

function get_first_system_id_with_timeout {
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


function wait_for_status {
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

