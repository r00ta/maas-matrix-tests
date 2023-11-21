#!/bin/bash

mkdir -p /tmp/maas
chmod 777 /tmp/maas

echo "Installing MAAS.."
if [ -z "$MAAS_VERSION" ]; then
	sudo snap install --channel=latest/edge maas-test-db
	original_dir="$(pwd)"
	git clone https://git.launchpad.net/~troyanov/maas --recurse-submodules --remote-submodules /tmp/maas/code
	cd /tmp/maas/code
	git fetch
	git checkout agent-wf-vlan-reconfigure
	make snap-tree
	sudo snap try dev-snap/tree
	utilities/connect-snap-interfaces
	cd $original_dir
else
	sudo snap install --channel=$MAAS_VERSION maas
	sudo snap install --channel=$MAAS_VERSION maas-test-db
fi


