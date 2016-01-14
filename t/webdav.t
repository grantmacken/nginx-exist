#!/usr/bin/env bash
source t/setup
use Test::More

plan tests 5

note "test plan for webdav on eXist"

is  "$( dpkg -s davfs2  2>/dev/null | grep Status)"\
    "Status: install ok installed"\
    "the apt package davfs2 should be installed"

is  "$( groups davfs2 2>/dev/null | grep -oP 'davfs2' | tail -1)"\
    "davfs2"\
    "davfs2 should belong to groups"

is  "$( id ${USER} 2>/dev/null | grep -oP '(\Kdavfs2)')"\
    "davfs2"\
    "user ${USER} should belong to davfs2 group "

is  "$( test -u /usr/sbin/mount.davfs && echo 'true' )"\
    "true"\
    "the suid bit should be set to allow user to mount webdav as user"

is  "$( ls ~/eXist | grep -oP 'apps' )"\
    "apps"\
    "collection apps should be listed under webdav mount"

note "FIN"
