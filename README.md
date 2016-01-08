# nginx-exist
my setup for nginx as a reverse proxy for the  eXist database

NOTE: At the mo I am reworking some old bash scripts into a single Makefile.
If it gets to untidy I will add make includes. I am pretty new to Make, so feel
free to point out a better way of doing things.  Why I choose Make, is outlined in
the reasons given by [Mike Bostock](http://bost.ocks.org/mike/make/)

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
server) provided by a  site hosting provider. I use a local one
<http://site-host.co.nz> at the cost of about $30 per month.

Included is the Makefile I will be using to set up such local development
and remote production servers. The project uses a simple config file for some
settings.

##Testing 1, 2, 3

The install is run on Travis

[![Build Status](https://travis-ci.org/grantmacken/nginx-exist.svg?branch=master)](https://travis-ci.org/grantmacken/nginx-exist)
<br/>[tests](https://travis-ci.org/grantmacken/nginx-exist)
 [![status](https://travis-ci.org/grantmacken/nginx-exist.svg)](
 https://travis-ci.org/grantmacken/nginx-exist )

test are in the t directory. Tests use tap output, using  prove.
Test are written, in bash using test-more-bash 

Setting up eXist.
-----------------

WARNING!
back up your existing eXist deployment first.
The process is automated, it will wipe out your  `/usr/local/eXist` folder or
whatever is nominated in the config file.

##Requirements##

A modern Linux OS that uses `systemd`. I recommend  Ubuntu  15.10 onwards

gnu make, expect, git, curl, wget, java 8 ( I'll include my install script for this later)

##Installing##

 Install Location: On our local machine I install eXist into /usr/local (see congfig)
 /usr/local out of the box is owned by root, so I change this by `sudo chown -R $USER /usr/local`  otherwise you will have to run make as sudo. Alternatively in config change the install location of eXist to somewhere like '~/eXist'.
Note - this is what happens with the Travis build.

 When you ssh to your remote VPS, you should be root so no need to sudo

Install: cd into this directory a run `make`

This will

1. establish the latest eXist version
2. download latest eXist install jar
3. create the expect install script. This is used to automate automate installation
4. run the expect script to install eXist to location nominated in config
   defaults to '/usr/local/eXist'

Other make targets

1. `sudo make exist-service` :  create a systemd exist.service script and then enable and start the service

##Passwords and Permissions##

Passwords: the default admin password is admin, however if there is a file in the ACCESS_TOKEN_PATH (see config) then our Makefile will use the content of that instead. I use my github access token because it reasonably long and easy to regenerate

On our VPS, the exist.service will run as root.

Setting Up Nginx
----------------

The setup is capable of serving **multiple web-site domains** without altering the Nginx config every time you add a new site. The production server makes use Nginx proxy cache capabilities.

The aim is to make it as simple as possible to set up local development and
remote production servers for hosting websites.

`systemctl set-environment SERVER=development`
