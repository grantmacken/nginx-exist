include config
SHELL=/bin/bash
CURRENT_MAKEFILE := $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
MAKEFILE_DIRECTORY := $(dir $(CURRENT_MAKEFILE))

ifneq ($(wildcard $(EXIST_DIR)/VERSION.txt ),)
 include $(EXIST_DIR)/VERSION.txt
endif

# misc functions
# Make sure we have the following apps installed:
APP_LIST = git curl expect
assert-command-present = $(if $(shell which $1),,$(error '$1' missing and needed for this build))
$(foreach src,$(APP_LIST),$(call assert-command-present,$(src)))

ifeq ($(TRAVIS_BRANCH),)
 CURRENT_BRANCH := $(shell git symbolic-ref HEAD 2> /dev/null | sed -e 's/refs\/heads\///' )
else
 CURRENT_BRANCH := $(TRAVIS_BRANCH)
endif

ifeq ($(TRAVIS_REPO_SLUG),)
 REPO_SLUG := $(shell git remote -v | grep -oP ':\K.+(?=\.git)' | head -1)
else
 REPO_SLUG := $(TRAVIS_REPO_SLUG)
endif

GIT_USER_NAME := $(shell git config user.name)
GIT_ACCESS_TOKEN := $(shell cat $(GIT_ACCESS_TOKEN_LOCATION) )

eXistVersion != curl -s $(EXIST_VERSION_SOURCE) | grep -oP 'Download \KeXist-db-setup[\S]+' | tail -n 1 > exist.version && cat exist.version
EXIST_VERSION := $(shell cat exist.version )

default: help

help:
	@echo 'REPO_SLUG': $(REPO_SLUG)
	@echo 'CURRENT_BRANCH': $(CURRENT_BRANCH)
	@echo 'DESCRIPTION: $(DESCRIPTION)'
	@echo 'GIT_USER_NAME: $(GIT_USER_NAME)'
	@echo 'GIT_ACCESS_TOKEN_LOCATION: $(GIT_ACCESS_TOKEN_LOCATION)'
	@echo 'EXIST_DOWNLOAD_SOURCE: $(EXIST_DOWNLOAD_SOURCE)'
	@echo 'EXIST_DIR: $(EXIST_DIR)'
	@echo 'SRC_DIR: $(SRC_DIR)'
	@echo 'EXIST_VERSION: $(EXIST_VERSION)'
ifneq ($(wildcard $(EXIST_DIR)/VERSION.txt ),)
	@echo '$(wildcard $(EXIST_DIR)/VERSION.txt )'
endif

#download: $(SRC_DIR)/$(EXIST_VERSION)
#
#expect: $(SRC_DIR)/eXist.expect
#
#install: $(SRC_DIR)/$(EXIST_VERSION) $(SRC_DIR)/eXist.expect $(EXIST_DIR)/VERSION.txt

.PHONY: create-account check-account

create-account:
	@echo "sm:create-account( '$(GIT_USER_NAME)', '$(GIT_ACCESS_TOKEN)', 'dba' )"
	@cd $(EXIST_DIR) && \
 echo "sm:create-account( '$(GIT_USER_NAME)', '$(GIT_ACCESS_TOKEN)', 'dba' )" | \
 java -jar start.jar client -u admin -P admin -x


check-account:
	@cd $(EXIST_DIR) && \
 echo "sm:is-dba('$(GIT_USER_NAME)')" | \
 java -jar start.jar client -u admin -P admin -x -s 2>/dev/null | grep 'true'
#


#$(SRC_DIR)/$(EXIST_VERSION):
#	@echo "mkdir: [ $(@D) ]"
#	@mkdir -p $(@D)
#	@chown $(SUDO_USER):$(SUDO_USER) $(@D)
#	@echo  "MODIFY $(notdir $@)"
#	@cd $(@D) && wget -O "$(notdir $@)" --trust-server-name "$(EXIST_DOWNLOAD_SOURCE)"
#	@chown $(SUDO_USER):$(SUDO_USER) $(@)

#$(SRC_DIR)/eXist.expect: $(SRC_DIR)/$(EXIST_VERSION)
#	@echo  "SOURCE $(notdir $<)"
#	@echo  "TARGET $(notdir $@)"
#	@mkdir -p $(@D)
#	@chown $(SUDO_USER):$(SUDO_USER) $(@D)
#	@$(file > $@,#!/usr/bin/expect )
#	@$(file >> $@,set timeout 10 )
#	@$(file >> $@,spawn su -c "java -jar $(EXIST_VERSION) -console"  -s /bin/sh $(SUDO_USER) )
#	@$(file >> $@,expect "Select target" { send "$(EXIST_DIR)\n" } )
#	@$(file >> $@,expect "*ress 1" { send "1\n" })
#	@$(file >> $@,expect "Data dir" { send "$(EXIST_DATA_DIR)\n" })
#	@$(file >> $@,expect "*ress 1" { send "1\n" })
#	@$(file >> $@,expect "Enter password" { send "admin\n" })
#	@$(file >> $@,expect "Enter password" { send "admin\n" })
#	@$(file >> $@,expect "Maximum memory" { send "\n" })
#	@$(file >> $@,expect "Cache memory" { send "\n" })
#	@$(file >> $@,expect "*ress 1" {send "1\n"})
#	@$(file >> $@,expect -timeout -1 "Console installation done" {)
#	@$(file >> $@,  wait)
#	@$(file >> $@,  exit)
#	@$(file >> $@,})
#	@chown $(SUDO_USER):$(SUDO_USER) $(@)

  
#@$(file >> $@,expect "*ress 1" { send "1\n" })

#$(EXIST_DIR)/VERSION.txt: $(SRC_DIR)/eXist.expect
#	@mkdir -p $(@D)
#	@chown $(SUDO_USER):$(SUDO_USER) $(@D)
#	@cd $(SRC_DIR) && expect < eXist.expect


#@mkdir -p $(@D)
#@echo  "MODIFY $(notdir $@)"
#@cp $< $@

