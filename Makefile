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
$(info SUDO USER - $(SUDO_USER))
$(info Who Am I - $(WHOAMI))
TEMP_DIR=.temp
ifeq ($(WHOAMI),travis)
EXIST_HOME = $(HOME)/eXist
endif
$(info eXist home - $(EXIST_HOME))
EXIST_VER := $(TEMP_DIR)/exist-latest.version
EXIST_EXPECT := $(TEMP_DIR)/exist.expect
EXPECT_LOG := $(TEMP_DIR)/exist.expect.log
EXIST_SERVICE := $(TEMP_DIR)/exist.service
EXIST_PASS := $(TEMP_DIR)/exist-pass.log

cat = $(shell if [ -e $(1) ] ;then echo "$$(<$(1))" ;fi )
GIT_USER := $(shell git config --get user.name)

$(info GIT USER - $(GIT_USER))
ACCESS_TOKEN := $(call cat,$(ACCESS_TOKEN_PATH))
# if we have a github access token use that as admin pass
$(if $(ACCESS_TOKEN),\
 $(info using found 'access token' for password),\
 $(info using 'admin' for password ))

P := $(if $(ACCESS_TOKEN),$(ACCESS_TOKEN),admin)

EXIST_JAR = $(call cat,$(EXIST_VER))
EXIST_JAR_PATH = $(TEMP_DIR)/$(call cat,$(EXIST_VER))
#shortcuts
JAVA := $(shell which java)
START_JAR := $(JAVA) -Djava.endorsed.dirs=lib/endorsed -jar start.jar

installer := $(if $(SUDO_USER),$(SUDO_USER),$(WHOAMI))

.PHONY: help

# @$(if $(SUDO_USER),$(info do something),$(info do not do anything))

help:
	$(info install exist)
	ls -al /usr/local
	ls -al /usr/local/lib
	ls -al /usr/local/bin
	ls -al /usr/local/share


build:  $(EXIST_VER)

$(EXIST_VER): config
	@echo "## $(notdir $@) ##"
	@mkdir $(dir $@)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $dir (@),)
	@echo 'fetch the latest eXist version'
	@curl -s -L  $(EXIST_VERSION_SOURCE) | grep -oP '>\KeXist-db-setup[-\w\.]+' > $@
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo "$(call cat,@)"
	@echo '-------------------------------------------------------------------'

$(EXIST_EXPECT): $(EXIST_VER)
	@echo "## $(notdir $@) ##"
	@$(call assert-is-root)
	@echo "EXIST_JAR: $(call EXIST_JAR)"
	@echo "EXIST_JAR_PATH: $(call EXIST_JAR_PATH)"
	$(if $(wildcard $(call EXIST_JAR_PATH)),\
 wget -O "$(call EXIST_JAR_PATH)" --trust-server-name "$(EXIST_DOWNLOAD_SOURCE)/$(call EXIST_JAR)",)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(call EXIST_JAR_PATH),)                  
	@echo 'we have $(call EXIST_JAR)'
	@echo 'creating expect file'
	$(file > $(EXIST_EXPECT),#!/usr/bin/expect )
	$(file >> $(EXIST_EXPECT),spawn su -c "java -jar $(call EXIST_JAR_PATH) -console" -s /bin/sh $(INSTALLER) )
	$(file >> $(EXIST_EXPECT),expect "Select target" { send "$(EXIST_HOME)\n" } )
	$(file >> $(EXIST_EXPECT),expect "*ress 1" { send "1\n" } )
	$(file >> $(EXIST_EXPECT),expect "*ress 1" { send "1\n" } )
	$(file >> $(EXIST_EXPECT),expect "Data dir" { send "$(EXIST_DATA_DIR)\n" })
	$(file >> $(EXIST_EXPECT),expect "*ress 1" { send "1\n" })
	$(file >> $(EXIST_EXPECT),expect "Enter password" { send "$(P)\n" })
	$(file >> $(EXIST_EXPECT),expect "Enter password" { send "$(P)\n" })
	$(file >> $(EXIST_EXPECT),expect "Maximum memory" { send "\n" } )
	$(file >> $(EXIST_EXPECT),expect "Cache memory" { send "\n" } )
	$(file >> $(EXIST_EXPECT),expect "*ress 1" {send "1\n"} )
	$(file >> $(EXIST_EXPECT),expect -timeout -1 "Console installation done" {)
	$(file >> $(EXIST_EXPECT), wait )
	$(file >> $(EXIST_EXPECT), exit )
	$(file >> $(EXIST_EXPECT),} )
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo '-------------------------------------------------------------------'

$(EXPECT_LOG): $(EXIST_EXPECT)
	@echo "## $(notdir $@) ##"
	@$(call assert-is-root)
	if( $(shell journalctl -u exist | tail -n 3 | grep -oP 'Stopped'),\
 systemctl stop exist,)
	@curl -I -s -f 'http://localhost:8080/' || echo 'OK. curl can not connect to port 8080'
	@echo 'remove any exiting eXist instalation'
	@if [ -d $(EXIST_HOME) ] ;then rm -R $(EXIST_HOME) ;fi
	@echo 'make eXist dir and reset permissions back to user'
	@mkdir -p  $(EXIST_HOME)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(EXIST_HOME),)
	@echo "Install eXist via expect script. Be Patient! this can take a few minutes"
	@expect < $(<) | tee $@ 2>&1
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo '-------------------------------------------------------------------'

