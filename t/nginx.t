#!/usr/bin/env bash
source t/setup
use Test::More

plan tests 4

note "test plan for nginx install"
note "curl tests use URL:  ${REPO} "

ok "$( [ -n ${NGINX_HOME} ] )"  "nginx home set: ${NGINX_HOME}"

is "$(curl -s -w '%{http_code}' -o /dev/null ${REPO})" \
    '200' \
    'curl should get ${REPO} ok' 

is "$(curl -s -w '%{remote_ip}' -o /dev/null  ${REPO})" \
 '127.0.0.1' \
 "if we have a dns bypass in /etc/hosts\
 when we GET ${REPO}\
 then the remote ip should be 127.0.0.1" 

is "$(curl -s -D /dev/null ${REPO} | grep -oP 'nginx')" \
 'nginx' \
 "nginx should appear in the headers when we GET ${REPO}" 
