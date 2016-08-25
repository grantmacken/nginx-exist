# nginx-exist
my setup for nginx as a reverse proxy for the  eXist database

NOTE: At the mo I am reworking some old bash scripts into a single Makefile.
If it gets to untidy I will add make includes. I am pretty new to Make, so feel
free to point out a better way of doing things.  Why I choose Make, is outlined in
the reasons given by [Mike Bostock](http://bost.ocks.org/mike/make/)

## quick-list make targets

NOTE: run as sudo

1. `make eXist` automated eXist console install from latest release 
2. `make nginx` compile nginx from latest 'mainline' source files
3. `make nginx-config` reset and test nginx config then reload nginx 
4. `make nginx-service`  load on boot service under systemd
5. `make exist-service` load on boot service under systemd 
6. `make webdav` automated webdav install (only for local machine not VPS)
6. `make git-user-as-eXist-user` create an user based on git user-name and access token

---------------------------------------------------------------------------------

**Nginx** as a reverse proxy and cache server for the eXist-db Application
Server

**eXist-db** provides a XML document-oriented schema-less data-store and an
XQuery engine to access and serve this data

-------------------------------------------------------------------------------

Nginx The Web Server, eXist The XML Application Server
------------------------------------------------------

The projects purpose is to help users set up Nginx as as a for eXist-db
application server for both local development and remote production.

It is assumed that the remote server will be a cheap VPS (virtual private
server) provided by a site hosting provider. I use a local one
<http://site-host.co.nz> at the cost of about $30 per month.

Included is the Makefile I will be using to set up such local development
and remote production servers. The project uses a simple config file for some
settings.

##Testing 1, 2, 3

 Please check the install as run on [Travis-ci](https://travis-ci.org/grantmacken/nginx-exist)
 [![status](https://travis-ci.org/grantmacken/nginx-exist.svg)](
 https://travis-ci.org/grantmacken/nginx-exist ).

Tests are in the t directory. Tests are invoked using `prove -v` and use tap output.
Test plans are written in bash using test-more-bash.

Setting up eXist.
-----------------

WARNING!
Backup your existing eXist deployment first.
The process is automated, it will wipe out your  `/usr/local/eXist` folder or
whatever is nominated in the config file.

##Requirements##

A modern Linux OS that uses `systemd`. I recommend  Ubuntu  16.4 onwards

gnu Make, expect, git, curl, wget, java 8 ( I'll include my install script for this later)

##Installing##

 Install Location:
 On our local machine I install eXist into '/usr/local' (see congfig)
 /usr/local out of the box is owned by root, so I change this by `sudo chown -R $USER /usr/local. Because we are changing some system files we will need to run as sudo, however when when you ssh to your remote VPS, you should be root so no need to sudo

The Make script will change ownership back to user, unless we are changing system files

Install: cd into this directory a run `sudo make eXist`

This will
1. establish the latest eXist version
2. download latest eXist install jar
3. create the expect install script. This is used to automate installation
4. run the expect script to install eXist to location nominated in config
   defaults to '/usr/local/eXist'

Other make targets

 `sudo make exist-service`

 This will:
 1. create a systemd exist.service script
 2. enable and start the service

exist.service sets 2 env constants which should be seen by eXist
1. EXIST_HOME
2. SERVER     which will be either development or production

 `sudo make webdav`

This will setup a eXit webdav mount in your home dir `~/eXist`.
It will allow you to browse your eXist database as a system file system.
This can be a bit tricky to setup

Note: do not do this on your VPS production server

##Passwords and Permissions##

Passwords: the default admin password is admin, however if there is a file in the ACCESS_TOKEN_PATH (see config) then our Makefile will use the content of that instead. I use my github access token because it reasonably long and easy to regenerate

On our VPS, the exist.service will run as root.

Setting Up Nginx
----------------

The setup is capable of serving **multiple web-site domains** without altering the Nginx config every time you add a new site. The production server makes use Nginx proxy cache capabilities.

The aim is to make it as simple as possible to set up local development and
remote production servers for hosting websites.

To install run `sudo make nginx`

This will:
1. install latest nginx from source. It will also down the pcre and zlib sources to include in the install
2. create a nginx config file that will enable nginx to act as a reverse proxy
   for eXist

To create an example website the Make creates a dns bypass for the example.com
domain in /etc/hosts 

