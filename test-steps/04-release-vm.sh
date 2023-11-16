#! /bin/bash

set -x

script_dir_path=$(dirname "${BASH_SOURCE[0]}")
. ${script_dir_path}/../functions/common.sh

echo "Logging in.."
maas login admin http://localhost:5240/MAAS `cat /tmp/maas/api-key-file`

echo "Reading Machine ID.."
MACHINE_SYSTEM_ID=`cat /tmp/maas/vm_system_id`

maas admin machine release $MACHINE_SYSTEM_ID

if wait_for_status "$MACHINE_SYSTEM_ID" "Ready"; then
    echo "Machine has been released!."
else
    echo "Timeout: Status is still not Ready or an error occurred."
    exit 1
fi


