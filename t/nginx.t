#!/usr/bin/env bash
source t/setup
use Test::More

plan tests 3

note "test plan for nginx install"

ok "$( [ -n ${NGINX_HOME} ] )"  "nginx home set: ${NGINX_HOME}"

is "$(curl -s -w '%{remote_ip}' -o /dev/null  ${REPO})" \
 '127.0.0.1' \
 'if we have a dns bypass in /etc/hosts\
 when we GET ${REPO}\
 then the remote ip should be 127.0.0.1' 

ok "$(curl -s -D /dev/null  ${REPO} | grep -oP 'nginx')" \
 'if nginx is runing\
 when we GET ${REPO} and dump the headers \
 then we should be able to grep nginx' 
