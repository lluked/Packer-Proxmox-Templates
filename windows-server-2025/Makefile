VARS_FILE=../proxmox.pkrvars.hcl

.PHONY: init build validate fmt clean build-debug

# Detect OS
PLATFORM := $(shell uname -s 2>/dev/null || echo WINDOWS)

init:
	packer init .

validate:
	packer validate -var-file="$(VARS_FILE)" .

build:
	packer build -var-file="$(VARS_FILE)" .

build-debug:
ifeq ($(PLATFORM),WINDOWS)
	set PACKER_LOG=1 && set PACKER_LOG_PATH=packer.log && packer build -on-error=abort -var-file="$(VARS_FILE)" .
else
	PACKER_LOG=1 PACKER_LOG_PATH=packer.log packer build -on-error=abort -var-file="$(VARS_FILE)" .
endif

fmt:
	packer fmt .

clean:
ifeq ($(PLATFORM),WINDOWS)
	if exist .packer rmdir /s /q .packer
else
	rm -rf .packer
endif
