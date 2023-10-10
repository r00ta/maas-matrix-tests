# Define the "prepare" target to depend on all the scripts
prepare:
	sudo ./install-steps/00-install-utils.sh
	sudo ./install-steps/01-install-lxd.sh
	sudo ./install-steps/02-install-maas.sh

# Clean up any temporary files created during execution
clean:
	sudo ./clean-steps/02-clean-maas.sh
	sudo ./clean-steps/01-clean-lxd.sh  
	sudo ./clean-steps/00-clean-utils.sh  

test: 
	./test-steps/00-deploy-cycle.sh
# By default, make will execute the "prepare" target
.DEFAULT_GOAL := prepare
