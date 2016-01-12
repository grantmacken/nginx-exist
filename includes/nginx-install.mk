NGINX_VERSION_SOURCE := http://nginx.org
NGINX_DOWNLOAD := http://nginx.org/download
PCRE_DOWNLOAD := ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre
ZLIB_DOWNLOAD := http://zlib.net
OPENSSL_DOWNLOAD := http://www.openssl.org/source
NGINX_VERSION := $(TEMP_DIR)/nginx-latest.version
NGINX_VERSION_OPTION := mainline
NGINX_CONFIG := $(NGINX_HOME)/conf/nginx.conf

chkWhichNginx := $(shell which nginx)
installedNginxVersion := $(if $(chkWhichNginx),\
$(shell  $(chkWhichNginx) -v 2>&1 | grep -oP '\K[0-9]+\.[0-9]+\.[0-9_]+' ),)
$(info install nginx version - $(installedNginxVersion))
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
	@echo '  default_type application/octet-stream;' >> $1
	@echo '  sendfile on;' >> $1
	@echo '  keepalive_timeout 65;' >> $1
	@echo '  server {' >> $1
	@echo '    listen 80 default deferred;' >> $1
	@echo '    server_name ~^(www\.)?(?<domain>.+)$$;' >> $1
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
	$(call  nginxConfig, $@)
	@$(if $(shell echo "$$($(NGINX_HOME)/sbin/nginx -t -q)"),\
$(NGINX_HOME)/sbin/nginx -t,\
echo "nginx config ok" > $(dir $@)nginx-tested.log)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) -R $(dir $<),)
	@$(if $(SUDO_USER),chown $(SUDO_USER) -R $(NGINX_HOME),)
	@echo '-----------------------------------------------------------------}}}'

# @cp -f -v nginx-config/common/* $(NGINX_HOME)/conf
# @cp -f -v nginx-config/prod/* $(NGINX_HOME)/conf
# @mv -f -v $(NGINX_HOME)/conf/nginx-prod.conf $(NGINX_HOME)/conf/nginx.conf
# $(TEMP_DIR)/nginx_ssl_install.log: $(TEMP_DIR)/curl-nginx.log
# @echo 'fetch the latest opnssl version'
# @echo OPENSSL_VER=$$( \
# curl -s 'https://www.openssl.org/source/' |  \
# grep -oP '>openssl-\K[0-9a-z\.]+(?=\.tar\.gz)' |  \
# tail -1 ) >> $(@)
 # curl $(OPENSSL_DOWNLOAD)/$(call getVERSION,$<,openssl) | \
 # tar xz --directory $(dir $@)
 # echo "$(PCRE_DOWNLOAD)/$(call getVERSION,$<,pcre)" && \
 # curl $(OPENSSL_DOWNLOAD)/$(call getVERSION,$<,openssl) | \
 # tar xz --directory $(dir $@)
# @echo "{{{ $(notdir $@) "
# source $(NGINX_VERSION); cd $(dir $(@))/nginx-$${NGINX_VER} ;\
# ./configure   --with-select_module  \
# --with-pcre="../pcre-$${PCRE_VER}" \
# --with-http_ssl_module \
# --with-openssl="../openssl-$${OPENSSL_VER}" \
# --with-zlib="../zlib-$${ZLIB_VER}" \
# --with-http_gzip_static_module && make && make install
# @$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
# @echo '-----------------------------------------------------------------}}}'

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
	@$(if $(shell echo "$$($(NGINX_HOME)/sbin/nginx -t -q)"),\
$(NGINX_HOME)/sbin/nginx -t,\
mv $@ $(dir $@)$(addprefix tested-,$(notdir $@)) && \
echo "nginx config ok" > $(dir $@)nginx-tested.log && \
$(NGINX_HOME)/sbin/nginx -s reload )
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(dir $@)nginx-tested.log,)
	@echo '-----------------------------------------------------------------}}}'
