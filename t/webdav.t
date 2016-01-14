#!/usr/bin/env bash
source t/setup
use Test::More

plan tests 1

note "test plan for webdav on eXist"

is  "$( ls ~/eXist | grep -oP 'apps' )"\
    "apps"\
    "collection apps is listed under webdav mount"

note "FIN"
