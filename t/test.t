#!/usr/bin/env bash
source t/setup
use Test::More

plan tests 7

note "test plan for ngnix-exist"

ok "$( [ -n ${EXIST_HOME} ] )"  "eXist home set: ${EXIST_HOME}"

ok "$( [[ -n "$(curl -I -s -f 'http://127.0.0.1:8080/')" ]] )"  'eXist is reachable'

is "$(curl -Is http://127.0.0.1:8080/ |\
 grep -oP 'Jetty')" 'Jetty'  'Jetty serves on port 8080' 

is "$(cd ${EXIST_HOME};echo 'sm:is-authenticated()' |\
 java -jar ${EXIST_HOME}/start.jar client -sqx -u admin -P ${P} |\
 tail -1)" 'true'  'can authenticate with username and password'

ok "$( [ -n ${NGINX_HOME} ] )"  "nginx home set: ${NGINX_HOME}"

ok "$( [[ -n "$(curl -I -s -f 'http://127.0.0.1:80/')" ]] )"  'nginx is reachable'

is "$(curl -Is http://example.com | grep -oP 'nginx')" \
 'nginx' \
 'example.com dns bypass OK' 


note "FIN"

