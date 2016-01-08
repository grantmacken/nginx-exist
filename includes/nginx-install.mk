NGINX_VERSION_SOURCE := http://nginx.org
NGINX_DOWNLOAD := http://nginx.org/download
NGINX_VERSION := $(TEMP_DIR)/nginx-latest.version
NGINX_VERSION_OPTION := mainline
PCRE := pcre

chkWhichNginx := $(shell which nginx)
installedNginxVersion := $(if $(chkWhichNginx),\
$(shell  $(chkWhichNginx) -v 2>&1 | grep -oP '\K[0-9]+\.[0-9]+\.[0-9_]+' ),)
$(info install nginx version - $(installedNginxVersion))

nginx:  $(NGINX_VERSION)

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
	@echo '-----------------------------------------------------------------}}}'
