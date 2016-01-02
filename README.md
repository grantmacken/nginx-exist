# nginx-exist
my setup for nginx as a reverse proxy for the  eXist database

NOTE: At the mo I am reworking some old bash scripts into a single Makefile.
If it gets to untidy I will add make includes. I am pretty new to Make, so feel
few to point out a better way of doing things.  Why I choose Make, is outline in
the reasons given by (Mike Bostock)[http://bost.ocks.org/mike/make/]
                         :
**Nginx** as a reverse proxy and cache server for the eXist-db Application
Server

**eXist-db** provides a XML document-oriented schema-less data-store and an
xQuery engine to access and serve this data

-------------------------------------------------------------------------------

Nginx The Web Server, Exist The XML Application Server
------------------------------------------------------

The projects purpose is to help users set up Nginx as as a for eXist-db
application server for both local development and remote production.

It is assumed that the remote server will be a cheap VPS (virtual private
server) provided by a  site hosting provider. I use a local one
<http://site-host.co.nz> at the cost of about $30 per month.

Included is the Makefile I will be using to set up such local development
and remote production servers.

Setting up eXist.
-----------------




Setting Up Nginx
----------------

The setup is capable of serving **multiple web-site domains** without altering the Nginx config every time you
add a new site. The production server makes use Nginx proxy cache capabilities.

The aim is to make it as simple as possible to set up local development and
remote production server for hosting websites.

`systemctl set-environment SERVER=development`
