 #!/usr/bin/env bash
source t/setup
use Test::More

plan tests 3

note "test plan for ngnix-exist"
note ""

ok "$( [ -n ${EXIST_HOME} ] )"  "eXist home set: ${EXIST_HOME}"

ok "$( [[ -n "$(curl -I -s -f 'http://127.0.0.1:8080/')" ]] )"  'eXist is reachable'

is "$(cd ${EXIST_HOME};echo 'sm:is-authenticated()' |\
 java -jar ${EXIST_HOME}/start.jar client -sqx -u admin -P ${P} |\
 tail -1)" 'true'  'can authenticate with username and password'

note "FIN"

