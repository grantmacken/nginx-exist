# nginx-exist
my setup for nginx as a reverse proxy for eXist database

NOTE: At the mo I am reworking these scripts.

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
server) provided by site site hosting provider. I use a local one
<http://site-host.co.nz> at the cost of about $30 per month.

Included are the files and scripts I have used to set up such local development
and remote production server enviroments which are capable of serving
 **multiple web-site domains** without altering the Nginx config every time you
add a new site. The production server makes use Nginx proxy cache capabilities.

The aim is to make it as simple as possible to set up local development and
remote production server for hosting websites.

