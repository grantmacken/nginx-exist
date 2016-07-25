#!/bin/bash +x

############################################################
#  Program: preperation for eXist-nginx install on a new ubuntu vps server
#  Author : Grant MacKenzie
#  markup.co.nz
#  grantmacken@gmail.com
#  run as sudo
#
# git clone https://github.com/grantmacken/nginx-eXist-ubuntu
# cd nginx-eXist-ubuntu/vps
# chmod +x vps-prep.sh
############################################################

clear
aptList=(cowsay curl expect net-tools ncurses-term vim w3m tidy)

aptList2=(git build-essential software-properties-common \
python-software-properties tmux)

echoMD '#UTILITY TOOLS#'
echoMD "TASK! Use apt-get to install some utility apps"
for i in ${!aptList[@]}
do
    echoLine
    aptInstall "${aptList[${i}]}"
done
afterReadClear
chkJavaVersion=$(
        java -version  2>&1 |
        grep -oP '\K[0-9]+\.[0-9]+\.[0-9_]+'  |
        head -1
        )

chkOracle8Installer=$(
        dpkg -s oracle-java8-installer  2>/dev/null |
        grep Status
        )

if [ -z "${chkJavaVersion}" ]; then
    echoMD "INFO! No Java version installed"
    while true; do
	read -p "Install oracle-java8 (Y/N)?" answer
	case $answer in
		[Yy]* )
		echo "YES"
		add-apt-repository ppa:webupd8team/java
		apt-get update
		apt-get install oracle-java8-installer
		apt-get install oracle-java8-set-default
		break;;
		[Nn]* ) echo "NO"; break;;
		* ) echo "Please answer yes or no.";;
	esac
    done
else
    echoMD "INFO! Current Java version installed: ${chkJavaVersion}"
    if [ -z "${chkOracle8Installer}" ]; then
        echoMD "TASK! install oracle-java8-installer"
    else
        echoMD "TICK! ORACLE-JAVA8-INSTALLER: ${chkOracle8Installer}"
        okOracle8Installer=$(
        echo  ${chkOracle8Installer} |
        grep -oP 'install ok \Kinstalled'  |
        head -1
        )
        if [ "${okOracle8Installer}" = "installed" ]; then
            echoMD "OK! Looks like oracle-java8-installer ${okOracle8Installer} OK"
        fi
    fi
fi
afterReadClear
echoMD '#BUILD TOOLS#'
echoMD "TASK! Use apt-get to install some BUILD TOOLS"
for i in ${!aptList2[@]}
do
    echoLine
    aptInstall "${aptList2[${i}]}"
done
