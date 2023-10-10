# !/bin/bash
mkdir -p /tmp/maas

echo "Installing MAAS.."
sudo snap install --channel=3.4/edge maas
sudo snap install --channel=3.4/edge maas-test-db

echo "Configuring MAAS.."
sudo maas init region+rack --maas-url http://localhost:5240/MAAS --database-uri maas-test-db:/// 
sleep 15
echo "Configuring admin.."
sudo maas createadmin --username maas --password maas --email test@example.com
sudo maas apikey --username=maas > /tmp/maas/api-key-file
maas login admin http://localhost:5240/MAAS `cat /tmp/maas/api-key-file`
export SUBNET=12.0.1.0/24
maas admin subnets create cidr=$SUBNET name=test-subnet
echo "Extracting fabric id.."
export FABRIC_ID=$(maas admin subnet read "$SUBNET" | jq -r ".vlan.fabric_id")
echo "Extracting vlan tag id.."
export VLAN_TAG=$(maas admin subnet read "$SUBNET" | jq -r ".vlan.vid")
echo "Extracting primary rack.."
export PRIMARY_RACK=$(maas admin rack-controllers read | jq -r ".[] | .system_id")
echo "Updating subnet.."
maas admin subnet update $SUBNET gateway_ip=12.0.1.1
maas admin ipranges create type=dynamic start_ip=12.0.1.200 end_ip=12.0.1.254
maas admin vlan update $FABRIC_ID $VLAN_TAG dhcp_on=True primary_rack=$PRIMARY_RACK
maas admin maas set-config name=upstream_dns value=8.8.8.8
maas admin boot-resources import
maas admin rack-controller import-boot-images $PRIMARY_RACK
ssh-keygen -q -t rsa -N "" -f "/tmp/maas/id_rsa"
sudo chown r00ta:r00ta /tmp/id_rsa /tmp/maas/id_rsa.pub
sudo chmod 600 /tmp/maas/id_rsa
sudo chmod 644 /tmp/maas/id_rsa.pub
maas admin sshkeys create key="$(cat /tmp/maas/id_rsa.pub)"
