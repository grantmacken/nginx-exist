NGINX_VERSION_SOURCE := http://nginx.org
NGINX_DOWNLOAD := http://nginx.org/download
PCRE_DOWNLOAD := ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre
ZLIB_DOWNLOAD := http://zlib.net
OPENSSL_DOWNLOAD := http://www.openssl.org/source
NGINX_VERSION := $(T)/nginx-latest.version
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
worker_processes $(shell grep ^proces /proc/cpuinfo | wc -l );

events {
  worker_connections  1024;
}

http {
  include mime.types;
  include gzip.conf;
  ########################################
  # proxy-common
  # http://wiki.nginx.org/HttpProxyModule
  #######################################
  proxy_redirect off;
  proxy_set_header  Host              $$host;
  proxy_set_header  X-Real-IP         $$remote_addr;
  proxy_set_header  X-Forwarded-For   $$proxy_add_x_forwarded_for;
  proxy_set_header  nginx-request-uri $$request_uri;
  # no jetty cookies
  proxy_set_header Cookie "";
  proxy_hide_header Set-Cookie;
  client_max_body_size 10m;
  client_body_buffer_size 128k;
  # increase timeout
  proxy_connect_timeout 300;
  proxy_send_timeout 120;
  proxy_read_timeout 120;
  # increase proxy memory buffer for faster responses:
  proxy_buffers               4 32k;
  proxy_busy_buffers_size     32k;
  proxy_temp_file_write_size  32k;
  # end proxy defaults
  # set proxy_cache_path here but enable with include proxy-cache.conf on location basis
  proxy_cache_path  /usr/local/nginx/cache  levels=1:2   keys_zone=muCache:8m inactive=600m  max_size=1000m;
  proxy_temp_path /usr/local/nginx/proxy;
  proxy_cache_key "$$scheme$$request_method$$host$$request_uri";
  # end proxy path cache
  default_type application/octet-stream;
  sendfile on;
  keepalive_timeout 65;
  server {
    listen 80 default deferred;
    charset utf-8;
    server_name ~^(www\.)?(?<domain>.+)$$;
    root  $(EXIST_HOME)/$(EXIST_DATA_DIR)/fs/db/apps/$$domain;
    include server-rewrites.conf;
    include server-locations.conf;
  }
}
endef

$(NGINX_VERSION): config
	@echo "{{{ $(notdir $@) "
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
	@$(call chownToUser,$(@))
	@echo '}}}'

$(T)/nginx-tested.log: $(NGINX_VERSION)
	@echo "{{{ $(notdir $@) "
	@echo "$(NGINX_DOWNLOAD)/$(call getVERSION,$<,nginx)" && \
 curl $(NGINX_DOWNLOAD)/$(call getVERSION,$<,nginx) |  \
 tar xz --directory $(dir $<) && \
 echo "$(PCRE_DOWNLOAD)/$(call getVERSION,$<,pcre)" && \
 curl $(PCRE_DOWNLOAD)/$(call getVERSION,$<,pcre) | \
 tar xz --directory $(dir $<)
	@source $(NGINX_VERSION); cd $(dir $(<))/nginx-$${NGINX_VER} ;\
 ./configure   --with-select_module  \
 --with-pcre="../pcre-$${PCRE_VER}" \
 --with-http_gzip_static_module && make && make install 
	@source $(NGINX_VERSION); cd $(dir $(<))/nginx-$${NGINX_VER} && $(MAKE)
	@source $(NGINX_VERSION); cd $(dir $(<))/nginx-$${NGINX_VER} && $(MAKE) install
	@$(if $(SUDO_USER),chown $(SUDO_USER) -R $(NGINX_HOME),)
	@$(if $(SUDO_USER),chown $(SUDO_USER) -R $(T),)
	@$(MAKE) nginx-config
	@echo '}}}'


$(T)/nginx-run.sh: $(T)/nginx-tested.log
	@echo "{{{ $(notdir $@) "
	@echo " $(notdir $@) will start ngnix on travis"
	@echo '#!/usr/bin/env bash' > $(@)
	@echo 'cd $(NGINX_HOME)/sbin' >> $(@)
	@echo './nginx &' >> $(@)
	@chmod +x $(@)
	@$(call chownToUser,$(@))
	@echo '-----------------------------------------------------------------}}}'

nginx-config: export nginxConfig:=$(nginxConfig)
nginx-config:
	@echo "$(NGINX_CONFIG)"
	@[ -d $(NGINX_HOME)/proxy ] || mkdir $(NGINX_HOME)/proxy
	@[ -d $(NGINX_HOME)/cache ] || mkdir $(NGINX_HOME)/cache
	@cp -f nginx-config/*  $(NGINX_HOME)/conf
	@echo "$${nginxConfig}" > $(NGINX_CONFIG)
	@$(NGINX_HOME)/sbin/nginx -t 
	@ps -lfC nginx | grep master && $(NGINX_HOME)/sbin/nginx -s reload 
	echo "$$($(NGINX_HOME)/sbin/nginx -t -q)"


# @$(call chownToUser,$@)
# @cp -f $@ $(NGINX_HOME)/conf/
# @$(NGINX_HOME)/sbin/nginx -t 
# @$(if $(shell echo "$$($(NGINX_HOME)/sbin/nginx -t -q)"),\
# $(NGINX_HOME)/sbin/nginx -t,\
# mv $@ $(dir $@)$(addprefix tested-,$(notdir $@)) && \
# echo "nginx config ok" > $(dir $@)nginx-tested.log)
# @$(if "$(ps -lfC nginx | grep nginx)",,$(NGINX_HOME)/sbin/nginx -s reload )
# @$(call chownToUser,$(dir $@)nginx-tested.log)

define nginxService
[Unit]

Description=The openresty nginx HTTP and reverse proxy server
After=network.target

[Service]
PIDFile=$(NGINX_HOME)/logs/nginx.pid
ExecStart=$(NGINX_HOME)/sbin/nginx
ExecReload=/bin/kill -s HUP $$MAINPID
ExecStop=/bin/kill -s QUIT $$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
endef

/lib/systemd/system/nginx.service: export nginxService:=$(nginxService)
/lib/systemd/system/nginx.service:
	@echo "$(notdir $@)"
	@$(call assert-is-root)
	@$(call assert-is-systemd)
	@echo "$${nginxService}" > $@
	@systemd-analyze verify $(notdir $@)
	@systemctl enable  $(notdir $@)
	@systemctl start  $(notdir $@)
	@echo '--------------------------------------------------------------'



# @echo "$${nginxConfig}" > $@
# @$(call chownToUser,$@)
# @cp -f $@ $(NGINX_HOME)/conf/nginx.conf
# @cp -f nginx-config/*  $(NGINX_HOME)/conf
# @$(if $(shell echo "$$($(NGINX_HOME)/sbin/nginx -t -q)"),\
# $(NGINX_HOME)/sbin/nginx -t,\
# mv $@ $(dir $@)$(addprefix tested-,$(notdir $@)) && \
# echo "nginx config ok" > $(dir $@)nginx-tested.log && \
# $(NGINX_HOME)/sbin/nginx -s reload )
# 	@$(call chownToUser,$(dir $@)nginx-tested.log)
