#!/usr/bin/env bash
source t/setup
use Test::More

cd ${EXIST_HOME}

plan tests 1

note "test plan for ${REPO} deployment"

is $(echo "xmldb:collection-available('/db/apps/${REPO}')" | ${cmdClient} |  tail -1 ) \
 'true' \
 "app collection ${REPO} should be available in eXist app collection"

note "FIN"
