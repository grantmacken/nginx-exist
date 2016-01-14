#!/usr/bin/env bash
source t/setup
use Test::More

plan tests 2

note "test plan for webdav on eXist"

is  "$( dpkg -s davfs2  2>/dev/null | grep Status)"\
    "Status: install ok installed"\
    "the apt package davfs2 install OK "

is  "$( ls ~/eXist | grep -oP 'apps' )"\
    "apps"\
    "collection apps is listed under webdav mount"

note "FIN"
