EXIST_VERSION := $(T)/eXist-latest.version
# functions
EXIST_JAR = $(call cat,$(EXIST_VERSION))
EXIST_JAR_PATH = $(T)/$(call cat,$(EXIST_VERSION))
# shortcuts
JAVA := $(shell which java)
START_JAR := $(JAVA) -Djava.endorsed.dirs=lib/endorsed -jar start.jar
EXPECT := $(shell which expect)
EXIST_DOWNLOAD_SOURCE=https://bintray.com/artifact/download/existdb/releases
EXIST_VERSION_SOURCE=https://bintray.com/existdb/releases/exist/_latestVersion

$(EXIST_VERSION):
	@echo "{{{## $(notdir $@) ##"
	@echo 'fetch the latest eXist version'
	@curl -s -L  $(EXIST_VERSION_SOURCE) | grep -oP '>\KeXist-db-setup[-\w\.]+' > $@
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@cat $@
	@echo '}}}'

$(T)/wget-eXist.log: $(EXIST_VERSION)
	@echo "{{{## $(notdir $@) ##"
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
	@echo '}}}'

$(T)/eXist.expect: $(T)/wget-eXist.log
	@echo "{{{## $(notdir $@) ##"
	@echo 'we have $(call EXIST_JAR)'
	@echo 'creating expect file'
	@echo '#!$(EXPECT) -f' > $(@)
	$(if $(SUDO_USER),\
 echo 'spawn su -c "java -jar $(call EXIST_JAR_PATH) -console" -s /bin/sh $(INSTALLER)' >> $(@),\
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
	@echo '}}}'

$(T)/eXist-expect.log: $(T)/eXist.expect
	@echo "{{{## $(notdir $@) ##"
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
	@echo '}}}'

$(T)/eXist-run.sh: $(T)/eXist-expect.log
	@echo "{{{## $(notdir $@) ##"
	@echo '#!/usr/bin/env bash' > $(@)
	@echo 'cd $(EXIST_HOME)' >> $(@)
	@echo 'java -Djava.endorsed.dirs=lib/endorsed -Djava.net.preferIPv4Stack=true -jar start.jar jetty &' >> $(@)
	@echo 'while [[ -z "$$(curl -I -s -f 'http://127.0.0.1:8080/')" ]] ; do sleep 5 ; done' >> $(@)
	@chmod +x $(@)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo '---------}}}'

$(T)/exist.service: $(T)/eXist-expect.log
	@echo "{{{  $(notdir $@) "
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
	@echo '-----}}}'

.PHONY: git-user-as-eXist-user

git-user-as-eXist-user:
	@cd $(EXIST_HOME) && echo 'sm:find-users-by-username("admin")' |\
 java -jar $(EXIST_HOME)/start.jar client -sqx -u admin -P $(P) | \
 tail -1
	@cd $(EXIST_HOME) && echo 'sm:find-users-by-username("$(GIT_USER)")' |\
 java -jar $(EXIST_HOME)/start.jar client -sqx -u admin -P $(P) | \
 tail -1
	@cd $(EXIST_HOME) && echo 'sm:create-account( "$(GIT_USER)", "$(P)", "dba" )' | \
 java -jar $(EXIST_HOME)/start.jar client -sqx -u admin -P $(P) | \
 tail -1
	@cd $(EXIST_HOME) && echo 'sm:find-users-by-username("$(GIT_USER)")' |\
 java -jar $(EXIST_HOME)/start.jar client -sqx -u admin -P $(P) | \
 tail -1


$(T)/webdav.log:
	@echo '{{{ $(notdir $@) '
	@$(call assert-is-root)
	@$(info CHECK -  mount.davfs suid flag set for user, allowing user to mount webdav)
	@$(if $(TRAVIS),,\
 test -u /usr/sbin/mount.davfs || \
 $(EXPECT) -c "spawn  dpkg-reconfigure davfs2 -freadline; expect \"Should\"; send \"y\\n\"; interact" )
	@$(info CHECK -  if there is a davfs group )
	@$(if $(shell echo "$$(groups davfs2 2>/dev/null)"),\
 $(info OK! there is davfs2 group),\
 groupadd davfs2 && usermod -aG davfs2 $(SUDO_USER) && groups davfs2 )
	@$(info CHECK -  if user belongs to davfs2 group )
	@$(if $(shell echo "$$(id $(SUDO_USER) 2>/dev/null | grep -oP '(\Kdavfs2)')"),\
 $(info OK! user belongs to davfs2 group),\
 usermod -aG davfs2 $(SUDO_USER) && echo 'Need to refresh group membership by *logging out* ' )
	@$(info CHECK -   have $(HOME)/eXist davfs mount point in fstab)
	@$(if $(shell echo "$$(cat /etc/fstab | grep $(HOME)/eXist )"),\
 $(info OK! have davfs mount point in fstab),\
 echo "http://localhost:8080/exist/webdav/db  $(HOME)/eXist  _netdev,user,rw,noauto  0  0" >> /etc/fstab )
	@$(if $(shell echo "$$( mount | grep -oP '$(HOME)/eXist' )"),\
  umount $(HOME)/eXist,\
 $(info not yet mounted))
	@echo '#very very very secret' >  /etc/davfs2/secrets
	@echo '/home/$(SUDO_USER)/eXist admin  $(P)' >> /etc/davfs2/secrets
	@chmod -v 600 /etc/davfs2/secrets
	@if [ ! -d $(HOME)/eXist ] ; then mkdir $(HOME)/eXist ; fi
	@if [ ! -d $(HOME)/.davfs2 ] ; then mkdir $(HOME)/.davfs2 ; fi
	@cp /etc/davfs2/davfs2.conf $(HOME)/.davfs2/davfs2.conf
	@cp /etc/davfs2/secrets $(HOME)/.davfs2/secrets
	@chown -v $(SUDO_USER):davfs2 $(HOME)/.davfs2/*
	@$(if $(TRAVIS),\
 mount $(HOME)/eXist,\
 su -c "mount $(HOME)/eXist" -s /bin/sh $(INSTALLER))
	@echo '-------------}}} '


$(T)/download_url.txt:
	@echo "{{{## $(notdir $@) ##"
	@curl -s x https://api.github.com/repos/$(DEPLOY)/releases/latest | \
 jq '.assets[] | .browser_download_url'  >> $@
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@cat $@
	@echo '}}}'

$(T)/deploy.sh: $(T)/download_url.txt
	@echo "{{{## $(notdir $@) ##"
	@echo '#!/usr/bin/env bash' > $(@)
	@echo 'cd $(EXIST_HOME)' >> $(@)
	@echo "echo \"repo:install-and-deploy('$(WEBSITE)','$(shell cat $<)')\" | \\" >> $@
	@echo ' java -jar $(EXIST_HOME)/start.jar client -sqx -u admin -P $(P) | tail -1' >> $@
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@chmod +x $(@)
	@cat $@
	@echo '}}}'

