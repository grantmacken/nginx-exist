EXIST_VERSION := $(T)/eXist-latest.version
# functions
EXIST_JAR = $(call cat,$(EXIST_VERSION))
EXIST_JAR_PATH = $(T)/$(call cat,$(EXIST_VERSION))
# shortcuts
JAVA := $(shell which java)
START_JAR := $(JAVA) \
 -Dexist.home=$(EXIST_HOME) \
 -Djetty.home=$(EXIST_HOME)/tools/jetty \
 -Dfile.encoding=UTF-8 \
 -Djava.endorsed.dirs=$(EXIST_HOME)/lib/endorsed \
 -Djavax.net.ssl.keyStore=$(EXIST_HOME)/tools/jetty/etc/keystore \
 -Djavax.net.ssl.keyStorePassword=secret \
 -Djavax.net.ssl.trustStore=$(EXIST_HOME)/tools/jetty/etc/keystore \
 -Djava.net.preferIPv4Stack=true \
 -Djavax.net.ssl.trustStorePassword=secret \
 -Dsun.security.ssl.allowLegacyHelloMessages=true \
 -Dsun.security.ssl.allowUnsafeRenegotiation=true \
 -Dhttps.protocols=TLSv1,TLSv1.1,TLSv1.2,SSLv2Hello \
 -Djsse.enableSNIExtension=true \
 -Dorg.apache.http.conn.ssl.SSLSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER \
 -Djavax.net.debug=ssl,handshake \
 -jar $(EXIST_HOME)/start.jar

# http://docs.oracle.com/javase/8/docs/technotes/guides/security/jsse/JSSERefGuide.html#InstallationAndCustomization
# sun.security.ssl.allowUnsafeRenegotiatio
# -Dhttps.protocols=TLSv1,TLSv1.1,TLSv1.2,SSLv2Hello
 # -Djava.net.preferIPv4Stack=true \
 # /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts
 # -Djavax.net.ssl.keyStore=$(EXIST_HOME)/tools/jetty/etc/keystore \
 # -Djavax.net.ssl.keyStorePassword=secret \
 # -Djavax.net.ssl.trustStore=$(EXIST_HOME)/tools/jetty/etc/keystore \
 # -Djavax.net.ssl.trustStorePassword=secret \i
 # -Djava.endorsed.dirs=$(EXIST_HOME)/lib/endorsed \
 # -Djava.net.preferIPv4Stack=true \
 # -Djavax.net.ssl.keyStore=$(EXIST_HOME)/tools/jetty/etc/keystore \
 # -Djavax.net.ssl.keyStorePassword=secret \
 # -Djavax.net.ssl.trustStore=/usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts \
 # -Djavax.net.ssl.trustStorePassword=changeit \
 # -Djavax.net.debug=ssl,handshake 
 #
 # org.apache.http.conn.ssl.SSLSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER


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

$(T)/wget-eXist.log:  $(T)/eXist-latest.version
	@echo "{{{## $(notdir $@) ##"
	@$(if $(call EXIST_JAR),,$(error oh no! this is bad))
	@echo "EXIST_JAR: $(call EXIST_JAR)"
	@echo "EXIST_JAR_PATH: $(call EXIST_JAR_PATH)"
	@echo "Downloading $(call EXIST_JAR). Be Patient! this can take a few minutes"
	@$(if $(wildcard $(call EXIST_JAR_PATH)),\
 touch $@,\
 wget -o $@ -O "$(call EXIST_JAR_PATH)" \
 --trust-server-name  --progress=dot$(:)mega -nc \
 "$(EXIST_DOWNLOAD_SOURCE)/$(call EXIST_JAR)")
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
	
define existService
[Unit]
Description=The exist db application server
After=network.target

[Service]
Environment="EXIST_HOME=$(EXIST_HOME)"
$(if $(SUDO_USER),
Environment="SERVER=development",
Environment="SERVER=production")
WorkingDirectory=$(EXIST_HOME)
User=$(INSTALLER)
Group=$(INSTALLER)
ExecStart=$(START_JAR) jetty
ExecStop=$(START_JAR) shutdown -u admin -p $(P)

[Install]
WantedBy=multi-user.target
endef

$(T)/exist.service: export existService:=$(existService)
$(T)/exist.service:
	@echo "{{{ $(notdir $@) "
	@$(call assert-is-root)
	@$(call assert-is-systemd)
	@echo "$${existService}" > $@
	@$(call chownToUser,$@)
	@cp -f $@ /lib/systemd/system/$(notdir $@)
	@systemd-analyze verify $(notdir $@)
	@systemctl enable  $(notdir $@)
	@systemctl start  $(notdir $@)
	@echo '}}}'

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
	@$(call chownToUser,$(@))
	@cat $@
	@echo '}}}'

$(T)/deploy.sh: $(T)/download_url.txt
	@echo "{{{## $(notdir $@) ##"
	@echo '#!/usr/bin/env bash' > $(@)
	@echo 'cd $(EXIST_HOME)' >> $(@)
	@echo "echo \"repo:install-and-deploy('$(WEBSITE)','$(shell cat $<)')\" | \\" >> $@
	@echo ' java -jar $(EXIST_HOME)/start.jar client -sqx -u admin -P $(P) | tail -1' >> $@
	@$(call chownToUser,$(@))
	@chmod +x $(@)
	@cat $@
	@echo '}}}'

