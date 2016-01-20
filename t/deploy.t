#!/usr/bin/env bash
source t/setup
use Test::More

cd ${EXIST_HOME}

plan tests 2

note "test plan for ${REPO} deployment"

is $(echo "xmldb:collection-available('/db/apps/${REPO}')" | ${cmdClient} |  tail -1 ) \
 'true' \
 "app collection ${REPO} should be available in eXist app collection"

is "$(curl -s -w '%{http_code}' -o /dev/null ${REPO})" \
    '200' \
    'curl should get ${REPO} ok' 

note "FIN"
