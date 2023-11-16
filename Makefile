prepare:
	sudo -E bash -c './install-steps/00-install-utils.sh'
	sudo -E bash -c './install-steps/01-install-lxd.sh'
	sudo -E bash -c './install-steps/02-install-maas.sh'

clean:
	sudo ./clean-steps/02-clean-maas.sh
	sudo ./clean-steps/01-clean-lxd.sh  
	sudo ./clean-steps/00-clean-utils.sh  

test: 
	./test-steps/00-enlist-vm.sh
	./test-steps/01-commission-vm.sh
	./test-steps/02-deploy-vm.sh
	./test-steps/03-ssh-vm.sh
	./test-steps/04-release-vm.sh

.DEFAULT_GOAL := prepare
