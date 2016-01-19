NGINX_VERSION_SOURCE := http://nginx.org
NGINX_DOWNLOAD := http://nginx.org/download
PCRE_DOWNLOAD := ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre
ZLIB_DOWNLOAD := http://zlib.net
OPENSSL_DOWNLOAD := http://www.openssl.org/source
NGINX_VERSION := $(TEMP_DIR)/nginx-latest.version
NGINX_VERSION_OPTION := mainline
NGINX_CONFIG := $(NGINX_HOME)/conf/nginx.conf

# chkWhichNginx := $(shell which nginx)
# installedNginxVersion := $(if $(chkWhichNginx),\
# $(shell  $(chkWhichNginx) -v 2>&1 | grep -oP '\K[0-9]+\.[0-9]+\.[0-9_]+' ),)
# $(info install nginx version - $(installedNginxVersion))
$(info nginx home - $(NGINX_HOME))

getSRCVAR = $(shell echo '$1_ver' | tr 'a-z' 'A-Z')
getVERSION = $(addsuffix .tar.gz,$(addprefix $2-,$(shell source $1 && echo $$$(call getSRCVAR,$2))))

define nginxConfig
	@echo "configure nginx so it acts as a reverse proxy for eXist"
	@echo 'set one worker per core'
	@echo 'worker_processes $(shell grep ^proces /proc/cpuinfo | wc -l );' > $1
	@cat $1 | tail -1
	@echo '' >> $1
	@echo 'events {' >> $1
	@echo '  worker_connections  1024;' >> $1
	@echo '}' >> $1
	@echo '' >> $1
	@echo 'http {' >> $1
	@echo '  include mime.types;' >> $1
	@echo '  include gzip.conf;' >> $1
	@echo '  include proxy-defaults.conf;' >> $1
	@echo '  default_type application/octet-stream;' >> $1
	@echo '  sendfile on;' >> $1
	@echo '  keepalive_timeout 65;' >> $1
	@echo '  server {' >> $1
	@echo '    listen 80 default deferred;' >> $1
	@echo '    charset utf-8;' >> $1
	@echo '    server_name ~^(www\.)?(?<domain>.+)$$;' >> $1
	@echo '' >> $1
	@echo '    root  $(EXIST_HOME)/$(EXIST_DATA_DIR)/fs/db/apps/$$domain;' >> $1
	@echo '' >> $1
	@echo '    include server-rewrites.conf;' >> $1
	@echo '    include server-locations.conf;' >> $1
	@echo '' >> $1
	@echo '' >> $1
	@echo '    location ~* ^(.*)\.html$$ {' >> $1
	@echo '      try_files $$uri @proxy;' >> $1
	@echo '      proxy_pass http://localhost:8080;' >> $1
	@echo '    }' >> $1
	@echo '' >> $1
	@echo '    location @proxy {' >> $1
	@echo '      rewrite ^/?(.*)$$ /exist/apps/$$domain/$$1 break;' >> $1
	@echo '      proxy_pass http://localhost:8080;' >> $1
	@echo '    }' >> $1
	@echo '  }' >> $1
	@echo '}' >> $1
	@echo '' >> $1
endef

define nginxMinConfig
	@echo "configure nginx so it acts as a reverse proxy for eXist"
	@echo 'set one worker per core'
	@echo 'worker_processes $(shell grep ^proces /proc/cpuinfo | wc -l );' > $1
	@cat $1 | tail -1
	@echo '' >> $1
	@echo 'events {' >> $1
	@echo '  worker_connections  1024;' >> $1
	@echo '}' >> $1
	@echo '' >> $1
	@echo 'http {' >> $1
	@echo '  include mime.types;' >> $1  
	@echo '  proxy_set_header  Host  $host;' >> $1 
	@echo '  proxy_set_header  X-Real-IP  $remote_addr;' >> $1 
	@echo '  proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;' >> $1 
	@echo '  proxy_set_header  nginx-request-uri  $request_uri;' >> $1 
	@echo '  server {' >> $1
	@echo '    listen 80;' >> $1
	@echo '    server_name ~^(www\.)?(?<domain>.+)$$;' >> $1
	@echo '    charset utf-8;' >> $1
	@echo '' >> $1
	@echo '    location ~* ^(.*)\.html$$ {' >> $1
	@echo '      rewrite ^/?(.*)$$ /exist/apps/$$domain/$$1 break;' >> $1
	@echo '      proxy_pass http://localhost:8080;' >> $1
	@echo '    }' >> $1
	@echo '' >> $1
	@echo '  }' >> $1
	@echo '}' >> $1
	@echo '' >> $1
endef

define nginxService
	@echo "creating systemd ngnix.service script"
	@echo '[Unit]' >> $1
	@echo '' >> $1
	@echo 'Description=The nginx HTTP and reverse proxy server' >> $1
	@echo 'After=network.target' >> $1
	@echo '' >> $1
	@echo '[Service]' >> $1
	@echo 'PIDFile=$(NGINX_HOME)/logs/nginx.pid' >> $1
	@echo 'ExecStartPre=$(NGINX_HOME)/sbin/nginx -t' >> $1
	@echo 'ExecStart=$(NGINX_HOME)/sbin/nginx' >> $1
	@echo 'ExecReload=/bin/kill -s HUP $$MAINPID' >> $1
	@echo 'ExecStop=/bin/kill -s QUIT $$MAINPID' >> $1
	@echo 'PrivateTmp=true' >> $1
	@echo '' >> $1
	@echo '[Install]' >> $1
	@echo 'WantedBy=multi-user.target' >> $1
endef

$(NGINX_VERSION): config
	@echo "{{{ $(notdir $@) "
	@if [ -d $(dir $@) ] ;then echo 'temp dir exists';else mkdir $(dir $@) ;fi
	@echo 'fetch the latest nginx version'
	@echo NGINX_VER=$$( curl -s -L  $(NGINX_VERSION_SOURCE) | tr -d '\n\r' |\
 grep -oP 'nginx-\K([0-9]+\.[0-9]+\.[0-9]+)(?=....$(NGINX_VERSION_OPTION))' |\
 head -1) > $(@)
	@cat $(@) | tail -1
	@echo 'fetch the latest pcre version'
	@echo PCRE_VER=$$( \
 curl -s 'ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/' | \
 grep -oP "pcre-\K[0-9]+\.[0-9]+(?=\.tar\.gz)" | \
 tail -1  ) >> $(@)
	@cat $(@) | tail -1
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) -R $(dir $@),)
	@echo '-----------------------------------------------------------------}}}'

$(TEMP_DIR)/nginx-tested.log: $(NGINX_VERSION)
	@echo "{{{ $(notdir $@) "
	@echo "$(NGINX_DOWNLOAD)/$(call getVERSION,$<,nginx)" && \
 curl $(NGINX_DOWNLOAD)/$(call getVERSION,$<,nginx) |  \
 tar xz --directory $(dir $<) && \
 echo "$(PCRE_DOWNLOAD)/$(call getVERSION,$<,pcre)" && \
 curl $(PCRE_DOWNLOAD)/$(call getVERSION,$<,pcre) | \
 tar xz --directory $(dir $<)
	source $(NGINX_VERSION); cd $(dir $(<))/nginx-$${NGINX_VER} ;\
 ./configure   --with-select_module  \
 --with-pcre="../pcre-$${PCRE_VER}" \
 --with-http_gzip_static_module && make && make install
	@if [ -d $(NGINX_HOME)/proxy ] ; then mkdir $(NGINX_HOME)/proxy ;fi
	@if [ -d $(NGINX_HOME)/cache ] ; then mkdir $(NGINX_HOME)/cache ;fi    
	@cp -f -v includes/nginx-config/* /usr/local/nginx/conf 
	$(call  nginxConfig, $@)
	@$(if $(shell echo "$$($(NGINX_HOME)/sbin/nginx -t -q)"),\
$(NGINX_HOME)/sbin/nginx -t,\
echo "nginx config ok" > $(dir $@)nginx-tested.log)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) -R $(dir $<),)
	@$(if $(SUDO_USER),chown $(SUDO_USER) -R $(NGINX_HOME),)
	@echo '-----------------------------------------------------------------}}}'


$(TEMP_DIR)/nginx-run.sh: $(TEMP_DIR)/nginx-tested.log
	@echo "{{{ $(notdir $@) "
	@echo " $(notdir $@) will start ngnix on travis"
	@echo '#!/usr/bin/env bash' > $(@)
	@echo 'cd $(NGINX_HOME)/sbin' >> $(@)
	@echo './nginx &' >> $(@)
	@echo 'while [[ -z "$$(curl -I -s -f 'http://127.0.0.1:80/')" ]] ; do sleep 5 ; done' >> $(@)
	@chmod +x $(@)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo '-----------------------------------------------------------------}}}'

$(TEMP_DIR)/nginx.conf:
	@echo "{{{ $(notdir $@) "
	$(call  nginxConfig, $@)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@cp -f $@ $(NGINX_HOME)/conf/nginx.conf
	@cp -f nginx-config/*  $(NGINX_HOME)/conf
	@$(if $(shell echo "$$($(NGINX_HOME)/sbin/nginx -t -q)"),\
$(NGINX_HOME)/sbin/nginx -t,\
mv $@ $(dir $@)$(addprefix tested-,$(notdir $@)) && \
echo "nginx config ok" > $(dir $@)nginx-tested.log && \
$(NGINX_HOME)/sbin/nginx -s reload )
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(dir $@)nginx-tested.log,)
	@echo '}}}'


$(TEMP_DIR)/min-nginx.conf:
	@echo "{{{ $(notdir $@) "
	$(call  nginxMinConfig, $@)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@cp -f $@ $(NGINX_HOME)/conf
	@mv -f $(NGINX_HOME)/conf/$(notdir $@) $(NGINX_HOME)/conf/nginx.conf   
	@$(if $(shell echo "$$($(NGINX_HOME)/sbin/nginx -t -q)"),\
$(NGINX_HOME)/sbin/nginx -t,\
mv $@ $(dir $@)$(addprefix tested-,$(notdir $@)) && \
echo "nginx config ok" > $(dir $@)nginx-tested.log && \
$(NGINX_HOME)/sbin/nginx -s reload )
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(dir $@)nginx-tested.log,)
	@cat  $(NGINX_HOME)/conf/nginx.conf 
	@echo '}}}'

$(TEMP_DIR)/nginx.service:
	@echo "{{{ $(notdir $@) "
	$(if $(shell ps -p1 | grep systemd ),\
 $(info  OK init system is systemd),\
 $(error init system is not systemd) )
	@$(call assert-is-root)
	$(call  nginxService, $@)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@cp -f $@ /lib/systemd/system/$(notdir $@)
	@systemd-analyze verify $(notdir $@)
	@systemctl enable  $(notdir $@)
	@systemctl start  $(notdir $@)
	@echo '}}}'
