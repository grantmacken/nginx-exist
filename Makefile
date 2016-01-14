include config
SHELL=/bin/bash
# Make sure we have the following apps installed:
APP_LIST := wget git curl expect
assert-command-present = $(if $(shell which $1),,$(error '$1' missing and needed for this build))
$(foreach src,$(APP_LIST),$(call assert-command-present,$(src)))
#
assert-file-present = $(if $(wildcard $1),,$(error '$1' missing and needed for this build))

assert-is-root = $(if $(shell id -u | grep -oP '^0$$'),\
 $(info OK! root user, so we can change some system files),\
 $(error changing system files so need to sudo) )

colon := :
$(colon) := :
#this will evaluate when running as sudo on desktop
# otherwise will be empty when running on remote
# so if running as sudo on desktop we can change permissions back to $SUDO_USER
#$(if $(SUDO_USER),$(info do something),$(info do not do anything))
SUDO_USER := $(shell echo "$${SUDO_USER}")
WHOAMI := $(shell whoami)
INSTALLER := $(if $(SUDO_USER),$(SUDO_USER),$(WHOAMI))

ifeq ($(INSTALLER),travis)
 TRAVIS := $(INSTALLER)
else
 TRAVIS =
endif

MAKE_VERSION := $(shell make --version | head -1)
SYSTEMD := $(shell ps -p1 | grep systemd )
TEMP_DIR := .temp
$(info who am i - $(WHOAMI))
$(info SUDO USER - $(SUDO_USER))
$(info make version - $(MAKE_VERSION))
$(info system - $(SYSTEMD))
$(info current working directory - $(shell pwd))
$(info which - $(shell which netstat))
$(info eXist home - $(EXIST_HOME))
$(info  travis repo slug- $(TRAVIS_REPO_SLUG))
$(info  travis java  home - $(JAVA_HOME))

EXIST_VERSION := $(TEMP_DIR)/eXist-latest.version

cat = $(shell if [ -e $(1) ] ;then echo "$$(<$(1))" ;fi )
GIT_USER := $(shell git config --get user.name)

$(info GIT USER - $(GIT_USER))
ACCESS_TOKEN := $(call cat,$(ACCESS_TOKEN_PATH))
# if we have a github access token use that as admin pass
$(if $(ACCESS_TOKEN),\
 $(info using found 'access token' for password),\
 $(info using 'admin' for password ))

P := $(if $(ACCESS_TOKEN),$(ACCESS_TOKEN),admin)

PROVE := $(shell which prove)

## SETUP ###
$(if $(wildcard $(TEMP_DIR)/),$(info OK! have temp dir),$(shell mkdir $(TEMP_DIR)))
$(if $(SUDO_USER),\
 $(shell \
 chown $(SUDO_USER)$(:)$(SUDO_USER) $(TEMP_DIR);\
 if [ -z "$$( cat /etc/hosts | grep -oP '^127\.0\.0\.1\s+\K(example.com)$$')" ] ;\
 then echo '127.0.0.1  example.com' >> /etc/hosts;fi ),\
 $(info OK! inital setup )) 

default: build

include includes/eXist-install.mk
include includes/nginx-install.mk

.PHONY: help test

eXist: $(TEMP_DIR)/eXist-run.sh

nginx: $(TEMP_DIR)/nginx-run.sh

nginx-config: $(TEMP_DIR)/nginx.conf

exist-service:  $(TEMP_DIR)/exist.service

nginx-service:  $(TEMP_DIR)/nginx.service

help:
	$(info install exist)

test:
	@$(PROVE) $(abspath t/test.t)


