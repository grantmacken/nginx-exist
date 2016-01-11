NGINX_VERSION_SOURCE := http://nginx.org
NGINX_DOWNLOAD := http://nginx.org/download
PCRE_DOWNLOAD := ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre
ZLIB_DOWNLOAD := http://zlib.net
OPENSSL_DOWNLOAD := http://www.openssl.org/source
NGINX_VERSION := $(TEMP_DIR)/nginx-latest.version
NGINX_VERSION_OPTION := mainline

chkWhichNginx := $(shell which nginx)
installedNginxVersion := $(if $(chkWhichNginx),\
$(shell  $(chkWhichNginx) -v 2>&1 | grep -oP '\K[0-9]+\.[0-9]+\.[0-9_]+' ),)
$(info install nginx version - $(installedNginxVersion))

getSRCVAR = $(shell echo '$1_ver' | tr 'a-z' 'A-Z')
getVERSION = $(addsuffix .tar.gz,$(addprefix $2-,$(shell source $1 && echo $$$(call getSRCVAR,$2))))

nginx:  $(TEMP_DIR)/nginx-run.sh

$(NGINX_VERSION):
	@echo "{{{ $(notdir $@) "
	@if [ -d $(dir $@) ] ;then echo 'temp dir exists';else mkdir $(dir $@) ;fi
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $dir (@),)
	@echo 'fetch the latest nginx version'
	@echo NGINX_VER=$$( curl -s -L  $(NGINX_VERSION_SOURCE) | tr -d '\n\r' |\
 grep -oP 'nginx-\K([0-9]+\.[0-9]+\.[0-9]+)(?=....$(NGINX_VERSION_OPTION))' |\
 head -1) > $(@)
	@echo 'fetch the latest pcre version'
	@echo PCRE_VER=$$( \
 curl -s 'ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/' | \
 grep -oP "pcre-\K[0-9]+\.[0-9]+(?=\.tar\.gz)" | \
 tail -1  ) >> $(@)
	@echo 'fetch the latest zlib version'
	@echo ZLIB_VER=$$( \
  curl -s 'http://zlib.net' | \
  grep -oP 'zlib \K[0-9]+\.[0-9]+\.[0-9]+' | \
  head -1 ) >> $(@)
	@echo 'fetch the latest opnssl version'
	@echo OPENSSL_VER=$$( \
 curl -s 'https://www.openssl.org/source/' |  \
 grep -oP '>openssl-\K[0-9a-z\.]+(?=\.tar\.gz)' |  \
 tail -1 ) >> $(@)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo '-----------------------------------------------------------------}}}'

$(TEMP_DIR)/curl-nginx.log: $(NGINX_VERSION)
	@echo "{{{ $(notdir $@) "
	@echo "$(call getVERSION,$<,nginx)"
	@curl $(NGINX_DOWNLOAD)/$(call getVERSION,$<,nginx) |  \
 tar xz --directory $(dir $@) && \
 echo  'downloaded and unzipped $(call getVERSION,$<,nginx)' >  $(@) &&  \
 curl $(ZLIB_DOWNLOAD)/$(call getVERSION,$<,zlib) | \
 tar xz --directory $(dir $@) && \
 echo  'downloaded and unzipped $(call getVERSION,$<,zlib)' >>  $(@) &&  \
 curl $(PCRE_DOWNLOAD)/$(call getVERSION,$<,pcre) | \
 tar xz --directory $(dir $@) && \
 echo  'downloaded and unzipped $(call getVERSION,$<,pcre)' >>  $(@) &&  \
 curl $(OPENSSL_DOWNLOAD)/$(call getVERSION,$<,openssl) | \
 tar xz --directory $(dir $@) && \
 echo  'downloaded and unzipped $(call getVERSION,$<,openssl)' >>  $(@)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo '-----------------------------------------------------------------}}}'

$(NGINX_HOME)/sbin/nginx: $(TEMP_DIR)/curl-nginx.log
	@echo "{{{ $(notdir $@) "
	source $(NGINX_VERSION); cd $(dir $(@))/nginx-$${NGINX_VER} ;\
 ./configure   --with-select_module  \
 --with-pcre="../pcre-$${PCRE_VER}" \
 --with-zlib="../zlib-$${ZLIB_VER}" \
 --with-http_gzip_static_module && make && make install 
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo '-----------------------------------------------------------------}}}'

$(TEMP_DIR)/nginx_ssl_install.log: $(TEMP_DIR)/curl-nginx.log
	@echo "{{{ $(notdir $@) "
	source $(NGINX_VERSION); cd $(dir $(@))/nginx-$${NGINX_VER} ;\
 ./configure   --with-select_module  \
 --with-pcre="../pcre-$${PCRE_VER}" \
 --with-http_ssl_module \
 --with-openssl="../openssl-$${OPENSSL_VER}" \
 --with-zlib="../zlib-$${ZLIB_VER}" \
 --with-http_gzip_static_module && make && make install
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo '-----------------------------------------------------------------}}}'

$(TEMP_DIR)/nginx-run.sh: $(NGINX_HOME)/sbin/nginx
	@echo "{{{ $(notdir $@) "
	@echo '#!/usr/bin/env bash' > $(@)
	@echo 'cd $(NGINX_HOME)/sbin' >> $(@)
	@echo './nginx &' >> $(@)
	@echo 'while [[ -z "$$(curl -I -s -f 'http://127.0.0.1:80/')" ]] ; do sleep 5 ; done' >> $(@)
	@chmod +x $(@)
	@$(if $(SUDO_USER),chown $(SUDO_USER)$(:)$(SUDO_USER) $(@),)
	@echo '-----------------------------------------------------------------}}}'
