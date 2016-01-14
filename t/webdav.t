#!/usr/bin/env bash
source t/setup
use Test::More

plan tests 4

note "test plan for webdav on eXist"

is  "$( dpkg -s davfs2  2>/dev/null | grep Status)"\
    "Status: install ok installed"\
    "the apt package davfs2 should be installed"
 

is  "$( test -u /usr/sbin/mount.davfs && echo 'true' )"\
    "true"\
    "the suid bit should be set to allow user to mount webdav as user"

is  "$( id ${USER} 2>/dev/null | grep -oP '(\Kdavfs2)')"\
    "davfs2"\
    "user ${USER} should belong to davfs2 group "
 
is  "$( ls ~/eXist | grep -oP 'apps' )"\
    "apps"\
    "collection apps should be listed under webdav mount"

note "FIN"
