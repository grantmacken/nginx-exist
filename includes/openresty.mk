# apt install libreadline-dev libncurses5-dev libpcre3-dev \
#     libssl-dev perl make build-essential

OPENRESTY_VERSION_SOURCE := https://openresty.org/en/download.html
OPENSSL_DOWNLOAD := http://www.openssl.org/source

orLatest: $(T)/openresty-latest.version
opensslLatest: $(T)/openssl-latest.version
pcreLatest: $(T)/pcre-latest.version
zlibLatest: $(T)/zlib-latest.version
luarocksLatest: $(T)/luarocks-latest.version
luaLatest: $(T)/lua-latest.version

orVer != [ -e $(T)/openresty-latest.version ] && cat $(T)/openresty-latest.version || echo ''
pcreVer != [ -e $(T)/pcre-latest.version ] && cat $(T)/pcre-latest.version || echo ''
zlibVer != [ -e $(T)/zlib-latest.version ] && cat $(T)/zlib-latest.version || echo ''
opensslVer != [ -e $(T)/openssl-latest.version ] && cat $(T)/openssl-latest.version || echo ''
luarocksVer != [ -e $(T)/luarocks-latest.version ] && cat $(T)/luarocks-latest.version || echo ''


.PHONY: orInstall luarocksInstall ngReload \
 downloadOpenresty downloadOpenssl downloadPcre downloadZlib downloadRedis\
 orLE openrestyService orSimpleConf orConf orGenSelfSigned certbotConf

$(T)/openresty-latest.version: config
	@echo " $(notdir $@) "
	@echo 'fetch the latest openresty version'
	@echo $$( curl -s -L https://openresty.org/en/download.html |\
 tr -d '\n\r' |\
 grep -oP 'openresty-\K([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' |\
 head -1) > $(@)
	@echo  "$$(<$@)" 
	@echo '------------------------------------------------'

downloadOpenresty: $(T)/openresty-latest.version
	@echo https://openresty.org/download/openresty-$(orVer).tar.gz
	@curl -L https://openresty.org/download/openresty-$(orVer).tar.gz | \
 tar xz --directory $(T)
	@echo '------------------------------------------------'

# curl $https://openresty.org/download/openresty-$(shell echo  "$$(<$@)" ).tar.gz | \
#  tar xz --directory $(T)

orInstall: $(T)/openresty-latest.version 
	@echo "configure and install openresty $$(<$(<))"
	@echo "$(pcreVer)"
	@echo "$(zlibVer)"
	@echo "$(opensslVer)"
	@cd $(T)/openresty-$$(<$(<));\
 ./configure \
 --with-select_module \
 --with-pcre="../pcre-$(pcreVer)" \
 --with-pcre-jit \
 --with-zlib="../zlib-$(zlibVer)" \
 --with-openssl="../openssl-OpenSSL_$(opensslVer)" \
 --with-http_ssl_module \
 --with-ipv6 \
 --with-http_v2_module \
 --with-file-aio \
 --with-http_realip_module \
 --with-http_gzip_static_module \
 --without-http_redis_module \
 --without-http_redis2_module \
 --without-http_uwsgi_module \
 --without-http_fastcgi_module \
 --without-http_scgi_module \
 --without-lua_resty_mysql && make && make install

 # --with-http_stub_status_module \
 # --with-http_secure_link_module 

# https://github.com/openssl/openssl/archive/
# OpenSSL_1_0_2h.tar.gz

$(T)/openssl-latest.version: config
	@echo " $(notdir $@) "
	@echo 'fetch the latest opensll version'
	@echo $$( curl -s -L https://github.com/openssl/openssl/releases | \
 tr -d '\n\r' | \
 grep -oP 'OpenSSL_\K(\d_\d_[2-9]{1}[a-z]{1})(?=\.tar\.gz)' |\
 head -1) > $(@)
	@echo '$(opensslVer)'
	@echo '------------------------------------------------'

# curl https://www.openssl.org/source/openssl-$(shell echo "$$(<$@)").tar.gz | \
 # tar xz --directory $(T)
# @$(call chownToUser,$(@))
# @echo  "$$(<$@)" 

downloadOpenssl: $(T)/openssl-latest.version
	@echo  "$$(<$(<))" 
	@echo https://github.com/openssl/openssl/archive/OpenSSL_$(opensslVer).tar.gz 
	@curl -L https://github.com/openssl/openssl/archive/OpenSSL_$(opensslVer).tar.gz | \
 tar xz --directory $(T)
	@echo '------------------------------------------------'

# @curl https://github.com/openssl/openssl/archive/openssl_$(opensslver).tar.gz | \
#  tar xz --directory $(t)

$(T)/pcre-latest.version: config
	@echo "$(notdir $@) "
	@echo 'fetch the latest pcre version'
	@echo $$( curl -s -L ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/ | tr -d '\n\r' |\
 grep -oP 'pcre-\K([0-9\.]+)(?=\.tar\.gz)' |\
 head -1) > $(@)
	@echo  "$$(<$@)" 
	@echo '------------------------------------------------'

downloadPcre: $(T)/pcre-latest.version
	@echo 'download the latest pcre  version'
	@echo  "$$(<$(<))" 
	curl ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$(shell echo "$$(<$(<))").tar.gz | \
 tar xz --directory $(T)
	@echo '------------------------------------------------'


$(T)/zlib-latest.version: config
	@echo " $(notdir $@) "
	@echo 'fetch the latest zlib  version'
	@echo 'http://zlib.net/'
	@echo $$( curl -s -L http://zlib.net/ | tr -d '\n\r' |\
 grep -oP 'zlib-\K([0-9\.]+)(?=\.tar\.gz)' |\
 head -1) > $(@)
	@echo  "$$(<$@)" 
	@echo '------------------------------------------------'

downloadZlib: $(T)/zlib-latest.version
	@echo 'download the latest  version'
	@echo  "$$(<$(<))" 
	curl http://zlib.net/zlib-$(shell echo "$$(<$(<))").tar.gz | \
 tar xz --directory $(T)
	@echo '------------------------------------------------'


$(T)/luarocks-latest.version: config
	@echo "{{{ $(notdir $@) "
	@echo 'fetch the latest luarocks version'
	@echo $$( curl -s -L  http://keplerproject.github.io/luarocks/releases/ | tr -d '\n\r' |\
 grep -oP 'luarocks-\K([0-9\.]+)(?=\.tar\.gz)' |\
 head -1) > $(@)
	curl  http://keplerproject.github.io/luarocks/releases/luarocks-$(shell echo "$$(<$@)").tar.gz | \
 tar xz --directory $(T)
	@$(call chownToUser,$(@))
	@echo  "$$(<$@)" 
	@echo '------------------------------------------------'

luarocksInstall:
	@echo 'install luarocks version'
	@echo $(luarocksVer)
	@cd $(T)/luarocks-$(luarocksVer) && \
 ./configure \
 --prefix=$(OPENRESTY_HOME)/luajit \
 --with-lua=$(OPENRESTY_HOME)/luajit \
 --lua-suffix=jit-2.1.0-beta2 \
 --with-lua-include=$(OPENRESTY_HOME)/luajit/include/luajit-2.1 && make && make install
	@export PATH=$(OPENRESTY_HOME)/luajit/bin:$$PATH
	@cd $(OPENRESTY_HOME)/luajit/bin; ln -s luajit lua
	@echo '--------------------------------------------'

downloadRedis:
	@echo 'download the stable redis version'
	curl http://download.redis.io/redis-stable.tar.gz | \
 tar xz --directory $(T)
	cd $(T)/redis-stable; $(MAKE) && $(MAKE) test && $(MAKE) install
	@echo '------------------------------------------------'



define ngConf
worker_processes $(shell grep ^proces /proc/cpuinfo | wc -l );
error_log logs/error.log;

events {
  worker_connections  1024;
}

http {
  include mime.types;
  default_type application/octet-stream;

  # The "auto_ssl" shared dict should be defined with enough storage space to
  # hold your certificate data. 1MB of storage holds certificates for
  # approximately 100 separate domains.
  lua_shared_dict auto_ssl 1m;

  # A DNS resolver must be defined for OCSP stapling to function.
  resolver 8.8.8.8;
  # Initial setup tasks.
  # init_by_lua_block {
  #   local rocks = require "luarocks.loader"
  #   auto_ssl = (require "resty.auto-ssl").new()

  #   -- Define a function to determine which SNI domains to automatically handle
  #   -- and register new certificates for. Defaults to not allowing any domains,
  #   -- so this must be configured.
  #   auto_ssl:set("allow_domain", function(domain)
  #     return true
  #   end)

  #   auto_ssl:init()
  # }

  # init_worker_by_lua_block {
  #   auto_ssl:init_worker()
  # }

  access_log off;

  # HTTPS server 
  server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    # certs sent to the client in SERVER HELLO are concatenated in ssl_certificate

    # Dynamic handler for issuing or returning certs for SNI domains.
     # ssl_certificate_by_lua_block {
     # auto_ssl:ssl_certificate()
     # }

    # You must still define a static ssl_certificate file for nginx to start.
    # certs sent to the client in SERVER HELLO are concatenated in ssl_certificat
    # ssl_certificate     /etc/ssl/resty-auto-ssl-fallback.crt;
    # ssl_certificate_key /etc/ssl/resty-auto-ssl-fallback.key;

    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    # Diffie-Hellman parameter for DHE ciphersuites, recommended 2048 bits
     # ssl_dhparam /path/to/dhparam.pem;
    # modern configuration. tweak to your needs.
    ssl_protocols TLSv1.2;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
    ssl_prefer_server_ciphers on;

    # HSTS (ngx_http_headers_module is required) (15768000 seconds = 6 months)
    # add_header Strict-Transport-Security max-age=15768000;

    # OCSP Stapling ---
    # fetch OCSP records from URL in ssl_certificate and cache them
    # ssl_stapling on;
    # ssl_stapling_verify on;

    ## verify chain of trust of OCSP response using Root CA and Intermediate certs
    # ssl_trusted_certificate /path/to/root_CA_cert_plus_intermediates;

    location / {
      default_type text/html;
      content_by_lua '
      ngx.say("<p>hello, world</p>")
      ';
      } 
   }

   # HTTP server
   server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name gmack.nz example.com;

    # Endpoint used for performing domain verification with Let's Encrypt.
    location /.well-known/acme-challenge/ {
       default_type "text/plain";
       root /tmp/letsencrypt;
       # content_by_lua_block {
       #   auto_ssl:challenge_server()
       # }
    }

    # Redirect all HTTP requests to HTTPS with a 301 Moved Permanently response.
    location / {
      return 301 https://$http_host$request_uri;
    }

   }

  # Internal server running on port 8999 for handling certificate tasks.
  # server {
  #   listen 127.0.0.1:8999;
  #   location / {
  #     content_by_lua_block {
  #       auto_ssl:hook_server()
  #     }
  #   }
  # }
}
endef

define orTestConf
location / {
  content_by_lua_block {
    require("handler")()
  }
}
endef


define luaTest
-- lua/test.lua
ngx.say("<p>Hello world from a lua file</p>");
endef


define luaFoo
-- conf/foo.lua

module("foo", package.seeall)

local bar = require "bar"

ngx.say("bar loaded")

function say (var)
    bar.say(var)
end
endef

define luaBar
-- conf/bar.lua

module("bar", package.seeall)

local rocks = require "luarocks.loader"
local md5 = require "md5"

ngx.say("rocks and md5 loaded")

function say (a)
    ngx.say(md5.sumhexa(a))
end
endef

orLuaBar: export luaBar:=$(luaBar)
orLuaBar:
	@find $(NGINX_HOME)/conf -type f -name 'bar.lua' -delete
	@echo "$${luaBar}" > $(NGINX_HOME)/conf/bar.lua

orLuaFoo: export luaFoo:=$(luaFoo)
orLuaFoo:
	@find $(NGINX_HOME)/conf -type f -name 'foo.lua' -delete
	@echo "$${luaFoo}" > $(NGINX_HOME)/conf/foo.lua

orLuaTest: export luaTest:=$(luaTest)
orLuaTest:
	@find $(NGINX_HOME)/lua -type f -name 'test.lua' -delete
	@echo "$${luaTest}" > $(NGINX_HOME)/lua/test.lua

#################################
#
# simple is the conf to setup letsencrypt
#
#################################

define orLetsEncryptConf
location /.well-known/acme-challenge {
   default_type "text/plain";
   alias        /opt/letsencrypt.sh/.acme-challenges;
}
endef

orLE: export orLetsEncryptConf:=$(ngSimporSimpleConf)
orLE:
	@echo "$${orLetsEncryptConf}" > $(NGINX_HOME)/conf/letsencrypt.conf
	@[ -d /opt/letsencrypt.sh ] || \
 cd /opt/letsencrypt.sh; git clone https://github.com/lukas2511/letsencrypt.sh
	@cd /opt/letsencrypt.sh && cp docs/examples/config config
	@cat /opt/letsencrypt.sh/ && cp config


define ngSimpleConf

worker_processes $(shell grep ^proces /proc/cpuinfo | wc -l );
error_log logs/error.log;
pid       logs/nginx.pid;

events {
  worker_connections  1024;
}

http {
  include mime.types;
  access_log off;

  server {
    listen 0.0.0.0:80 default_server;
    listen    [::]:80 default_server ipv6only=on;

    server_name ~^(www\.)?(?<domain>.+)$$;

    location / {
        return 301 https://$$host$$request_uri;
    }

   include letsencrypt.conf;

  }
}
endef


orSimpleConf: export ngSimpleConf:=$(ngSimpleConf)
orSimpleConf:
	@[ -d $(NGINX_HOME)/proxy ] || mkdir $(NGINX_HOME)/proxy
	@[ -d $(NGINX_HOME)/cache ] || mkdir $(NGINX_HOME)/cache
	@[ -d $(NGINX_HOME)/lua ] || mkdir $(NGINX_HOME)/lua
	@[ -d /etc/letsencrypt ] || mkdir /etc/letsencrypt
	@[ -d /tmp/letsencrypt ] || mkdir /tmp/letsencrypt
	@echo 'create a 4096-bits Diffie-Hellman parameter file that nginx can use'
	@[ -d $(NGINX_HOME)/ssl ] || mkdir $(NGINX_HOME)/ssl
	[  -e $(NGINX_HOME)//ssl/dh-param.pem ] || \
 openssl dhparam -out $(NGINX_HOME)//ssl/dh-param.pem 4096
	@echo 'clean out the nginx dir'
	@find $(NGINX_HOME)/conf -type f -name 'fast*' -delete
	@find $(NGINX_HOME)/conf -type f -name 'scgi*' -delete
	@find $(NGINX_HOME)/conf -type f -name 'uwsgi*' -delete
	@find $(NGINX_HOME)/conf -type f -name '*.default' -delete
	@find $(NGINX_HOME)/logs -type f -name 'error.log' -delete
	@find $(NGINX_HOME)/logs -type f -name 'koi-*' -delete
	@find $(NGINX_HOME)/logs -type f -name 'win-*' -delete
	@find $(NGINX_HOME)/conf -type f -name 'nginx.conf' -delete
	@echo "$${ngSimpleConf}" > $(NGINX_HOME)/conf/nginx.conf

orReload:
	@$(OPENRESTY_HOME)/bin/openresty -t
	@$(OPENRESTY_HOME)/bin/openresty -s reload

orConf: export ngConf:=$(ngConf)
orConf:
	@[ -d $(NGINX_HOME)/proxy ] || mkdir $(NGINX_HOME)/proxy
	@[ -d $(NGINX_HOME)/cache ] || mkdir $(NGINX_HOME)/cache
	@[ -d $(NGINX_HOME)/lua ] || mkdir $(NGINX_HOME)/lua
	@[ -d $(NGINX_HOME)/ssl ] || mkdir $(NGINX_HOME)/ssl
	@find $(NGINX_HOME)/conf -type f -name 'fast*' -delete
	@find $(NGINX_HOME)/conf -type f -name 'scgi*' -delete
	@find $(NGINX_HOME)/conf -type f -name 'uwsgi*' -delete
	@find $(NGINX_HOME)/conf -type f -name '*.default' -delete
	@find $(NGINX_HOME)/conf -type f -name 'nginx.conf' -delete
	@find $(NGINX_HOME)/logs -type f -name 'error.log' -delete
	@echo "$${ngConf}" > $(NGINX_HOME)/conf/nginx.conf


#########################################################
# 
# SSL CONFIGERATION note  
#
# can not be done on local dev server 
#
# use cerbot-auto with configuration file
#
#
#
#
#########################################################
define certbotConfig

# https://certbot.eff.org/docs/using.html#command-line
# This is an example of the kind of things you can do in a configuration file.
# All flags used by the client can be configured here. Run Certbot with
# "--help" to learn more about the available options.

# Use a 4096 bit RSA key instead of 2048
rsa-key-size = 4096

# Uncomment and update to register with the specified e-mail address
email = grantmacken@gmail.com

# Uncomment and update to generate certificates for the specified
# domains.
domains = gmack.nz, www.gmack.nz

# Uncomment to use a text interface instead of ncurses
text = True

# Uncomment to use the standalone authenticator on port 443
# authenticator = standalone
# standalone-supported-challenges = tls-sni-01

# Uncomment to use the webroot authenticator. Replace webroot-path with the
# path to the public_html / webroot folder being served by your web server.
authenticator = webroot
webroot-path = $(NGINX_HOME)/html/

agree-tos = true

endef

certbotConf: export certbotConfig:=$(certbotConfig)
certbotConf:
	@echo "if they don't exist create dirs"
	@[ -d $(T)/certbot ] || mkdir $(T)/certbot
	@[ -d /etc/letsencrypt ] || mkdir /etc/letsencrypt
	@[ -d /tmp/letsencrypt ] || mkdir /tmp/letsencrypt
	@echo "create cli config file"
	@echo "$${certbotConfig}" > /etc/letsencrypt/cli.ini
	@[ -d $(T)/certbot/certbot-auto ] || curl https://dl.eff.org/certbot-auto -o $(T)/certbot/certbot-auto 
	@$(call chownToUser,$(T)/certbot/certbot-auto)
	@chmod +x $(T)/certbot/certbot-auto
	@$(T)/certbot/certbot-auto --help



# @[ -e $(T)/certbot/cerbot-auto ] || \
 # { cd $(T)/certbot; wget https://dl.eff.org/certbot-auto; chmod a+x ./certbot-auto }
# @cd $(T)/certbot; ./certbot-auto --help
# @cd $(T)/certbot; ./certbot-auto certonly --config cli.ini

# https://github.com/GUI/lua-resty-auto-ssl
# openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
#   -subj '/CN=sni-support-required-for-valid-ssl' \
#   -keyout /etc/ssl/resty-auto-ssl-fallback.key \
#   -out /etc/ssl/resty-auto-ssl-fallback.crt

orGenSelfSigned:
	@[ -d /etc/resty-auto-ssl ] || mkdir /etc/resty-auto-ssl

# @openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
 # -subj '/CN=sni-support-required-for-valid-ssl' \
 # -keyout /etc/ssl/resty-auto-ssl-fallback.key \
 # -out /etc/ssl/resty-auto-ssl-fallback.crt
#   sudo apt-get install letsencrypt
#  letsencrypt certonly --webroot -w /var/www/example -d example.com -d www.example.com -w /var/www/thing -d thing.is -d m.thing.is
testConf: export orTestConf:=$(orTestConf)
testConf:
	@find $(NGINX_HOME)/conf -type f -name 'test.conf' -delete
	@echo "$${orTestConf}" > $(NGINX_HOME)/conf/test.conf


nginx-openresty-config: export nginxConfig:=$(nginxConfig)
nginx-open-resty-config:
	@echo "$(NGINX_CONFIG)"
	@[ -d $(NGINX_HOME)/proxy ] || mkdir $(NGINX_HOME)/proxy
	@[ -d $(NGINX_HOME)/cache ] || mkdir $(NGINX_HOME)/cache
	@cp -f nginx-config/*  $(NGINX_HOME)/conf
	@echo "$${nginxConfig}" > $(NGINX_CONFIG)
	@$(NGINX_HOME)/sbin/nginx -t 
	@ps -lfC nginx | grep master && $(NGINX_HOME)/sbin/nginx -s reload 
	echo "$$($(NGINX_HOME)/sbin/nginx -t -q)"



# curl  http://keplerproject.github.io/luarocks/releases/luarocks-$(shell echo "$$(<$@)").tar.gz | \
#  tar xz --directory $(T)

# curl https://www.openssl.org/source/openssl-$(shell echo "$$(<$@)").tar.gz | \
#  tar xz --directory $(T)
##################################
#
# Set up openresty as a service
# 
#  openresty now symlinked to usr/local/openresty/bin
#
#
#

define openrestyService
[Unit]
Description=OpenResty stack for Nginx HTTP server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=$(NGINX_HOME)/logs/nginx.pid
ExecStartPre=$(OPENRESTY_HOME)bin/openresty -t
ExecStart=$(OPENRESTY_HOME)/bin/openresty
ExecReload=/bin/kill -s HUP $$MAINPID
ExecStop=/bin/kill -s QUIT $$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
endef

orService: export openrestyService:=$(openrestyService)
orService:
	@echo "setup openresty as nginx.service under systemd"
	@$(call assert-is-root)
	@$(call assert-is-systemd)
	@echo 'Check if service is enabled'
	@echo "$(systemctl is-enabled nginx.service)"
	@echo 'Check if service is active'
	@systemctl is-active nginx.service && systemctl stop  nginx.service || echo 'inactive'
	@echo 'Check if service is failed'
	@systemctl is-failed nginx.service || systemctl stop nginx.service && echo 'inactive'
	@echo "$${ngService}"
	@echo "$${ngService}" > /lib/systemd/system/nginx.service
	@systemd-analyze verify nginx.service
	@systemctl is-enabled nginx.service || systemctl enable nginx.service
	@systemctl start nginx.service
	@echo 'Check if service is enabled'
	@systemctl is-enabled nginx.service
	@echo 'Check if service is active'
	@systemctl is-active nginx.service
	@echo 'Check if service is failed'
	@systemctl is-failed nginx.service || echo 'OK!'
	@journalctl -f -u nginx.service -o cat
	@echo '--------------------------------------------------------------'



