include config
SHELL=/bin/bash
# Make sure we have the following apps installed:
$(if $(shell ps -p1 | grep systemd ),\
 $(info  OK init system is systemd),\
 $(error init system is not systemd) )
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
SUDO_USER := $(shell echo "$$SUDO_USER")
WHOAMI := $(shell whoami)
INSTALLER := $(if $(SUDO_USER),$(SUDO_USER),$(WHOAMI))
$(info SUDO USER - $(SUDO_USER))
$(info Who Am I - $(WHOAMI))
EXIST_VER := $(TEMP_DIR)/exist-latest.version
EXIST_EXPECT := $(TEMP_DIR)/exist.expect
EXPECT_LOG := $(TEMP_DIR)/exist.expect.log
EXIST_SERVICE := $(TEMP_DIR)/exist.service
EXIST_PASS := $(TEMP_DIR)/exist-pass.log

cat = $(shell if [ -e $(1) ] ;then echo "$$(<$(1))" ;fi )
GIT_USER := $(shell git config --get user.name)
GITHUB_ACCESS_TOKEN := $(call cat,$(GITHUB_ACCESS_TOKEN_PATH))
# if we have a github access token use that as admin pass
P := $(if $(GITHUB_ACCESS_TOKEN),$(GITHUB_ACCESS_TOKEN),admin)

EXIST_JAR = $(call cat,$(EXIST_VER))
EXIST_JAR_PATH = $(TEMP_DIR)/$(call cat,$(EXIST_VER))
#shortcuts
JAVA := $(shell which java)
START_JAR := $(JAVA) -Djava.endorsed.dirs=lib/endorsed -jar start.jar

installer := $(if $(SUDO_USER),$(SUDO_USER),$(WHOAMI))

# @echo 'EXIST_VERSION_SOURCE: $(EXIST_VERSION_SOURCE)'
# @echo 'DESCRIPTION: $(DESCRIPTION)'
# @echo 'GIT_USER_NAME: $(GIT_USER)'
# @echo 'GITHUB_ACCESS_TOKEN: $(GITHUB_ACCESS_TOKEN:)'
# @echo 'EXIST_HOME: $(EXIST_HOME)'
# @echo 'EXST_JAR $(EXIST_JAR)'
# @echo "EXIST_JAR_PATH $(EXIST_JAR_PATH)"
# @echo "USER_ID $(shell id -u)"
# @echo "USER $(shell whoami)"
# @echo '$(if $(shell if [ $$(id -u) -eq 0 ] ;then  echo "isRoot";fi ),$(shell echo "$${SUDO_USER}" ),$(shell whoami) )'
#
#  when not running sudo on the desktop
ifeq ($(SUDO_USER),)
cmdExistClient = java -jar $(EXIST_HOME)/start.jar client -sqx -u $(1) -P $(2)
smFindUsersByUsername = sm$(:)find-users-by-username('$(1)')
smFindGroupsByGroupname = sm$(:)find-groups-by-groupname('$(1)')
smRemoveGroup = sm$(:)remove-group('$(1)')
smIsDBA = sm$(:)is-dba('$(1)')
smIsAccountEnabled = sm$(:)is-account-enabled('$(1)')
smIsAuthenticated = sm$(:)is-authenticated()
smCreateAccount = sm$(:)create-account('$(1)','$(2)','$(3)')

isUser = $(shell echo "$$(cd $(EXIST_HOME);\
 echo "$(call smFindUsersByUsername,$(1))" | \
 $(call cmdExistClient,admin,$(P)) | \
 tail -1 | \
 grep '$(1)')")

isGroup = $(shell echo "$$(cd $(EXIST_HOME);\
 echo "$(call smFindGroupsByGroupname,$(1))" | \
 $(call cmdExistClient,admin,$(P)) | \
 tail -1 | \
 grep '$(1)')")

createDBA = $(shell echo "$$(cd $(EXIST_HOME);\
 echo "sm$(:)create-account('$(1)','$(2)','$(3)')" | \
 $(call cmdExistClient,admin,$(P)) | \
 tail -1 )")

removeGroup = $(shell echo "$$(cd $(EXIST_HOME);\
 echo "sm:remove-group('$(1)')" | \
 $(call cmdExistClient,admin,$(P)))")

isAuthenticated  = $(shell echo "$$(cd $(EXIST_HOME);\
 echo 'sm:is-authenticated()' |\
 $(call cmdExistClient,$(1),$(2)) | \
 tail -1 )")

endif

# isDBA  = $(shell echo "$$(cd $(EXIST_HOME);\
#  echo "sm:is-dba('$(1)')" |\
#  $(call cmdExistClient,$(2),$(3)) | \
#  tail -1 )")

# NY: all
# userExists  = $(shell echo "$$(cd $(EXIST_HOME);\
#  echo "sm:user-exists('$(1)')" |\
#  $(call cmdExistClient,$(2),$(3)) | \
#  tail -1 )")

.PHONY: help

help:
	@$(if $(SUDO_USER),$(info do something),$(info do not do anything))

exist-install:  $(EXIST_SERVICE) 

exist-pass:  $(EXIST_PASS)

$(EXIST_VER): config
	@echo "## $(notdir $@) ##"
	@$(call assert-is-root)
	@echo 'fetch the latest eXist version'
	@curl -s -L  $(EXIST_VERSION_SOURCE) | grep -oP '>\KeXist-db-setup[-\w\.]+' > $@
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo '-------------------------------------------------------------------'

$(EXIST_EXPECT): $(EXIST_VER)
	@echo "## $(notdir $@) ##"
	@$(call assert-is-root)
	@echo "EXIST_JAR: $(call EXIST_JAR)"        
	@echo "EXIST_JAR_PATH: $(call EXIST_JAR_PATH)"
ifeq ($(wildcard $(call EXIST_JAR_PATH)),)
	@echo 'checked we do not have $(call EXIST_JAR) so will download'
	@wget -O "$(call EXIST_JAR_PATH)" --trust-server-name "$(EXIST_DOWNLOAD_SOURCE)/$(call EXIST_JAR)"
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(call EXIST_JAR_PATH),)
endif
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
ifneq ( $(shell journalctl -u exist | tail -n 3 | grep -oP 'Stopped' | tail -1 ),Stopped)
	@echo 'stop existing eXist service'
	@systemctl stop exist
endif
	@journalctl -u exist | tail -n 3 | grep -oP 'Stopped(.+)' | tail -1
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

#@systemctl list-units --type=target

$(EXIST_SERVICE): $(EXPECT_LOG)
	@echo "## $(notdir $@) ##"
	@$(call assert-is-root)
	@systemctl is-failed exist.service > /dev/null && echo 'OK! unit intentionally stopped'
	$(file > $(@),[Unit])
	$(file >> $(@),Description=The exist db application server)
	$(file >> $(@),After=network.target)
	$(file >> $(@),)
	$(file >> $(@),[Service])
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

$(EXIST_PASS):
	@echo "## $(notdir $@) ##"
	@$(call assert-file-present,$(GITHUB_ACCESS_TOKEN_PATH))
	@echo "GIT_USER: $(GIT_USER) "
ifeq ($(call isUser,admin),admin)
	@echo 'admin is in eXists list of users'
endif
ifeq ($(call isUser,$(GIT_USER)),)
	@echo '$(GIT_USER) does not exist in eXists list of users'
endif
ifeq ($(call isGroup,$(GIT_USER)),)
	@echo '$(GIT_USER) does not exist in eXists list of groups'
endif
	@echo "Create a new default password using git user name and github access token"
ifeq ($(call isUser,$(GIT_USER)),)
	@echo 'no user but check for users group account an remove if exists'
	@$(if $(call isGroup,$(GIT_USER)),\
 $(call removeGroup,$(GIT_USER)),echo 'OK')
	@$(call createDBA,$(GIT_USER),$(GITHUB_ACCESS_TOKEN))
endif
ifeq ($(call isUser,$(GIT_USER)),$(GIT_USER))
	@echo '$(GIT_USER) is in eXists list of users'
endif
ifeq ($(call isGroup,$(GIT_USER)),$(GIT_USER))
	@echo '$(GIT_USER) is in eXists list of groups'
endif
	@echo "login using git user name and github access token"
	@echo "$(call isAuthenticated,$(GIT_USER),$(GITHUB_ACCESS_TOKEN))"
	@echo '-------------------------------------------------------------------'

