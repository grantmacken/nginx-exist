VPS: Ubuntu prep
=================

To host your sites you can use a cheap VPS (virtual private server)
provided by a server hosting provider.
There are plenty of hosting providers out there.
They are relativly cheap.
With the VPS you should get.
* A fresh install of the latest Ubuntu LTS.
* Root Access password
* An IP address

I use a local hosting provider  <site-host.co.nz>
at the cost of about $30 per month.
The proccess of setting up a new VPS with a fresh Ubuntu install takes minutes.


SSH access
----------

Once you have established a fresh install of Ubuntu on a new VPS and are givin a
root access  with an IP address thhe first thing you will need to do is
set up your SSH keys so you can stop using that root password.

There are plenty of step by step how tos on the web like the one from
<https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2>

To access your remote host using ssh you also might want to simplify your life
with an ssh config
<http://nerderati.com/2011/03/17/simplify-your-life-with-an-ssh-config-file>


Lets go..... and SSH to our new remote Ubuntu server

grant@grant:~/projects/nginx-eXist-ubuntu$ ssh awhitu
Welcome to Ubuntu 14.04.1 LTS (GNU/Linux 3.13.0-24-generic x86_64)

 * Documentation:  https://help.ubuntu.com/

This is a custom SiteHost VPS image for Ubuntu 14.04.1 LTS (14.04)

  We have altered the following:
    Console - The console runs on hvc0 versus tty0

Last login: Fri Oct 10 10:31:50 2014 from 118.82.146.24
root@awhitu

> Run these command to update Ubuntu with latest fixes

root@awhitu:~# apt-get update
root@awhitu:~# apt-get upgrade

> Install git

	root@awhitu:~#  apt-get install git-core

configure your vps servers git username and email on the remote server as the same as your local develoment  machine,

git config --global user.name "John Doe"
git config --global user.email johndoe@example.com
git config --global core.editor vim

copy your local existing git authorising SSH keys to the remote

`scp ~/.shh/id_* awhitu:~/.ssh/id_*


> Get the nginx-eXist-ubuntu scripts

	root@awhitu:~# git clone https://github.com/grantmacken/nginx-eXist-ubuntu
	Cloning into 'nginx-eXist-ubuntu'...
	remote: Counting objects: 375, done.
	remote: Total 375 (delta 0), reused 0 (delta 0)
	Receiving objects: 100% (375/375), 54.36 KiB | 0 bytes/s, done.
	Resolving deltas: 100% (183/183), done.
	Checking connectivity... done.
	root@awhitu:~# cd nginx-eXist-ubuntu

> give ./vps-prep.sh execute permissions and execute


	root@awhitu:~/nginx-eXist-ubuntu/vps# chmod +x vps-prep.sh
	root@awhitu:~/nginx-eXist-ubuntu/vps# ls -al .
	total 16
	drwxr-xr-x 2 root root 4096 Oct 15 11:28 .
	drwxr-xr-x 6 root root 4096 Oct 15 11:28 ..
	-rw-r--r-- 1 root root 2094 Oct 15 11:28 readme.md
	-rwxr-xr-x 1 root root 1071 Oct 15 11:28 vps-prep.sh

	root@awhitu:~/nginx-eXist-ubuntu/vps# ./vps-prep.sh

> We have installed Java 8
> Now we compile from source and install Nginx

	root@awhitu:~# cd ~/nginx-eXist-ubuntu/nginx/install
	root@awhitu:~# chmod +x nginx-install.sh
	root@awhitu:~# ./nginx-install.sh

> We have installed Nginx  /usr/local/nginx

cd ~/nginx-eXist-ubuntu/nginx/install
