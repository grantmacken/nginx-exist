#!/usr/bin/env bash
source t/setup
use Test::More

plan tests 3

note "test plan for nginx install"

ok "$( [ -n ${NGINX_HOME} ] )"  "nginx home set: ${NGINX_HOME}"

ok "$( [[ -n "$(curl -I -s -f 'http://127.0.0.1:80/')" ]] )"  'nginx is reachable'

is "$(curl -Is http://example.com | grep -oP 'nginx')" \
 'nginx' \
 'example.com dns bypass OK' 

