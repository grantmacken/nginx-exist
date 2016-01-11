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
MAKE_VERSION := $(shell make --version | head -1)
SYSTEMD := $(shell ps -p1 | grep systemd )
$(info who am i - $(WHOAMI))
$(info SUDO USER - $(SUDO_USER))
$(info make version - $(MAKE_VERSION))
$(info system - $(SYSTEMD))
$(info current working directory - $(shell pwd))
TEMP_DIR=.temp
ifeq ($(WHOAMI),travis)
EXIST_HOME = $(HOME)/eXist
endif
$(info eXist home - $(EXIST_HOME))
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

EXIST_JAR = $(call cat,$(EXIST_VERSION))
EXIST_JAR_PATH = $(TEMP_DIR)/$(call cat,$(EXIST_VERSION))
#shortcuts
JAVA := $(shell which java)
START_JAR := $(JAVA) -Djava.endorsed.dirs=lib/endorsed -jar start.jar
EXPECT := $(shell which expect)
PROVE := $(shell which prove)

default: build

.PHONY: help test

build: $(TEMP_DIR)/run.sh $(TEMP_DIR)/run-nginx.sh

exist-service:  $(TEMP_DIR)/exist.service

help:
	$(info install exist)

test:
	@$(PROVE) $(abspath t/test.t)

include includes/nginx-install.mk

$(EXIST_VERSION):
	@echo "## $(notdir $@) ##"
	@if [ -d $(dir $@) ] ;then echo 'temp dir exists';else mkdir $(dir $@) ;fi
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $dir (@),)
	@echo 'fetch the latest eXist version'
	@curl -s -L  $(EXIST_VERSION_SOURCE) | grep -oP '>\KeXist-db-setup[-\w\.]+' > $@
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@ls -al $(dir $@)
	@cat $@
	@echo '-------------------------------------------------------------------'

$(TEMP_DIR)/wget-eXist.log: $(EXIST_VERSION)
	@echo "## $(notdir $@) ##"
	@$(if $(call EXIST_JAR),,$(error oh no! this is bad))
	@echo "EXIST_JAR: $(call EXIST_JAR)"
	@echo "EXIST_JAR_PATH: $(call EXIST_JAR_PATH)"
	@echo "Downloading $(call EXIST_JAR). Be Patient! this can take a few minutes"
	@wget -o $@ -O "$(call EXIST_JAR_PATH)" \
 --trust-server-name  --progress=dot$(:)mega -nc \
 "$(EXIST_DOWNLOAD_SOURCE)/$(call EXIST_JAR)"
	echo '# because we use wget with no clobber, if we have source then just touch log'
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@cat $@
	@echo '-------------------------------------------------------------------'

$(TEMP_DIR)/eXist.expect: $(TEMP_DIR)/wget-eXist.log
	@echo "## $(notdir $@) ##"
	@echo 'we have $(call EXIST_JAR)'
	@echo 'creating expect file'
	@echo '#!$(EXPECT) -f' > $(@)
	$(if $(SUDO_USER),\
 echo 'spawn su -c "java -jar $(call EXIST_JAR_PATH) -console" -s /bin/sh $(INSTALLER)' > $(@),\
 echo 'spawn java -jar $(call EXIST_JAR_PATH) -console' >> $(@))
	@echo 'expect "Select target" { send "$(EXIST_HOME)\n" }'  >> $(@)
	@echo 'expect "*ress 1" { send "1\n" }'  >> $(@)
	@echo 'expect "*ress 1" { send "1\n" }'  >> $(@)
	@echo 'expect "Data dir" { send "$(EXIST_DATA_DIR)\n" }' >> $(@)
	@echo 'expect "*ress 1" { send "1\n" }' >> $(@)
	@echo 'expect "Enter password" { send "$(P)\n" }' >> $(@)
	@echo 'expect "Enter password" { send "$(P)\n" }' >> $(@)
	@echo 'expect "Maximum memory" { send "\n" }'  >> $(@)
	@echo 'expect "Cache memory" { send "\n" }'  >> $(@)
	@echo 'expect "*ress 1" {send "1\n"}'  >> $(@)
	@echo 'expect -timeout -1 "Console installation done" {' >> $(@)
	@echo ' wait'  >> $(@)
	@echo ' exit'  >> $(@)
	@echo '}'  >> $(@)
	@ls -al $(@)
	@cat $(@)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@chmod +x $(@)
	@echo '-------------------------------------------------------------------'

$(TEMP_DIR)/eXist-expect.log: $(TEMP_DIR)/eXist.expect
	@echo "## $(notdir $@) ##"
	@echo "$(EXIST_HOME)"
	@cat $(<)
	@$(if $(shell curl -I -s -f 'http://localhost:8080/' ),\
 $(error detected eXist already running),)
	@echo 'remove any exiting eXist instalation'
	@if [ -d $(EXIST_HOME) ] ;then rm -R $(EXIST_HOME) ;fi
	@echo 'make eXist dir and reset permissions back to user'
	@mkdir -p $(EXIST_HOME)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(EXIST_HOME),)
	@echo "Install eXist via expect script. Be Patient! this can take a few minutes"
	@$(<) | tee $(@)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo '-------------------------------------------------------------------'

$(TEMP_DIR)/run.sh: $(TEMP_DIR)/eXist-expect.log
	@echo "## $(notdir $@) ##"
	@echo '#!/usr/bin/env bash' > $(@)
	@echo 'cd $(EXIST_HOME)' >> $(@)
	@echo 'java -Djava.endorsed.dirs=lib/endorsed -Djava.net.preferIPv4Stack=true -jar start.jar jetty &' >> $(@)
	@echo 'while [[ -z "$$(curl -I -s -f 'http://127.0.0.1:8080/')" ]] ; do sleep 5 ; done' >> $(@)
	@chmod +x $(@)
	@echo '-------------------------------------------------------------------'

$(TEMP_DIR)/exist.service: $(TEMP_DIR)/eXist-expect.log
	@echo "## $(notdir $@) ##"
	$(if $(shell ps -p1 | grep systemd ),\
 $(info  OK init system is systemd),\
 $(error init system is not systemd) )
	@$(call assert-is-root)
	@systemctl is-failed exist.service > /dev/null && echo 'OK! unit intentionally stopped'
	$(file > $(@),[Unit])
	$(file >> $(@),Description=The exist db application server)
	$(file >> $(@),After=network.target)
	$(file >> $(@),)
	$(file >> $(@),[Service])
	$(file >> $(@),Environment="EXIST_HOME=$(EXIST_HOME)")
	$(file >> $(@),$(if $(SUDO_USER),Environment="SERVER=development",Environment="SERVER=production"))
	$(file >> $(@),WorkingDirectory=$(EXIST_HOME))
	$(file >> $(@),User=$(INSTALLER))
	$(file >> $(@),Group=$(INSTALLER))
	$(file >> $(@),ExecStart=$(START_JAR) jetty)
	$(file >> $(@),ExecStop=$(START_JAR) shutdown -u admin -p $(P) )
	$(file >> $(@),)
	$(file >> $(@),[Install])
	$(file >> $(@),WantedBy=multi-user.target)
	@cp $@ /lib/systemd/system/$(notdir $@)
	@systemd-analyze verify $(notdir $@)
	@systemctl enable  $(notdir $@)
	@systemctl start  $(notdir $@)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo '-------------------------------------------------------------------'
