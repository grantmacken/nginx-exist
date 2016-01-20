#!/usr/bin/env bash
source t/setup
use Test::More

cd ${EXIST_HOME}

plan tests 3

note "test plan for ${REPO} deployment"

is $(echo "xmldb:collection-available('/db/apps/${REPO}')" | ${cmdClient} |  tail -1 ) \
 'true' \
 "app collection ${REPO} should be available in eXist app collection"

is $(echo "xmldb:collection-available('/db/data/${REPO}')" | ${cmdClient} |  tail -1 ) \
 'true' \
 "app collection ${REPO} should be available in eXist data collection"

is "$(curl -s -w '%{http_code}' -o /dev/null ${REPO})" \
    '200' \
    "GET ${REPO} should respond with http status code 200 " 

note "FIN"
