# !/bin/bash

set -x

retry_until_success() {
  local maas_command="$1"
  local status_to_check="$2"
  local max_wait_time=600
  local sleep_interval=10
  local elapsed_time=0

  while [ $elapsed_time -lt $max_wait_time ]; do
    output=$(eval "$maas_command")
    if [ "$output" = "$status_to_check" ]; then
      echo "Success!"
      return 0  # Success
    fi
    sleep $sleep_interval
    elapsed_time=$((elapsed_time + sleep_interval))
  done

  echo "Timeout reached. Importing may not be complete."
  return 1  # Timeout
}

mkdir -p /tmp/maas
chmod 777 /tmp/maas 

echo "Installing MAAS.."
sudo snap install --channel=$MAAS_VERSION maas
sudo snap install --channel=$MAAS_VERSION maas-test-db

echo "Configuring MAAS.."
sudo maas init region+rack --maas-url http://localhost:5240/MAAS --database-uri maas-test-db:/// 
sleep 15
echo "Configuring admin.."
sudo maas createadmin --username maas --password maas --email test@example.com
sudo maas apikey --username=maas > /tmp/maas/api-key-file
maas login admin http://localhost:5240/MAAS `cat /tmp/maas/api-key-file`
maas admin boot-resources import
retry_until_success "maas admin boot-resources is-importing" "false"
echo "Extracting primary rack.."
export PRIMARY_RACK=$(maas admin rack-controllers read | jq -r ".[] | .system_id")
maas admin rack-controller import-boot-images $PRIMARY_RACK
retry_until_success "maas admin rack-controller list-boot-images $PRIMARY_RACK | jq -r .status" "synced"

export SUBNET=12.0.1.0/24
maas admin subnets create cidr=$SUBNET name=test-subnet
echo "Extracting fabric id.."
export FABRIC_ID=$(maas admin subnet read "$SUBNET" | jq -r ".vlan.fabric_id")
echo "Extracting vlan tag id.."
export VLAN_TAG=$(maas admin subnet read "$SUBNET" | jq -r ".vlan.vid")
echo "Updating subnet.."
maas admin subnet update $SUBNET gateway_ip=12.0.1.1
maas admin ipranges create type=dynamic start_ip=12.0.1.200 end_ip=12.0.1.254
maas admin vlan update $FABRIC_ID $VLAN_TAG dhcp_on=True primary_rack=$PRIMARY_RACK
maas admin maas set-config name=upstream_dns value=8.8.8.8

export SUBNET=172.0.2.0/24
echo "Extracting fabric id for baremetals.."
export FABRIC_ID=$(maas admin subnet read "$SUBNET" | jq -r ".vlan.fabric_id")
echo "Extracting vlan tag id for baremetals.."
export VLAN_TAG=$(maas admin subnet read "$SUBNET" | jq -r ".vlan.vid")
echo "Updating subnet.."
maas admin subnet update $SUBNET gateway_ip=172.0.2.1
maas admin ipranges create type=dynamic start_ip=172.0.2.200 end_ip=172.0.2.254
maas admin ipranges create type=reserved start_ip=172.0.2.1 end_ip=172.0.2.10
maas admin vlan update $FABRIC_ID $VLAN_TAG dhcp_on=True primary_rack=$PRIMARY_RACK

echo "Generaing ssh keys.."
ssh-keygen -q -t rsa -N "" -f "/tmp/maas/id_rsa"
sudo chown r00ta:r00ta /tmp/id_rsa /tmp/maas/id_rsa.pub
sudo chmod 777 /tmp/maas/id_rsa
sudo chmod 777 /tmp/maas/id_rsa.pub
maas admin sshkeys create key="$(cat /tmp/maas/id_rsa.pub)"
