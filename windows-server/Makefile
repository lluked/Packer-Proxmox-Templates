PROXMOX_VARS_FILE = ../proxmox.pkrvars.hcl

VERSION ?= 2019
EDITION ?= Essentials

VALID_EDITIONS := Standard Standard-Core Datacenter Datacenter-Core

# Add Essentials only for specific versions
ifneq (,$(filter $(VERSION),2016 2019))
  VALID_EDITIONS += Essentials
endif

# Only validate if EDITION is NOT empty
ifneq ($(strip $(EDITION)),)
  ifeq ($(filter $(EDITION),$(VALID_EDITIONS)),$(EDITION))
    # valid
  else
    $(error Invalid EDITION '$(EDITION)' for VERSION $(VERSION). Must be one of: $(foreach e,$(VALID_EDITIONS),'$(e)') or empty to use default from build_version_vars file)
  endif
endif

VERSION_VARS_FILE = ./build_version_vars/$(VERSION).pkrvars.hcl

VAR_STRING = -var-file="$(PROXMOX_VARS_FILE)" -var-file="$(VERSION_VARS_FILE)" -var "build_edition=$(EDITION)"

.PHONY: init build validate fmt clean build-debug

# Detect OS
PLATFORM := $(shell uname -s 2>/dev/null || echo WINDOWS)

init:
	packer init .

validate:
	packer validate $(VAR_STRING) .	

build:
	packer build $(VAR_STRING) .

build-debug:
ifeq ($(PLATFORM),WINDOWS)
	set PACKER_LOG=1 && set PACKER_LOG_PATH=packer.log && packer build -on-error=abort $(VAR_STRING) .
else
	PACKER_LOG=1 PACKER_LOG_PATH=packer.log packer build -on-error=abort $(VAR_STRING) .
endif

fmt:
	packer fmt .

clean:
ifeq ($(PLATFORM),WINDOWS)
	if exist .packer rmdir /s /q .packer
else
	rm -rf .packer
endif
