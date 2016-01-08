 #!/usr/bin/env bash 
source t/setup
use Test::More

function cmdExistClient(){
 echo 'sm:is-authenticated()' |
 java -jar $(EXIST_HOME)/start.jar client -sqx -u admin -P admin
}

plan tests 2

note "test plan for ngnix-exist"
note ""

ok "$( [ -n ${EXIST_HOME} ] )"  'eXist home set'

ok "$( [[ -n "$(curl -I -s -f 'http://127.0.0.1:8080/')" ]] )"  'eXist is reachable'


note "FIN"

