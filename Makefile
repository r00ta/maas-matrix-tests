# Define the "prepare" target to depend on all the scripts
prepare:
	./install-steps/00-install-utils.sh
	./install-steps/01-install-lxd.sh
	./install-steps/02-install-maas.sh

# Clean up any temporary files created during execution
clean:
	./clean-steps/02-clean-maas.sh
	./clean-steps/01-clean-lxd.sh  
	./clean-steps/00-clean-utils.sh  

test: 
	./test-steps/00-deploy-cycle.sh
# By default, make will execute the "prepare" target
.DEFAULT_GOAL := prepare
