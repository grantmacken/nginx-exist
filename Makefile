include config
SHELL=/bin/bash
T=.temp
# Make sure we have the following apps installed:
APP_LIST := wget git curl expect
assert-command-present = $(if $(shell which $1),,$(error '$1' missing and needed for this build))
$(foreach src,$(APP_LIST),$(call assert-command-present,$(src)))
#
assert-file-present = $(if $(wildcard $1),,$(error '$1' missing and needed for this build))

assert-is-root = $(if $(shell id -u | grep -oP '^0$$'),\
 $(info OK! root user, so we can change some system files),\
 $(error changing system files so need to sudo) )

assert-is-systemd = $(if $(shell ps -p1 | grep systemd),\
 $(info OK! systemd is init system),\
 $(error  init system is not systemd))

cat = $(shell if [ -e $(1) ] ;then echo "$$(<$(1))" ;fi )

colon := :
$(colon) := :

REPO  := $(shell  echo '$(DEPLOY)' | cut -d/ -f2 )
OWNER := $(shell echo $(DEPLOY) |cut -d/ -f1 )
WEBSITE := $(addprefix http://,$(REPO))
# MAKE_VERSION := $(shell make --version | head -1)
SYSTEMD := $(shell ps -p1 | grep systemd )
# $(info who am i - $(WHOAMI))
# $(info SUDO USER - $(SUDO_USER))
# $(info make version - $(MAKE_VERSION))
# $(info system - $(SYSTEMD))
# $(info current working directory - $(shell pwd))
# $(info which - $(shell which netstat))
# $(info eXist home - $(EXIST_HOME))
# $(info  travis java  home - $(JAVA_HOME))
# $(info  repo - $(REPO))
# $(info  owner - $(OWNER))
# $(info  website - $(WEBSITE))
# $(info GIT USER - $(GIT_USER))

#this will evaluate when running as sudo
# otherwise will be empty when running on remote
# so if running as sudo on desktop we can change permissions back to $SUDO_USER
#$(if $(SUDO_USER),$(info do something),$(info do not do anything))
SUDO_USER := $(shell echo "$${SUDO_USER}")
WHOAMI := $(shell whoami)
INSTALLER := $(if $(SUDO_USER),$(SUDO_USER),$(WHOAMI))
#this will evaluate when running on travis
ifeq ($(INSTALLER),travis)
 TRAVIS := $(INSTALLER)
else
 TRAVIS =
endif
#this will evaluate if we have a access token
ACCESS_TOKEN := $(call cat,$(ACCESS_TOKEN_PATH))
# if we have a github access token use that as admin pass
# $(if $(ACCESS_TOKEN),\
#  $(info using found 'access token' for password),\
#  $(info using 'admin' for password ))
P := $(if $(ACCESS_TOKEN),$(ACCESS_TOKEN),admin)
GIT_USER := $(shell git config --get user.name)
## SETUP ###
chownToUser = $(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $1,)
$(if $(wildcard $(T)/),,$(shell mkdir $(T)))
$(call chownToUser,$(T))

PROVE := $(shell which prove)

default: build

include includes/nginx.mk

.PHONY: help test

eXist: $(T)/eXist-run.sh

nginx: $(T)/nginx-run.sh

nginx-config: $(T)/nginx.conf

nginx-service: $(T)/nginx.service

exist-service:  $(T)/exist.service

webdav:  $(T)/webdav.log

deploy:  $(T)/deploy.sh

help:
	@cat README.md

test:
	@$(PROVE) $(abspath t/test.t)
